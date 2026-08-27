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
    case nameNotOwnedByExercise(proposedText: String, exerciseID: ExerciseID)
    case nameOwnershipConflict(proposedText: String, existingOwnerID: ExerciseID)
    case database(message: String)
}

struct StoredReviewObservation: Equatable, Sendable {
    let observation: StagedExerciseObservation
    let status: ExerciseObservationReviewStatus
    let resolvedExerciseID: ExerciseID?
    let evidenceSnapshot: String

    var observedName: String { observation.observedName }
}

public struct BasicExerciseNameNormalizer: Sendable {
    public init() {}

    public func normalize(_ text: String) throws -> String {
        var cosmeticText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cosmeticText.last == "." || cosmeticText.last == "!" {
            cosmeticText.removeLast()
            cosmeticText = cosmeticText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let normalized = cosmeticText
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

    public func setPreferredName(
        _ text: String,
        for exerciseID: ExerciseID,
        now: Date = Date()
    ) throws -> ExerciseName {
        guard try exerciseExists(exerciseID) else {
            throw ExerciseLibraryError.exerciseNotFound(exerciseID)
        }
        let normalizedText = try normalizer.normalize(text)
        guard let name = try name(forNormalizedText: normalizedText),
              name.exerciseID == exerciseID else {
            throw ExerciseLibraryError.nameNotOwnedByExercise(
                proposedText: text,
                exerciseID: exerciseID
            )
        }
        try run(
            "UPDATE exercise SET preferred_name_id = ?, updated_at = ? WHERE id = ?",
            bindings: [
                .text(name.id.rawValue.uuidString),
                .double(now.timeIntervalSince1970),
                .text(exerciseID.rawValue.uuidString),
            ]
        )
        return name
    }

    public func allPreferredNames() throws -> [ExerciseName] {
        try queryNames(
            """
            SELECT n.id, n.exercise_id, n.text, n.normalized_text, n.provenance, n.created_at
            FROM exercise e
            JOIN exercise_name n ON n.exercise_id = e.id AND n.id = e.preferred_name_id
            ORDER BY n.normalized_text, n.id
            """
        )
    }

    public func allNames() throws -> [ExerciseName] {
        try queryNames(
            """
            SELECT id, exercise_id, text, normalized_text, provenance, created_at
            FROM exercise_name
            ORDER BY normalized_text, id
            """
        )
    }

    func ingestReviewObservations(
        _ ingestion: ExerciseObservationIngestion,
        observations: [IngestedExerciseObservation]
    ) throws -> ExerciseObservationIngestionReport {
        let alreadyIngested = try scalarInt(
            "SELECT COUNT(*) FROM exercise_observation_ingestion WHERE id = ?",
            bindings: [.text(ingestion.id)]
        ) == 1

        if alreadyIngested {
            let matching = try scalarInt(
                """
                SELECT COUNT(*) FROM exercise_observation_ingestion
                WHERE id = ? AND source_kind = ? AND source_reference = ? AND source_fingerprint = ?
                """,
                bindings: [
                    .text(ingestion.id),
                    .text(ingestion.sourceKind),
                    .text(ingestion.sourceReference),
                    .text(ingestion.sourceFingerprint),
                ]
            ) == 1
            guard matching else {
                throw ExerciseIdentityReviewError.ingestionConflict(ingestion.id)
            }
        }

        for item in observations {
            guard item.observation.source.adapter == ingestion.sourceKind,
                  item.observation.source.reference == ingestion.id,
                  item.occurrences.reduce(0, { $0 + $1.occurrenceCount }) == item.observation.occurrenceCount else {
                throw ExerciseIdentityReviewError.invalidIngestion
            }
            if let existing = try storedReviewObservation(item.observation.id),
               existing.observation.observedName != item.observation.observedName.trimmingCharacters(in: .whitespacesAndNewlines)
                || existing.observation.source != item.observation.source {
                throw ExerciseIdentityReviewError.observationIDConflict(item.observation.id)
            }
        }

        try transaction {
            try run(
                """
                INSERT OR IGNORE INTO exercise_observation_ingestion (
                    id, source_kind, source_reference, source_fingerprint, created_at
                ) VALUES (?, ?, ?, ?, ?)
                """,
                bindings: [
                    .text(ingestion.id),
                    .text(ingestion.sourceKind),
                    .text(ingestion.sourceReference),
                    .text(ingestion.sourceFingerprint),
                    .double(Date().timeIntervalSince1970),
                ]
            )
            for item in observations {
                try stageReviewObservation(item.observation)
                for occurrence in item.occurrences {
                    try run(
                        """
                        INSERT OR IGNORE INTO exercise_observation_occurrence (
                            observation_id, ingestion_id, source_reference, evidence_text,
                            occurrence_count, created_at
                        ) VALUES (?, ?, ?, ?, ?, ?)
                        """,
                        bindings: [
                            .text(item.observation.id.rawValue),
                            .text(ingestion.id),
                            .text(occurrence.sourceReference),
                            .text(occurrence.evidence),
                            .double(Double(occurrence.occurrenceCount)),
                            .double(Date().timeIntervalSince1970),
                        ]
                    )
                }
            }
        }

        return .init(
            alreadyIngested: alreadyIngested,
            observationCount: observations.count,
            occurrenceCount: observations.reduce(0) { $0 + $1.observation.occurrenceCount }
        )
    }

    func reviewQueueItems() throws -> [ExerciseReviewQueueItem] {
        let statement = try prepare(
            """
            SELECT id, observed_name, source_adapter, source_reference, occurrence_count, status
            FROM exercise_review_observation
            WHERE status IN ('pending', 'deferred')
            ORDER BY CASE status WHEN 'deferred' THEN 1 ELSE 0 END, updated_at, id
            """,
            bindings: []
        )
        defer { sqlite3_finalize(statement) }

        var items: [ExerciseReviewQueueItem] = []
        while true {
            switch sqlite3_step(statement) {
            case SQLITE_ROW:
                guard let id = columnText(statement, 0),
                      let observedName = columnText(statement, 1),
                      let adapter = columnText(statement, 2),
                      let reference = columnText(statement, 3),
                      let statusText = columnText(statement, 5),
                      let status = ExerciseObservationReviewStatus(rawValue: statusText) else {
                    throw databaseError()
                }
                let observationID = ExerciseObservationID(rawValue: id)
                let observation = StagedExerciseObservation(
                    id: observationID,
                    observedName: observedName,
                    source: .init(adapter: adapter, reference: reference),
                    occurrenceCount: Int(sqlite3_column_int64(statement, 4))
                )
                let occurrences = try observationOccurrences(observationID)
                items.append(.init(
                    observation: observation,
                    status: status,
                    occurrences: occurrences.isEmpty
                        ? [.init(sourceReference: reference, evidence: "", occurrenceCount: observation.occurrenceCount)]
                        : occurrences
                ))
            case SQLITE_DONE:
                return items
            default:
                throw databaseError()
            }
        }
    }

    func reviewObservationFeedbackRecords() throws -> [ExerciseObservationFeedbackRecord] {
        let statement = try prepare(
            """
            SELECT id, observed_name, source_adapter, source_reference, occurrence_count,
                   status, resolved_exercise_id, evidence_snapshot
            FROM exercise_review_observation
            ORDER BY id
            """,
            bindings: []
        )
        defer { sqlite3_finalize(statement) }

        var records: [ExerciseObservationFeedbackRecord] = []
        while true {
            switch sqlite3_step(statement) {
            case SQLITE_ROW:
                guard let id = columnText(statement, 0),
                      let observedName = columnText(statement, 1),
                      let adapter = columnText(statement, 2),
                      let reference = columnText(statement, 3),
                      let statusText = columnText(statement, 5),
                      let status = ExerciseObservationReviewStatus(rawValue: statusText),
                      let resolvedIDText = columnText(statement, 6),
                      let evidenceSnapshot = columnText(statement, 7) else {
                    throw databaseError()
                }
                let observationID = ExerciseObservationID(rawValue: id)
                let resolvedExerciseID = resolvedIDText.isEmpty
                    ? nil
                    : UUID(uuidString: resolvedIDText).map(ExerciseID.init(rawValue:))
                records.append(.init(
                    observation: .init(
                        id: observationID,
                        observedName: observedName,
                        source: .init(adapter: adapter, reference: reference),
                        occurrenceCount: Int(sqlite3_column_int64(statement, 4))
                    ),
                    status: status,
                    resolvedExerciseID: resolvedExerciseID,
                    evidenceSnapshot: evidenceSnapshot,
                    occurrences: try observationOccurrences(observationID)
                ))
            case SQLITE_DONE:
                return records
            default:
                throw databaseError()
            }
        }
    }

    private func observationOccurrences(
        _ observationID: ExerciseObservationID
    ) throws -> [ExerciseObservationOccurrence] {
        let statement = try prepare(
            """
            SELECT source_reference, evidence_text, occurrence_count
            FROM exercise_observation_occurrence
            WHERE observation_id = ?
            ORDER BY ingestion_id, source_reference, evidence_text
            """,
            bindings: [.text(observationID.rawValue)]
        )
        defer { sqlite3_finalize(statement) }
        var occurrences: [ExerciseObservationOccurrence] = []
        while true {
            switch sqlite3_step(statement) {
            case SQLITE_ROW:
                guard let reference = columnText(statement, 0),
                      let evidence = columnText(statement, 1) else { throw databaseError() }
                occurrences.append(.init(
                    sourceReference: reference,
                    evidence: evidence,
                    occurrenceCount: Int(sqlite3_column_int64(statement, 2))
                ))
            case SQLITE_DONE:
                return occurrences
            default:
                throw databaseError()
            }
        }
    }

    func stageReviewObservation(_ observation: StagedExerciseObservation) throws {
        let trimmed = observation.observedName.trimmingCharacters(in: .whitespacesAndNewlines)
        _ = try normalizer.normalize(trimmed)
        try run(
            """
            INSERT INTO exercise_review_observation (
                id, observed_name, source_adapter, source_reference, occurrence_count,
                status, resolved_exercise_id, evidence_snapshot, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, 'pending', '', '', ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                occurrence_count = excluded.occurrence_count,
                updated_at = excluded.updated_at
            WHERE exercise_review_observation.observed_name = excluded.observed_name
              AND exercise_review_observation.source_adapter = excluded.source_adapter
              AND exercise_review_observation.source_reference = excluded.source_reference
            """,
            bindings: [
                .text(observation.id.rawValue),
                .text(trimmed),
                .text(observation.source.adapter),
                .text(observation.source.reference),
                .double(Double(observation.occurrenceCount)),
                .double(Date().timeIntervalSince1970),
                .double(Date().timeIntervalSince1970),
            ]
        )
    }

    func storedReviewObservation(_ id: ExerciseObservationID) throws -> StoredReviewObservation? {
        let statement = try prepare(
            """
            SELECT observed_name, source_adapter, source_reference, occurrence_count,
                   status, resolved_exercise_id, evidence_snapshot
            FROM exercise_review_observation WHERE id = ?
            """,
            bindings: [.text(id.rawValue)]
        )
        defer { sqlite3_finalize(statement) }
        let result = sqlite3_step(statement)
        if result == SQLITE_DONE { return nil }
        guard result == SQLITE_ROW,
              let observedName = columnText(statement, 0),
              let sourceAdapter = columnText(statement, 1),
              let sourceReference = columnText(statement, 2),
              let statusText = columnText(statement, 4),
              let status = ExerciseObservationReviewStatus(rawValue: statusText),
              let resolvedText = columnText(statement, 5),
              let snapshot = columnText(statement, 6) else {
            throw databaseError()
        }
        let resolvedID = UUID(uuidString: resolvedText).map { ExerciseID(rawValue: $0) }
        return .init(
            observation: .init(
                id: id,
                observedName: observedName,
                source: .init(adapter: sourceAdapter, reference: sourceReference),
                occurrenceCount: Int(sqlite3_column_int64(statement, 3))
            ),
            status: status,
            resolvedExerciseID: resolvedID,
            evidenceSnapshot: snapshot
        )
    }

    func resolveReviewObservation(
        _ id: ExerciseObservationID,
        status: ExerciseObservationReviewStatus,
        exerciseID: ExerciseID
    ) throws {
        try run(
            """
            UPDATE exercise_review_observation
            SET status = ?, resolved_exercise_id = ?, updated_at = ?
            WHERE id = ?
            """,
            bindings: [
                .text(status.rawValue),
                .text(exerciseID.rawValue.uuidString),
                .double(Date().timeIntervalSince1970),
                .text(id.rawValue),
            ]
        )
    }

    func linkReviewObservationAtomically(
        _ id: ExerciseObservationID,
        observedName: String,
        to exerciseID: ExerciseID,
        now: Date = Date()
    ) throws -> ExerciseName {
        guard try exerciseExists(exerciseID) else {
            throw ExerciseLibraryError.exerciseNotFound(exerciseID)
        }
        let normalizedText = try normalizer.normalize(observedName)
        if let existing = try name(forNormalizedText: normalizedText),
           existing.exerciseID != exerciseID {
            throw ExerciseLibraryError.nameOwnershipConflict(
                proposedText: observedName,
                existingOwnerID: existing.exerciseID
            )
        }

        try transaction {
            if try name(forNormalizedText: normalizedText) == nil {
                try run(
                    """
                    INSERT INTO exercise_name (
                        id, exercise_id, text, normalized_text, provenance, created_at
                    ) VALUES (?, ?, ?, ?, 'importedConfirmed', ?)
                    """,
                    bindings: [
                        .text(UUID().uuidString),
                        .text(exerciseID.rawValue.uuidString),
                        .text(observedName.trimmingCharacters(in: .whitespacesAndNewlines)),
                        .text(normalizedText),
                        .double(now.timeIntervalSince1970),
                    ]
                )
            }
            try run(
                """
                UPDATE exercise_review_observation
                SET status = 'linked', resolved_exercise_id = ?, updated_at = ?
                WHERE id = ?
                """,
                bindings: [
                    .text(exerciseID.rawValue.uuidString),
                    .double(now.timeIntervalSince1970),
                    .text(id.rawValue),
                ]
            )
        }
        guard let name = try name(forNormalizedText: normalizedText) else {
            throw databaseError()
        }
        return name
    }

    func createReviewObservationAtomically(
        _ id: ExerciseObservationID,
        observedName: String,
        now: Date = Date()
    ) throws -> CreatedExercise {
        let trimmed = observedName.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedText = try normalizer.normalize(trimmed)
        if let existing = try name(forNormalizedText: normalizedText) {
            throw ExerciseLibraryError.nameOwnershipConflict(
                proposedText: observedName,
                existingOwnerID: existing.exerciseID
            )
        }

        let exerciseID = ExerciseID(rawValue: UUID())
        let nameID = ExerciseNameID(rawValue: UUID())
        let timestamp = now.timeIntervalSince1970
        try transaction {
            try run(
                "INSERT INTO exercise (id, preferred_name_id, created_at, updated_at) VALUES (?, ?, ?, ?)",
                bindings: [
                    .text(exerciseID.rawValue.uuidString),
                    .text(nameID.rawValue.uuidString),
                    .double(timestamp),
                    .double(timestamp),
                ]
            )
            try run(
                """
                INSERT INTO exercise_name (
                    id, exercise_id, text, normalized_text, provenance, created_at
                ) VALUES (?, ?, ?, ?, 'importedConfirmed', ?)
                """,
                bindings: [
                    .text(nameID.rawValue.uuidString),
                    .text(exerciseID.rawValue.uuidString),
                    .text(trimmed),
                    .text(normalizedText),
                    .double(timestamp),
                ]
            )
            try run(
                """
                UPDATE exercise_review_observation
                SET status = 'created', resolved_exercise_id = ?, updated_at = ?
                WHERE id = ?
                """,
                bindings: [
                    .text(exerciseID.rawValue.uuidString),
                    .double(timestamp),
                    .text(id.rawValue),
                ]
            )
        }
        return .init(
            exercise: .init(id: exerciseID, preferredNameID: nameID, createdAt: now, updatedAt: now),
            preferredName: .init(
                id: nameID,
                exerciseID: exerciseID,
                text: trimmed,
                normalizedText: normalizedText,
                provenance: .importedConfirmed,
                createdAt: now
            )
        )
    }

    func deferReviewObservation(_ id: ExerciseObservationID, evidenceSnapshot: String) throws {
        try run(
            """
            UPDATE exercise_review_observation
            SET status = 'deferred', evidence_snapshot = ?, updated_at = ?
            WHERE id = ?
            """,
            bindings: [
                .text(evidenceSnapshot),
                .double(Date().timeIntervalSince1970),
                .text(id.rawValue),
            ]
        )
    }

    func undoReviewDecisionAtomically(_ receipt: ExerciseIdentityReviewUndoReceipt) throws {
        guard let stored = try storedReviewObservation(receipt.observationID),
              stored.status == receipt.decision,
              stored.resolvedExerciseID == receipt.resolvedExerciseID else {
            throw ExerciseIdentityReviewError.incompatibleRepeatedDecision
        }

        try transaction {
            if receipt.decision == .created {
                guard let exerciseID = receipt.resolvedExerciseID,
                      try scalarInt(
                        "SELECT COUNT(*) FROM exercise_name WHERE exercise_id = ?",
                        bindings: [.text(exerciseID.rawValue.uuidString)]
                      ) == 1,
                      try scalarInt(
                        "SELECT COUNT(*) FROM exercise_review_observation WHERE resolved_exercise_id = ? AND id <> ?",
                        bindings: [.text(exerciseID.rawValue.uuidString), .text(receipt.observationID.rawValue)]
                      ) == 0 else {
                    throw ExerciseIdentityReviewError.incompatibleRepeatedDecision
                }
                try run(
                    "DELETE FROM exercise_name WHERE exercise_id = ?",
                    bindings: [.text(exerciseID.rawValue.uuidString)]
                )
                try run(
                    "DELETE FROM exercise WHERE id = ?",
                    bindings: [.text(exerciseID.rawValue.uuidString)]
                )
            } else if receipt.decision == .linked {
                guard let exerciseID = receipt.resolvedExerciseID else {
                    throw ExerciseIdentityReviewError.incompatibleRepeatedDecision
                }
                let normalized = try normalizer.normalize(stored.observedName)
                guard let linkedName = try name(forNormalizedText: normalized),
                      linkedName.exerciseID == exerciseID,
                      try preferredName(for: exerciseID)?.id != linkedName.id else {
                    throw ExerciseIdentityReviewError.incompatibleRepeatedDecision
                }
                try run(
                    "DELETE FROM exercise_name WHERE id = ?",
                    bindings: [.text(linkedName.id.rawValue.uuidString)]
                )
            }

            try run(
                """
                UPDATE exercise_review_observation
                SET status = ?, resolved_exercise_id = '', evidence_snapshot = ?, updated_at = ?
                WHERE id = ?
                """,
                bindings: [
                    .text(receipt.previousStatus.rawValue),
                    .text(receipt.previousEvidenceSnapshot),
                    .double(Date().timeIntervalSince1970),
                    .text(receipt.observationID.rawValue),
                ]
            )
        }
    }

    func recordSeparateExercises(_ lhs: ExerciseID, _ rhs: ExerciseID) throws {
        guard try exerciseExists(lhs) else { throw ExerciseLibraryError.exerciseNotFound(lhs) }
        guard try exerciseExists(rhs) else { throw ExerciseLibraryError.exerciseNotFound(rhs) }
        let ordered = [lhs.rawValue.uuidString, rhs.rawValue.uuidString].sorted()
        try run(
            """
            INSERT OR IGNORE INTO separate_exercise_decision (
                first_exercise_id, second_exercise_id, created_at
            ) VALUES (?, ?, ?)
            """,
            bindings: [.text(ordered[0]), .text(ordered[1]), .double(Date().timeIntervalSince1970)]
        )
    }

    func separateExerciseDecisionCount() throws -> Int {
        try scalarInt("SELECT COUNT(*) FROM separate_exercise_decision")
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

                CREATE TABLE IF NOT EXISTS exercise_review_observation (
                    id TEXT PRIMARY KEY NOT NULL,
                    observed_name TEXT NOT NULL CHECK (length(trim(observed_name)) > 0),
                    source_adapter TEXT NOT NULL CHECK (length(trim(source_adapter)) > 0),
                    source_reference TEXT NOT NULL CHECK (length(trim(source_reference)) > 0),
                    occurrence_count INTEGER NOT NULL CHECK (occurrence_count > 0),
                    status TEXT NOT NULL CHECK (status IN ('pending', 'deferred', 'linked', 'created')),
                    resolved_exercise_id TEXT NOT NULL DEFAULT '',
                    evidence_snapshot TEXT NOT NULL DEFAULT '',
                    created_at REAL NOT NULL,
                    updated_at REAL NOT NULL CHECK (updated_at >= created_at)
                );

                CREATE TABLE IF NOT EXISTS separate_exercise_decision (
                    first_exercise_id TEXT NOT NULL,
                    second_exercise_id TEXT NOT NULL,
                    created_at REAL NOT NULL,
                    PRIMARY KEY (first_exercise_id, second_exercise_id),
                    CHECK (first_exercise_id < second_exercise_id),
                    FOREIGN KEY (first_exercise_id) REFERENCES exercise(id),
                    FOREIGN KEY (second_exercise_id) REFERENCES exercise(id)
                );

                CREATE TABLE IF NOT EXISTS exercise_observation_ingestion (
                    id TEXT PRIMARY KEY NOT NULL,
                    source_kind TEXT NOT NULL CHECK (length(trim(source_kind)) > 0),
                    source_reference TEXT NOT NULL CHECK (length(trim(source_reference)) > 0),
                    source_fingerprint TEXT NOT NULL UNIQUE CHECK (length(trim(source_fingerprint)) > 0),
                    created_at REAL NOT NULL
                );

                CREATE TABLE IF NOT EXISTS exercise_observation_occurrence (
                    observation_id TEXT NOT NULL,
                    ingestion_id TEXT NOT NULL,
                    source_reference TEXT NOT NULL CHECK (length(trim(source_reference)) > 0),
                    evidence_text TEXT NOT NULL,
                    occurrence_count INTEGER NOT NULL CHECK (occurrence_count > 0),
                    created_at REAL NOT NULL,
                    PRIMARY KEY (
                        observation_id, ingestion_id, source_reference, evidence_text
                    ),
                    FOREIGN KEY (observation_id) REFERENCES exercise_review_observation(id),
                    FOREIGN KEY (ingestion_id) REFERENCES exercise_observation_ingestion(id)
                );

                CREATE INDEX IF NOT EXISTS exercise_observation_occurrence_observation_id
                    ON exercise_observation_occurrence(observation_id);

                INSERT OR IGNORE INTO schema_version(version) VALUES (1);
                INSERT OR IGNORE INTO schema_version(version) VALUES (2);
                INSERT OR IGNORE INTO schema_version(version) VALUES (3);
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

        return try decodeName(statement)
    }

    private func queryNames(_ sql: String, bindings: [Binding] = []) throws -> [ExerciseName] {
        let statement = try prepare(sql, bindings: bindings)
        defer { sqlite3_finalize(statement) }

        var names: [ExerciseName] = []
        while true {
            switch sqlite3_step(statement) {
            case SQLITE_ROW:
                names.append(try decodeName(statement))
            case SQLITE_DONE:
                return names
            default:
                throw databaseError()
            }
        }
    }

    private func decodeName(_ statement: OpaquePointer) throws -> ExerciseName {
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
