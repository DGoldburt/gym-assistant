import AppKit
import GymAssistantWorkspace
import GymAssistantMacOS

/// Explicit synthetic development app; never registers a Service or accesses Notes.
@MainActor final class DevelopmentDelegate: NSObject, NSApplicationDelegate {
    private var controller: SessionScratchpadWindowController?
    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            let noteID = NoteID("synthetic-development-note")
            let workspaceID = WorkspaceID(UUID(uuidString: "B1FB8360-E88A-4245-BFAD-FE8BB89C48EE")!)
            let sessionID = SessionID(UUID(uuidString: "2F4C5870-0933-4EA8-B9B5-C7A954CB43F8")!)
            let body = "Session 18\nWarmup\nBalance preparation\nA1 Single-leg RDL\nB1 Press\nB2 \n"
            let context = "Synthetic program\nSession 17\nA1 Row\n\n" + body + "\nProgram notes: synthetic example only.\n"
            let note = NoteSnapshot(id: noteID, text: context)
            let range = (context as NSString).range(of: body)
            let association = SessionAssociation(sessionID: sessionID, noteID: noteID,
                observationID: note.observationID, range: SourceRange(location: range.location, length: range.length))
            // Separate synthetic store, not the installed app's user workspace directory.
            let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("GymAssistantScratchpadDevelopment", isDirectory: true)
            let store = WorkspaceSnapshotStore(directory: root)
            let rich = NSMutableAttributedString(string: body, attributes: [.font: NSFont.systemFont(ofSize: 16)])
            for (heading, level) in [("Session 18\n", 2), ("Warmup\n", 3)] {
                let style = NSMutableParagraphStyle(); style.headerLevel = level
                rich.addAttributes([.paragraphStyle: style, .font: NSFont.boldSystemFont(ofSize: level == 2 ? 22 : 18)],
                                   range: (body as NSString).range(of: heading))
            }
            let loaded = try store.load(id: workspaceID)
            let snapshot = try loaded?.snapshot ?? WorkspaceSnapshot(workspaceID: workspaceID,
                anchor: SessionAnchor(sessionID: sessionID, noteID: noteID, recordedHeading: "Session 18", baselineText: body),
                text: body, richTextArchive: RichTextArchive.encode(rich))
            controller = try SessionScratchpadWindowController(snapshot: snapshot, store: store, note: note,
                association: association, profile: CoachingProfile(version: "synthetic-empty-1", entries: []),
                assistant: FakeProgrammingAssistant(delay: .seconds(15)))
            if loaded?.recoveredFromPrevious == true {
                let alert = NSAlert(); alert.messageText = "Recovered previous synthetic scratchpad"
                alert.informativeText = "Revision \(snapshot.revision) is available; damaged current state is preserved. Saves may remain blocked until recovery is resolved."
                alert.runModal()
            }
            let menu = NSMenu()
            let item = NSMenuItem(); let appMenu = NSMenu()
            appMenu.addItem(withTitle: "Quit Scratchpad Development", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            item.submenu = appMenu; menu.addItem(item)
            let edit = NSMenuItem(); edit.title = "Edit"; let editMenu = NSMenu(title: "Edit")
            for (title, action, key) in [("Undo", Selector(("undo:")), "z"), ("Copy", #selector(NSText.copy(_:)), "c"),
                                        ("Paste", #selector(NSText.paste(_:)), "v"), ("Select All", #selector(NSText.selectAll(_:)), "a")] {
                editMenu.addItem(withTitle: title, action: action, keyEquivalent: key)
            }
            let copyForNotes = NSMenuItem(title: "Copy Markdown for Notes", action: #selector(SessionScratchpadWindowController.copyForNotes), keyEquivalent: "c")
            copyForNotes.keyEquivalentModifierMask = [.command, .shift]
            copyForNotes.target = controller
            editMenu.addItem(copyForNotes)
            edit.submenu = editMenu; menu.addItem(edit); NSApp.mainMenu = menu
            let windowItem = NSMenuItem(); windowItem.title = "Window"
            let windowMenu = NSMenu(title: "Window")
            let reopen = NSMenuItem(title: "Session Scratchpad", action: #selector(showScratchpad), keyEquivalent: "0")
            reopen.target = self
            windowMenu.addItem(reopen); windowItem.submenu = windowMenu; menu.addItem(windowItem)
            controller?.show()
        } catch {
            let alert = NSAlert(); alert.messageText = "Synthetic workspace unavailable"
            alert.informativeText = "Existing files were preserved. \(error)"; alert.runModal()
            NSApp.terminate(nil)
        }
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        controller?.show(); return false
    }
    @objc private func showScratchpad() { controller?.show() }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if let controller, !controller.flushAndStop() { return .terminateCancel }
        return .terminateNow
    }
}

@main @MainActor struct DevelopmentMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = DevelopmentDelegate()
        app.delegate = delegate; app.setActivationPolicy(.regular)
        app.run()
    }
}
