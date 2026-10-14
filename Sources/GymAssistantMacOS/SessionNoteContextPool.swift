import Foundation
import GymAssistantWorkspace

/// App-owned pool, not window-owned: two sessions in one note use one monitor.
/// Stored closed-workspace anchors are loaded before any ownership decision.
@MainActor public final class SessionNoteContextPool {
    private let store: WorkspaceSnapshotStore
    private let reader: any NotesContextReading
    private var contexts: [NoteID: SessionNoteContext] = [:]
    public init(store: WorkspaceSnapshotStore, reader: any NotesContextReading) {
        self.store = store; self.reader = reader
    }
    public func context(for noteID: NoteID) throws -> SessionNoteContext {
        if let existing = contexts[noteID] { return existing }
        let owners = try store.storedAnchors().filter { $0.anchor.noteID == noteID }
        let context = try SessionNoteContext(noteID: noteID, anchors: owners.map(\.anchor), reader: reader)
        contexts[noteID] = context
        return context
    }
}
