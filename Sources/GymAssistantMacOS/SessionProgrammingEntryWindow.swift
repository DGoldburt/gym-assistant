import AppKit
import GymAssistantWorkspace

/// Independent of Services: the host schedules start() after returning its
/// callback. Permission onboarding and window lifetime never hold that callback.
@MainActor public final class SessionProgrammingEntryWindow: NSWindowController, NSWindowDelegate {
    private let workspaces: SessionWorkspaceWindows
    private let requestAccess: @MainActor () async throws -> Void
    private let status = NSTextField(wrappingLabelWithString: "")
    private let latest = NSButton(title: "Work on latest session", target: nil, action: nil)
    private let skeleton = NSButton(title: "New session", target: nil, action: nil)
    private let access = NSButton(title: "Allow Notes access…", target: nil, action: nil)
    private let retry = NSButton(title: "Use currently selected Notes note", target: nil, action: nil)
    private var noteID: NoteID?
    private var task: Task<Void, Never>?
    private var generation = UUID()
    private let modeDescription: String
    private let presentWorkspace: (@MainActor (SessionScratchpadWindowController) -> Void)?
    private var entryContent: NSView?
    private var proposal: SessionWorkspaceEntry.NewSessionProposal?
    private var previewStatus: NSTextField?
    private var acceptSkeleton: NSButton?
    private var recoveryID: WorkspaceID?
    private var recoveryPreview: WorkspaceRecoveryPreview?
    private let previewBackup = NSButton(title: "Preview last valid backup…", target: nil, action: nil)

    public init(workspaces: SessionWorkspaceWindows, modeDescription: String,
                presentWorkspace: (@MainActor (SessionScratchpadWindowController) -> Void)? = nil,
                requestAccess: @escaping @MainActor () async throws -> Void) {
        self.workspaces = workspaces; self.modeDescription = modeDescription; self.requestAccess = requestAccess
        self.presentWorkspace = presentWorkspace
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
        skeleton.frame = NSRect(x: 260, y: 64, width: 250, height: 32); skeleton.isEnabled = false
        skeleton.target = self; skeleton.action = #selector(openNewSession)
        skeleton.keyEquivalent = "n"; skeleton.keyEquivalentModifierMask = [.command]
        skeleton.identifier = .init("program-entry-new")
        skeleton.toolTip = "New session (Command-N). Resume unfinished unrecorded work, or preview a headings-only skeleton."
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
        entryContent = window.contentView
        previewBackup.frame = NSRect(x: 20, y: 64, width: 490, height: 32)
        previewBackup.target = self; previewBackup.action = #selector(showBackupPreview)
        previewBackup.identifier = .init("program-entry-preview-backup"); previewBackup.isHidden = true
        window.contentView?.addSubview(previewBackup)
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
        restoreEntryContent()
        recoveryID = nil; previewBackup.isHidden = true; latest.isHidden = false; skeleton.isHidden = false
        task?.cancel(); generation = UUID(); let operation = generation
        noteID = nil; latest.isEnabled = false; skeleton.isEnabled = false; retry.isEnabled = false; access.isHidden = true; access.isEnabled = true
        status.stringValue = "Reading the single selected note in Notes…"
        task = Task { [weak self] in
            guard let self else { return }
            do {
                let captured = try await self.workspaces.captureNote()
                guard self.generation == operation, !Task.isCancelled else { return }
                self.noteID = captured; self.latest.isEnabled = true; self.skeleton.isEnabled = true
                self.status.stringValue = "Return: latest session. Command-N: new session or resume unrecorded work. Changing your selection in Notes will not change this captured target."
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
        latest.isEnabled = false; skeleton.isEnabled = false; retry.isEnabled = false
        status.stringValue = "Checking the session and its saved scratchpad…"
        task = Task { [weak self] in
            guard let self else { return }
            do {
                let controller = try await self.workspaces.latest(in: noteID)
                try Task.checkCancellation()
                guard self.generation == operation else { return }
                self.showWorkspace(controller)
            } catch { if !Task.isCancelled { self.present(error) } }
            guard self.generation == operation else { return }
            self.latest.isEnabled = true; self.skeleton.isEnabled = true; self.retry.isEnabled = true; self.task = nil
        }
    }

    private func showWorkspace(_ controller: SessionScratchpadWindowController) {
        if let presentWorkspace { presentWorkspace(controller); return }
        controller.onActivate = { [weak self, weak controller] in
            guard let self, let controller else { return }
            self.installMenus(for: controller)
        }
        controller.window?.title = "Session scratchpad — local test assistant"
        controller.show(); window?.orderOut(nil)
    }

    @objc private func openNewSession() {
        guard task == nil, let noteID else { return }
        let operation = generation
        latest.isEnabled = false; skeleton.isEnabled = false; retry.isEnabled = false
        status.stringValue = "Checking for unfinished work before preparing a new session…"
        task = Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await self.workspaces.prepareNewSession(in: noteID)
                try Task.checkCancellation()
                guard self.generation == operation else { return }
                switch result {
                case .workspace(let controller): self.showWorkspace(controller)
                case .proposal(let proposal): self.showProposal(proposal)
                }
            } catch { if !Task.isCancelled { self.present(error) } }
            guard self.generation == operation else { return }
            self.task = nil; self.latest.isEnabled = true; self.skeleton.isEnabled = true; self.retry.isEnabled = true
        }
    }

    private func showProposal(_ proposal: SessionWorkspaceEntry.NewSessionProposal) {
        self.proposal = proposal
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 530, height: 520))
        let title = NSTextField(wrappingLabelWithString: "New session — headings only. No exercises, doses, dates or results are copied. You can edit the scratchpad after creating it.")
        title.frame = NSRect(x: 20, y: 445, width: 490, height: 55); root.addSubview(title)
        let scroll = NSScrollView(frame: NSRect(x: 20, y: 125, width: 490, height: 310))
        scroll.hasVerticalScroller = true
        let text = NSTextView(frame: NSRect(origin: .zero, size: scroll.frame.size))
        text.isEditable = false; text.isSelectable = true
        text.isVerticallyResizable = true; text.autoresizingMask = [.width]; text.textContainer?.widthTracksTextView = true
        text.font = .systemFont(ofSize: 16); text.identifier = .init("session-skeleton-preview")
        text.string = proposal.skeleton.evidence.text
        let omitted = proposal.skeleton.headingsNeedingReview.map { $0.paragraph.label }
        if !omitted.isEmpty {
            text.string += "\nNot copied — these headings may contain prescriptions or have uncertain structure:\n"
                + omitted.map { "• " + $0 }.joined(separator: "\n")
                + "\n\nReview these omissions before creating the scratchpad. Add any needed structure manually afterward."
        }
        scroll.documentView = text; root.addSubview(scroll)
        let message = NSTextField(wrappingLabelWithString: "Nothing is saved until you choose Create scratchpad. Notes will not be changed.")
        message.frame = NSRect(x: 20, y: 55, width: 490, height: 60)
        message.identifier = .init("session-skeleton-status"); root.addSubview(message); previewStatus = message
        let create = NSButton(title: "Create scratchpad", target: self, action: #selector(createFromProposal))
        create.frame = NSRect(x: 295, y: 15, width: 215, height: 30); create.keyEquivalent = "\r"
        create.identifier = .init("session-skeleton-create"); root.addSubview(create); acceptSkeleton = create
        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancelProposal))
        cancel.frame = NSRect(x: 20, y: 15, width: 90, height: 30); cancel.keyEquivalent = "\u{1b}"
        cancel.identifier = .init("session-skeleton-cancel"); root.addSubview(cancel)
        window?.contentView = root; window?.setContentSize(NSSize(width: 530, height: 520))
        window?.makeFirstResponder(create)
    }

    @objc private func createFromProposal() {
        guard task == nil, let proposal else { return }
        let operation = generation
        acceptSkeleton?.isEnabled = false; previewStatus?.stringValue = "Rechecking Notes before creating the scratchpad…"
        task = Task { [weak self] in
            guard let self else { return }
            do {
                let controller = try await self.workspaces.acceptNewSession(proposal)
                try Task.checkCancellation()
                guard self.generation == operation else { return }
                self.restoreEntryContent(); self.showWorkspace(controller)
            } catch { if !Task.isCancelled { self.present(error) } }
            guard self.generation == operation else { return }
            self.task = nil
            // A failed preview is not retried silently; Cancel and prepare again.
        }
    }

    private func restoreEntryContent() {
        guard proposal != nil || recoveryPreview != nil, let entryContent else { return }
        recoveryPreview = nil
        proposal = nil; previewStatus = nil; acceptSkeleton = nil
        window?.contentView = entryContent; window?.setContentSize(NSSize(width: 530, height: 250))
    }
    @objc private func cancelProposal() { stopPending(); restoreEntryContent() }

    @objc private func showBackupPreview() {
        guard task == nil, let recoveryID else { return }
        do {
            let preview = try workspaces.recoveryPreview(id: recoveryID)
            recoveryPreview = preview
            let root = NSView(frame: NSRect(x: 0, y: 0, width: 650, height: 560))
            let date = preview.backupModifiedAt?.formatted(date: .abbreviated, time: .standard) ?? "unknown"
            let title = NSTextField(wrappingLabelWithString: "Backup: \(preview.snapshot.anchor.recordedHeading) · revision \(preview.snapshot.revision)\nBackup file modified: \(date). This may omit more recent edits. Notes will not change.")
            title.frame = NSRect(x: 20, y: 465, width: 610, height: 75); root.addSubview(title)
            let scroll = NSScrollView(frame: NSRect(x: 20, y: 140, width: 610, height: 315)); scroll.hasVerticalScroller = true
            let text = NSTextView(frame: scroll.bounds); text.isEditable = false; text.isSelectable = true
            text.isVerticallyResizable = true; text.autoresizingMask = [.width]; text.textContainer?.widthTracksTextView = true
            text.textStorage?.setAttributedString(try RichTextArchive.decode(preview.snapshot.richTextArchive))
            text.identifier = .init("recovery-backup-preview"); scroll.documentView = text; root.addSubview(scroll)
            let detail = NSTextField(wrappingLabelWithString: "Restore this local scratchpad, including its saved conversation and unsent message. The damaged file will be retained separately; the backup stays intact.")
            detail.frame = NSRect(x: 20, y: 55, width: 610, height: 75); detail.identifier = .init("recovery-status")
            root.addSubview(detail); previewStatus = detail
            let restore = NSButton(title: "Restore this backup", target: self, action: #selector(restoreBackup))
            restore.frame = NSRect(x: 410, y: 15, width: 220, height: 30)
            restore.keyEquivalent = "\r"; restore.keyEquivalentModifierMask = [.command]
            restore.identifier = .init("recovery-restore"); root.addSubview(restore); acceptSkeleton = restore
            let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancelProposal))
            cancel.frame = NSRect(x: 20, y: 15, width: 90, height: 30); cancel.keyEquivalent = "\u{1b}"
            cancel.identifier = .init("recovery-cancel"); root.addSubview(cancel)
            window?.contentView = root; window?.setContentSize(NSSize(width: 650, height: 560))
            window?.makeFirstResponder(cancel)
        } catch {
            status.stringValue = "No safely restorable backup is available. Existing files are preserved; no empty scratchpad was created."
        }
    }

    @objc private func restoreBackup() {
        guard task == nil, let recoveryPreview else { return }
        acceptSkeleton?.isEnabled = false
        do {
            let preserved = try workspaces.restoreBackup(recoveryPreview)
            restoreEntryContent(); recoveryID = nil; previewBackup.isHidden = true
            latest.isHidden = false; skeleton.isHidden = false
            status.stringValue = "Backup restored locally. \(preserved == nil ? "No damaged current file existed." : "Damaged file retained beside the backup.") Choose the session again; Notes association will be rechecked."
        } catch SessionWorkspaceWindows.RecoveryError.retainedWorkspaces {
            previewStatus?.stringValue = "Other scratchpads are retained in this app. Quit normally to save them, relaunch, then review this backup again. Nothing was restored."
        } catch {
            previewStatus?.stringValue = "Restore could not be confirmed. Files were retained. Cancel and review again; do not assume restoration succeeded."
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
        case SessionEntryError.recoveryRequired(let id), SnapshotStoreError.recoveryRequired(let id):
            recoveryID = id; previewBackup.isHidden = false; latest.isHidden = true; skeleton.isHidden = true
            status.stringValue = "A saved scratchpad could not be opened safely. Preview its last valid backup before deciding whether to restore. Existing files are preserved."
        case SessionEntryError.unresolvedSavedWorkspace:
            status.stringValue = "Saved work needs association review. Choose New session to resume unrecorded work. Recorded-session association recovery is not connected yet; nothing has been replaced."
        case SessionEntryError.skeletonSourceChanged:
            status.stringValue = "Notes changed during preview. Cancel and choose New session again to review current headings. Nothing was created."
        case SessionEntryError.multipleUnrecordedWorkspaces:
            status.stringValue = "More than one unrecorded scratchpad exists for this note. None was chosen or replaced; workspace selection needs review."
        default:
            status.stringValue = "Could not open this session safely. Notes and existing scratchpads were preserved. Check Notes access and supported formatting before retrying."
        }
        previewStatus?.stringValue = status.stringValue
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
        controller.comparisonMenuItems().forEach { editMenu.addItem($0) }
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
        skeleton.isEnabled = noteID != nil
    }
    public func windowWillClose(_ notification: Notification) { stopPending(); restoreEntryContent() }
    public func cancel() { stopPending(); restoreEntryContent(); window?.orderOut(nil) }
}
