import AppKit
import Testing
import GymAssistantWorkspace
@testable import GymAssistantMacOS

private actor ReplacementReader: NotesContextReading {
    var html = "<div><h2>Session 1</h2></div><div>A1 Row</div>"
    func captureSelectedNote() async throws -> NoteSnapshot { try await read(id: .init("replacement")) }
    func read(id: NoteID) async throws -> NoteSnapshot { .init(id: id, text: "", html: html) }
    func metadata(id: NoteID) async throws -> NoteMetadata { .init(id: id, modifiedAt: .distantPast) }
    func replace(_ value: String) { html = value }
}

@Suite("Explicit Notes replacement", .serialized) @MainActor struct NotesReplacementTests {
    private func setup(_ store: WorkspaceSnapshotStore, _ reader: ReplacementReader) async throws -> (SessionNoteContext, WorkspaceSnapshot) {
        let context = try SessionNoteContext(noteID: .init("replacement"), anchors: [], reader: reader)
        let document = try await context.refresh(for: .resume)
        var snapshot = try context.createWorkspace(range: document.candidates()[0].range,
            observation: document.snapshot.observationID, store: store)
        let rich = NSMutableAttributedString(attributedString: try RichTextArchive.decode(snapshot.richTextArchive))
        rich.append(NSAttributedString(string: "Coach idea not yet in Notes\n"))
        snapshot.text = rich.string; snapshot.richTextArchive = try RichTextArchive.encode(rich)
        snapshot.boundaryProtection?.markUncertain(currentLength: rich.length)
        snapshot.composerText = "Keep this question"
        snapshot.revision += 1
        snapshot.messages = [.init(requestID: UUID(), conversationID: snapshot.conversationID, role: .coach,
            text: "I want coordination practice", status: .complete, scratchpadRevision: 0, observationID: UUID())]
        try store.save(snapshot)
        return (context, snapshot)
    }

    @Test func replacementPreservesIndependentHistoryConversationAndIdentity() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("replacement-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = WorkspaceSnapshotStore(directory: root), reader = ReplacementReader()
        let (context, original) = try await setup(store, reader)
        await reader.replace("<div><h2>Session 1 — dated</h2></div><div>A1 Row</div>")
        _ = try await context.refresh(for: .comparison)
        let bytes = try Data(contentsOf: store.currentURL(for: original.workspaceID))
        let preview = try context.replacementPreview(original)
        #expect(try Data(contentsOf: store.currentURL(for: original.workspaceID)) == bytes)
        let next = try context.replaceFromNotes(preview, current: original, store: store)
        #expect(next.text == "Session 1 — dated\nA1 Row\n")
        #expect(next.workspaceID == original.workspaceID && next.anchor.sessionID == original.anchor.sessionID)
        #expect(next.messages == original.messages && next.composerText == original.composerText)
        #expect(next.conversationID == original.conversationID)
        #expect(context.registry.anchor(for: original.anchor.sessionID)?.baselineText == next.text)
        let history = try #require(store.storedAnchors().first { !$0.isActive })
        let preserved = try #require(store.load(id: history.workspaceID)?.snapshot)
        #expect(preserved.preservedFromWorkspaceID == original.workspaceID)
        #expect(preserved.text == original.text && preserved.richTextArchive == original.richTextArchive)
        #expect(preserved.messages == original.messages && preserved.composerText == original.composerText)
        var later = next; later.revision += 1; later.composerText = "A later question"
        try store.save(later); later.revision += 1; try store.save(later)
        #expect(try store.load(id: preserved.workspaceID)?.snapshot == preserved)
    }

    @Test func changedNotesOrEditorAndUnlocatedRegionRefuseReplacement() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("replacement-stale-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = WorkspaceSnapshotStore(directory: root), reader = ReplacementReader()
        let (context, original) = try await setup(store, reader)
        let preview = try context.replacementPreview(original)
        var changed = original; changed.composerText = "Changed since confirmation"
        #expect(throws: WorkspaceError.staleAssociation) { _ = try context.replaceFromNotes(preview, current: changed, store: store) }
        await reader.replace("<div><h2>Session 1 — new date</h2></div><div>A1 Row</div>")
        _ = try await context.refresh(for: .comparison)
        #expect(throws: WorkspaceError.staleAssociation) { _ = try context.replaceFromNotes(preview, current: original, store: store) }
        await reader.replace("<div><h2>Session 1</h2></div><div>Different work</div>")
        _ = try await context.refresh(for: .comparison)
        #expect(throws: WorkspaceError.staleAssociation) { _ = try context.replacementPreview(original) }
        #expect(try store.load(id: original.workspaceID)?.snapshot == original)
        #expect(try store.storedAnchors().count == 1)
    }

    @Test func failedActivePromotionKeepsOriginalReferenceAndLatchesOwnership() async throws {
        enum Injected: Error { case failure }
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("replacement-fault-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        var armed = false, promotions = 0
        let store = WorkspaceSnapshotStore(directory: root, fault: {
            if armed && $0 == .promoted { promotions += 1; if promotions == 2 { throw Injected.failure } }
        }), reader = ReplacementReader()
        let (context, original) = try await setup(store, reader)
        let preview = try context.replacementPreview(original)
        armed = true
        #expect(throws: NotesReplacementError.persistenceUncertain) {
            _ = try context.replaceFromNotes(preview, current: original, store: store)
        }
        let history = try #require(store.storedAnchors().first { !$0.isActive })
        #expect(try store.load(id: history.workspaceID)?.snapshot.text == original.text)
        #expect(try JSONDecoder().decode(WorkspaceSnapshot.self,
            from: Data(contentsOf: store.previousURL(for: original.workspaceID))) == original)
        #expect(context.failure != nil)
        await #expect(throws: WorkspaceError.staleAssociation) { _ = try await context.refresh(for: .resume) }
    }
}
