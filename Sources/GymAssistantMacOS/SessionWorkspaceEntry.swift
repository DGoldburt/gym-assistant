import AppKit
import GymAssistantWorkspace

public enum SessionEntryError: Error, Equatable {
    case duplicateHeadings([String])
    case boundaryReviewRequired
    case unresolvedSavedWorkspace
    case recoveryRequired(WorkspaceID)
}

/// Local entry preparation, invoked only after choosing the programming branch.
/// Selection is captured once; subsequent reads address that identity even if
/// the coach selects another note while the independent window is opening.
@MainActor public final class SessionWorkspaceEntry {
    private let store: WorkspaceSnapshotStore
    private let reader: any NotesContextReading
    private let pool: SessionNoteContextPool

    public init(store: WorkspaceSnapshotStore, reader: any NotesContextReading) {
        self.store = store; self.reader = reader
        pool = SessionNoteContextPool(store: store, reader: reader)
    }

    public func captureNote() async throws -> NoteID {
        let captured = try await reader.captureSelectedNote()
        try Task.checkCancellation()
        return captured.id
    }

    public struct PreparedSession {
        public let snapshot: WorkspaceSnapshot
        public let context: SessionNoteContext
        public let association: SessionAssociation
        public let note: NoteSnapshot
    }

    /// Last region in document order, never highest label or modification date.
    /// Does not silently classify an unknown heading or bypass a saved owner.
    public func latest(in noteID: NoteID) async throws -> PreparedSession {
        let context = try pool.context(for: noteID)
        let document = try await context.refresh(for: .resume)
        try Task.checkCancellation()
        guard context.registry.duplicateLabels.isEmpty else {
            throw SessionEntryError.duplicateHeadings(context.registry.duplicateLabels.sorted())
        }
        guard let candidate = document.candidates().last, !candidate.needsClassification else {
            throw SessionEntryError.boundaryReviewRequired
        }
        let owners = context.registry.mappings.values.filter {
            NSIntersectionRange($0.range.nsRange, candidate.range.nsRange).length > 0
        }
        let snapshot: WorkspaceSnapshot
        if let owner = owners.first {
            // A manually adjusted range needs its own explicit entry choice if
            // it overlaps multiple inferred regions; do not resize it on entry.
            guard owners.count == 1, owner.range == candidate.range else {
                throw SessionEntryError.boundaryReviewRequired
            }
            let headers = try store.storedAnchors().filter {
                $0.anchor.noteID == noteID && $0.anchor.sessionID == owner.sessionID
            }
            guard headers.count == 1, let header = headers.first,
                  let loaded = try store.load(id: header.workspaceID) else {
                throw SessionEntryError.unresolvedSavedWorkspace
            }
            guard !loaded.recoveredFromPrevious else {
                throw SessionEntryError.recoveryRequired(header.workspaceID)
            }
            snapshot = loaded.snapshot
        } else {
            guard context.registry.unresolved.isEmpty else {
                throw SessionEntryError.unresolvedSavedWorkspace
            }
            snapshot = try context.createWorkspace(range: candidate.range,
                observation: document.snapshot.observationID, store: store)
        }
        return PreparedSession(snapshot: snapshot, context: context,
            association: try context.association(for: snapshot.anchor.sessionID), note: document.snapshot)
    }
}
