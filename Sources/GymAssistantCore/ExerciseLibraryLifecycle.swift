import Foundation
import SQLite3

struct MergedExerciseRecord: Equatable, Sendable {
    let id: ExerciseID
    let targetID: ExerciseID
    let createdAt: Date
    let updatedAt: Date
}

extension ExerciseLibrary {
    static let lifecycleSchema = """
        CREATE TABLE exercise_v4 (
            id TEXT PRIMARY KEY NOT NULL,
            preferred_name_id TEXT,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL CHECK (updated_at >= created_at),
            lifecycle TEXT NOT NULL DEFAULT 'active',
            merged_into_id TEXT,
            CHECK ((lifecycle = 'active' AND preferred_name_id IS NOT NULL AND merged_into_id IS NULL)
                OR (lifecycle = 'merged' AND preferred_name_id IS NULL AND merged_into_id IS NOT NULL AND merged_into_id <> id)),
            FOREIGN KEY (id, preferred_name_id) REFERENCES exercise_name(exercise_id, id)
                DEFERRABLE INITIALLY DEFERRED,
            FOREIGN KEY (merged_into_id) REFERENCES exercise(id)
        );
        CREATE TABLE exercise_name_v4 (
            id TEXT PRIMARY KEY NOT NULL,
            exercise_id TEXT NOT NULL,
            text TEXT NOT NULL CHECK (length(trim(text)) > 0),
            normalized_text TEXT NOT NULL UNIQUE CHECK (length(trim(normalized_text)) > 0),
            provenance TEXT NOT NULL CHECK (provenance IN ('systemSeeded', 'userConfirmed', 'importedConfirmed')),
            created_at REAL NOT NULL,
            UNIQUE (exercise_id, id),
            FOREIGN KEY (exercise_id) REFERENCES exercise(id)
        );
        CREATE TABLE exercise_library_edit (
            operation_id TEXT PRIMARY KEY NOT NULL,
            action TEXT NOT NULL CHECK (action IN ('merge', 'split')),
            created_at REAL NOT NULL,
            payload_version INTEGER NOT NULL CHECK (payload_version = 1),
            payload TEXT NOT NULL
        );
        """

    static let lifecycleGuards = """
        CREATE TRIGGER exercise_name_active_insert BEFORE INSERT ON exercise_name
        WHEN NOT EXISTS (SELECT 1 FROM exercise WHERE id = NEW.exercise_id AND lifecycle = 'active')
        BEGIN SELECT RAISE(ABORT, 'Names require an active owner'); END;
        CREATE TRIGGER exercise_name_active_update BEFORE UPDATE OF exercise_id ON exercise_name
        WHEN NOT EXISTS (SELECT 1 FROM exercise WHERE id = NEW.exercise_id AND lifecycle = 'active')
        BEGIN SELECT RAISE(ABORT, 'Names require an active owner'); END;
        CREATE TRIGGER exercise_merge_nameless BEFORE UPDATE OF lifecycle ON exercise
        WHEN NEW.lifecycle = 'merged' AND EXISTS (SELECT 1 FROM exercise_name WHERE exercise_id = NEW.id)
        BEGIN SELECT RAISE(ABORT, 'Merged exercises cannot own names'); END;
        CREATE TRIGGER exercise_edit_no_update BEFORE UPDATE ON exercise_library_edit
        BEGIN SELECT RAISE(ABORT, 'Edit receipts are append-only'); END;
        CREATE TRIGGER exercise_edit_no_delete BEFORE DELETE ON exercise_library_edit
        BEGIN SELECT RAISE(ABORT, 'Edit receipts are append-only'); END;
        """

    func validateForeignKeys() throws {
        let statement = try prepare("PRAGMA foreign_key_check", bindings: [])
        defer { sqlite3_finalize(statement) }
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw ExerciseLibraryError.database(message: "Library foreign-key validation failed")
        }
    }

    /// A read-only preflight precedes the first read/write connection. SQLite's
    /// backup API includes committed WAL pages; copying only the main file does not.
    static func prepareUpgrade(databaseURL: URL, beforeBackup: () throws -> Void = {}) throws {
        guard FileManager.default.fileExists(atPath: databaseURL.path) else { return }
        var source: OpaquePointer?
        guard sqlite3_open_v2(databaseURL.path, &source, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            sqlite3_close(source)
            throw ExerciseLibraryError.database(message: "Cannot inspect library before upgrade")
        }
        defer { sqlite3_close(source) }
        var statement: OpaquePointer?
        let sql = "SELECT MAX(version) FROM schema_version"
        guard sqlite3_prepare_v2(source, sql, -1, &statement, nil) == SQLITE_OK else {
            // Existing files without version metadata are not silently repaired.
            throw ExerciseLibraryError.database(message: "Existing library has no readable schema version")
        }
        defer { sqlite3_finalize(statement) }
        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw ExerciseLibraryError.database(message: "Cannot read library schema version")
        }
        let version = sqlite3_column_int(statement, 0)
        guard (1...4).contains(version) else {
            throw ExerciseLibraryError.database(message: "Unsupported library schema version \(version)")
        }
        guard version < 4 else { return }
        try beforeBackup()
        let backupURL = databaseURL.deletingLastPathComponent()
            .appendingPathComponent("\(databaseURL.lastPathComponent).pre-v4-\(UUID().uuidString).sqlite")
        var destination: OpaquePointer?
        guard sqlite3_open_v2(backupURL.path, &destination, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil) == SQLITE_OK else {
            sqlite3_close(destination)
            throw ExerciseLibraryError.database(message: "Cannot create pre-upgrade backup")
        }
        defer { sqlite3_close(destination) }
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: backupURL.path)
        guard let backup = sqlite3_backup_init(destination, "main", source, "main") else {
            throw ExerciseLibraryError.database(message: "Cannot prepare pre-upgrade backup")
        }
        let copied = sqlite3_backup_step(backup, -1)
        let finished = sqlite3_backup_finish(backup)
        guard copied == SQLITE_DONE, finished == SQLITE_OK else {
            throw ExerciseLibraryError.database(message: "Pre-upgrade backup failed; original library unchanged")
        }
        var check: OpaquePointer?
        guard sqlite3_prepare_v2(destination, "PRAGMA integrity_check", -1, &check, nil) == SQLITE_OK else {
            throw ExerciseLibraryError.database(message: "Cannot verify pre-upgrade backup")
        }
        defer { sqlite3_finalize(check) }
        guard sqlite3_step(check) == SQLITE_ROW,
              sqlite3_column_text(check, 0).map({ String(cString: $0) }) == "ok" else {
            throw ExerciseLibraryError.database(message: "Pre-upgrade backup failed integrity check")
        }
    }

    public func resolvedExerciseID(for id: ExerciseID) throws -> ExerciseID? {
        var current = id
        var visited: Set<ExerciseID> = []
        while visited.insert(current).inserted {
            let statement = try prepare("SELECT lifecycle, merged_into_id, created_at, updated_at FROM exercise WHERE id = ?",
                                        bindings: [.text(current.rawValue.uuidString)])
            defer { sqlite3_finalize(statement) }
            let step = sqlite3_step(statement)
            if step == SQLITE_DONE {
                if current == id { return nil }
                throw ExerciseLibraryError.database(message: "Missing merge target")
            }
            guard step == SQLITE_ROW else { throw databaseError() }
            if columnText(statement, 0) == "active" { return current }
            guard columnText(statement, 0) == "merged",
                  let target = columnText(statement, 1).flatMap(UUID.init(uuidString:)) else {
                throw ExerciseLibraryError.database(message: "Invalid merge target")
            }
            let record = MergedExerciseRecord(id: current, targetID: .init(rawValue: target),
                                              createdAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 2)),
                                              updatedAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 3)))
            current = record.targetID
        }
        throw ExerciseLibraryError.database(message: "Cycle in exercise redirects")
    }

    func activeExercise(_ id: ExerciseID) throws -> Exercise {
        let statement = try prepare("SELECT preferred_name_id, created_at, updated_at FROM exercise WHERE id = ? AND lifecycle = 'active'",
                                    bindings: [.text(id.rawValue.uuidString)])
        defer { sqlite3_finalize(statement) }
        guard sqlite3_step(statement) == SQLITE_ROW,
              let preferred = columnText(statement, 0).flatMap(UUID.init(uuidString:)) else {
            throw LibraryEditError.inactiveExercise(id)
        }
        return .init(id: id, preferredNameID: .init(rawValue: preferred),
                     createdAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 1)),
                     updatedAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 2)))
    }
}
