import AppKit
import Testing
import GymAssistantWorkspace
@testable import GymAssistantMacOS

@Suite("Native scratchpad controller", .serialized) @MainActor struct ScratchpadWindowTests {
    private func descendants(_ view: NSView) -> [NSView] {
        [view] + view.subviews.flatMap(descendants)
    }
    @Test func composingFollowupDoesNotFalselyMarkScratchpadChanged() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("scratchpad-window-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let note = NoteSnapshot(id: NoteID("synthetic-window-test"), text: "Session 1\nB2\n")
        let rich = NSAttributedString(string: note.text)
        let snapshot = WorkspaceSnapshot(anchor: SessionAnchor(noteID: note.id, recordedHeading: "Session 1", baselineText: note.text),
            text: note.text, richTextArchive: try RichTextArchive.encode(rich))
        let controller = try SessionScratchpadWindowController(snapshot: snapshot, store: WorkspaceSnapshotStore(directory: root),
            note: note, association: SessionAssociation(sessionID: snapshot.anchor.sessionID, noteID: note.id,
                observationID: note.observationID, range: SourceRange(location: 0, length: (note.text as NSString).length)),
            profile: CoachingProfile(version: "empty-test", entries: []), assistant: FakeProgrammingAssistant(delay: .seconds(60)))
        let content = try #require(controller.window?.contentView)
        let views = descendants(content)
        let composer = try #require(views.first { $0.identifier?.rawValue == "chat-composer" } as? NSTextView)
        let editor = try #require(views.first { $0.identifier?.rawValue == "scratchpad-editor" } as? NSTextView)
        let status = try #require(views.first { $0.identifier?.rawValue == "workspace-status" } as? NSTextField)
        let send = try #require(views.compactMap { $0 as? NSButton }.first { $0.title == "Send" })
        let stop = try #require(views.compactMap { $0 as? NSButton }.first { $0.title == "Stop" })
        composer.string = "B2?"
        controller.textDidChange(Notification(name: NSText.didChangeNotification, object: composer))
        send.performClick(nil)
        #expect(!send.isEnabled && stop.isEnabled)
        composer.string = "Keep it unloaded"
        controller.textDidChange(Notification(name: NSText.didChangeNotification, object: composer))
        #expect(controller.snapshot.revision == 0)
        #expect(!status.stringValue.contains("Scratchpad changed"))
        #expect(controller.snapshot.messages.filter { $0.role == .coach }.count == 1)
        editor.string += "Coach edit\n"
        controller.textDidChange(Notification(name: NSText.didChangeNotification, object: editor))
        #expect(controller.snapshot.revision == 1)
        #expect(status.stringValue.contains("Scratchpad changed"))
        stop.performClick(nil)
        #expect(composer.string == "Keep it unloaded")
        #expect(send.isEnabled && !stop.isEnabled)
        #expect(controller.snapshot.messages.last?.status == .cancelled)
        #expect(controller.flushAndStop())
        controller.window?.close()
    }
}
