import AppKit
import GymAssistantWorkspace
import GymAssistantMacOS
import GymAssistantOpenAI

private struct MentionFixtureAssistant: ProgrammingAssistant {
    func reply(to request: ProgrammingRequest) async throws -> ProgrammingResponse {
        let text = "Synthetic display test — not exercise advice.\nTry SL RDL or single-leg RDL with reach. Keep the rest unchanged."
        let mentions = ["SL RDL", "single-leg RDL with reach"].map { name in
            let range = (text as NSString).range(of: name)
            return ExerciseMention(text: name, range: .init(location: range.location, length: range.length))
        }
        return ProgrammingResponse(requestID: request.id, text: text, exerciseMentions: mentions)
    }
}

private actor SyntheticEntryReader: NotesContextReading {
    static let html = "<div><h2>Session 18</h2></div><div><h3>Warmup</h3></div><div>Balance preparation</div><div><h3>Strength</h3></div><div>A1 Row</div><div><h2>Parking Lot</h2></div><ul><li>Try a <b>light clean</b> next time</li></ul>"
    func captureSelectedNote() async throws -> NoteSnapshot { try await read(id: NoteID("synthetic-entry-note")) }
    func read(id: NoteID) async throws -> NoteSnapshot {
        NoteSnapshot(id: id, text: "", html: Self.html)
    }
    func metadata(id: NoteID) async throws -> NoteMetadata { NoteMetadata(id: id, modifiedAt: .distantPast) }
}

/// Explicit development app; Notes access requires a separate fixture-test command.
@MainActor final class DevelopmentDelegate: NSObject, NSApplicationDelegate {
    private var controller: SessionScratchpadWindowController?
    private var entry: SessionProgrammingEntryWindow?
    private var workspaces: SessionWorkspaceWindows?
    private let notesReader = NotesContextReader()
    private let chatGPTConnection = ChatGPTConnection()
    func applicationDidFinishLaunching(_ notification: Notification) {
        if CommandLine.arguments.contains("--synthetic-entry") {
            let root = FileManager.default.temporaryDirectory.appendingPathComponent("gym-assistant-entry-acceptance-" + UUID().uuidString)
            let store = WorkspaceSnapshotStore(directory: root)
            if CommandLine.arguments.contains("--synthetic-planning") {
                do {
                    let noteID = NoteID("synthetic-entry-note")
                    for (html, question) in [
                        (SyntheticEntryReader.html, "Could the finisher challenge coordination without more load?"),
                        ("<div><h2>Session 17</h2></div><div>An older idea not found in current Notes</div>", "Keep this idea for another session")
                    ] {
                        let (document, rich) = try ProgramDocumentReader.read(.init(id: noteID, text: "", html: html))
                        let evidence = SessionSourceEvidence(paragraphs: document.paragraphs)
                        var snapshot = WorkspaceSnapshot(anchor: .init(noteID: noteID,
                            recordedHeading: evidence.paragraphs[0].label, baselineText: evidence.text, sourceEvidence: evidence),
                            text: rich.string, richTextArchive: try RichTextArchive.encode(rich), composerText: question)
                        snapshot.messages = [.init(requestID: UUID(), conversationID: snapshot.conversationID,
                            role: .coach, text: "I chose a light movement to leave room for coordination practice.",
                            status: .complete, scratchpadRevision: 0, observationID: UUID())]
                        try store.save(snapshot)
                    }
                } catch { NSApp.terminate(nil); return }
            }
            if CommandLine.arguments.contains("--synthetic-recovery") {
                do {
                    let rich = NSAttributedString(string: "Session 19\nSaved synthetic coach work\n")
                    let snapshot = WorkspaceSnapshot(anchor: .init(noteID: NoteID("synthetic-entry-note"), recordedHeading: "Session 19",
                        baselineText: "", recordingState: .unrecorded), text: rich.string,
                        richTextArchive: try RichTextArchive.encode(rich), composerText: "Saved synthetic question")
                    try store.save(snapshot); try store.save(snapshot)
                    try Data("Synthetic damaged current file".utf8).write(to: store.currentURL(for: snapshot.workspaceID))
                } catch { NSApp.terminate(nil); return }
            }
            let windows = SessionWorkspaceWindows(store: store, reader: SyntheticEntryReader(),
                profile: .init(version: "synthetic-empty", entries: []),
                assistant: CommandLine.arguments.contains("--synthetic-mentions") ? MentionFixtureAssistant() : FakeProgrammingAssistant(),
                exerciseLookup: { text in
                    guard CommandLine.arguments.contains("--synthetic-mentions") else { return .unavailable }
                    return text == "SL RDL" ? .inLibrary(canonicalName: "Single-leg Romanian deadlift") : .notMatched
                })
            workspaces = windows
            entry = SessionProgrammingEntryWindow(workspaces: windows,
                modeDescription: "Synthetic entry acceptance · temporary store · no Notes access · local test assistant",
                requestAccess: { throw NotesReadError.unavailable })
            entry?.start()
            return
        }
        do {
            let live = CommandLine.arguments.contains("--live-synthetic")
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
                .appendingPathComponent(live ? "GymAssistantLiveSyntheticTrial" : "GymAssistantScratchpadDevelopment", isDirectory: true)
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
                association: association, profile: CoachingProfile(version: "synthetic-short-replies-1", entries: [
                    .init(wording: "Keep replies short.", source: "Synthetic trial profile", kind: .authored, confirmed: true)
                ]),
                assistant: live ? ChatGPTProgrammingAssistant(connection: chatGPTConnection) : FakeProgrammingAssistant(delay: .seconds(15)))
            if live { controller?.window?.title = "Synthetic trial · 5.6 Terra medium · Using ChatGPT plan · 100 KB / 10 requests" }
            if loaded?.recoveredFromPrevious == true {
                let alert = NSAlert(); alert.messageText = "Recovered previous synthetic scratchpad"
                alert.informativeText = "Revision \(snapshot.revision) is available; damaged current state is preserved. Saves may remain blocked until recovery is resolved."
                alert.runModal()
            }
            let menu = NSMenu()
            let item = NSMenuItem(); let appMenu = NSMenu()
            appMenu.addItem(withTitle: "Quit Scratchpad Development", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            item.submenu = appMenu; menu.addItem(item)
            if live {
                let account = NSMenuItem(title: "ChatGPT Account…", action: #selector(showChatGPTAccount), keyEquivalent: "")
                account.target = self; appMenu.addItem(account)
            }
            let edit = NSMenuItem(); edit.title = "Edit"; let editMenu = NSMenu(title: "Edit")
            for (title, action, key) in [("Undo", Selector(("undo:")), "z"), ("Copy", #selector(NSText.copy(_:)), "c"),
                                        ("Paste", #selector(NSText.paste(_:)), "v"), ("Select All", #selector(NSText.selectAll(_:)), "a")] {
                editMenu.addItem(withTitle: title, action: action, keyEquivalent: key)
            }
            let copyForNotes = NSMenuItem(title: "Copy Markdown for Notes", action: #selector(SessionScratchpadWindowController.copyForNotes), keyEquivalent: "c")
            copyForNotes.keyEquivalentModifierMask = [.command, .shift]
            copyForNotes.target = controller
            editMenu.addItem(copyForNotes)
            let boundary = NSMenuItem(title: "Adjust Session Boundary…", action: #selector(SessionScratchpadWindowController.adjustBoundary), keyEquivalent: "b")
            boundary.keyEquivalentModifierMask = [.command, .shift]; boundary.target = controller
            editMenu.addItem(boundary)
            edit.submenu = editMenu; menu.addItem(edit); NSApp.mainMenu = menu
            let redo = NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "z")
            redo.keyEquivalentModifierMask = [.command, .shift]; editMenu.insertItem(redo, at: 1)
            let format = NSMenuItem(); format.title = "Format"; format.submenu = controller?.formattingMenu()
            menu.addItem(format)
            let windowItem = NSMenuItem(); windowItem.title = "Window"
            let windowMenu = NSMenu(title: "Window")
            let reopen = NSMenuItem(title: "Session Scratchpad", action: #selector(showScratchpad), keyEquivalent: "0")
            reopen.target = self
            windowMenu.addItem(reopen); windowItem.submenu = windowMenu; menu.addItem(windowItem)
            let preferences = NSMenuItem(title: "Programming Preferences…", action: #selector(SessionScratchpadWindowController.showProgrammingPreferences), keyEquivalent: ",")
            preferences.target = controller; appMenu.addItem(preferences)
            let access = NSMenuItem(title: "Request Notes Access for Fixture Test…", action: #selector(requestNotesAccess), keyEquivalent: "")
            access.target = self; appMenu.addItem(access)
            let verify = NSMenuItem(title: "Verify Selected Notes Test Fixture…", action: #selector(verifyNotesFixture), keyEquivalent: "")
            verify.target = self; appMenu.addItem(verify)
            controller?.show()
        } catch {
            let alert = NSAlert(); alert.messageText = "Synthetic workspace unavailable"
            alert.informativeText = "Existing files were preserved. \(error)"; alert.runModal()
            NSApp.terminate(nil)
        }
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if let entry {
            if workspaces?.showMostRecent() != true { entry.showExisting() }
            return false
        }
        controller?.show(); return false
    }
    @objc private func showScratchpad() { controller?.show() }
    @objc private func showChatGPTAccount() {
        Task {
            let used = (try? await chatGPTConnection.trialRequestsUsed()).map(String.init) ?? "unknown"
            let alert = NSAlert()
            alert.messageText = "ChatGPT plan · 5.6 Terra · medium"
            alert.informativeText = "Synthetic trial requests used: \(used) / 10. Whole-request text limit: 100 KB. No output-token cap or automatic retries. Notes are not connected in this test window."
            for title in ["Done", "Continue with ChatGPT", "Manage usage", "Sign out"] { alert.addButton(withTitle: title) }
            let choice = alert.runModal()
            do {
                if choice.rawValue == NSApplication.ModalResponse.alertFirstButtonReturn.rawValue + 1 {
                    try await chatGPTConnection.connect { url in await MainActor.run { NSWorkspace.shared.open(url) } }
                    try await chatGPTConnection.verifySelectedModel()
                    showConnectionResult("Connected. 5.6 Terra is available. No programming request was sent.")
                } else if choice.rawValue == NSApplication.ModalResponse.alertFirstButtonReturn.rawValue + 2 {
                    NSWorkspace.shared.open(URL(string: "https://chatgpt.com/#settings/Usage")!)
                } else if choice.rawValue == NSApplication.ModalResponse.alertFirstButtonReturn.rawValue + 3 {
                    let confirmed = try await chatGPTConnection.disconnect()
                    showConnectionResult(confirmed ? "Signed out. Local programming work is preserved." : "Signed out locally. Remote revocation was not confirmed; disconnect Gym Assistant in ChatGPT settings. Local programming work is preserved.")
                }
            } catch {
                showConnectionResult("Account action could not complete. If a reply is running, stop it first. Existing scratchpad content is preserved.")
            }
        }
    }
    private func showConnectionResult(_ text: String) {
        let alert = NSAlert(); alert.messageText = "ChatGPT connection"; alert.informativeText = text; alert.runModal()
    }
    @objc private func requestNotesAccess() {
        Task {
            do { try await notesReader.requestAccess(); showFixtureResult("Notes access is available. Select the synthetic capability-test note, then run Verify Selected Notes Test Fixture.") }
            catch { showFixtureResult("Notes access unavailable: \(error). No note was changed.") }
        }
    }
    @objc private func verifyNotesFixture() {
        Task {
            do {
                let captured = try await notesReader.captureSelectedNote()
                guard captured.text.components(separatedBy: .newlines).first?.lowercased() == "gym assistant capability test" else {
                    showFixtureResult("Select the note named Gym assistant capability test. No other note will be imported or saved by this test."); return
                }
                let (document, _) = try ProgramDocumentReader.read(captured)
                let metadata = try await notesReader.metadata(id: captured.id)
                let reread = try await notesReader.read(id: captured.id)
                guard metadata.id == captured.id, reread.id == captured.id else { throw NotesReadError.unavailable }
                showFixtureResult("Native read and captured-ID reread succeeded. Imported \(document.paragraphs.count) supported paragraphs and \(document.candidates().count) session regions. Metadata read returned the same note identity. No Notes write, stored note body, clipboard change, or API call occurred.")
            } catch { showFixtureResult("Fixture verification did not pass: \(error). Existing scratchpad and Notes were preserved.") }
        }
    }
    private func showFixtureResult(_ message: String) {
        let alert = NSAlert(); alert.messageText = "Notes reader fixture test"
        alert.informativeText = message; alert.runModal()
    }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if let workspaces, !workspaces.flushAndStop() { return .terminateCancel }
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
