import Foundation
import SQLite3

/// Ephemeral chooser presentation, independent of name ownership or identity.
public struct ExerciseChooserExpansion: Sendable {
    public private(set) var expandedIDs: Set<ExerciseID> = []
    public init() {}
    public mutating func expand(_ id: ExerciseID) { expandedIDs.insert(id) }
    public mutating func collapse(_ id: ExerciseID) { expandedIDs.remove(id) }
    public mutating func reset() { expandedIDs.removeAll() }
}

public struct LibraryMaintenanceRowActions: Equatable, Sendable {
    public let canPromote: Bool
    public let canCombine: Bool
    public init(isAlias: Bool, confirmedNameCount: Int) {
        canPromote = isAlias && confirmedNameCount > 1
        canCombine = confirmedNameCount > 0 && (!isAlias || confirmedNameCount > 1)
    }
}

public enum LibraryMaintenanceRoute: Equatable, Sendable {
    case edit
    case add
    case importSource
    case reviewCandidates
}

public struct LibraryMaintenanceSelection: Equatable, Sendable {
    public let exerciseID: ExerciseID
    public let nameID: ExerciseNameID
    public init(exerciseID: ExerciseID, nameID: ExerciseNameID) {
        self.exerciseID = exerciseID
        self.nameID = nameID
    }
}

/// Read-only starting point for merge search; preserve already-visible alternatives
/// while prefilling the selected wording. Editing the query resumes normal search.
public struct LibraryDuplicateSearchStart: Sendable {
    public let query: String
    public let retainedCandidates: [ExerciseSearchMatch]?
    public init(selectedName: String, source: ExerciseID, visibleMatches: [ExerciseSearchMatch]) {
        query = selectedName
        let alternatives = visibleMatches.filter { $0.exerciseID != source }
        retainedCandidates = alternatives.isEmpty ? nil : alternatives
    }
}

/// Ephemeral navigation and drafts; all identity and queue writes remain in services.
public struct LibraryMaintenanceNavigation: Equatable, Sendable {
    public private(set) var route: LibraryMaintenanceRoute
    public var selection: LibraryMaintenanceSelection?
    public var creationDraft: String
    public var editQuery: String
    public init(route: LibraryMaintenanceRoute, query: String, selection: LibraryMaintenanceSelection?) {
        self.route = route
        self.selection = selection
        creationDraft = query
        editQuery = query
    }
    public mutating func show(_ route: LibraryMaintenanceRoute) { self.route = route }
    public mutating func back() {
        switch route {
        case .reviewCandidates: route = .importSource
        case .importSource: route = .add
        case .edit, .add: break
        }
    }
}

public struct LibraryImportPreview: Equatable, Sendable {
    public let source: PersonalLibrarySource
    public let sourceReference: String
    public let exactReuseCount: Int
}

public enum LibraryImportError: Error, Equatable {
    case noObservations
    case sourceChanged
}

public final class LibraryImportService {
    private let library: ExerciseLibrary
    private let review: ExerciseIdentityReviewService
    private let adapter = PersonalLibraryCSVAdapter()
    public init(library: ExerciseLibrary) {
        self.library = library
        review = .init(library: library)
    }
    public func preview(data: Data, sourceReference: String) throws -> LibraryImportPreview {
        let source = try adapter.parse(data: data)
        guard !source.observations.isEmpty else { throw LibraryImportError.noObservations }
        let exact = try source.observations.filter { try library.exactName(for: $0.observedName) != nil }.count
        return .init(source: source, sourceReference: sourceReference, exactReuseCount: exact)
    }
    public func apply(_ preview: LibraryImportPreview, currentData: Data) throws -> ExerciseObservationIngestionReport {
        let current = try adapter.parse(data: currentData)
        guard current.sourceHash == preview.source.sourceHash else { throw LibraryImportError.sourceChanged }
        // A source imported previously by CLI or under a different file name is
        // still the same ingestion. Keep its original reference, not a new label.
        let reference = try library.existingIngestionReference(fingerprint: current.sourceHash) ?? preview.sourceReference
        let (ingestion, observations) = preview.source.ingestion(sourceReference: reference)
        return try review.ingest(ingestion, observations: observations)
    }
    public func pendingReviewCount() throws -> Int {
        try review.reviewQueue().filter { $0.status == .pending }.count
    }
}

extension ExerciseLibrary {
    func existingIngestionReference(fingerprint: String) throws -> String? {
        let statement = try prepare("SELECT source_reference FROM exercise_observation_ingestion WHERE source_fingerprint = ?", bindings: [.text(fingerprint)])
        defer { sqlite3_finalize(statement) }
        let step = sqlite3_step(statement)
        if step == SQLITE_DONE { return nil }
        guard step == SQLITE_ROW else { throw databaseError() }
        return columnText(statement, 0)
    }
}
