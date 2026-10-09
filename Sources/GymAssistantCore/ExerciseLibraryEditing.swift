import CryptoKit
import Foundation
import SQLite3

public struct LibraryEditOperationID: Hashable, Sendable, Codable {
    public let rawValue: UUID
    public init(rawValue: UUID = UUID()) { self.rawValue = rawValue }
}

public enum LibraryEditError: Error, Equatable {
    case inactiveExercise(ExerciseID)
    case sameIdentity
    case onlyNameCannotSplit
    case nameNotOwned(ExerciseNameID)
    case stalePreview
    case confirmationMismatch
    case operationIDConflict
}

public struct LibraryNameSource: Equatable, Sendable, Codable {
    public let observationID: String
    public let nameID: ExerciseNameID
    public let status: String
    public let originallyResolvedExerciseID: ExerciseID?
    public let sourceAdapter: String
    public let sourceReference: String
    public let occurrenceCount: Int
}

public struct ExerciseLibraryDetail: Equatable, Sendable, Codable {
    public let exercise: Exercise
    public let names: [ExerciseName]
    public let sources: [LibraryNameSource]
    public var preferredName: ExerciseName { names.first { $0.id == exercise.preferredNameID }! }
}

public enum LibraryEditAction: Equatable, Sendable, Codable {
    case merge(source: ExerciseID, survivor: ExerciseID)
    case moveName(name: ExerciseNameID, source: ExerciseID, destination: ExerciseID)
    case split(name: ExerciseNameID, source: ExerciseID, newExercise: ExerciseID)
}

public struct LibraryEditPreview: Equatable, Sendable, Codable {
    public let operationID: LibraryEditOperationID
    public let action: LibraryEditAction
    public let before: [ExerciseLibraryDetail]
    public let replacementPreferredNameID: ExerciseNameID?
    public let fingerprint: String

    public var confirmationPrompt: String {
        switch action {
        case .merge:
            return "Combine these exercises?"
        case .moveName(let name, _, _):
            let moved = before[0].names.first { $0.id == name }!.text
            return "Move ‘\(moved)’ to this exercise?"
        case .split(let name, _, _):
            let moved = before[0].names.first { $0.id == name }!.text
            return "Promote ‘\(moved)’ to its own exercise?"
        }
    }

    public var confirmationDetails: String {
        if case .moveName = action {
            return before[1].names.map(\.text).joined(separator: ", ")
        }
        guard case .merge = action else { return "" }
        return before.reversed().map { $0.names.map(\.text).joined(separator: ", ") }
            .joined(separator: "\n\n")
    }
}

/// Only the UI's affirmative action creates a confirmation. It binds the entire
/// preview, not just its operation ID, and is not a claim of authenticated identity.
public struct LibraryEditConfirmation: Equatable, Sendable, Codable {
    public let preview: LibraryEditPreview
    public let origin: String
    public init(confirming preview: LibraryEditPreview) {
        self.preview = preview
        origin = "explicitLocalUserAction"
    }
}

public struct LibraryEditReceipt: Equatable, Sendable, Codable {
    public let version: Int
    public let preview: LibraryEditPreview
    public let confirmation: LibraryEditConfirmation
    public let timestamp: Date
    public let after: [ExerciseLibraryDetail]
    public let mergedSource: ExerciseID?
    public let mergedInto: ExerciseID?
    public var operationID: LibraryEditOperationID { preview.operationID }
}

public final class ExerciseLibraryEditService {
    private let library: ExerciseLibrary
    public init(library: ExerciseLibrary) { self.library = library }

    public func detail(exerciseID: ExerciseID) throws -> ExerciseLibraryDetail {
        guard let root = try library.resolvedExerciseID(for: exerciseID) else {
            throw LibraryEditError.inactiveExercise(exerciseID)
        }
        return try library.editDetail(root)
    }

    public func previewMerge(source: ExerciseID, survivor: ExerciseID) throws -> LibraryEditPreview {
        guard source != survivor else { throw LibraryEditError.sameIdentity }
        return try library.editPreview(action: .merge(source: source, survivor: survivor), operationID: .init())
    }

    /// The editing entry point retains the exercise the user started with.
    public func previewCombine(retaining exercise: ExerciseID, duplicate: ExerciseID) throws -> LibraryEditPreview {
        try previewMerge(source: duplicate, survivor: exercise)
    }

    public func previewSplit(nameID: ExerciseNameID, from source: ExerciseID) throws -> LibraryEditPreview {
        try library.editPreview(action: .split(name: nameID, source: source, newExercise: .init(rawValue: UUID())), operationID: .init())
    }

    public func previewMoveName(nameID: ExerciseNameID, from source: ExerciseID, to destination: ExerciseID) throws -> LibraryEditPreview {
        try library.editPreview(action: .moveName(name: nameID, source: source, destination: destination), operationID: .init())
    }

    public func apply(_ preview: LibraryEditPreview, confirmation: LibraryEditConfirmation) throws -> LibraryEditReceipt {
        guard confirmation.preview == preview else { throw LibraryEditError.confirmationMismatch }
        return try library.applyEdit(preview, confirmation: confirmation)
    }

    public func receipt(operationID: LibraryEditOperationID) throws -> LibraryEditReceipt? {
        try library.editReceipt(operationID)
    }

    /// Source lines remain in their original observation store, not edit receipts.
    public func sourceEvidence(nameID: ExerciseNameID) throws -> [ExerciseObservationOccurrence] {
        guard let name = try library.allNames().first(where: { $0.id == nameID }) else { return [] }
        let normalizer = BasicExerciseNameNormalizer()
        return try library.reviewObservationFeedbackRecords().filter {
            try normalizer.normalize($0.observation.observedName) == name.normalizedText
        }.flatMap(\.occurrences)
    }
}

extension ExerciseLibrary {
    func editDetail(_ id: ExerciseID) throws -> ExerciseLibraryDetail {
        let exercise = try activeExercise(id)
        let names = try queryNames("SELECT id, exercise_id, text, normalized_text, provenance, created_at FROM exercise_name WHERE exercise_id = ? ORDER BY created_at, id",
                                  bindings: [.text(id.rawValue.uuidString)])
        let sources = try reviewObservationFeedbackRecords().compactMap { record -> LibraryNameSource? in
            guard let normalized = try? BasicExerciseNameNormalizer().normalize(record.observation.observedName),
                  let name = names.first(where: { $0.normalizedText == normalized }) else { return nil }
            return .init(observationID: record.observation.id.rawValue, nameID: name.id,
                         status: record.status.rawValue, originallyResolvedExerciseID: record.resolvedExerciseID,
                         sourceAdapter: record.observation.source.adapter, sourceReference: record.observation.source.reference,
                         occurrenceCount: record.observation.occurrenceCount)
        }
        return .init(exercise: exercise, names: names, sources: sources)
    }

    func editPreview(action: LibraryEditAction, operationID: LibraryEditOperationID) throws -> LibraryEditPreview {
        let before: [ExerciseLibraryDetail]
        let replacement: ExerciseNameID?
        switch action {
        case .merge(let source, let survivor):
            guard source != survivor else { throw LibraryEditError.sameIdentity }
            before = try [editDetail(source), editDetail(survivor)]
            replacement = nil
        case .moveName(let name, let source, let destination):
            guard source != destination else { throw LibraryEditError.sameIdentity }
            let detail = try editDetail(source)
            guard detail.names.contains(where: { $0.id == name }) else { throw LibraryEditError.nameNotOwned(name) }
            guard detail.names.count > 1 else { throw LibraryEditError.onlyNameCannotSplit }
            before = try [detail, editDetail(destination)]
            replacement = detail.exercise.preferredNameID == name ? detail.names.first { $0.id != name }!.id : nil
        case .split(let name, let source, _):
            let detail = try editDetail(source)
            guard detail.names.contains(where: { $0.id == name }) else { throw LibraryEditError.nameNotOwned(name) }
            guard detail.names.count > 1 else { throw LibraryEditError.onlyNameCannotSplit }
            before = [detail]
            replacement = detail.exercise.preferredNameID == name ? detail.names.first { $0.id != name }!.id : nil
        }
        // Include incoming redirects and prior edit IDs. An edit followed by a
        // reverse-looking edit cannot accidentally revive an old preview or Back.
        let ids = before.map { $0.exercise.id }
        let referenceState = try editReferenceState(ids)
        let encoded = try stableJSON(before)
        let fingerprint = digest(encoded + referenceState)
        return .init(operationID: operationID, action: action, before: before,
                     replacementPreferredNameID: replacement, fingerprint: fingerprint)
    }

    private func editReferenceState(_ ids: [ExerciseID]) throws -> String {
        let statement = try prepare("SELECT id, merged_into_id FROM exercise WHERE lifecycle = 'merged' ORDER BY id", bindings: [])
        defer { sqlite3_finalize(statement) }
        var result = ""
        while true {
            let step = sqlite3_step(statement)
            if step == SQLITE_DONE { break }
            guard step == SQLITE_ROW else { throw databaseError() }
            if let id = columnText(statement, 0), let target = columnText(statement, 1),
               ids.contains(where: { $0.rawValue.uuidString == target }) {
                result += "\(id):\(target);"
            }
        }
        for receipt in try allEditReceipts() {
            let affected = receipt.preview.before.map { $0.exercise.id } + receipt.after.map { $0.exercise.id }
            if !Set(ids).isDisjoint(with: affected) { result += receipt.operationID.rawValue.uuidString }
        }
        return result
    }

    func reviewUndoFingerprint(exerciseID: ExerciseID?) throws -> String? {
        guard let exerciseID else { return nil }
        return try digest(stableJSON(editDetail(exerciseID)) + editReferenceState([exerciseID]))
    }

    func editReceipt(_ id: LibraryEditOperationID) throws -> LibraryEditReceipt? {
        let statement = try prepare("SELECT payload FROM exercise_library_edit WHERE operation_id = ?",
                                    bindings: [.text(id.rawValue.uuidString)])
        defer { sqlite3_finalize(statement) }
        let step = sqlite3_step(statement)
        if step == SQLITE_DONE { return nil }
        guard step == SQLITE_ROW, let payload = columnText(statement, 0) else { throw databaseError() }
        return try JSONDecoder().decode(LibraryEditReceipt.self, from: Data(payload.utf8))
    }

    private func allEditReceipts() throws -> [LibraryEditReceipt] {
        let statement = try prepare("SELECT payload FROM exercise_library_edit ORDER BY operation_id", bindings: [])
        defer { sqlite3_finalize(statement) }
        var receipts: [LibraryEditReceipt] = []
        while true {
            let step = sqlite3_step(statement)
            if step == SQLITE_DONE { return receipts }
            guard step == SQLITE_ROW, let payload = columnText(statement, 0) else { throw databaseError() }
            receipts.append(try JSONDecoder().decode(LibraryEditReceipt.self, from: Data(payload.utf8)))
        }
    }

    func applyEdit(_ preview: LibraryEditPreview, confirmation: LibraryEditConfirmation) throws -> LibraryEditReceipt {
        var result: LibraryEditReceipt?
        try transaction {
            if let existing = try editReceipt(preview.operationID) {
                guard existing.preview == preview, existing.confirmation == confirmation else { throw LibraryEditError.operationIDConflict }
                result = existing
                return
            }
            let current: LibraryEditPreview
            do { current = try editPreview(action: preview.action, operationID: preview.operationID) }
            catch { throw LibraryEditError.stalePreview }
            guard current == preview else { throw LibraryEditError.stalePreview }
            let now = Date()
            let timestamp = max(now.timeIntervalSince1970, preview.before.map { $0.exercise.updatedAt.timeIntervalSince1970 }.max() ?? 0)
            var afterIDs: [ExerciseID]
            var mergedSource: ExerciseID?
            var mergedInto: ExerciseID?
            let actionText: String
            switch preview.action {
            case .moveName(let name, let source, let destination):
                // The indexed column is the merge family; the typed receipt
                // records whether this combined identities or moved one name.
                actionText = "merge"
                if let replacement = preview.replacementPreferredNameID {
                    try run("UPDATE exercise SET preferred_name_id = ? WHERE id = ?",
                            bindings: [.text(replacement.rawValue.uuidString), .text(source.rawValue.uuidString)])
                }
                try run("UPDATE exercise_name SET exercise_id = ? WHERE id = ?",
                        bindings: [.text(destination.rawValue.uuidString), .text(name.rawValue.uuidString)])
                for id in [source, destination] {
                    try run("UPDATE exercise SET updated_at = ? WHERE id = ?",
                            bindings: [.double(timestamp), .text(id.rawValue.uuidString)])
                }
                afterIDs = [destination, source]
            case .merge(let source, let survivor):
                actionText = "merge"
                try run("UPDATE exercise_name SET exercise_id = ? WHERE exercise_id = ?",
                        bindings: [.text(survivor.rawValue.uuidString), .text(source.rawValue.uuidString)])
                try run("UPDATE exercise SET lifecycle = 'merged', preferred_name_id = NULL, merged_into_id = ?, updated_at = ? WHERE id = ?",
                        bindings: [.text(survivor.rawValue.uuidString), .double(timestamp), .text(source.rawValue.uuidString)])
                try run("UPDATE exercise SET updated_at = ? WHERE id = ?",
                        bindings: [.double(timestamp), .text(survivor.rawValue.uuidString)])
                afterIDs = [survivor]
                mergedSource = source
                mergedInto = survivor
            case .split(let name, let source, let newExercise):
                actionText = "split"
                if let replacement = preview.replacementPreferredNameID {
                    try run("UPDATE exercise SET preferred_name_id = ?, updated_at = ? WHERE id = ?",
                            bindings: [.text(replacement.rawValue.uuidString), .double(timestamp), .text(source.rawValue.uuidString)])
                } else {
                    try run("UPDATE exercise SET updated_at = ? WHERE id = ?", bindings: [.double(timestamp), .text(source.rawValue.uuidString)])
                }
                try run("INSERT INTO exercise (id, preferred_name_id, created_at, updated_at) VALUES (?, ?, ?, ?)",
                        bindings: [.text(newExercise.rawValue.uuidString), .text(name.rawValue.uuidString), .double(timestamp), .double(timestamp)])
                try run("UPDATE exercise_name SET exercise_id = ? WHERE id = ?",
                        bindings: [.text(newExercise.rawValue.uuidString), .text(name.rawValue.uuidString)])
                afterIDs = [source, newExercise]
            }
            let receipt = LibraryEditReceipt(version: 1, preview: preview, confirmation: confirmation,
                                             timestamp: Date(timeIntervalSince1970: timestamp), after: try afterIDs.map(editDetail),
                                             mergedSource: mergedSource, mergedInto: mergedInto)
            try run("INSERT INTO exercise_library_edit (operation_id, action, created_at, payload_version, payload) VALUES (?, ?, ?, 1, ?)",
                    bindings: [.text(preview.operationID.rawValue.uuidString), .text(actionText), .double(timestamp), .text(try stableJSON(receipt))])
            result = receipt
        }
        return result!
    }
}

private func stableJSON<T: Encodable>(_ value: T) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return String(decoding: try encoder.encode(value), as: UTF8.self)
}

private func digest(_ value: String) -> String {
    SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
}
