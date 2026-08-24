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
