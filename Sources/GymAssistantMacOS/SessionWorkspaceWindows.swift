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
    private var planningWindow: PreviousPlanningWindow?
    public var onWorkspaceSetAside: (() -> Void)?
    public var onResumeWorkspace: ((SessionScratchpadWindowController) -> Void)?

    /// Isolated evidence read: browsing must not register owners, promote an
    /// insertion, interrupt a request, save an editor or rewrite old snapshots.
    public func planningReferences(in noteID: NoteID) async throws -> [PlanningReference] {
        let headers = try store.storedAnchors().filter { $0.anchor.noteID == noteID }
        var snapshots: [WorkspaceSnapshot] = []
        for header in headers {
            guard let loaded = try store.load(id: header.workspaceID), !loaded.recoveredFromPrevious else {
                throw SnapshotStoreError.recoveryRequired(header.workspaceID)
            }
            snapshots.append(loaded.snapshot)
        }
        var document: ProgramDocument?
        do { document = try ProgramDocumentReader.read(await reader.read(id: noteID)).0 }
        catch { try Task.checkCancellation() /* local references remain accessible offline */ }
        try Task.checkCancellation()
        // Capture retained editors after the read, including still-unsaved typing.
        snapshots = try snapshots.map { try controllers[$0.workspaceID]?.planningReferenceSnapshot() ?? $0 }
        return try snapshots.map { snapshot in
            // Historical references do not compete for ownership. Multiple old
            // records may refer to one unique current region; ambiguous source
            // regions still remain unverified by the existing evidence matcher.
            var registry = try SessionAssociationRegistry(noteID: noteID,
                anchors: snapshot.anchor.isUnrecorded ? [] : [snapshot.anchor])
            if let document { try registry.observe(document) }
            let attributes = try FileManager.default.attributesOfItem(atPath: store.currentURL(for: snapshot.workspaceID).path)
            let heading: String?
            if let document, let mapping = registry.mappings[snapshot.anchor.sessionID] {
                heading = try document.evidence(in: mapping.range).paragraphs.first?.label
            } else { heading = nil }
            return PlanningReference(snapshot: snapshot, savedAt: attributes[.modificationDate] as? Date,
                includesOpenEditor: controllers[snapshot.workspaceID] != nil, verifiedHeading: heading)
        }.sorted {
            if $0.savedAt != $1.savedAt { return ($0.savedAt ?? .distantPast) > ($1.savedAt ?? .distantPast) }
            return $0.snapshot.workspaceID.rawValue.uuidString < $1.snapshot.workspaceID.rawValue.uuidString
        }
    }

    public func showPreviousPlanning(in noteID: NoteID) async throws {
        let records = try await planningReferences(in: noteID)
        try Task.checkCancellation()
        let window = try PreviousPlanningWindow(records: records, setAside: { [weak self] expected in
            guard let self else { throw SnapshotStoreError.unavailable }
            return try self.setAside(expected)
        }, resume: { [weak self] id in
            guard let self else { throw SnapshotStoreError.unavailable }
            let controller = try await self.resume(id: id)
            if let present = self.onResumeWorkspace { present(controller) }
            else { controller.show() }
        })
        planningWindow?.close(); planningWindow = window; window.show()
    }

    public func setAside(_ expected: WorkspaceSnapshot) throws -> WorkspaceSnapshot {
        guard expected.isActive else { throw SnapshotStoreError.staleRevision }
        let controller = controllers[expected.workspaceID]
        let saved: WorkspaceSnapshot
        if let controller {
            // Require the content the coach actually reviewed, not a newer editor.
            guard try controller.planningReferenceSnapshot() == expected else { throw SnapshotStoreError.staleRevision }
            guard controller.flushAndStop() else { throw SnapshotStoreError.unavailable }
            saved = controller.snapshot
        } else { saved = expected }
        let preserved = try store.setAside(saved)
        controller?.retire(with: preserved)
        entry.releaseSetAside(preserved)
        controllers.removeValue(forKey: expected.workspaceID)
        if mostRecent == expected.workspaceID { mostRecent = nil }
        onWorkspaceSetAside?()
        return preserved
    }

    private func connectPlanning(_ controller: SessionScratchpadWindowController) {
        controller.onPreviousPlanning = { [weak self, weak controller] in
            guard let self, let controller else { return }
            try await self.showPreviousPlanning(in: controller.snapshot.anchor.noteID)
        }
    }

    public init(store: WorkspaceSnapshotStore, reader: any NotesContextReading,
                profile: CoachingProfile, assistant: any ProgrammingAssistant,
                exerciseLookup: @escaping (String) -> ExerciseMentionMatch = { _ in .unavailable }) {
        self.store = store; self.profile = profile; self.assistant = assistant
        self.reader = reader
        self.exerciseLookup = exerciseLookup
        entry = SessionWorkspaceEntry(store: store, reader: reader)
    }

    public func captureNote() async throws -> NoteID { try await entry.captureNote() }

    public func resume(id: WorkspaceID) async throws -> SessionScratchpadWindowController {
        let prepared = try await entry.resume(id: id)
        mostRecent = id
        if let existing = controllers[id] { return existing }
        let controller = try SessionScratchpadWindowController(snapshot: prepared.snapshot, store: store,
            note: prepared.note, association: try? prepared.context.association(for: prepared.snapshot.anchor.sessionID),
            profile: profile, assistant: assistant, noteContext: prepared.context, exerciseLookup: exerciseLookup)
        controllers[id] = controller; connectPlanning(controller)
        return controller
    }

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

    public func boundaryReview(in noteID: NoteID) async throws -> SessionWorkspaceEntry.BoundaryReview {
        try await entry.boundaryReview(in: noteID)
    }

    public func prepareNewSession(in noteID: NoteID, review: SessionWorkspaceEntry.BoundaryReview? = nil, range: SourceRange? = nil) async throws -> NewSessionEntry {
        switch try await entry.prepareNewSession(in: noteID, review: review, range: range) {
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
        connectPlanning(controller)
        return controller
    }

    /// The caller chooses when to show the window and install its menus. No
    /// permission prompt, focus change, clipboard publication or API call here.
    public func latest(in noteID: NoteID, review: SessionWorkspaceEntry.BoundaryReview? = nil, range: SourceRange? = nil) async throws -> SessionScratchpadWindowController {
        let prepared = try await entry.latest(in: noteID, review: review, range: range)
        mostRecent = prepared.snapshot.workspaceID
        if let existing = controllers[prepared.snapshot.workspaceID] { return existing }
        let controller = try SessionScratchpadWindowController(snapshot: prepared.snapshot, store: store,
            note: prepared.note, association: prepared.association, profile: profile,
            assistant: assistant, noteContext: prepared.context, exerciseLookup: exerciseLookup)
        controllers[prepared.snapshot.workspaceID] = controller
        connectPlanning(controller)
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
