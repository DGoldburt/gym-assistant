import Foundation
import SQLite3

public struct ExerciseID: Hashable, Sendable, RawRepresentable {
    public let rawValue: UUID

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}

public struct ExerciseNameID: Hashable, Sendable, RawRepresentable {
    public let rawValue: UUID

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }
}

public enum ExerciseNameProvenance: String, Sendable {
    case systemSeeded
    case userConfirmed
    case importedConfirmed
}

public struct Exercise: Equatable, Sendable {
    public let id: ExerciseID
    public let preferredNameID: ExerciseNameID
    public let createdAt: Date
    public let updatedAt: Date
}

public struct ExerciseName: Equatable, Sendable {
    public let id: ExerciseNameID
    public let exerciseID: ExerciseID
    public let text: String
    public let normalizedText: String
    public let provenance: ExerciseNameProvenance
    public let createdAt: Date
}

public struct CreatedExercise: Equatable, Sendable {
    public let exercise: Exercise
    public let preferredName: ExerciseName
}

public enum ExerciseLibraryError: Error, Equatable {
    case emptyName
    case exerciseNotFound(ExerciseID)
    case nameOwnershipConflict(proposedText: String, existingOwnerID: ExerciseID)
    case database(message: String)
}

public struct BasicExerciseNameNormalizer: Sendable {
    public init() {}

    public func normalize(_ text: String) throws -> String {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .split(whereSeparator: \Character.isWhitespace)
            .joined(separator: " ")

        guard !normalized.isEmpty else {
            throw ExerciseLibraryError.emptyName
        }
        return normalized
    }
}

public final class ExerciseLibrary {
    private var database: OpaquePointer?
    private let normalizer: BasicExerciseNameNormalizer

    public init(databaseURL: URL, normalizer: BasicExerciseNameNormalizer = .init()) throws {
        self.normalizer = normalizer

        guard sqlite3_open(databaseURL.path, &database) == SQLITE_OK else {
            let message = database.map { String(cString: sqlite3_errmsg($0)) } ?? "Unable to open database"
            sqlite3_close(database)
            database = nil
            throw ExerciseLibraryError.database(message: message)
        }

        do {
            try execute("PRAGMA foreign_keys = ON")
            guard try scalarInt("PRAGMA foreign_keys") == 1 else {
                throw ExerciseLibraryError.database(message: "SQLite foreign-key enforcement is disabled")
            }
            try migrate()
        } catch {
            sqlite3_close(database)
            database = nil
            throw error
        }
    }

    deinit {
        sqlite3_close(database)
    }

    public func createExercise(
        preferredName text: String,
        provenance: ExerciseNameProvenance = .userConfirmed,
        now: Date = Date()
    ) throws -> CreatedExercise {
        let normalizedText = try normalizer.normalize(text)
        if let ownerID = try ownerID(forNormalizedText: normalizedText) {
            throw ExerciseLibraryError.nameOwnershipConflict(proposedText: text, existingOwnerID: ownerID)
        }

        let exerciseID = ExerciseID(rawValue: UUID())
        let nameID = ExerciseNameID(rawValue: UUID())
        let timestamp = now.timeIntervalSince1970

        try transaction {
            try run(
                "INSERT INTO exercise (id, preferred_name_id, created_at, updated_at) VALUES (?, ?, ?, ?)",
                bindings: [.text(exerciseID.rawValue.uuidString), .text(nameID.rawValue.uuidString), .double(timestamp), .double(timestamp)]
            )
            try run(
                "INSERT INTO exercise_name (id, exercise_id, text, normalized_text, provenance, created_at) VALUES (?, ?, ?, ?, ?, ?)",
                bindings: [
                    .text(nameID.rawValue.uuidString),
                    .text(exerciseID.rawValue.uuidString),
                    .text(text.trimmingCharacters(in: .whitespacesAndNewlines)),
                    .text(normalizedText),
                    .text(provenance.rawValue),
                    .double(timestamp),
                ]
            )
        }

        return CreatedExercise(
            exercise: Exercise(id: exerciseID, preferredNameID: nameID, createdAt: now, updatedAt: now),
            preferredName: ExerciseName(
                id: nameID,
                exerciseID: exerciseID,
                text: text.trimmingCharacters(in: .whitespacesAndNewlines),
                normalizedText: normalizedText,
                provenance: provenance,
                createdAt: now
            )
        )
    }

    public func addName(
        _ text: String,
        to exerciseID: ExerciseID,
        provenance: ExerciseNameProvenance = .userConfirmed,
        now: Date = Date()
    ) throws -> ExerciseName {
        guard try exerciseExists(exerciseID) else {
            throw ExerciseLibraryError.exerciseNotFound(exerciseID)
        }

        let normalizedText = try normalizer.normalize(text)
        if let existing = try name(forNormalizedText: normalizedText) {
            guard existing.exerciseID == exerciseID else {
                throw ExerciseLibraryError.nameOwnershipConflict(
                    proposedText: text,
                    existingOwnerID: existing.exerciseID
                )
            }
            return existing
        }

        let name = ExerciseName(
            id: ExerciseNameID(rawValue: UUID()),
            exerciseID: exerciseID,
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            normalizedText: normalizedText,
            provenance: provenance,
            createdAt: now
        )
        try run(
            "INSERT INTO exercise_name (id, exercise_id, text, normalized_text, provenance, created_at) VALUES (?, ?, ?, ?, ?, ?)",
            bindings: [
                .text(name.id.rawValue.uuidString),
                .text(exerciseID.rawValue.uuidString),
                .text(name.text),
                .text(normalizedText),
                .text(provenance.rawValue),
                .double(now.timeIntervalSince1970),
            ]
        )
        return name
    }

    public func exactName(for text: String) throws -> ExerciseName? {
        try name(forNormalizedText: normalizer.normalize(text))
    }

    public func preferredName(for exerciseID: ExerciseID) throws -> ExerciseName? {
        try queryName(
            """
            SELECT n.id, n.exercise_id, n.text, n.normalized_text, n.provenance, n.created_at
            FROM exercise e
            JOIN exercise_name n ON n.exercise_id = e.id AND n.id = e.preferred_name_id
            WHERE e.id = ?
            """,
            bindings: [.text(exerciseID.rawValue.uuidString)]
        )
    }

    private func migrate() throws {
        try transaction {
            try execute(
                """
                CREATE TABLE IF NOT EXISTS schema_version (
                    version INTEGER PRIMARY KEY
                );

                CREATE TABLE IF NOT EXISTS exercise (
                    id TEXT PRIMARY KEY NOT NULL,
                    preferred_name_id TEXT NOT NULL,
                    created_at REAL NOT NULL,
                    updated_at REAL NOT NULL CHECK (updated_at >= created_at),
                    FOREIGN KEY (id, preferred_name_id)
                        REFERENCES exercise_name(exercise_id, id)
                        DEFERRABLE INITIALLY DEFERRED
                );

                CREATE TABLE IF NOT EXISTS exercise_name (
                    id TEXT PRIMARY KEY NOT NULL,
                    exercise_id TEXT NOT NULL,
                    text TEXT NOT NULL CHECK (length(trim(text)) > 0),
                    normalized_text TEXT NOT NULL UNIQUE CHECK (length(trim(normalized_text)) > 0),
                    provenance TEXT NOT NULL CHECK (provenance IN ('systemSeeded', 'userConfirmed', 'importedConfirmed')),
                    created_at REAL NOT NULL,
                    UNIQUE (exercise_id, id),
                    FOREIGN KEY (exercise_id) REFERENCES exercise(id)
                );

                CREATE INDEX IF NOT EXISTS exercise_name_exercise_id
                    ON exercise_name(exercise_id);

                INSERT OR IGNORE INTO schema_version(version) VALUES (1);
                """
            )
        }
    }

    private func exerciseExists(_ id: ExerciseID) throws -> Bool {
        try scalarInt("SELECT COUNT(*) FROM exercise WHERE id = ?", bindings: [.text(id.rawValue.uuidString)]) == 1
    }

    private func ownerID(forNormalizedText normalizedText: String) throws -> ExerciseID? {
        try name(forNormalizedText: normalizedText)?.exerciseID
    }

    private func name(forNormalizedText normalizedText: String) throws -> ExerciseName? {
        try queryName(
            "SELECT id, exercise_id, text, normalized_text, provenance, created_at FROM exercise_name WHERE normalized_text = ?",
            bindings: [.text(normalizedText)]
        )
    }

    private func queryName(_ sql: String, bindings: [Binding]) throws -> ExerciseName? {
        let statement = try prepare(sql, bindings: bindings)
        defer { sqlite3_finalize(statement) }

        let result = sqlite3_step(statement)
        if result == SQLITE_DONE { return nil }
        guard result == SQLITE_ROW else { throw databaseError() }

        guard
            let idText = columnText(statement, 0), let id = UUID(uuidString: idText),
            let exerciseIDText = columnText(statement, 1), let exerciseID = UUID(uuidString: exerciseIDText),
            let text = columnText(statement, 2),
            let normalizedText = columnText(statement, 3),
            let provenanceText = columnText(statement, 4),
            let provenance = ExerciseNameProvenance(rawValue: provenanceText)
        else {
            throw ExerciseLibraryError.database(message: "Stored exercise-name row is invalid")
        }

        return ExerciseName(
            id: ExerciseNameID(rawValue: id),
            exerciseID: ExerciseID(rawValue: exerciseID),
            text: text,
            normalizedText: normalizedText,
            provenance: provenance,
            createdAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 5))
        )
    }

    private enum Binding {
        case text(String)
        case double(Double)
    }

    private func transaction(_ body: () throws -> Void) throws {
        try execute("BEGIN IMMEDIATE")
        do {
            try body()
            try execute("COMMIT")
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }

    private func execute(_ sql: String) throws {
        var errorMessage: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(database, sql, nil, nil, &errorMessage) == SQLITE_OK else {
            let message = errorMessage.map { String(cString: $0) } ?? databaseErrorMessage()
            sqlite3_free(errorMessage)
            throw ExerciseLibraryError.database(message: message)
        }
    }

    private func run(_ sql: String, bindings: [Binding]) throws {
        let statement = try prepare(sql, bindings: bindings)
        defer { sqlite3_finalize(statement) }
        guard sqlite3_step(statement) == SQLITE_DONE else { throw databaseError() }
    }

    private func scalarInt(_ sql: String, bindings: [Binding] = []) throws -> Int {
        let statement = try prepare(sql, bindings: bindings)
        defer { sqlite3_finalize(statement) }
        guard sqlite3_step(statement) == SQLITE_ROW else { throw databaseError() }
        return Int(sqlite3_column_int64(statement, 0))
    }

    private func prepare(_ sql: String, bindings: [Binding]) throws -> OpaquePointer {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            throw databaseError()
        }
        do {
            for (offset, binding) in bindings.enumerated() {
                let index = Int32(offset + 1)
                let result: Int32
                switch binding {
                case .text(let value):
                    result = sqlite3_bind_text(statement, index, value, -1, SQLITE_TRANSIENT)
                case .double(let value):
                    result = sqlite3_bind_double(statement, index, value)
                }
                guard result == SQLITE_OK else { throw databaseError() }
            }
            return statement
        } catch {
            sqlite3_finalize(statement)
            throw error
        }
    }

    private func columnText(_ statement: OpaquePointer, _ index: Int32) -> String? {
        sqlite3_column_text(statement, index).map { String(cString: $0) }
    }

    private func databaseError() -> ExerciseLibraryError {
        .database(message: databaseErrorMessage())
    }

    private func databaseErrorMessage() -> String {
        database.map { String(cString: sqlite3_errmsg($0)) } ?? "Database is closed"
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
