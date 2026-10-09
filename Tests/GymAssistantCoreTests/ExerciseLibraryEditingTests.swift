import Foundation
import SQLite3
import Testing
@testable import GymAssistantCore

@Suite("Library identity edits")
struct ExerciseLibraryEditingTests {
    @Test func movingAliasPreservesBothIdentitiesOtherNamesAndReplay() throws {
        let f = try EditFixture()
        let source = try f.library.createExercise(preferredName: "Squat")
        let alias = try f.library.addName("DB Squat", to: source.exercise.id)
        let storedAlias = try f.service.detail(exerciseID: source.exercise.id).names.first { $0.id == alias.id }!
        let destination = try f.library.createExercise(preferredName: "Dumbbell Squat")
        let preview = try f.service.previewMoveName(nameID: alias.id, from: source.exercise.id, to: destination.exercise.id)
        #expect(preview.confirmationPrompt == "Move ‘DB Squat’ to this exercise?")
        #expect(preview.confirmationDetails == "Dumbbell Squat")
        let receipt = try f.service.apply(preview, confirmation: .init(confirming: preview))
        #expect(receipt.mergedSource == nil && receipt.mergedInto == nil)
        #expect(try f.service.detail(exerciseID: source.exercise.id).names.map(\.text) == ["Squat"])
        let moved = try f.service.detail(exerciseID: destination.exercise.id).names.first { $0.id == alias.id }
        #expect(moved?.text == storedAlias.text && moved?.provenance == storedAlias.provenance && moved?.createdAt == storedAlias.createdAt)
        #expect(try f.library.resolvedExerciseID(for: source.exercise.id) == source.exercise.id)
        #expect(try f.library.resolvedExerciseID(for: destination.exercise.id) == destination.exercise.id)
        #expect(try f.service.apply(preview, confirmation: .init(confirming: preview)) == receipt)
        let reopened = try ExerciseLibrary(databaseURL: f.url)
        #expect(try ExerciseLibraryEditService(library: reopened).receipt(operationID: preview.operationID) == receipt)
        try f.library.validateForeignKeys()
    }

    @Test func movingHiddenDefaultRepairsSourceAndRejectsStaleOrInvalidMoves() throws {
        let f = try EditFixture()
        let source = try f.library.createExercise(preferredName: "Squat")
        let remaining = try f.library.addName("Back Squat", to: source.exercise.id)
        let destination = try f.library.createExercise(preferredName: "Dumbbell Squat")
        #expect(throws: LibraryEditError.sameIdentity) {
            try f.service.previewMoveName(nameID: source.preferredName.id, from: source.exercise.id, to: source.exercise.id)
        }
        #expect(throws: LibraryEditError.onlyNameCannotSplit) {
            try f.service.previewMoveName(nameID: destination.preferredName.id, from: destination.exercise.id, to: source.exercise.id)
        }
        #expect(throws: LibraryEditError.nameNotOwned(destination.preferredName.id)) {
            try f.service.previewMoveName(nameID: destination.preferredName.id, from: source.exercise.id, to: destination.exercise.id)
        }
        let stale = try f.service.previewMoveName(nameID: source.preferredName.id, from: source.exercise.id, to: destination.exercise.id)
        _ = try f.library.addName("Goblet Squat", to: destination.exercise.id)
        #expect(throws: LibraryEditError.stalePreview) {
            try f.service.apply(stale, confirmation: .init(confirming: stale))
        }
        let preview = try f.service.previewMoveName(nameID: source.preferredName.id, from: source.exercise.id, to: destination.exercise.id)
        #expect(preview.replacementPreferredNameID == remaining.id)
        try f.library.execute("CREATE TRIGGER fail_move BEFORE INSERT ON exercise_library_edit BEGIN SELECT RAISE(ABORT, 'injected'); END")
        #expect(throws: ExerciseLibraryError.self) { try f.service.apply(preview, confirmation: .init(confirming: preview)) }
        #expect(try f.service.detail(exerciseID: source.exercise.id) == preview.before[0])
        #expect(try f.service.detail(exerciseID: destination.exercise.id) == preview.before[1])
        #expect(try f.service.receipt(operationID: preview.operationID) == nil)
        try f.library.execute("DROP TRIGGER fail_move")
        _ = try f.service.apply(preview, confirmation: .init(confirming: preview))
        #expect(try f.service.detail(exerciseID: source.exercise.id).preferredName.id == remaining.id)
        #expect(try f.service.detail(exerciseID: destination.exercise.id).preferredName.id == destination.preferredName.id)
        try f.library.validateForeignKeys()
    }

    @Test func combineRetainsEditingExerciseWithOneConfirmation() throws {
        let f = try EditFixture()
        let edited = try f.library.createExercise(preferredName: "Romanian Deadlift")
        _ = try f.library.addName("RDL", to: edited.exercise.id)
        let duplicate = try f.library.createExercise(preferredName: "Romanian DL")
        let before = try f.library.allNames()
        let preview = try f.service.previewCombine(retaining: edited.exercise.id, duplicate: duplicate.exercise.id)
        #expect(preview.action == .merge(source: duplicate.exercise.id, survivor: edited.exercise.id))
        #expect(preview.confirmationPrompt == "Combine these exercises?")
        #expect(preview.confirmationDetails.contains("Romanian Deadlift, RDL"))
        #expect(preview.confirmationDetails.contains("Romanian DL"))
        #expect(!preview.confirmationDetails.contains("survivor"))
        #expect(!preview.confirmationDetails.contains("All names remain available"))
        #expect(try f.library.allNames() == before) // cancellation requires no write
        let receipt = try f.service.apply(preview, confirmation: .init(confirming: preview))
        #expect(receipt.after[0].exercise.id == edited.exercise.id)
        #expect(receipt.after[0].preferredName.id == edited.preferredName.id)
        #expect(try f.library.resolvedExerciseID(for: duplicate.exercise.id) == edited.exercise.id)
        #expect(Set(receipt.after[0].names.map(\.id)) == Set(before.map(\.id)))
    }

    @Test func mergeChainPreservesNamesAndOldIDs() throws {
        let f = try EditFixture()
        let a = try f.library.createExercise(preferredName: "RDL")
        _ = try f.library.addName("Romanian DL", to: a.exercise.id, provenance: .importedConfirmed)
        // Compare the persisted baseline: Date -> SQLite REAL can round submicroseconds.
        let alias = try #require(try f.library.exactName(for: "Romanian DL"))
        let b = try f.library.createExercise(preferredName: "Romanian Deadlift")
        let c = try f.library.createExercise(preferredName: "Hip hinge")
        let preview = try f.service.previewMerge(source: a.exercise.id, survivor: b.exercise.id)
        #expect(try f.library.allPreferredNames().count == 3) // preparation is read-only
        let receipt = try f.service.apply(preview, confirmation: .init(confirming: preview))
        let moved = try #require(try f.library.exactName(for: alias.text))
        #expect(moved.id == alias.id && moved.createdAt == alias.createdAt && moved.provenance == alias.provenance)
        #expect(moved.exerciseID == b.exercise.id)
        #expect(try f.library.preferredName(for: a.exercise.id)?.id == b.preferredName.id)
        #expect(try f.service.apply(preview, confirmation: .init(confirming: preview)) == receipt)
        let next = try f.service.previewMerge(source: b.exercise.id, survivor: c.exercise.id)
        _ = try f.service.apply(next, confirmation: .init(confirming: next))
        #expect(try f.library.resolvedExerciseID(for: a.exercise.id) == c.exercise.id)
        #expect(try f.library.allPreferredNames().count == 1)
        #expect(try ExerciseAutocompleteSearch(library: f.library).search("RDL").first?.exerciseID == c.exercise.id)
        #expect(throws: ExerciseLibraryError.self) { try f.library.addName("New", to: a.exercise.id) }
        #expect(throws: ExerciseLibraryError.self) { try f.library.setPreferredName("RDL", for: a.exercise.id) }
        let reopened = try ExerciseLibrary(databaseURL: f.url)
        #expect(try reopened.resolvedExerciseID(for: a.exercise.id) == c.exercise.id)
        #expect(try ExerciseLibraryEditService(library: reopened).receipt(operationID: preview.operationID) == receipt)
        #expect(throws: ExerciseLibraryError.self) { try f.library.execute("DELETE FROM exercise_library_edit") }
        #expect(throws: ExerciseLibraryError.self) { try f.library.execute("UPDATE exercise_library_edit SET payload = '{}' ") }
    }

    @Test func splitAliasAndPreferredWithoutChooser() throws {
        let f = try EditFixture()
        let original = try f.library.createExercise(preferredName: "Romanian Deadlift", now: Date(timeIntervalSince1970: 1))
        let first = try f.library.addName("RDL", to: original.exercise.id, now: Date(timeIntervalSince1970: 2))
        let second = try f.library.addName("Romanian DL", to: original.exercise.id, now: Date(timeIntervalSince1970: 3))
        let ordinary = try f.service.previewSplit(nameID: second.id, from: original.exercise.id)
        #expect(ordinary.replacementPreferredNameID == nil)
        #expect(ordinary.confirmationPrompt == "Promote ‘Romanian DL’ to its own exercise?")
        let separated = try f.service.apply(ordinary, confirmation: .init(confirming: ordinary))
        #expect(separated.after[1].preferredName.id == second.id)
        let preferred = try f.service.previewSplit(nameID: original.preferredName.id, from: original.exercise.id)
        #expect(preferred.replacementPreferredNameID == first.id)
        #expect(preferred.confirmationPrompt == "Promote ‘Romanian Deadlift’ to its own exercise?")
        #expect(preferred.confirmationDetails.isEmpty)
        let result = try f.service.apply(preferred, confirmation: .init(confirming: preferred))
        #expect(result.after[0].preferredName.id == first.id)
        #expect(result.after[1].preferredName.id == original.preferredName.id)
        #expect(throws: LibraryEditError.onlyNameCannotSplit) {
            try f.service.previewSplit(nameID: first.id, from: original.exercise.id)
        }
    }

    @Test func stalePreviewAndMismatchedConfirmationDoNotWrite() throws {
        let f = try EditFixture()
        let a = try f.library.createExercise(preferredName: "A")
        let b = try f.library.createExercise(preferredName: "B")
        let preview = try f.service.previewMerge(source: a.exercise.id, survivor: b.exercise.id)
        let other = try f.service.previewMerge(source: b.exercise.id, survivor: a.exercise.id)
        #expect(throws: LibraryEditError.confirmationMismatch) {
            try f.service.apply(preview, confirmation: .init(confirming: other))
        }
        _ = try f.library.addName("A alias", to: a.exercise.id)
        #expect(throws: LibraryEditError.stalePreview) {
            try f.service.apply(preview, confirmation: .init(confirming: preview))
        }
        #expect(try f.service.receipt(operationID: preview.operationID) == nil)
        #expect(try f.library.allPreferredNames().count == 2)
    }

    @Test func receiptFailureRollsBackOwnershipAndRedirect() throws {
        let f = try EditFixture()
        let a = try f.library.createExercise(preferredName: "A")
        let b = try f.library.createExercise(preferredName: "B")
        let preview = try f.service.previewMerge(source: a.exercise.id, survivor: b.exercise.id)
        try f.library.execute("CREATE TRIGGER fail_receipt BEFORE INSERT ON exercise_library_edit BEGIN SELECT RAISE(ABORT, 'injected'); END")
        #expect(throws: ExerciseLibraryError.self) { try f.service.apply(preview, confirmation: .init(confirming: preview)) }
        #expect(try f.library.exactName(for: "A")?.exerciseID == a.exercise.id)
        #expect(try f.library.resolvedExerciseID(for: a.exercise.id) == a.exercise.id)
        #expect(try f.service.receipt(operationID: preview.operationID) == nil)
        try f.library.execute("DROP TRIGGER fail_receipt")
        _ = try f.service.apply(preview, confirmation: .init(confirming: preview))
        let conflicting = LibraryEditPreview(operationID: preview.operationID, action: .merge(source: b.exercise.id, survivor: a.exercise.id),
                                             before: preview.before, replacementPreferredNameID: nil, fingerprint: preview.fingerprint)
        #expect(throws: LibraryEditError.operationIDConflict) { try f.service.apply(conflicting, confirmation: .init(confirming: conflicting)) }
    }

    @Test func staleBackAfterSplitOrMergePreservesHistory() throws {
        let f = try EditFixture()
        let review = ExerciseIdentityReviewService(library: f.library)
        let observation = StagedExerciseObservation(id: .init(rawValue: "sample"), observedName: "DB squat",
                                                   source: .init(adapter: "test", reference: "test"), occurrenceCount: 1)
        try review.stage(observation)
        let a = try f.library.createExercise(preferredName: "Dumbbell squat")
        let (_, undo) = try review.linkWithUndoReceipt(observationID: observation.id, to: a.exercise.id)
        let alias = try #require(try f.library.exactName(for: "DB squat"))
        let split = try f.service.previewSplit(nameID: alias.id, from: a.exercise.id)
        _ = try f.service.apply(split, confirmation: .init(confirming: split))
        #expect(throws: ExerciseIdentityReviewError.incompatibleRepeatedDecision) { try review.undo(undo) }
        #expect(try f.library.exactName(for: "DB squat")?.id == alias.id)
        #expect(try review.feedbackRecords().first?.resolvedExerciseID == a.exercise.id)
        let createdObservation = StagedExerciseObservation(id: .init(rawValue: "created"), observedName: "Other squat",
                                                          source: observation.source, occurrenceCount: 1)
        try review.stage(createdObservation)
        let (_, createdUndo) = try review.createWithUndoReceipt(observationID: createdObservation.id)
        let createdID = try #require(createdUndo.resolvedExerciseID)
        let merge = try f.service.previewMerge(source: createdID, survivor: a.exercise.id)
        _ = try f.service.apply(merge, confirmation: .init(confirming: merge))
        #expect(throws: ExerciseIdentityReviewError.incompatibleRepeatedDecision) { try review.undo(createdUndo) }
        #expect(try f.library.resolvedExerciseID(for: createdID) == a.exercise.id)
    }

    @Test func lifecycleGuardsAndCycleDetection() throws {
        let f = try EditFixture()
        let a = try f.library.createExercise(preferredName: "A")
        let b = try f.library.createExercise(preferredName: "B")
        #expect(throws: ExerciseLibraryError.self) {
            try f.library.execute("UPDATE exercise SET lifecycle = 'merged', preferred_name_id = NULL, merged_into_id = '\(b.exercise.id.rawValue)' WHERE id = '\(a.exercise.id.rawValue)'")
        }
        #expect(throws: ExerciseLibraryError.self) { try f.library.execute("UPDATE exercise SET preferred_name_id = NULL") }
        let p = try f.service.previewMerge(source: a.exercise.id, survivor: b.exercise.id)
        _ = try f.service.apply(p, confirmation: .init(confirming: p))
        #expect(throws: ExerciseLibraryError.self) {
            try f.library.execute("UPDATE exercise_name SET exercise_id = '\(a.exercise.id.rawValue)' WHERE exercise_id = '\(b.exercise.id.rawValue)'")
        }
        // Corrupt synthetic redirects deliberately to prove reads fail explicitly.
        let c = UUID().uuidString
        try f.library.execute("INSERT INTO exercise(id, preferred_name_id, created_at, updated_at, lifecycle, merged_into_id) VALUES ('\(c)', NULL, 1, 1, 'merged', '\(a.exercise.id.rawValue)')")
        try f.library.execute("UPDATE exercise SET merged_into_id = '\(c)' WHERE id = '\(a.exercise.id.rawValue)'")
        #expect(throws: ExerciseLibraryError.self) { try f.library.resolvedExerciseID(for: a.exercise.id) }
    }

    @Test func backAfterExactAliasReuseDoesNotDeleteEstablishedName() throws {
        let f = try EditFixture()
        let exercise = try f.library.createExercise(preferredName: "Dumbbell squat")
        let alias = try f.library.addName("DB squat", to: exercise.exercise.id)
        let review = ExerciseIdentityReviewService(library: f.library)
        let observation = StagedExerciseObservation(id: .init(rawValue: "reuse"), observedName: alias.text,
                                                   source: .init(adapter: "test", reference: "test"), occurrenceCount: 1)
        try review.stage(observation)
        let (_, undo) = try review.createWithUndoReceipt(observationID: observation.id)
        #expect(undo.writtenNameID == nil)
        try review.undo(undo)
        #expect(try f.library.exactName(for: alias.text)?.id == alias.id)
        #expect(try review.feedbackRecords().first?.status == .pending)
    }

    @Test func splitRollbackAndSourceEvidenceDoNotLeakIntoReceipt() throws {
        let f = try EditFixture()
        let review = ExerciseIdentityReviewService(library: f.library)
        let ingestion = ExerciseObservationIngestion(id: "synthetic", sourceKind: "test", sourceReference: "test", sourceFingerprint: "synthetic-fingerprint")
        let observation = StagedExerciseObservation(id: .init(rawValue: "source"), observedName: "DB squat",
                                                   source: .init(adapter: "test", reference: ingestion.id), occurrenceCount: 1)
        let evidence = "PRIVATE SYNTHETIC SOURCE LINE"
        _ = try review.ingest(ingestion, observations: [.init(observation: observation, occurrences: [.init(sourceReference: "synthetic location", evidence: evidence, occurrenceCount: 1)])])
        let exercise = try f.library.createExercise(preferredName: "Dumbbell squat")
        _ = try review.link(observationID: observation.id, to: exercise.exercise.id)
        let name = try #require(try f.library.exactName(for: "DB squat"))
        #expect(try f.service.sourceEvidence(nameID: name.id).first?.evidence == evidence)
        let preview = try f.service.previewSplit(nameID: exercise.preferredName.id, from: exercise.exercise.id)
        try f.library.execute("CREATE TRIGGER fail_split BEFORE INSERT ON exercise_library_edit BEGIN SELECT RAISE(ABORT, 'injected'); END")
        #expect(throws: ExerciseLibraryError.self) { try f.service.apply(preview, confirmation: .init(confirming: preview)) }
        #expect(try f.library.preferredName(for: exercise.exercise.id)?.id == exercise.preferredName.id)
        #expect(try f.library.allPreferredNames().count == 1)
        try f.library.execute("DROP TRIGGER fail_split")
        let receipt = try f.service.apply(preview, confirmation: .init(confirming: preview))
        let payload = String(decoding: try JSONEncoder().encode(receipt), as: UTF8.self)
        #expect(!payload.contains(evidence))
        #expect(try review.feedbackRecords().first?.resolvedExerciseID == exercise.exercise.id)
    }
}

private final class EditFixture {
    let directory: URL
    let url: URL
    let library: ExerciseLibrary
    let service: ExerciseLibraryEditService
    init() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("library-edit-test-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        url = directory.appendingPathComponent("library.sqlite")
        library = try ExerciseLibrary(databaseURL: url)
        service = ExerciseLibraryEditService(library: library)
    }
    deinit { try? FileManager.default.removeItem(at: directory) }
}
