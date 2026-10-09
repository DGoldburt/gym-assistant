import Foundation
import Testing
@testable import GymAssistantCore

@Suite("Library maintenance navigation and CSV import")
struct LibraryMaintenanceTests {
    @Test func chooserExpansionsAreIndependent() {
        let first = ExerciseID(rawValue: UUID())
        let second = ExerciseID(rawValue: UUID())
        var expansion = ExerciseChooserExpansion()
        expansion.expand(first)
        expansion.expand(second)
        #expect(expansion.expandedIDs == [first, second])
        expansion.collapse(first)
        #expect(expansion.expandedIDs == [second])
        expansion.reset()
        #expect(expansion.expandedIDs.isEmpty)
    }

    @Test func promotionRequiresAnExplicitAliasAndMergeSupportsBothRowKinds() {
        #expect(LibraryMaintenanceRowActions(isAlias: false, confirmedNameCount: 3) == .init(isAlias: false, confirmedNameCount: 1))
        #expect(!LibraryMaintenanceRowActions(isAlias: false, confirmedNameCount: 3).canPromote)
        #expect(LibraryMaintenanceRowActions(isAlias: true, confirmedNameCount: 3).canPromote)
        #expect(LibraryMaintenanceRowActions(isAlias: true, confirmedNameCount: 3).canCombine)
        #expect(!LibraryMaintenanceRowActions(isAlias: true, confirmedNameCount: 1).canPromote)
    }

    @Test func editEntryWithoutSelectionStartsSearchWithoutIdentity() {
        let nav = LibraryMaintenanceNavigation(route: .edit, query: "", selection: nil)
        #expect(nav.route == .edit)
        #expect(nav.selection == nil)
        #expect(nav.editQuery.isEmpty)
    }

    @Test func mergeSearchPrefillsSelectedAliasAndRetainsVisibleAlternatives() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("merge-search-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let library = try ExerciseLibrary(databaseURL: directory.appendingPathComponent("library.sqlite"))
        let source = try library.createExercise(preferredName: "Dumbbell Squat")
        let other = try library.createExercise(preferredName: "Dumbbell Front Squat")
        let before = try library.allNames()
        let visible = try ExerciseAutocompleteSearch(library: library).search("Dumbbell")
        let start = LibraryDuplicateSearchStart(selectedName: "DB Squat", source: source.exercise.id, visibleMatches: visible)
        #expect(start.query == "DB Squat")
        #expect(start.retainedCandidates?.map(\.exerciseID) == [other.exercise.id])
        let onlySource = visible.filter { $0.exerciseID == source.exercise.id }
        #expect(LibraryDuplicateSearchStart(selectedName: "Dumbbell Squat", source: source.exercise.id, visibleMatches: onlySource).retainedCandidates == nil)
        #expect(try library.allNames() == before)
    }

    @Test func peerAndChildNavigationPreservesDraftsAndIdentity() {
        let selection = LibraryMaintenanceSelection(exerciseID: .init(rawValue: UUID()), nameID: .init(rawValue: UUID()))
        var nav = LibraryMaintenanceNavigation(route: .edit, query: "RDL", selection: selection)
        nav.show(.add)
        nav.creationDraft = "My exercise"
        nav.show(.importSource)
        nav.show(.reviewCandidates)
        nav.back()
        #expect(nav.route == .importSource)
        nav.back()
        #expect(nav.route == .add)
        nav.show(.edit)
        #expect(nav.selection == selection && nav.creationDraft == "My exercise" && nav.editQuery == "RDL")
    }

    @Test func importPreviewChangedFileAndPendingBadge() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("maintenance-test-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("library.sqlite")
        let library = try ExerciseLibrary(databaseURL: url)
        let imports = LibraryImportService(library: library)
        let review = ExerciseIdentityReviewService(library: library)
        let known = try library.createExercise(preferredName: "Dumbbell Squat")
        let csv = Data("""
            observed_name_verbatim,source_note,source_line_verbatim,occurrence_count,extraction_status,extraction_note
            Dumbbell Squat,Synthetic,Synthetic line,2,plausible_exercise,
            DB Squat,Synthetic,Synthetic line,3,plausible_exercise,
            Other exercise,Synthetic,Synthetic line,1,plausible_exercise,
            """.utf8)
        let preview = try imports.preview(data: csv, sourceReference: "synthetic.csv")
        #expect(preview.source.recordCount == 3 && preview.source.observations.count == 3)
        #expect(preview.exactReuseCount == 1)
        #expect(try imports.pendingReviewCount() == 0)
        let changed = csv + Data("\nNew exercise,Synthetic,Line,1,plausible_exercise,\n".utf8)
        #expect(throws: LibraryImportError.sourceChanged) { try imports.apply(preview, currentData: changed) }
        #expect(try imports.pendingReviewCount() == 0)
        let result = try imports.apply(preview, currentData: csv)
        #expect(result.observationCount == 3 && result.occurrenceCount == 6)
        #expect(try imports.pendingReviewCount() == 2)
        #expect(try imports.apply(preview, currentData: csv).alreadyIngested)
        let renamed = try imports.preview(data: csv, sourceReference: "renamed.csv")
        #expect(try imports.apply(renamed, currentData: csv).alreadyIngested)
        #expect(try imports.pendingReviewCount() == 2)
        let other = try #require(try review.reviewQueue().first { $0.observation.observedName == "Other exercise" })
        let (_, undoSkip) = try review.skipWithUndoReceipt(observationID: other.observation.id)
        #expect(try imports.pendingReviewCount() == 1)
        try review.undo(undoSkip)
        #expect(try imports.pendingReviewCount() == 2)
        let alias = try #require(try review.reviewQueue().first { $0.observation.observedName == "DB Squat" })
        let (_, undoLink) = try review.linkWithUndoReceipt(observationID: alias.observation.id, to: known.exercise.id)
        #expect(try imports.pendingReviewCount() == 1)
        try review.undo(undoLink)
        #expect(try imports.pendingReviewCount() == 2)
        _ = try review.create(observationID: alias.observation.id)
        _ = try review.create(observationID: other.observation.id)
        #expect(try imports.pendingReviewCount() == 0)
        #expect(try LibraryImportService(library: ExerciseLibrary(databaseURL: url)).pendingReviewCount() == 0)
    }

    @Test func malformedAndEmptyImportsStageNothing() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("invalid-import-test-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let library = try ExerciseLibrary(databaseURL: directory.appendingPathComponent("library.sqlite"))
        let service = LibraryImportService(library: library)
        #expect(throws: PersonalLibrarySourceError.invalidHeader) { try service.preview(data: Data("bad header".utf8), sourceReference: "test") }
        #expect(throws: LibraryImportError.noObservations) {
            try service.preview(data: Data("observed_name_verbatim,source_note,source_line_verbatim,occurrence_count,extraction_status,extraction_note\n".utf8), sourceReference: "test")
        }
        #expect(try service.pendingReviewCount() == 0)
        #expect(try library.allNames().isEmpty)
    }
}
