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
        let title = try #require(descendants(content).first { $0.identifier?.rawValue == "scratchpad-note-title" } as? NSTextField)
        #expect(title.stringValue == "Session 1")
        #expect(title.stringValue != snapshot.anchor.recordedHeading)
        #expect(queries == ["SL RDL"] && transcript.decorations.count == 1)
        #expect(controller.snapshot.messages == snapshot.messages && controller.snapshot.text == snapshot.text)
        #expect(controller.flushAndStop())
        controller.window?.close()
    }

    @Test func promptColumnsPreserveTextAndReflowWithWidth() throws {
        let view = ExerciseConversationView(frame: NSRect(x: 0, y: 0, width: 420, height: 300))
        view.textContainerInset = NSSize(width: 12, height: 16)
        view.textContainer?.widthTracksTextView = true
        let text = "You\nKeep it light.\n\nAssistant\nA short response."
        let split = (text as NSString).range(of: "Assistant").location
        let spans: [ExerciseConversationView.MessagePresentation] = [
            .init(range: NSRange(location: 0, length: split - 2), role: .coach),
            .init(range: NSRange(location: split, length: (text as NSString).length - split), role: .assistant)]
        view.display(NSAttributedString(string: text), decorations: [], messages: spans)
        let prompt = try #require(view.attributedString().attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)
        let response = try #require(view.attributedString().attribute(.paragraphStyle, at: split, effectiveRange: nil) as? NSParagraphStyle)
        #expect(prompt.headIndent > response.headIndent + 60)
        view.setFrameSize(NSSize(width: 540, height: view.frame.height))
        let wider = try #require(view.attributedString().attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)
        #expect(wider.headIndent > prompt.headIndent)
        #expect(view.string == text)
    }

    @Test func latestArrowTracksOverflowAndJumpDoesNotChangeSelection() throws {
        let scroll = ConversationScrollView(frame: NSRect(x: 0, y: 0, width: 420, height: 240))
        let view = ExerciseConversationView(frame: NSRect(x: 0, y: 0, width: 400, height: 240))
        view.isVerticallyResizable = true
        view.isHorizontallyResizable = false
        view.autoresizingMask = [.width]
        view.textContainer?.widthTracksTextView = true
        scroll.documentView = view
        view.display(NSAttributedString(string: String(repeating: "A long conversation line\n", count: 60),
                                       attributes: [.font: NSFont.systemFont(ofSize: 15)]), decorations: [])
        scroll.layoutSubtreeIfNeeded()
        view.scroll(NSPoint.zero)
        scroll.updateLatestVisibility()
        #expect(scroll.hasContentBelow && !scroll.latestButton.isHidden)
        view.setSelectedRange(NSRange(location: 2, length: 4))
        scroll.latestButton.performClick(nil)
        #expect(!scroll.hasContentBelow && scroll.latestButton.isHidden)
        #expect(view.selectedRange() == NSRange(location: 2, length: 4))
        view.display(NSAttributedString(string: "Short reply"), decorations: [])
        scroll.updateLatestVisibility()
        #expect(scroll.latestButton.isHidden)
    }

    @Test func refreshedMessagesKeepAnEarlierReadingPosition() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let note = NoteSnapshot(id: NoteID("scroll-fixture"), text: "Program title\nSession 1\n")
        let rich = NSAttributedString(string: "Session 1\n")
        var snapshot = WorkspaceSnapshot(anchor: .init(noteID: note.id, recordedHeading: "Session 1",
            baselineText: "", recordingState: .unrecorded), text: rich.string, richTextArchive: try RichTextArchive.encode(rich))
        snapshot.messages = [.init(requestID: UUID(), conversationID: snapshot.conversationID, role: .assistant,
            text: String(repeating: "Earlier response for reading and scrolling.\n", count: 60), status: .complete,
            scratchpadRevision: 0, observationID: note.observationID)]
        let controller = try SessionScratchpadWindowController(snapshot: snapshot, store: .init(directory: root),
            note: note, association: nil, profile: .init(version: "test", entries: []),
            assistant: FakeProgrammingAssistant(delay: .milliseconds(1)))
        func descendants(_ view: NSView) -> [NSView] { [view] + view.subviews.flatMap(descendants) }
        let views = descendants(try #require(controller.window?.contentView))
        let scroll = try #require(views.compactMap { $0 as? ConversationScrollView }.first)
        let composer = try #require(views.first { $0.identifier?.rawValue == "chat-composer" } as? NSTextView)
        let send = try #require(views.compactMap { $0 as? NSButton }.first { $0.title == "Send" })
        scroll.contentView.scroll(to: .zero)
        scroll.reflectScrolledClipView(scroll.contentView)
        composer.string = "Keep this as an offline test."
        controller.textDidChange(Notification(name: NSText.didChangeNotification, object: composer))
        send.performClick(nil)
        for _ in 0..<100 {
            if controller.snapshot.messages.last?.status == .complete { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(controller.snapshot.messages.last?.status == .complete)
        #expect(scroll.contentView.bounds.origin.y == 0)
        #expect(scroll.hasContentBelow && !scroll.latestButton.isHidden)
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
