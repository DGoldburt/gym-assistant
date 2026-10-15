import AppKit
import Testing
import GymAssistantWorkspace
@testable import GymAssistantMacOS

@Suite("Subtle exercise decoration") @MainActor struct ExerciseConversationViewTests {
    @Test func controllerLooksUpOnlyCompletedAssistantMentionsAndPreservesStoredText() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let rich = NSAttributedString(string: "Session 2\n")
        let note = NoteSnapshot(id: NoteID("mentions-fixture"), text: "Session 1\n")
        var snapshot = WorkspaceSnapshot(anchor: .init(noteID: note.id, recordedHeading: "Session 2",
            baselineText: "", recordingState: .unrecorded), text: rich.string, richTextArchive: try RichTextArchive.encode(rich))
        let mention = ExerciseMention(text: "SL RDL", range: .init(location: 0, length: 6))
        for (role, status) in [(MessageRole.coach, MessageStatus.complete), (.assistant, .complete), (.assistant, .failed)] {
            snapshot.messages.append(.init(requestID: UUID(), conversationID: snapshot.conversationID, role: role,
                text: "SL RDL", status: status, scratchpadRevision: 0, observationID: note.observationID, exerciseMentions: [mention]))
        }
        var queries: [String] = []
        let controller = try SessionScratchpadWindowController(snapshot: snapshot, store: WorkspaceSnapshotStore(directory: root),
            note: note, association: nil, profile: .init(version: "test", entries: []), exerciseLookup: {
                queries.append($0); return .inLibrary(canonicalName: "Single-leg RDL")
            })
        func descendants(_ view: NSView) -> [NSView] { [view] + view.subviews.flatMap(descendants) }
        let content = try #require(controller.window?.contentView)
        let transcript = try #require(descendants(content).compactMap { $0 as? ExerciseConversationView }.first)
        #expect(queries == ["SL RDL"] && transcript.decorations.count == 1)
        #expect(controller.snapshot.messages == snapshot.messages && controller.snapshot.text == snapshot.text)
        #expect(controller.flushAndStop())
        controller.window?.close()
    }

    @Test func usesUnderlinesAndTooltipsWithoutChangingCopyTextOrAddingLinks() {
        let view = ExerciseConversationView()
        let text = "SL RDL; reach; unknown"
        view.display(NSAttributedString(string: text), decorations: [
            .init(range: NSRange(location: 0, length: 6), match: .inLibrary(canonicalName: "Single-leg RDL")),
            .init(range: NSRange(location: 8, length: 5), match: .notMatched),
            .init(range: NSRange(location: 15, length: 7), match: .unavailable)])
        let rich = view.attributedString()
        #expect(view.string == text && view.decorations.count == 2)
        #expect(rich.attribute(.underlineStyle, at: 0, effectiveRange: nil) as? Int == NSUnderlineStyle.single.rawValue)
        #expect(rich.attribute(.underlineStyle, at: 8, effectiveRange: nil) as? Int == NSUnderlineStyle.single.rawValue | NSUnderlineStyle.patternDot.rawValue)
        #expect(rich.attribute(.toolTip, at: 0, effectiveRange: nil) as? String == "In library · Single-leg RDL")
        #expect(rich.attribute(.toolTip, at: 8, effectiveRange: nil) as? String == "Not matched")
        #expect(rich.attribute(.underlineStyle, at: 15, effectiveRange: nil) == nil)
        #expect(rich.attribute(.link, at: 0, effectiveRange: nil) == nil)
        view.setSelectedRange(NSRange(location: (text as NSString).length, length: 0))
        view.focusFirstMention()
        #expect(view.selectedRange() == NSRange(location: 0, length: 6))
        let tab = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0,
            windowNumber: 0, context: nil, characters: "\t", charactersIgnoringModifiers: "\t", isARepeat: false, keyCode: 48)!
        view.keyDown(with: tab)
        #expect(view.selectedRange() == NSRange(location: 8, length: 5) && view.string == text)
    }
}
