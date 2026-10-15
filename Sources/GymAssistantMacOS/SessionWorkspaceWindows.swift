import AppKit
import GymAssistantWorkspace

/// App-owned lifetime, independent of the short-lived Services callback. Closing
/// a window hides it; re-entry reuses its editor, pending reply and unsaved text.
@MainActor public final class SessionWorkspaceWindows {
    private let store: WorkspaceSnapshotStore
    private var entry: SessionWorkspaceEntry
    private let reader: any NotesContextReading
    private let profile: CoachingProfile
    private let assistant: any ProgrammingAssistant
    private let exerciseLookup: (String) -> ExerciseMentionMatch
    private var controllers: [WorkspaceID: SessionScratchpadWindowController] = [:]
    private var mostRecent: WorkspaceID?

    public init(store: WorkspaceSnapshotStore, reader: any NotesContextReading,
                profile: CoachingProfile, assistant: any ProgrammingAssistant,
                exerciseLookup: @escaping (String) -> ExerciseMentionMatch = { _ in .unavailable }) {
        self.store = store; self.profile = profile; self.assistant = assistant
        self.reader = reader
        self.exerciseLookup = exerciseLookup
        entry = SessionWorkspaceEntry(store: store, reader: reader)
    }

    public func captureNote() async throws -> NoteID { try await entry.captureNote() }

    public func recoveryPreview(id: WorkspaceID) throws -> WorkspaceRecoveryPreview {
        try store.recoveryPreview(id: id)
    }

    public enum RecoveryError: Error { case retainedWorkspaces }
    @discardableResult public func restoreBackup(_ preview: WorkspaceRecoveryPreview) throws -> URL? {
        // Retained editors may have newer unsaved content and cached ownership.
        guard controllers.isEmpty else { throw RecoveryError.retainedWorkspaces }
        let preserved = try store.restore(preview)
        entry = SessionWorkspaceEntry(store: store, reader: reader)
        return preserved
    }

    public enum NewSessionEntry {
        case workspace(SessionScratchpadWindowController)
        case proposal(SessionWorkspaceEntry.NewSessionProposal)
    }

    public func prepareNewSession(in noteID: NoteID) async throws -> NewSessionEntry {
        switch try await entry.prepareNewSession(in: noteID) {
        case .resume(let prepared): return .workspace(try unrecordedWindow(prepared))
        case .proposal(let proposal): return .proposal(proposal)
        }
    }

    public func acceptNewSession(_ proposal: SessionWorkspaceEntry.NewSessionProposal) async throws -> SessionScratchpadWindowController {
        try unrecordedWindow(await entry.acceptNewSession(proposal))
    }

    private func unrecordedWindow(_ prepared: SessionWorkspaceEntry.UnrecordedSession) throws -> SessionScratchpadWindowController {
        mostRecent = prepared.snapshot.workspaceID
        if let existing = controllers[prepared.snapshot.workspaceID] { return existing }
        let controller = try SessionScratchpadWindowController(snapshot: prepared.snapshot, store: store,
            note: prepared.note, association: nil, profile: profile, assistant: assistant, noteContext: prepared.context,
            exerciseLookup: exerciseLookup)
        controllers[prepared.snapshot.workspaceID] = controller
        return controller
    }

    /// The caller chooses when to show the window and install its menus. No
    /// permission prompt, focus change, clipboard publication or API call here.
    public func latest(in noteID: NoteID) async throws -> SessionScratchpadWindowController {
        let prepared = try await entry.latest(in: noteID)
        mostRecent = prepared.snapshot.workspaceID
        if let existing = controllers[prepared.snapshot.workspaceID] { return existing }
        let controller = try SessionScratchpadWindowController(snapshot: prepared.snapshot, store: store,
            note: prepared.note, association: prepared.association, profile: profile,
            assistant: assistant, noteContext: prepared.context, exerciseLookup: exerciseLookup)
        controllers[prepared.snapshot.workspaceID] = controller
        return controller
    }

    public func showMostRecent() -> Bool {
        guard let mostRecent, let controller = controllers[mostRecent] else { return false }
        controller.show(); return true
    }

    /// Attempt every save, not just until the first failure. A failed save vetoes
    /// application termination so its editor remains available for recovery.
    public func flushAndStop() -> Bool {
        var succeeded = true
        for controller in controllers.values {
            if !controller.flushAndStop() { succeeded = false }
        }
        return succeeded
    }
}
