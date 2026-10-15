import AppKit
import Testing
import GymAssistantWorkspace
@testable import GymAssistantMacOS

private actor UnrecordedReader: NotesContextReading {
    func captureSelectedNote() async throws -> NoteSnapshot { try await read(id: NoteID("fixture")) }
    func read(id: NoteID) async throws -> NoteSnapshot {
        NoteSnapshot(id: id, text: "", html: "<div><h2>Session 1</h2></div><div>A1 Row</div>")
    }
    func metadata(id: NoteID) async throws -> NoteMetadata { NoteMetadata(id: id, modifiedAt: .distantPast) }
}

@Suite("Unrecorded snapshot compatibility") @MainActor struct UnrecordedSnapshotTests {
    @Test func readsLegacyWithoutRewriteAndPreservesBackupOnExplicitUpgrade() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("legacy-workspace-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let rich = NSAttributedString(string: "Session 1\nA1 Row\n")
        var legacy = WorkspaceSnapshot(anchor: .init(noteID: NoteID("fixture"), recordedHeading: "Session 1", baselineText: rich.string),
            text: rich.string, richTextArchive: try RichTextArchive.encode(rich))
        legacy.schemaVersion = 1; legacy.anchor.recordingState = nil
        let bytes = try JSONEncoder().encode(legacy)
        let store = WorkspaceSnapshotStore(directory: root)
        try bytes.write(to: store.currentURL(for: legacy.workspaceID))
        let loaded = try #require(store.load(id: legacy.workspaceID)?.snapshot)
        #expect(loaded == legacy)
        #expect(!loaded.anchor.isUnrecorded)
        #expect(try Data(contentsOf: store.currentURL(for: legacy.workspaceID)) == bytes)
        #expect(try store.storedAnchors().first?.schemaVersion == 1)
        var upgraded = loaded; upgraded.schemaVersion = 2; upgraded.revision += 1
        try store.save(upgraded)
        #expect(try Data(contentsOf: store.previousURL(for: legacy.workspaceID)) == bytes)
        var downgrade = upgraded; downgrade.schemaVersion = 1; downgrade.revision += 1
        #expect(throws: SnapshotStoreError.identityMismatch) { try store.save(downgrade) }
        #expect(try store.load(id: legacy.workspaceID)?.snapshot == upgraded)
        #expect(try Data(contentsOf: store.previousURL(for: legacy.workspaceID)) == bytes)
    }

    @Test func unrecordedWorkspaceReloadsWithoutReservingRecordedNotesRegion() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("unrecorded-workspace-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = WorkspaceSnapshotStore(directory: root)
        let rich = NSAttributedString(string: "Session 2\nWarmup\n")
        let snapshot = WorkspaceSnapshot(anchor: .init(noteID: NoteID("fixture"), recordedHeading: "Session 2", baselineText: "", recordingState: .unrecorded),
            revision: 3, text: rich.string, richTextArchive: try RichTextArchive.encode(rich), composerText: "Keep this unloaded")
        try store.save(snapshot)
        #expect(try store.load(id: snapshot.workspaceID)?.snapshot == snapshot)
        #expect(try store.storedAnchors().first?.anchor.isUnrecorded == true)
        let context = try SessionNoteContextPool(store: store, reader: UnrecordedReader()).context(for: snapshot.anchor.noteID)
        let document = try await context.refresh(for: .resume)
        #expect(context.registry.mappings.isEmpty && context.registry.unresolved.isEmpty)
        let recorded = try context.createWorkspace(range: document.candidates()[0].range, observation: document.snapshot.observationID, store: store)
        #expect(recorded.anchor.sessionID != snapshot.anchor.sessionID)
        #expect(try store.load(id: snapshot.workspaceID)?.snapshot == snapshot)
    }
}
