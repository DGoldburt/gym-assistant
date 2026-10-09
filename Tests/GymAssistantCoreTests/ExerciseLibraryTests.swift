import Foundation
import SQLite3
import Testing
@testable import GymAssistantCore

@Suite("Exercise library persistence")
struct ExerciseLibraryTests {
    @Test("Create exercise commits stable identity and owned preferred name")
    func createExercise() throws {
        let fixture = try Fixture()
        let created = try fixture.library.createExercise(preferredName: "Front Squat")

        #expect(created.exercise.preferredNameID == created.preferredName.id)
        #expect(created.exercise.id == created.preferredName.exerciseID)
        let storedPreferredName = try fixture.library.preferredName(for: created.exercise.id)
        #expect(storedPreferredName?.id == created.preferredName.id)
        #expect(storedPreferredName?.exerciseID == created.exercise.id)
        #expect(storedPreferredName?.text == "Front Squat")
    }

    @Test("Add and exactly resolve a confirmed name")
    func addAndResolveName() throws {
        let fixture = try Fixture()
        let created = try fixture.library.createExercise(preferredName: "Single-Leg Romanian Deadlift")
        let alias = try fixture.library.addName("SL RDL", to: created.exercise.id)

        let resolved = try fixture.library.exactName(for: "  sl   rdl ")
        #expect(resolved?.id == alias.id)
        #expect(resolved?.exerciseID == created.exercise.id)
        #expect(resolved?.text == alias.text)
        #expect(resolved?.normalizedText == alias.normalizedText)
        #expect(resolved?.provenance == alias.provenance)
    }

    @Test("Adding the same normalized name to its owner is idempotent")
    func sameOwnerIsIdempotent() throws {
        let fixture = try Fixture()
        let created = try fixture.library.createExercise(preferredName: "Front Squat")

        let existing = try fixture.library.addName(" front   squat ", to: created.exercise.id)
        #expect(existing.id == created.preferredName.id)
    }

    @Test("Only an owned confirmed alias can become preferred")
    func changePreferredName() throws {
        let fixture = try Fixture()
        let rdl = try fixture.library.createExercise(preferredName: "Romanian Deadlift")
        let alias = try fixture.library.addName("RDL", to: rdl.exercise.id)
        let squat = try fixture.library.createExercise(preferredName: "Front Squat")

        let changed = try fixture.library.setPreferredName(" rdl ", for: rdl.exercise.id)
        #expect(changed.id == alias.id)
        #expect(changed.exerciseID == rdl.exercise.id)
        #expect(try fixture.library.preferredName(for: rdl.exercise.id)?.id == alias.id)
        #expect(try fixture.library.preferredName(for: rdl.exercise.id)?.text == "RDL")
        #expect(throws: ExerciseLibraryError.nameNotOwnedByExercise(
            proposedText: "Front Squat",
            exerciseID: rdl.exercise.id
        )) {
            try fixture.library.setPreferredName("Front Squat", for: rdl.exercise.id)
        }
        #expect(try fixture.library.preferredName(for: squat.exercise.id)?.text == "Front Squat")
        #expect(try fixture.library.allNames().count == 3)
    }

    @Test("A normalized name cannot be owned by two exercises")
    func conflictingOwnershipFails() throws {
        let fixture = try Fixture()
        let first = try fixture.library.createExercise(preferredName: "Front Squat")
        let second = try fixture.library.createExercise(preferredName: "Goblet Squat")

        #expect(throws: ExerciseLibraryError.nameOwnershipConflict(
            proposedText: "FRONT  SQUAT",
            existingOwnerID: first.exercise.id
        )) {
            try fixture.library.addName("FRONT  SQUAT", to: second.exercise.id)
        }
    }

    @Test("Database rejects an exercise without an owned preferred name")
    func orphanExerciseFailsAtCommit() throws {
        let fixture = try Fixture()
        var database: OpaquePointer?
        #expect(sqlite3_open(fixture.databaseURL.path, &database) == SQLITE_OK)
        defer { sqlite3_close(database) }

        #expect(sqlite3_exec(database, "PRAGMA foreign_keys = ON", nil, nil, nil) == SQLITE_OK)
        #expect(sqlite3_exec(database, "BEGIN", nil, nil, nil) == SQLITE_OK)

        let orphanID = UUID().uuidString
        let missingNameID = UUID().uuidString
        let insert = "INSERT INTO exercise (id, preferred_name_id, created_at, updated_at) VALUES ('\(orphanID)', '\(missingNameID)', 1, 1)"
        #expect(sqlite3_exec(database, insert, nil, nil, nil) == SQLITE_OK)
        #expect(sqlite3_exec(database, "COMMIT", nil, nil, nil) == SQLITE_CONSTRAINT)
        _ = sqlite3_exec(database, "ROLLBACK", nil, nil, nil)
    }

    @Test("Preferred name must belong to the same exercise")
    func crossOwnedPreferredNameFailsAtCommit() throws {
        let fixture = try Fixture()
        let first = try fixture.library.createExercise(preferredName: "Front Squat")

        var database: OpaquePointer?
        #expect(sqlite3_open(fixture.databaseURL.path, &database) == SQLITE_OK)
        defer { sqlite3_close(database) }
        #expect(sqlite3_exec(database, "PRAGMA foreign_keys = ON", nil, nil, nil) == SQLITE_OK)
        #expect(sqlite3_exec(database, "BEGIN", nil, nil, nil) == SQLITE_OK)

        let secondID = UUID().uuidString
        let insert = "INSERT INTO exercise (id, preferred_name_id, created_at, updated_at) VALUES ('\(secondID)', '\(first.preferredName.id.rawValue.uuidString)', 1, 1)"
        #expect(sqlite3_exec(database, insert, nil, nil, nil) == SQLITE_OK)
        #expect(sqlite3_exec(database, "COMMIT", nil, nil, nil) == SQLITE_CONSTRAINT)
        _ = sqlite3_exec(database, "ROLLBACK", nil, nil, nil)
    }
}

private final class Fixture {
    let directoryURL: URL
    let databaseURL: URL
    let library: ExerciseLibrary

    init() throws {
        directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("gym-assistant-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        databaseURL = directoryURL.appendingPathComponent("exercise-library.sqlite")
        library = try ExerciseLibrary(databaseURL: databaseURL)
    }

    deinit {
        try? FileManager.default.removeItem(at: directoryURL)
    }
}

@Suite("Lifecycle migration")
struct LibraryLifecycleMigrationTests {
    @Test(arguments: [1, 2, 3]) func upgradePreservesRowsAndBackup(version: Int) throws {
        let f = try LegacyLibraryFixture(version: version)
        let library = try ExerciseLibrary(databaseURL: f.url)
        #expect(try library.scalarInt("SELECT MAX(version) FROM schema_version") == 4)
        let name = try #require(try library.exactName(for: "Legacy squat"))
        #expect(name.id.rawValue == f.nameID && name.exerciseID.rawValue == f.exerciseID)
        #expect(name.provenance == .importedConfirmed && name.createdAt == Date(timeIntervalSince1970: 7))
        #expect(try library.scalarInt("SELECT COUNT(*) FROM exercise_review_observation") == 1)
        #expect(try library.scalarInt("SELECT COUNT(*) FROM separate_exercise_decision") == 0)
        let backups = try FileManager.default.contentsOfDirectory(at: f.directory, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.contains("pre-v4") }
        #expect(backups.count == 1)
        let backupVersion = try f.scalar("SELECT MAX(version) FROM schema_version", at: backups[0])
        #expect(backupVersion == version)
        let second = try ExerciseLibrary(databaseURL: f.url)
        #expect(try second.allNames() == library.allNames())
        #expect(try FileManager.default.contentsOfDirectory(at: f.directory, includingPropertiesForKeys: nil).count == 2)
        try second.validateForeignKeys()
    }

    @Test func backupFailurePrecedesMutatingOpen() throws {
        let f = try LegacyLibraryFixture(version: 3)
        let before = try Data(contentsOf: f.url)
        #expect(throws: ExerciseLibraryError.self) {
            try ExerciseLibrary(databaseURL: f.url, beforeUpgradeBackup: {
                throw ExerciseLibraryError.database(message: "Injected backup failure")
            })
        }
        #expect(try Data(contentsOf: f.url) == before)
        #expect(try f.scalar("SELECT MAX(version) FROM schema_version") == 3)
    }

    @Test func failedMigrationRollsBackAndFutureVersionIsRejected() throws {
        let f = try LegacyLibraryFixture(version: 3)
        try f.execute("CREATE TABLE exercise_v4 (unrelated TEXT)")
        #expect(throws: ExerciseLibraryError.self) { try ExerciseLibrary(databaseURL: f.url) }
        #expect(try f.scalar("SELECT MAX(version) FROM schema_version") == 3)
        #expect(try f.scalar("SELECT COUNT(*) FROM exercise_name") == 1)
        try f.execute("INSERT INTO schema_version VALUES(99)")
        #expect(throws: ExerciseLibraryError.self) { try ExerciseLibrary(databaseURL: f.url) }
        #expect(try f.scalar("SELECT MAX(version) FROM schema_version") == 99)
    }

    @Test func legacyPairsAndOccurrenceEvidenceSurviveRebuild() throws {
        let f = try LegacyLibraryFixture(version: 3)
        let otherExercise = UUID()
        let otherName = UUID()
        let ordered = [f.exerciseID.uuidString, otherExercise.uuidString].sorted()
        try f.execute("""
            INSERT INTO exercise VALUES('\(otherExercise)', '\(otherName)', 7, 8);
            INSERT INTO exercise_name VALUES('\(otherName)', '\(otherExercise)', 'Other squat', 'other squat', 'userConfirmed', 7);
            CREATE TABLE separate_exercise_decision (
                first_exercise_id TEXT NOT NULL, second_exercise_id TEXT NOT NULL, created_at REAL NOT NULL,
                PRIMARY KEY(first_exercise_id, second_exercise_id), CHECK(first_exercise_id < second_exercise_id),
                FOREIGN KEY(first_exercise_id) REFERENCES exercise(id), FOREIGN KEY(second_exercise_id) REFERENCES exercise(id));
            INSERT INTO separate_exercise_decision VALUES('\(ordered[0])', '\(ordered[1])', 9);
            CREATE TABLE exercise_observation_ingestion (
                id TEXT PRIMARY KEY NOT NULL, source_kind TEXT NOT NULL, source_reference TEXT NOT NULL,
                source_fingerprint TEXT NOT NULL UNIQUE, created_at REAL NOT NULL);
            INSERT INTO exercise_observation_ingestion VALUES('legacy', 'test', 'fixture', 'legacy-hash', 7);
            CREATE TABLE exercise_observation_occurrence (
                observation_id TEXT NOT NULL, ingestion_id TEXT NOT NULL, source_reference TEXT NOT NULL,
                evidence_text TEXT NOT NULL, occurrence_count INTEGER NOT NULL, created_at REAL NOT NULL,
                PRIMARY KEY(observation_id, ingestion_id, source_reference, evidence_text),
                FOREIGN KEY(observation_id) REFERENCES exercise_review_observation(id),
                FOREIGN KEY(ingestion_id) REFERENCES exercise_observation_ingestion(id));
            INSERT INTO exercise_observation_occurrence VALUES('old-observation', 'legacy', 'fixture', 'Synthetic preserved evidence', 1, 7);
            """)
        let library = try ExerciseLibrary(databaseURL: f.url)
        #expect(try library.separateExerciseDecisionCount() == 1)
        let records = try ExerciseIdentityReviewService(library: library).feedbackRecords()
        #expect(records.first?.occurrences.first?.evidence == "Synthetic preserved evidence")
        try library.validateForeignKeys()
    }

    @Test func invalidLegacyForeignKeyIsNotSilentlyRepaired() throws {
        let f = try LegacyLibraryFixture(version: 3)
        try f.execute("UPDATE exercise SET preferred_name_id = 'missing'")
        #expect(throws: ExerciseLibraryError.self) { try ExerciseLibrary(databaseURL: f.url) }
        #expect(try f.scalar("SELECT MAX(version) FROM schema_version") == 3)
        #expect(try f.scalar("SELECT COUNT(*) FROM exercise_name") == 1)
    }
}

private final class LegacyLibraryFixture {
    let directory: URL
    let url: URL
    let exerciseID = UUID()
    let nameID = UUID()
    init(version: Int) throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("legacy-library-test-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        url = directory.appendingPathComponent("library.sqlite")
        try execute("""
            CREATE TABLE schema_version(version INTEGER PRIMARY KEY);
            INSERT INTO schema_version VALUES(\(version));
            CREATE TABLE exercise (
                id TEXT PRIMARY KEY NOT NULL, preferred_name_id TEXT NOT NULL,
                created_at REAL NOT NULL, updated_at REAL NOT NULL CHECK(updated_at >= created_at),
                FOREIGN KEY(id, preferred_name_id) REFERENCES exercise_name(exercise_id, id) DEFERRABLE INITIALLY DEFERRED);
            CREATE TABLE exercise_name (
                id TEXT PRIMARY KEY NOT NULL, exercise_id TEXT NOT NULL, text TEXT NOT NULL,
                normalized_text TEXT NOT NULL UNIQUE, provenance TEXT NOT NULL, created_at REAL NOT NULL,
                UNIQUE(exercise_id, id), FOREIGN KEY(exercise_id) REFERENCES exercise(id));
            INSERT INTO exercise VALUES('\(exerciseID)', '\(nameID)', 7, 8);
            INSERT INTO exercise_name VALUES('\(nameID)', '\(exerciseID)', 'Legacy squat', 'legacy squat', 'importedConfirmed', 7);
            CREATE TABLE exercise_review_observation (
                id TEXT PRIMARY KEY NOT NULL, observed_name TEXT NOT NULL,
                source_adapter TEXT NOT NULL, source_reference TEXT NOT NULL, occurrence_count INTEGER NOT NULL,
                status TEXT NOT NULL, resolved_exercise_id TEXT NOT NULL DEFAULT '', evidence_snapshot TEXT NOT NULL DEFAULT '',
                created_at REAL NOT NULL, updated_at REAL NOT NULL);
            INSERT INTO exercise_review_observation VALUES('old-observation', 'Other squat', 'test', 'fixture', 1, 'pending', '', '', 7, 7);
            """)
    }
    func execute(_ sql: String) throws {
        var connection: OpaquePointer?
        guard sqlite3_open(url.path, &connection) == SQLITE_OK else { throw ExerciseLibraryError.database(message: "Fixture open failed") }
        defer { sqlite3_close(connection) }
        guard sqlite3_exec(connection, sql, nil, nil, nil) == SQLITE_OK else {
            throw ExerciseLibraryError.database(message: String(cString: sqlite3_errmsg(connection)))
        }
    }
    func scalar(_ sql: String, at databaseURL: URL? = nil) throws -> Int {
        var connection: OpaquePointer?
        guard sqlite3_open((databaseURL ?? url).path, &connection) == SQLITE_OK else { throw ExerciseLibraryError.database(message: "Fixture open failed") }
        defer { sqlite3_close(connection) }
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(connection, sql, -1, &statement, nil) == SQLITE_OK else { throw ExerciseLibraryError.database(message: "Fixture query failed") }
        defer { sqlite3_finalize(statement) }
        guard sqlite3_step(statement) == SQLITE_ROW else { throw ExerciseLibraryError.database(message: "Missing fixture scalar") }
        return Int(sqlite3_column_int(statement, 0))
    }
    deinit { try? FileManager.default.removeItem(at: directory) }
}
