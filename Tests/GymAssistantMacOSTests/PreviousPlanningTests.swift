import AppKit
import Testing
import GymAssistantWorkspace
@testable import GymAssistantMacOS

private actor PlanningReader: NotesContextReading {
    var html = "<div><h2>Session 4</h2></div><div>A1 Row</div>"
    var unavailable = false
    func captureSelectedNote() async throws -> NoteSnapshot { try await read(id: NoteID("planning-fixture")) }
    func read(id: NoteID) async throws -> NoteSnapshot {
        if unavailable { throw NotesReadError.unavailable }
        return NoteSnapshot(id: id, text: "", html: html)
    }
    func metadata(id: NoteID) async throws -> NoteMetadata { .init(id: id, modifiedAt: .distantPast) }
    func replace(_ value: String) { html = value }
    func goOffline() { unavailable = true }
}

@Suite("Previous planning", .serialized) @MainActor struct PreviousPlanningTests {
    private func descendants(_ view: NSView) -> [NSView] { [view] + view.subviews.flatMap(descendants) }

    @Test func browsingCapturesOpenEditsWithoutSavingAndDoesNotGuessHeadingIdentity() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("planning-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = WorkspaceSnapshotStore(directory: root), reader = PlanningReader()
        let windows = SessionWorkspaceWindows(store: store, reader: reader,
            profile: .init(version: "test", entries: []), assistant: FakeProgrammingAssistant())
        let id = NoteID("planning-fixture")
        let controller = try await windows.latest(in: id)
        let url = store.currentURL(for: controller.snapshot.workspaceID)
        let saved = try Data(contentsOf: url)
        let views = descendants(try #require(controller.window?.contentView))
        let editor = try #require(views.first { $0.identifier?.rawValue == "scratchpad-editor" } as? NSTextView)
        let composer = try #require(views.first { $0.identifier?.rawValue == "chat-composer" } as? NSTextView)
        let added = "An unsaved idea\n"
        #expect(controller.textView(editor, shouldChangeTextIn: NSRange(location: editor.string.utf16.count, length: 0), replacementString: added))
        editor.textStorage?.append(NSAttributedString(string: added)); composer.string = "Why not a clean?"
        await reader.replace("<div><h2>Session 5 — dated</h2></div><div>A1 Row</div>")
        let references = try await windows.planningReferences(in: id)
        #expect(references.count == 1)
        #expect(references[0].snapshot.text.contains("An unsaved idea"))
        #expect(references[0].snapshot.composerText == "Why not a clean?")
        #expect(references[0].includesOpenEditor && references[0].verifiedHeading == "Session 5 — dated")
        #expect(references[0].snapshot.anchor.recordedHeading == "Session 4")
        #expect(try Data(contentsOf: url) == saved)
        await reader.replace("<div><h2>Session 4</h2></div><div>Different performed work</div>")
        #expect(try await windows.planningReferences(in: id)[0].verifiedHeading == nil)
        await reader.goOffline()
        let offline = try await windows.planningReferences(in: id)
        #expect(offline.count == 1 && offline[0].verifiedHeading == nil)
        #expect(try Data(contentsOf: url) == saved)
        controller.window?.close()
    }

    @Test func browserShowsReadOnlyScratchpadConversationAndUnsentRationale() throws {
        let text = "Session 4\nParking Lot\nTry a clean\n"
        var snapshot = WorkspaceSnapshot(anchor: .init(noteID: .init("fixture"), recordedHeading: "Session 4", baselineText: text),
            text: text, richTextArchive: try RichTextArchive.encode(NSAttributedString(string: text)), composerText: "Keep it light")
        snapshot.messages = [.init(requestID: UUID(), conversationID: snapshot.conversationID, role: .coach,
            text: "I want a coordination challenge", status: .complete, scratchpadRevision: 0, observationID: UUID())]
        let browser = try PreviousPlanningWindow(records: [.init(snapshot: snapshot, savedAt: nil,
            includesOpenEditor: false, verifiedHeading: nil)])
        let views = descendants(try #require(browser.window?.contentView))
        let scratchpad = try #require(views.first { $0.identifier?.rawValue == "previous-planning-scratchpad" } as? NSTextView)
        let conversation = try #require(views.first { $0.identifier?.rawValue == "previous-planning-conversation" } as? NSTextView)
        let chooser = try #require(views.first { $0.identifier?.rawValue == "previous-planning-chooser" } as? NSPopUpButton)
        #expect(!scratchpad.isEditable && scratchpad.isSelectable && scratchpad.string == text)
        #expect(!conversation.isEditable && conversation.isSelectable)
        #expect(conversation.string.contains("I want a coordination challenge"))
        #expect(conversation.string.contains("Unsent message\nKeep it light"))
        #expect(chooser.titleOfSelectedItem?.contains("Other planning for this note") == true)
        let previousMenu = NSApp.mainMenu
        defer { NSApp.mainMenu = previousMenu }
        browser.windowDidBecomeKey(Notification(name: NSWindow.didBecomeKeyNotification))
        let menu = try #require(NSApp.mainMenu)
        #expect(menu.items.allSatisfy { $0.title != "Format" })
        let edit = try #require(menu.items.first { $0.title == "Edit" }?.submenu)
        #expect(edit.items.map(\.title) == ["Copy", "Select All"])
        #expect(edit.items.allSatisfy { $0.target == nil })
        browser.close()
    }

    @Test func damagedCurrentIsNotSilentlyShownAsItsOlderBackup() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("planning-damage-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = WorkspaceSnapshotStore(directory: root), reader = PlanningReader()
        let windows = SessionWorkspaceWindows(store: store, reader: reader,
            profile: .init(version: "test", entries: []), assistant: FakeProgrammingAssistant())
        let controller = try await windows.latest(in: NoteID("planning-fixture"))
        try store.save(controller.snapshot)
        let url = store.currentURL(for: controller.snapshot.workspaceID)
        let damaged = Data("broken".utf8); try damaged.write(to: url)
        await #expect(throws: SnapshotStoreError.recoveryRequired(controller.snapshot.workspaceID)) {
            _ = try await windows.planningReferences(in: NoteID("planning-fixture"))
        }
        #expect(try Data(contentsOf: url) == damaged)
        controller.window?.close()
    }
}
