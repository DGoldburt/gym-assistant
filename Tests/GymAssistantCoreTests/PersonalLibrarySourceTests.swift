import Foundation
import SQLite3
import Testing
@testable import GymAssistantCore

@Suite("Personal library source adapter")
struct PersonalLibrarySourceTests {
    @Test("Parses quoted multiline evidence and consolidates normalized wording")
    func multilineAndConsolidation() throws {
        let csv = """
        observed_name_verbatim,source_note,source_line_verbatim,occurrence_count,extraction_status,extraction_note\r
        Front Squat,Program A,"A1 Front Squat, 3x5",2,plausible_exercise,\r
        " FRONT   SQUAT! ",Program B,"First line
        second line",1,plausible_exercise,\r
        DB Floor Press,Program B,DB Floor Press,1,plausible_exercise,\r
        """

        let source = try PersonalLibraryCSVAdapter().parse(data: Data(csv.utf8))
        #expect(source.recordCount == 3)
        #expect(source.occurrenceCount == 4)
        #expect(source.observations.count == 2)
        let squat = source.observations.first { $0.normalizedName == "front squat" }
        #expect(squat?.occurrenceCount == 3)
        #expect(squat?.sources.count == 2)
        #expect(squat?.sources.last?.line == "First line\nsecond line")
    }

    @Test("Stable IDs depend on source hash and normalized wording")
    func stableIdentifiers() throws {
        let csv = """
        observed_name_verbatim,source_note,source_line_verbatim,occurrence_count,extraction_status,extraction_note
        Front Squat,Program A,Front Squat,1,plausible_exercise,
        """
        let adapter = PersonalLibraryCSVAdapter()
        let first = try adapter.parse(data: Data(csv.utf8))
        let second = try adapter.parse(data: Data(csv.utf8))
        #expect(first.sourceHash == second.sourceHash)
        #expect(first.observations.map(\.id) == second.observations.map(\.id))
    }

    @Test("Rejects unreviewed status without echoing private content")
    func rejectsUnreviewedRows() {
        let csv = """
        observed_name_verbatim,source_note,source_line_verbatim,occurrence_count,extraction_status,extraction_note
        Secret Exercise,Private Note,Private line,1,needs_human_review,
        """
        #expect(throws: PersonalLibrarySourceError.unsupportedStatus(record: 2, status: "needs_human_review")) {
            try PersonalLibraryCSVAdapter().parse(data: Data(csv.utf8))
        }
    }

    @Test("Ingestion preserves occurrence provenance and is repeatable")
    func durableIngestion() throws {
        let csv = """
        observed_name_verbatim,source_note,source_line_verbatim,occurrence_count,extraction_status,extraction_note
        Front Squat,Program A,A1 Front Squat,2,plausible_exercise,
        FRONT SQUAT!,Program B,B1 Front Squat,1,plausible_exercise,
        DB Floor Press,Program B,B2 DB Floor Press,1,plausible_exercise,
        """
        let source = try PersonalLibraryCSVAdapter().parse(data: Data(csv.utf8))
        let (ingestion, observations) = source.ingestion(sourceReference: "fixture-import")
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("gym-assistant-ingestion-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let library = try ExerciseLibrary(databaseURL: directory.appendingPathComponent("library.sqlite"))
        let service = ExerciseIdentityReviewService(library: library)

        let first = try service.ingest(ingestion, observations: observations)
        let second = try service.ingest(ingestion, observations: observations)
        let queue = try service.reviewQueue()

        #expect(first.alreadyIngested == false)
        #expect(second.alreadyIngested == true)
        #expect(first.observationCount == 2)
        #expect(first.occurrenceCount == 4)
        #expect(queue.count == 2)
        let squat = queue.first { $0.observation.observedName == "Front Squat" }
        #expect(squat?.occurrences.count == 2)
        #expect(squat?.occurrences.reduce(0, { $0 + $1.occurrenceCount }) == 3)
        #expect(squat?.occurrences.map(\.sourceReference) == ["Program A", "Program B"])
    }

    @Test("A failed occurrence write rolls back the ingestion and observation")
    func ingestionRollback() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("gym-assistant-ingestion-rollback-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let databaseURL = directory.appendingPathComponent("library.sqlite")
        let library = try ExerciseLibrary(databaseURL: databaseURL)
        let service = ExerciseIdentityReviewService(library: library)

        var database: OpaquePointer?
        #expect(sqlite3_open(databaseURL.path, &database) == SQLITE_OK)
        defer { sqlite3_close(database) }
        #expect(sqlite3_exec(
            database,
            """
            CREATE TRIGGER reject_fixture_occurrence
            BEFORE INSERT ON exercise_observation_occurrence
            BEGIN SELECT RAISE(ABORT, 'controlled fixture failure'); END;
            """,
            nil,
            nil,
            nil
        ) == SQLITE_OK)

        let ingestion = ExerciseObservationIngestion(
            id: "rollback-ingestion",
            sourceKind: "fixture",
            sourceReference: "rollback-source",
            sourceFingerprint: "rollback-fingerprint"
        )
        let observation = IngestedExerciseObservation(
            observation: .init(
                id: .init(rawValue: "rollback-observation"),
                observedName: "Rollback Exercise",
                source: .init(adapter: "fixture", reference: "rollback-ingestion"),
                occurrenceCount: 1
            ),
            occurrences: [.init(sourceReference: "row-1", evidence: "Rollback Exercise", occurrenceCount: 1)]
        )

        #expect(throws: (any Error).self) {
            try service.ingest(ingestion, observations: [observation])
        }
        #expect(try service.reviewQueue().isEmpty)
    }

    @Test("Feedback export preserves outcomes, skipped evidence, and provenance")
    func feedbackExport() throws {
        let csv = """
        observed_name_verbatim,source_note,source_line_verbatim,occurrence_count,extraction_status,extraction_note
        Front Squat,Program A,A1 Front Squat,2,plausible_exercise,
        DB Floor Press,Program B,B1 DB Floor Press,1,plausible_exercise,
        """
        let source = try PersonalLibraryCSVAdapter().parse(data: Data(csv.utf8))
        let (ingestion, observations) = source.ingestion(sourceReference: "feedback-fixture")
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("gym-assistant-feedback-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let library = try ExerciseLibrary(databaseURL: directory.appendingPathComponent("library.sqlite"))
        _ = try library.createExercise(preferredName: "Dumbbell Floor Press")
        let service = ExerciseIdentityReviewService(library: library)
        _ = try service.ingest(ingestion, observations: observations)

        let squatID = try #require(source.observations.first { $0.observedName == "Front Squat" }?.id)
        let floorPressID = try #require(source.observations.first { $0.observedName == "DB Floor Press" }?.id)
        _ = try service.create(observationID: squatID)
        _ = try service.deferDecision(observationID: floorPressID)

        let records = try service.feedbackRecords()
        let squat = try #require(records.first { $0.observation.id == squatID })
        let floorPress = try #require(records.first { $0.observation.id == floorPressID })
        #expect(squat.status == .created)
        #expect(squat.resolvedExerciseID != nil)
        #expect(squat.occurrences == [
            .init(sourceReference: "Program A", evidence: "A1 Front Squat", occurrenceCount: 2),
        ])
        #expect(floorPress.status == .deferred)
        #expect(floorPress.resolvedExerciseID == nil)
        #expect(!floorPress.evidenceSnapshot.isEmpty)
        #expect(floorPress.occurrences.first?.sourceReference == "Program B")
    }
}
