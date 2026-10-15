import AppKit
import GymAssistantWorkspace

/// Independent of Services: the host schedules start() after returning its
/// callback. Permission onboarding and window lifetime never hold that callback.
@MainActor public final class SessionProgrammingEntryWindow: NSWindowController, NSWindowDelegate {
    private let workspaces: SessionWorkspaceWindows
    private let requestAccess: @MainActor () async throws -> Void
    private let status = NSTextField(wrappingLabelWithString: "")
    private let latest = NSButton(title: "Work on latest session", target: nil, action: nil)
    private let access = NSButton(title: "Allow Notes access…", target: nil, action: nil)
    private let retry = NSButton(title: "Use currently selected Notes note", target: nil, action: nil)
    private var noteID: NoteID?
    private var task: Task<Void, Never>?
    private var generation = UUID()
    private let modeDescription: String

    public init(workspaces: SessionWorkspaceWindows, modeDescription: String,
                requestAccess: @escaping @MainActor () async throws -> Void) {
        self.workspaces = workspaces; self.modeDescription = modeDescription; self.requestAccess = requestAccess
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 530, height: 250),
            styleMask: [.titled, .closable], backing: .buffered, defer: false)
        super.init(window: window)
        window.title = "Program session"; window.isReleasedWhenClosed = false; window.delegate = self
        let detail = NSTextField(wrappingLabelWithString: modeDescription)
        detail.frame = NSRect(x: 20, y: 192, width: 490, height: 40)
        window.contentView?.addSubview(detail)
        status.frame = NSRect(x: 20, y: 104, width: 490, height: 78)
        status.identifier = NSUserInterfaceItemIdentifier("program-entry-status")
        window.contentView?.addSubview(status)
        latest.frame = NSRect(x: 20, y: 64, width: 230, height: 32)
        latest.keyEquivalent = "\r"; latest.target = self; latest.action = #selector(openLatest)
        latest.identifier = NSUserInterfaceItemIdentifier("program-entry-latest")
        window.contentView?.addSubview(latest)
        let skeleton = NSButton(title: "New session — not connected yet", target: nil, action: nil)
        skeleton.frame = NSRect(x: 260, y: 64, width: 250, height: 32); skeleton.isEnabled = false
        skeleton.toolTip = "Heading-only new-session entry remains an implementation task."
        window.contentView?.addSubview(skeleton)
        access.frame = NSRect(x: 20, y: 20, width: 190, height: 30)
        access.target = self; access.action = #selector(allowAccess)
        access.identifier = NSUserInterfaceItemIdentifier("program-entry-access")
        window.contentView?.addSubview(access)
        retry.frame = NSRect(x: 210, y: 20, width: 300, height: 30)
        retry.target = self; retry.action = #selector(captureSelection)
        retry.identifier = NSUserInterfaceItemIdentifier("program-entry-capture")
        window.contentView?.addSubview(retry)
        latest.isEnabled = false; access.isHidden = true
    }
    public required init?(coder: NSCoder) { nil }

    public func start() {
        showExisting()
        captureSelection()
    }
    public func showExisting() {
        showWindow(nil); window?.center(); window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func captureSelection() {
        task?.cancel(); generation = UUID(); let operation = generation
        noteID = nil; latest.isEnabled = false; retry.isEnabled = false; access.isHidden = true; access.isEnabled = true
        status.stringValue = "Reading the single selected note in Notes…"
        task = Task { [weak self] in
            guard let self else { return }
            do {
                let captured = try await self.workspaces.captureNote()
                guard self.generation == operation, !Task.isCancelled else { return }
                self.noteID = captured; self.latest.isEnabled = true
                self.status.stringValue = "Press Return to work on the last session in this note. Changing your selection in Notes will not change this captured target."
            } catch {
                guard self.generation == operation, !Task.isCancelled else { return }
                self.present(error)
            }
            self.retry.isEnabled = true; self.task = nil
        }
    }

    @objc private func allowAccess() {
        guard task == nil else { return }
        let operation = generation
        access.isEnabled = false
        task = Task { [weak self] in
            guard let self else { return }
            do {
                try await self.requestAccess()
                try Task.checkCancellation()
                guard self.generation == operation else { return }
                // Permission may have taken time. Do not silently capture whatever
                // different note is selected after the system dialog closes.
                self.status.stringValue = "Access granted. Select the intended note in Notes, then choose Use currently selected Notes note."
                self.access.isHidden = true
            } catch { if !Task.isCancelled { self.present(error) } }
            guard self.generation == operation else { return }
            self.access.isEnabled = true; self.task = nil
        }
    }

    @objc private func openLatest() {
        guard task == nil, let noteID else { return }
        let operation = generation
        latest.isEnabled = false; retry.isEnabled = false
        status.stringValue = "Checking the session and its saved scratchpad…"
        task = Task { [weak self] in
            guard let self else { return }
            do {
                let controller = try await self.workspaces.latest(in: noteID)
                try Task.checkCancellation()
                guard self.generation == operation else { return }
                controller.onActivate = { [weak self, weak controller] in
                    guard let self, let controller else { return }
                    self.installMenus(for: controller)
                }
                controller.window?.title = "Session scratchpad — local test assistant"
                controller.show(); self.window?.orderOut(nil)
            } catch { if !Task.isCancelled { self.present(error) } }
            guard self.generation == operation else { return }
            self.latest.isEnabled = true; self.retry.isEnabled = true; self.task = nil
        }
    }

    private func present(_ error: any Error) {
        switch error {
        case NotesReadError.permission:
            status.stringValue = "Notes read access is needed. Allow access explicitly, then choose the intended note."
            access.isHidden = false
        case NotesReadError.ambiguousSelection:
            status.stringValue = "Select exactly one note in Notes, then retry."
        case SessionEntryError.duplicateHeadings(let labels):
            status.stringValue = "Duplicate session headings: \(labels.joined(separator: ", ")). Correct them in Notes, then press Return again. No scratchpad was replaced."
        case SessionEntryError.boundaryReviewRequired:
            status.stringValue = "The latest session needs explicit boundary selection. Entry boundary review is not connected yet; existing scratchpads are preserved."
        case SessionEntryError.recoveryRequired, SessionEntryError.unresolvedSavedWorkspace:
            status.stringValue = "A saved workspace needs association or file recovery. It has not been replaced. Recovery controls are not connected yet."
        default:
            status.stringValue = "Could not open this session safely. Notes and existing scratchpads were preserved. Check Notes access and supported formatting before retrying."
        }
    }

    private func installMenus(for controller: SessionScratchpadWindowController) {
        let menu = NSMenu()
        let app = NSMenuItem(); let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit Gym Assistant", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        app.submenu = appMenu; menu.addItem(app)
        let edit = NSMenuItem(title: "Edit", action: nil, keyEquivalent: ""), editMenu = NSMenu(title: "Edit")
        for (title, action, key) in [("Undo", Selector(("undo:")), "z"), ("Copy", #selector(NSText.copy(_:)), "c"),
                                    ("Paste", #selector(NSText.paste(_:)), "v"), ("Select All", #selector(NSText.selectAll(_:)), "a")] {
            editMenu.addItem(withTitle: title, action: action, keyEquivalent: key)
        }
        let redo = NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]; editMenu.insertItem(redo, at: 1)
        for (title, action, key) in [("Copy Markdown for Notes", #selector(SessionScratchpadWindowController.copyForNotes), "c"),
                                    ("Adjust Session Boundary…", #selector(SessionScratchpadWindowController.adjustBoundary), "b")] {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
            item.keyEquivalentModifierMask = [.command, .shift]; item.target = controller; editMenu.addItem(item)
        }
        edit.submenu = editMenu; menu.addItem(edit)
        let format = NSMenuItem(title: "Format", action: nil, keyEquivalent: "")
        format.submenu = controller.formattingMenu(); menu.addItem(format)
        let preferences = NSMenuItem(title: "Programming Preferences…", action: #selector(SessionScratchpadWindowController.showProgrammingPreferences), keyEquivalent: ",")
        preferences.target = controller; appMenu.addItem(preferences)
        NSApp.mainMenu = menu
    }

    private func stopPending() {
        task?.cancel(); task = nil; generation = UUID()
        retry.isEnabled = true; access.isEnabled = true; latest.isEnabled = noteID != nil
    }
    public func windowWillClose(_ notification: Notification) { stopPending() }
    public func cancel() { stopPending(); window?.orderOut(nil) }
}
