import AppKit
import GymAssistantWorkspace

@MainActor private final class ChatComposer: NSTextView {
    var submit: (() -> Void)?
    override func keyDown(with event: NSEvent) {
        if [36, 76].contains(event.keyCode), !event.modifierFlags.contains(.shift) { submit?(); return }
        super.keyDown(with: event)
    }
}

/// Persistent editor for recorded sections or explicitly unrecorded additions.
/// Live context is optional for bounded offline tests; installed rollout remains gated.
@MainActor public final class SessionScratchpadWindowController: NSWindowController, NSTextViewDelegate, NSWindowDelegate, NSMenuItemValidation {
    public private(set) var snapshot: WorkspaceSnapshot
    public var onActivate: (() -> Void)?
    public var onPreviousPlanning: (@MainActor () async throws -> Void)?
    private var planningTask: Task<Void, Never>?

    public func planningReferenceSnapshot() throws -> WorkspaceSnapshot {
        var reference = snapshot
        reference.text = editor.string
        reference.richTextArchive = try RichTextArchive.encode(editor.attributedString())
        reference.composerText = composer.string
        try reference.validate()
        return reference
    }

    @objc public func previousPlanning() {
        guard planningTask == nil, let onPreviousPlanning else { return }
        planningTask = Task { [weak self] in
            defer { self?.planningTask = nil }
            do { try await onPreviousPlanning() }
            catch { if !Task.isCancelled { self?.status.stringValue = "Previous planning could not be opened safely. Existing work is unchanged." } }
        }
    }
    private let store: WorkspaceSnapshotStore
    private var note: NoteSnapshot
    private var association: SessionAssociation?
    private let profile: CoachingProfile
    private let assistant: any ProgrammingAssistant
    private let noteContext: SessionNoteContext?
    private let pasteboard: NSPasteboard
    private let editor = ScratchpadTextView()
    private let transcript = ExerciseConversationView()
    private let exerciseLookup: (String) -> ExerciseMentionMatch
    private let composer = ChatComposer()
    private let diff = NSTextView()
    private let status = NSTextField(labelWithString: "")
    private let sendButton = NSButton(title: "Send", target: nil, action: nil)
    private let stopButton = NSButton(title: "Stop", target: nil, action: nil)
    private var gate = RequestGate()
    private var responseTask: Task<Void, Never>?
    private var saveTask: Task<Void, Never>?
    private var editorScroll = NSScrollView()
    private var diffScroll = NSScrollView()
    private var showingDiff = false
    private var savedRevision: Int?
    private var boundaryBrowser: SessionBoundaryBrowser?
    private var preferencesWindow: ProgrammingPreferencesWindow?
    private var preparingRequest = false
    private let checkedCopy = CheckedScratchpadCopy()
    private var comparisonTask: Task<Void, Never>?
    private var comparisonGeneration = UUID()
    private var boundaryTask: Task<Void, Never>?
    private var committingBoundary = false
    private var preparedBoundaryRestore: WorkspaceSnapshot?
    private var associationPane: SessionAssociationPane?
    private var conversationViews: [NSView] = []
    private let findSessionButton = NSButton(title: "Find session in Notes…", target: nil, action: nil)
    private var compareButton: NSButton?
    private let notPastedButton = NSButton(title: "Not pasted yet", target: nil, action: nil)
    private let replaceButton = NSButton(title: "Replace scratchpad with current Notes…", target: nil, action: nil)
    private var replacementTask: Task<Void, Never>?
    private var replacing = false
    private var replacementNeedsReopen = false

    public init(snapshot: WorkspaceSnapshot, store: WorkspaceSnapshotStore,
                note: NoteSnapshot, association: SessionAssociation?, profile: CoachingProfile,
                assistant: any ProgrammingAssistant = FakeProgrammingAssistant(), noteContext: SessionNoteContext? = nil,
                pasteboard: NSPasteboard = .general,
                exerciseLookup: @escaping (String) -> ExerciseMentionMatch = { _ in .unavailable }) throws {
        self.snapshot = snapshot; self.store = store; self.note = note
        self.association = association; self.profile = profile; self.assistant = assistant
        self.noteContext = noteContext
        self.pasteboard = pasteboard
        self.exerciseLookup = exerciseLookup
        let rich = try RichTextArchive.decode(snapshot.richTextArchive)
        try snapshot.validate()
        guard snapshot.isActive else { throw SnapshotStoreError.unsafeExistingFile }
        guard rich.string == snapshot.text else { throw WorkspaceError.invalidArchive }
        guard snapshot.anchor.noteID == note.id else { throw WorkspaceError.staleAssociation }
        if let association {
            guard association.sessionID == snapshot.anchor.sessionID, association.noteID == note.id else {
                throw WorkspaceError.staleAssociation
            }
        }
        if snapshot.anchor.isUnrecorded {
            guard association == nil else { throw WorkspaceError.staleAssociation }
            if let noteContext {
                guard noteContext.noteID == note.id,
                      noteContext.sourceDocument?.snapshot.observationID == note.observationID else {
                    throw WorkspaceError.staleAssociation
                }
            }
        } else if let association, let noteContext {
            guard try noteContext.association(for: snapshot.anchor.sessionID) == association,
                  noteContext.sourceDocument?.snapshot.observationID == note.observationID else {
                throw WorkspaceError.staleAssociation
            }
            if let savedRange = snapshot.boundaryProtection?.sourceRange, savedRange != association.range {
                // Stable association may relocate a session after earlier headings
                // change length. Old absolute edit coordinates are not reusable.
                self.snapshot.boundaryProtection = BoundaryEditProtection(sourceRange: association.range)
                self.snapshot.boundaryProtection?.markUncertain(currentLength: rich.length)
            }
        } else if let association, let savedRange = snapshot.boundaryProtection?.sourceRange, savedRange != association.range {
            guard savedRange.isParagraphAligned(in: note.text),
                  snapshot.anchor.sourceEvidence?.text == (note.text as NSString).substring(with: savedRange.nsRange) else {
                throw WorkspaceError.staleAssociation
            }
            self.association = SessionAssociation(sessionID: association.sessionID, noteID: association.noteID,
                                                  observationID: note.observationID, range: savedRange)
        }
        guard snapshot.anchor.isUnrecorded || association != nil else { throw WorkspaceError.staleAssociation }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1050, height: 680),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        super.init(window: window)
        window.title = noteContext == nil ? "Session scratchpad — offline synthetic test" : "Session scratchpad"
        window.isReleasedWhenClosed = false
        window.delegate = self
        snapshotDidRestore()
        configure(rich: rich)
        if noteContext != nil {
            let undo = ValidatedBoundaryUndoManager()
            undo.didChangeChecking = { [weak self] checking in
                self?.editor.isEditable = !checking
                if checking { self?.status.stringValue = "Checking Notes before boundary undo/redo…" }
            }
            undo.didFail = { [weak self] _ in
                self?.status.stringValue = "Boundary undo/redo unchanged. Notes, ownership, or local storage needs review."
            }
            editor.boundaryUndoManager = undo
        }
        if snapshot.boundaryProtection == nil, let association = self.association {
            self.snapshot.boundaryProtection = BoundaryEditProtection(sourceRange: association.range)
            // Older saved scratchpads have no edit correspondence. Preserve them;
            // do not assume visible text equality proves formatting was untouched.
            if snapshot.revision > 0 { self.snapshot.boundaryProtection?.markUncertain(currentLength: rich.length) }
        }
        refreshTranscript()
        updateAvailability()
        saveNow()
        noteContext?.subscribe(workspace: snapshot.workspaceID) { [weak self] in self?.sourceChanged() }
    }
    public required init?(coder: NSCoder) { nil }
    public func formattingMenu() -> NSMenu {
        let menu = NSMenu(title: "Format")
        for command in ScratchpadFormat.allCases {
            let item = NSMenuItem(title: command.title, action: #selector(formatScratchpad(_:)), keyEquivalent: command.key)
            item.tag = command.rawValue; item.target = self; item.keyEquivalentModifierMask = command.modifiers
            menu.addItem(item)
        }
        return menu
    }
    public func validateMenuItem(_ item: NSMenuItem) -> Bool {
        if let keyWindow = NSApp.keyWindow, keyWindow !== window { return false }
        if replacing || replacementNeedsReopen { return false }
        if item.action == #selector(focusConversation) { return associationPane == nil }
        if item.action == #selector(findSessionInNotes) {
            return snapshot.anchor.isUnrecorded && associationPane == nil && boundaryTask == nil
                && gate.active == nil && !preparingRequest && noteContext != nil
        }
        if item.action == #selector(toggleDiff) { item.state = showingDiff ? .on : .off }
        if item.action == #selector(adjustBoundary) { return !snapshot.anchor.isUnrecorded }
        if item.action == #selector(formatScratchpad(_:)) {
            return window?.firstResponder === editor && !showingDiff && editor.isEditable
        }
        return true
    }
    public func comparisonMenuItems() -> [NSMenuItem] {
        [("Find Session in Notes…", #selector(findSessionInNotes), "f"),
         ("Compare with Source", #selector(toggleDiff), "d"),
         ("Focus Conversation", #selector(focusConversation), "m")].map { title, action, key in
            let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
            item.target = self; item.keyEquivalentModifierMask = [.command, .shift]
            return item
        }
    }
    @objc public func focusConversation() {
        guard associationPane == nil else { return }
        transcript.focusFirstMention()
    }
    private struct FormattingState {
        let rich: NSAttributedString
        let selection: NSRange
        let typing: [NSAttributedString.Key: Any]
        let protection: BoundaryEditProtection?
    }
    private func formattingState() -> FormattingState {
        FormattingState(rich: NSAttributedString(attributedString: editor.attributedString()), selection: editor.selectedRange(),
                        typing: editor.typingAttributes, protection: snapshot.boundaryProtection)
    }
    private func restoreFormatting(_ state: FormattingState) {
        let inverse = formattingState()
        editor.undoManager?.registerUndo(withTarget: self) { $0.restoreFormatting(inverse) }
        editor.undoManager?.disableUndoRegistration()
        editor.textStorage?.setAttributedString(state.rich)
        editor.setSelectedRange(state.selection); editor.typingAttributes = state.typing
        editor.undoManager?.enableUndoRegistration()
        if let association, state.protection?.sourceRange != association.range {
            // An undo captured before association has no recorded coordinates.
            // Keep the undo, but never restore absent/stale boundary protection.
            snapshot.boundaryProtection = BoundaryEditProtection(sourceRange: association.range)
            snapshot.boundaryProtection?.markUncertain(currentLength: state.rich.length)
        } else { snapshot.boundaryProtection = state.protection }
        textDidChange(Notification(name: NSText.didChangeNotification, object: editor))
    }
    @objc public func formatScratchpad(_ sender: NSMenuItem) {
        guard validateMenuItem(sender), let command = ScratchpadFormat(rawValue: sender.tag) else { return }
        let before = formattingState()
        if command == .bold && before.selection.length == 0 {
            let font = before.typing[.font] as? NSFont ?? .systemFont(ofSize: 16)
            let bold = NSFontManager.shared.traits(of: font).contains(.boldFontMask)
            editor.typingAttributes[.font] = bold ? NSFontManager.shared.convert(font, toNotHaveTrait: .boldFontMask)
                : NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
            return
        }
        let source = NSMutableAttributedString(attributedString: before.rich)
        // An empty final paragraph needs an actual paragraph to hold a semantic
        // style in persistence/export. Keep the insertion point on that paragraph.
        if command != .bold && before.selection.location == source.length && (source.length == 0 || source.string.hasSuffix("\n")) {
            source.append(NSAttributedString(string: "\n", attributes: before.typing))
        }
        let affected = command == .bold ? before.selection : ScratchpadFormatting.paragraphRange(before.selection, in: source.string as NSString)
        let result = ScratchpadFormatting.apply(command, to: source, selection: before.selection)
        do {
            let oldLength = min(affected.length, max(0, before.rich.length - affected.location))
            let oldRange = NSRange(location: affected.location, length: oldLength)
            if result.length != before.rich.length {
                try snapshot.boundaryProtection?.edited(range: oldRange, replacementLength: oldLength + result.length - before.rich.length)
            } else { try snapshot.boundaryProtection?.formattingChanged(range: oldRange) }
        } catch { snapshot.boundaryProtection?.markUncertain(currentLength: result.length) }
        editor.undoManager?.registerUndo(withTarget: self) { $0.restoreFormatting(before) }
        editor.undoManager?.setActionName(command.title)
        editor.undoManager?.disableUndoRegistration()
        editor.textStorage?.setAttributedString(result)
        let delta = result.length - before.rich.length
        let position = min(result.length, max(affected.location, before.selection.location + (command == .bulletedList ? max(0, delta) : min(0, delta))))
        editor.setSelectedRange(before.selection.length == 0 ? NSRange(location: position, length: 0)
            : NSRange(location: affected.location, length: affected.length + result.length - source.length))
        if result.length > 0 { editor.typingAttributes = result.attributes(at: min(position, result.length - 1), effectiveRange: nil) }
        editor.undoManager?.enableUndoRegistration()
        textDidChange(Notification(name: NSText.didChangeNotification, object: editor))
    }
    private func snapshotDidRestore() { snapshot.markInterruptedRequests() }
    private func scroll(_ text: NSTextView, frame: NSRect, editable: Bool, rich: Bool) -> NSScrollView {
        let scroll = NSScrollView(frame: frame)
        scroll.hasVerticalScroller = true
        text.frame = NSRect(origin: .zero, size: frame.size)
        text.minSize = NSSize(width: 0, height: frame.height)
        text.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        text.isVerticallyResizable = true
        text.isHorizontallyResizable = false
        text.textContainer?.widthTracksTextView = true
        text.textContainerInset = NSSize(width: 12, height: 12)
        text.autoresizingMask = [.width]
        text.isEditable = editable; text.isRichText = rich; text.allowsUndo = editable
        text.font = .systemFont(ofSize: 15)
        scroll.documentView = text
        return scroll
    }
    private func configure(rich: NSAttributedString) {
        guard let root = window?.contentView else { return }
        editor.returnToBody = { [weak self] in
            let item = NSMenuItem(title: "Body", action: #selector(Self.formatScratchpad(_:)), keyEquivalent: "")
            item.tag = ScratchpadFormat.body.rawValue
            self?.formatScratchpad(item)
        }
        let description = NSTextField(labelWithString: noteContext == nil
            ? "Synthetic note · saved locally · fake assistant · no Notes/API access"
            : "Notes context · scratchpad saved locally · manual handoff")
        description.frame = NSRect(x: 18, y: 646, width: 1000, height: 20)
        description.textColor = .secondaryLabelColor
        root.addSubview(description)
        editorScroll = scroll(editor, frame: NSRect(x: 16, y: 58, width: 570, height: 568), editable: true, rich: true)
        editorScroll.autoresizingMask = [.width, .height]
        editor.textStorage?.setAttributedString(rich)
        editor.identifier = NSUserInterfaceItemIdentifier("scratchpad-editor")
        editor.setAccessibilityLabel("Session scratchpad")
        editor.delegate = self
        root.addSubview(editorScroll)
        diffScroll = scroll(diff, frame: editorScroll.frame, editable: false, rich: false)
        diffScroll.autoresizingMask = editorScroll.autoresizingMask
        diffScroll.isHidden = true
        root.addSubview(diffScroll)
        let chat = scroll(transcript, frame: NSRect(x: 605, y: 222, width: 425, height: 404), editable: false, rich: false)
        transcript.setAccessibilityLabel("Conversation")
        chat.autoresizingMask = [.minXMargin, .height]
        root.addSubview(chat)
        let input = scroll(composer, frame: NSRect(x: 605, y: 90, width: 425, height: 118), editable: true, rich: false)
        input.autoresizingMask = [.minXMargin]
        composer.submit = { [weak self] in self?.submit() }
        composer.identifier = NSUserInterfaceItemIdentifier("chat-composer")
        composer.setAccessibilityLabel("Message")
        input.borderType = .lineBorder
        composer.string = snapshot.composerText
        composer.delegate = self
        root.addSubview(input)
        let copy = NSButton(image: NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: "Copy Markdown for Notes")!, target: self, action: #selector(copyForNotes))
        copy.frame = NSRect(x: 543, y: 591, width: 30, height: 28)
        copy.autoresizingMask = [.minXMargin, .minYMargin]
        copy.toolTip = "Copy Markdown for Notes (Command-Shift-C). Use Notes Paste as Markdown."
        copy.keyEquivalent = "c"; copy.keyEquivalentModifierMask = [.command, .shift]
        root.addSubview(copy)
        let compare = NSButton(checkboxWithTitle: "Compare with source", target: self, action: #selector(toggleDiff))
        compareButton = compare
        compare.frame = NSRect(x: 16, y: 26, width: 195, height: 24)
        compare.toolTip = noteContext == nil ? "Compare with the frozen synthetic source; live Notes monitoring is not connected."
            : "Compare with Notes after a fresh read. Notes changes never replace the scratchpad."
        diff.identifier = NSUserInterfaceItemIdentifier("notes-comparison")
        root.addSubview(compare)
        sendButton.target = self; sendButton.action = #selector(send)
        sendButton.frame = NSRect(x: 947, y: 54, width: 83, height: 26)
        sendButton.autoresizingMask = [.minXMargin]
        root.addSubview(sendButton)
        stopButton.target = self; stopButton.action = #selector(stop)
        stopButton.frame = NSRect(x: 857, y: 54, width: 83, height: 26)
        stopButton.autoresizingMask = [.minXMargin]
        root.addSubview(stopButton)
        conversationViews = [chat, input, sendButton, stopButton]
        findSessionButton.frame = NSRect(x: 605, y: 630, width: 235, height: 28)
        findSessionButton.target = self; findSessionButton.action = #selector(findSessionInNotes)
        findSessionButton.autoresizingMask = [.minXMargin, .minYMargin]
        findSessionButton.isHidden = !snapshot.anchor.isUnrecorded
        root.addSubview(findSessionButton)
        notPastedButton.frame = NSRect(x: 850, y: 630, width: 180, height: 28)
        notPastedButton.target = self; notPastedButton.action = #selector(confirmNotPasted)
        notPastedButton.autoresizingMask = [.minXMargin, .minYMargin]
        notPastedButton.isHidden = !snapshot.anchor.isUnrecorded
        root.addSubview(notPastedButton)
        description.frame.size.width = 575
        let history = NSButton(title: "Previous planning…", target: self, action: #selector(previousPlanning))
        history.frame = NSRect(x: 395, y: 630, width: 190, height: 25)
        history.identifier = .init("scratchpad-previous-planning")
        history.keyEquivalent = "h"; history.keyEquivalentModifierMask = [.command, .shift]
        history.toolTip = "Previous planning for this note (Command-Shift-H). Read only."
        root.addSubview(history)
        description.frame.size.width = 370
        replaceButton.frame = NSRect(x: 215, y: 25, width: 375, height: 26)
        replaceButton.target = self; replaceButton.action = #selector(replaceFromCurrentNotes)
        replaceButton.identifier = .init("replace-scratchpad-from-notes")
        replaceButton.isHidden = true; root.addSubview(replaceButton)
        status.frame = NSRect(x: 16, y: 3, width: 1014, height: 20)
        status.identifier = NSUserInterfaceItemIdentifier("workspace-status")
        status.autoresizingMask = [.width]
        status.textColor = .secondaryLabelColor
        root.addSubview(status)
        window?.minSize = NSSize(width: 1000, height: 650)
    }
    public func show() {
        guard snapshot.isActive else { return }
        showWindow(nil); window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(editor)
        NSApp.activate(ignoringOtherApps: true)
        if let noteContext { Task { await noteContext.setVisible(true, workspace: snapshot.workspaceID) } }
    }
    public func windowDidBecomeKey(_ notification: Notification) { onActivate?() }

    private func sourceChanged() {
        updateReplacementAvailability()
        guard !committingBoundary else { return }
        guard let noteContext else { return }
        if let document = noteContext.sourceDocument { note = document.snapshot }
        if let pane = associationPane {
            if let document = noteContext.sourceDocument, let rich = noteContext.richText {
                if document.paragraphs != pane.document.paragraphs {
                    pane.refresh(document: document, rich: rich, owners: associationOwners())
                } else { pane.updateOwners(associationOwners()) }
            }
            return
        }
        if snapshot.anchor.isUnrecorded {
            do {
                switch try insertionState() {
                case .notInserted:
                    status.stringValue = "Unrecorded session · scratchpad saved locally; Notes not written."
                case .needsReview:
                    status.stringValue = "Notes changed · session association needs review. Scratchpad preserved; chat paused."
                case .verified:
                    var current = snapshot
                    current.text = editor.string
                    current.richTextArchive = try RichTextArchive.encode(editor.attributedString())
                    current.composerText = composer.string
                    committingBoundary = true
                    defer { committingBoundary = false }
                    // Save the complete editor state before ownership changes.
                    try store.save(current)
                    snapshot = try noteContext.associateInsertedSession(current, observation: note.observationID, store: store)
                    savedRevision = snapshot.revision
                    association = try noteContext.association(for: snapshot.anchor.sessionID)
                    findSessionButton.isHidden = true; notPastedButton.isHidden = true
                    status.stringValue = "Session found in Notes · scratchpad and conversation preserved."
                    refreshTranscript()
                }
            } catch {
                status.stringValue = "Session association could not be verified. Scratchpad preserved; review Notes or local recovery."
            }
            if snapshot.anchor.isUnrecorded {
                if showingDiff { renderComparison() }
                return
            }
        }
        if let fresh = try? noteContext.association(for: snapshot.anchor.sessionID) {
            if fresh.range != association?.range {
                snapshot.boundaryProtection = BoundaryEditProtection(sourceRange: fresh.range)
                snapshot.boundaryProtection?.markUncertain(currentLength: (snapshot.text as NSString).length)
            }
            association = fresh
            if let document = noteContext.sourceDocument,
               let latest = try? document.evidence(in: fresh.range), latest.text != snapshot.anchor.baselineText {
                status.stringValue = "Notes changed — compare before pasting. Scratchpad preserved."
            }
        } else {
            status.stringValue = noteContext.failure ?? "Session association needs review. Use Adjust Session Boundary."
        }
        if showingDiff { renderComparison() }
    }
    private func insertionState() throws -> UnrecordedSessionAssociation.Result {
        guard let noteContext, noteContext.failure == nil, let document = noteContext.sourceDocument else {
            throw WorkspaceError.staleAssociation
        }
        let scratchpad = try ProgramDocumentReader.document(snapshot: NoteSnapshot(id: note.id, text: editor.string),
            richText: editor.attributedString())
        return UnrecordedSessionAssociation.evaluate(anchor: snapshot.anchor,
            scratchpad: SessionSourceEvidence(paragraphs: scratchpad.paragraphs), document: document)
    }

    private func associationOwners() -> [SessionBoundaryBrowser.Owner] {
        guard let noteContext else { return [] }
        return noteContext.registry.mappings.values.map {
            .init(label: noteContext.registry.anchor(for: $0.sessionID)?.recordedHeading ?? "Saved workspace", range: $0.range)
        }
    }
    @objc public func findSessionInNotes() {
        guard !replacing, !replacementNeedsReopen else { return }
        guard snapshot.anchor.isUnrecorded, associationPane == nil, boundaryTask == nil,
              gate.active == nil, !preparingRequest, let noteContext else { return }
        boundaryTask = Task { [weak self] in
            guard let self else { return }
            defer { self.boundaryTask = nil }
            do {
                let document = try await noteContext.refresh(for: .comparison)
                try Task.checkCancellation()
                guard self.snapshot.anchor.isUnrecorded, let rich = noteContext.richText else { return }
                self.saveTask?.cancel()
                guard self.saveNow() else { return }
                let pane = SessionAssociationPane(frame: NSRect(x: 605, y: 54, width: 425,
                    height: self.editorScroll.frame.maxY - 54), document: document, rich: rich, owners: self.associationOwners())
                self.associationPane = pane
                self.editor.isEditable = false
                self.conversationViews.forEach { $0.isHidden = true }
                self.findSessionButton.isHidden = true; self.notPastedButton.isHidden = true
                pane.selectionChanged = { [weak self] _ in if self?.showingDiff == true { self?.renderComparison() } }
                pane.cancel = { [weak self] in self?.endAssociationReview() }
                pane.apply = { [weak self, weak pane] range, preview in
                    guard let self, let pane else { throw WorkspaceError.staleAssociation }
                    let fresh = try await noteContext.refresh(for: .comparison)
                    try Task.checkCancellation()
                    guard self.associationPane === pane, fresh.paragraphs == preview.paragraphs else { throw WorkspaceError.staleAssociation }
                    guard self.saveNow() else { throw WorkspaceError.invalidSnapshot }
                    self.committingBoundary = true
                    defer { self.committingBoundary = false }
                    self.snapshot = try noteContext.confirmInsertedSession(self.snapshot, range: range,
                        observation: fresh.snapshot.observationID, store: self.store)
                    self.savedRevision = self.snapshot.revision
                    self.association = try noteContext.association(for: self.snapshot.anchor.sessionID)
                    self.endAssociationReview()
                    self.status.stringValue = "Session associated. Neither Notes nor scratchpad content was replaced."
                }
                self.window?.contentView?.addSubview(pane)
                pane.suggestHeading(self.editor.string.components(separatedBy: .newlines).first ?? "")
                pane.focus(); self.updateAvailability()
            } catch { self.status.stringValue = "Could not read Notes for association. Scratchpad preserved." }
        }
    }
    private func endAssociationReview() {
        associationPane?.stop(); associationPane?.removeFromSuperview(); associationPane = nil
        editor.isEditable = true
        conversationViews.forEach { $0.isHidden = false }
        findSessionButton.isHidden = !snapshot.anchor.isUnrecorded; notPastedButton.isHidden = !snapshot.anchor.isUnrecorded
        updateAvailability()
        if showingDiff { renderComparison() }
        window?.makeFirstResponder(editor)
    }
    @objc public func confirmNotPasted() {
        guard !replacing, !replacementNeedsReopen else { return }
        guard snapshot.anchor.isUnrecorded, associationPane == nil, boundaryTask == nil,
              gate.active == nil, !preparingRequest, let noteContext else { return }
        boundaryTask = Task { [weak self] in
            guard let self else { return }
            self.committingBoundary = true
            defer { self.boundaryTask = nil; self.committingBoundary = false }
            do {
                let document = try await noteContext.refresh(for: .resume)
                try Task.checkCancellation()
                guard self.snapshot.anchor.isUnrecorded else { return }
                var candidate = self.snapshot
                candidate.anchor.unrecordedOrigin = .init(paragraphs: document.paragraphs)
                candidate.text = self.editor.string; candidate.richTextArchive = try RichTextArchive.encode(self.editor.attributedString())
                candidate.composerText = self.composer.string; candidate.revision += 1
                try self.store.save(candidate)
                self.snapshot = candidate; self.savedRevision = candidate.revision
                self.note = document.snapshot
                self.status.stringValue = "Confirmed not pasted · scratchpad remains an unrecorded addition."
            } catch { self.status.stringValue = "Unrecorded state unchanged. Notes or local storage could not be verified." }
        }
    }
    public func textDidChange(_ notification: Notification) {
        let changedEditor = notification.object as AnyObject? === editor
        guard changedEditor || notification.object as AnyObject? === composer else { return }
        snapshot.composerText = composer.string
        if changedEditor {
            snapshot.text = editor.string; snapshot.revision += 1
            if snapshot.boundaryProtection?.isValid(currentLength: (editor.string as NSString).length) == false {
                snapshot.boundaryProtection?.markUncertain(currentLength: (editor.string as NSString).length)
            }
        }
        if changedEditor, gate.active != nil { status.stringValue = "Scratchpad changed · reply uses an earlier revision" }
        refreshTranscript()
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(500)) } catch { return }
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }
    public func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        guard textView === editor else { return true }
        do {
            if let replacementString {
                try snapshot.boundaryProtection?.edited(range: affectedCharRange, replacementLength: (replacementString as NSString).length)
            } else { try snapshot.boundaryProtection?.formattingChanged(range: affectedCharRange) }
        } catch { snapshot.boundaryProtection?.markUncertain() }
        return true
    }

    @objc public func adjustBoundary() {
        guard !replacing, !replacementNeedsReopen else { return }
        guard let association, !snapshot.anchor.isUnrecorded else {
            status.stringValue = "Unrecorded session has no Notes boundary to adjust."; return
        }
        guard editor.boundaryUndoManager?.checking != true, boundaryTask == nil else { return }
        if let noteContext {
            boundaryTask = Task { [weak self] in
                guard let self else { return }
                defer { self.boundaryTask = nil }
                do {
                    let document = try await noteContext.refresh(for: .boundary)
                    let current = try noteContext.association(for: self.snapshot.anchor.sessionID)
                    guard let rich = noteContext.richText else { throw WorkspaceError.staleAssociation }
                    let owners = noteContext.registry.mappings.values.filter { $0.sessionID != current.sessionID }.map {
                        SessionBoundaryBrowser.Owner(label: noteContext.registry.anchor(for: $0.sessionID)?.recordedHeading ?? "Saved session", range: $0.range)
                    }
                    self.boundaryBrowser = SessionBoundaryBrowser(document: document, richText: rich, selected: current.range,
                        owners: owners, preview: { [weak self] range in
                            guard let self, let protection = self.snapshot.boundaryProtection else { throw BoundaryChangeError.uncertainCorrespondence }
                            _ = try protection.preview(range, in: document.snapshot.text)
                        }, apply: { [weak self] range in
                            guard let self else { throw WorkspaceError.staleAssociation }
                            try await self.applyLiveBoundary(range, preview: document, expectedRange: current.range)
                        })
                    self.boundaryBrowser?.show()
                } catch { self.status.stringValue = "Boundary unavailable. Notes association or local recovery needs review; scratchpad preserved." }
            }
            return
        }
        do {
            let rich = NSAttributedString(string: note.text, attributes: [.font: NSFont.systemFont(ofSize: 15)])
            let document = try ProgramDocumentReader.document(snapshot: note, richText: rich)
            boundaryBrowser = SessionBoundaryBrowser(document: document, richText: rich, selected: association.range,
                owners: [], preview: { [weak self] range in
                    guard let self, let protection = self.snapshot.boundaryProtection else {
                        throw BoundaryChangeError.uncertainCorrespondence
                    }
                    _ = try protection.preview(range, in: document.snapshot.text)
                }, apply: { [weak self] range in
                    guard let self else { throw WorkspaceError.staleAssociation }
                    try Task.checkCancellation()
                    try self.applyBoundary(range, document: document, source: rich)
                })
            boundaryBrowser?.show()
        } catch { status.stringValue = "Boundary unavailable: \(error)" }
    }

    func applyLiveBoundary(_ range: SourceRange, preview: ProgramDocument, expectedRange: SourceRange) async throws {
        guard let noteContext, editor.boundaryUndoManager?.checking != true else { throw WorkspaceError.staleAssociation }
        let fresh = try await noteContext.refresh(for: .boundary)
        try Task.checkCancellation()
        guard editor.boundaryUndoManager?.checking != true,
              fresh.paragraphs == preview.paragraphs, association?.range == expectedRange,
              let rich = noteContext.richText else { throw WorkspaceError.staleAssociation }
        try applyBoundary(range, document: fresh, source: rich)
    }

    @objc public func showProgrammingPreferences() {
        if preferencesWindow == nil { preferencesWindow = ProgrammingPreferencesWindow(profile: profile) }
        preferencesWindow?.show()
    }

    func applyBoundary(_ range: SourceRange, document: ProgramDocument, source: NSAttributedString) throws {
        guard let association, !snapshot.anchor.isUnrecorded else { throw WorkspaceError.staleAssociation }
        guard document.snapshot.observationID == note.observationID else { throw WorkspaceError.staleAssociation }
        guard var protection = snapshot.boundaryProtection else { throw BoundaryChangeError.uncertainCorrespondence }
        let change = try protection.apply(range, in: note.text)
        let before = NSAttributedString(attributedString: editor.attributedString())
        let previousAssociation = association
        let previousAnchor = snapshot.anchor
        let previousProtection = snapshot.boundaryProtection
        let rich = NSMutableAttributedString(attributedString: before)
        if change.removeSuffix > 0 { rich.deleteCharacters(in: NSRange(location: rich.length - change.removeSuffix, length: change.removeSuffix)) }
        if change.removePrefix > 0 { rich.deleteCharacters(in: NSRange(location: 0, length: change.removePrefix)) }
        if let prefix = change.prepend { rich.insert(source.attributedSubstring(from: prefix.nsRange), at: 0) }
        if let suffix = change.append { rich.append(source.attributedSubstring(from: suffix.nsRange)) }
        if noteContext != nil {
            let previous = BoundaryState(rich: before, association: previousAssociation,
                anchor: previousAnchor, protection: previousProtection, document: document)
            var candidate = snapshot
            candidate.anchor.sourceEvidence = try document.evidence(in: range)
            candidate.boundaryProtection = protection
            try persistBoundary(&candidate, rich: rich, range: range, document: document)
            editor.breakUndoCoalescing()
            editor.boundaryUndoManager?.beginBoundaryGroup()
            registerLiveBoundaryUndo(previous)
            editor.boundaryUndoManager?.endBoundaryGroup()
            installBoundary(candidate, rich: rich, range: range, document: document)
            return
        }
        editor.undoManager?.registerUndo(withTarget: self) { target in
            target.restoreBoundary(rich: before, association: previousAssociation, anchor: previousAnchor, protection: previousProtection)
        }
        editor.undoManager?.setActionName("Adjust session boundary")
        self.association = SessionAssociation(sessionID: association.sessionID, noteID: association.noteID,
                                         observationID: association.observationID, range: range)
        snapshot.anchor.sourceEvidence = try document.evidence(in: range)
        snapshot.boundaryProtection = protection
        editor.undoManager?.disableUndoRegistration()
        editor.textStorage?.setAttributedString(rich)
        editor.undoManager?.enableUndoRegistration()
        snapshot.revision += 1
        saveNow(); refreshTranscript()
    }

    private struct BoundaryState {
        let rich: NSAttributedString
        let association: SessionAssociation
        let anchor: SessionAnchor
        let protection: BoundaryEditProtection?
        let document: ProgramDocument
    }

    private func persistBoundary(_ candidate: inout WorkspaceSnapshot, rich: NSAttributedString,
                                 range: SourceRange, document: ProgramDocument) throws {
        guard let noteContext else { throw WorkspaceError.staleAssociation }
        candidate.text = rich.string; candidate.richTextArchive = try RichTextArchive.encode(rich)
        candidate.composerText = composer.string; candidate.revision = snapshot.revision + 1
        committingBoundary = true
        defer { committingBoundary = false }
        try noteContext.commitBoundary(candidate, range: range, observation: document.snapshot.observationID, store: store)
    }

    private func installBoundary(_ candidate: WorkspaceSnapshot, rich: NSAttributedString,
                                 range: SourceRange, document: ProgramDocument) {
        saveTask?.cancel()
        snapshot = candidate; savedRevision = candidate.revision; note = document.snapshot
        association = SessionAssociation(sessionID: snapshot.anchor.sessionID, noteID: note.id,
            observationID: note.observationID, range: range)
        editor.undoManager?.disableUndoRegistration()
        editor.textStorage?.setAttributedString(rich)
        editor.undoManager?.enableUndoRegistration()
        refreshTranscript(); sourceChanged()
    }

    private func registerLiveBoundaryUndo(_ target: BoundaryState) {
        guard let undo = editor.boundaryUndoManager else { return }
        undo.registerUndo(withTarget: self) { controller in
            guard let candidate = controller.preparedBoundaryRestore,
                  let association = controller.association,
                  let document = controller.noteContext?.sourceDocument else { return }
            let reverse = BoundaryState(rich: NSAttributedString(attributedString: controller.editor.attributedString()),
                association: association, anchor: controller.snapshot.anchor,
                protection: controller.snapshot.boundaryProtection, document: document)
            controller.preparedBoundaryRestore = nil
            controller.registerLiveBoundaryUndo(reverse)
            controller.installBoundary(candidate, rich: target.rich, range: target.association.range, document: document)
        }
        undo.nameBoundaryAction { [weak self] in
            guard let self, let context = self.noteContext else { throw WorkspaceError.staleAssociation }
            let document = try await context.refresh(for: .boundary)
            try Task.checkCancellation()
            guard document.paragraphs == target.document.paragraphs else { throw WorkspaceError.staleAssociation }
            var candidate = self.snapshot
            candidate.anchor = target.anchor; candidate.boundaryProtection = target.protection
            candidate.anchor.sourceEvidence = try document.evidence(in: target.association.range)
            try self.persistBoundary(&candidate, rich: target.rich, range: target.association.range, document: document)
            self.preparedBoundaryRestore = candidate
        }
    }

    private func restoreBoundary(rich: NSAttributedString, association previous: SessionAssociation,
                                 anchor: SessionAnchor, protection: BoundaryEditProtection?) {
        guard let association else { return }
        // Frozen development source only. Live ownership/freshness must be checked
        // before this operation is offered in the real Notes workspace.
        guard previous.observationID == note.observationID else {
            status.stringValue = "Cannot undo boundary: Notes association changed."; return
        }
        let redoRich = NSAttributedString(attributedString: editor.attributedString()), redoAssociation = association, redoAnchor = snapshot.anchor
        let redoProtection = snapshot.boundaryProtection
        editor.undoManager?.registerUndo(withTarget: self) { target in
            target.restoreBoundary(rich: redoRich, association: redoAssociation, anchor: redoAnchor, protection: redoProtection)
        }
        self.association = previous; snapshot.anchor = anchor; snapshot.boundaryProtection = protection
        editor.undoManager?.disableUndoRegistration()
        editor.textStorage?.setAttributedString(rich)
        editor.undoManager?.enableUndoRegistration()
        snapshot.revision += 1; saveNow(); refreshTranscript()
    }
    @discardableResult private func saveNow() -> Bool {
        // Replacement starts from a fully saved editor and preserves its prior
        // state. On uncertain promotion, freeze writes until a fresh app reopen.
        if replacementNeedsReopen { return true }
        guard snapshot.isActive else { return true }
        do {
            snapshot.text = editor.string
            snapshot.richTextArchive = try RichTextArchive.encode(editor.attributedString())
            snapshot.composerText = composer.string
            try store.save(snapshot)
            savedRevision = snapshot.revision
            status.stringValue = gate.active == nil ? "Saved scratchpad r\(snapshot.revision) locally · \(noteContext == nil ? "synthetic Notes unverified" : "Notes not written")" : "Saved locally · reply in progress\(snapshot.revision == gate.active?.revision ? "" : " · Scratchpad changed")"
            if gate.active == nil { sourceChanged() }
            return true
        } catch {
            status.stringValue = "Local save failed; last saved revision \(savedRevision.map(String.init) ?? "unknown"). Keep this window open."
            return false
        }
    }
    @objc private func send() { submit() }
    private func submit() {
        guard !replacing, !replacementNeedsReopen else { return }
        guard snapshot.isActive else { return }
        guard associationPane == nil else { return }
        guard gate.active == nil, !preparingRequest else { status.stringValue = "Reply in progress — Stop or wait; follow-up stays here."; return }
        let question = composer.string
        if let noteContext {
            preparingRequest = true; updateAvailability()
            status.stringValue = "Reading current Notes context…"
            responseTask = Task { [weak self] in
                guard let self else { return }
                do {
                    _ = try await noteContext.refresh(for: .chat)
                    try Task.checkCancellation()
                    guard let document = noteContext.sourceDocument else { throw WorkspaceError.staleAssociation }
                    self.note = document.snapshot
                    if !self.snapshot.anchor.isUnrecorded {
                        self.association = try noteContext.association(for: self.snapshot.anchor.sessionID)
                    }
                    self.preparingRequest = false
                    self.sendPrepared(question: question)
                } catch {
                    guard !Task.isCancelled else { return }
                    self.preparingRequest = false; self.updateAvailability()
                    self.status.stringValue = "Question not sent. Notes or session association needs review; your message is preserved."
                }
            }
        } else { sendPrepared(question: question) }
    }

    private func sendPrepared(question: String) {
        saveTask?.cancel()
        guard saveNow() else { updateAvailability(); return }
        do {
            let request: ProgrammingRequest
            if snapshot.anchor.isUnrecorded {
                if noteContext != nil {
                    guard try insertionState() == .notInserted else { throw WorkspaceError.staleAssociation }
                }
                request = try ProgramContextAssembler.assembleUnrecorded(note: note, workspace: snapshot,
                    profile: profile, question: question, maximumContextBytes: 1_000_000)
            } else {
                guard let association else { throw WorkspaceError.staleAssociation }
                request = try ProgramContextAssembler.assemble(note: note, association: association,
                    workspace: snapshot, profile: profile, question: question, maximumContextBytes: 1_000_000)
            }
            try gate.begin(request)
            snapshot.messages.append(ConversationMessage(requestID: request.id, conversationID: request.conversationID,
                role: .coach, text: request.question, status: .complete, scratchpadRevision: request.revision, observationID: request.observationID))
            snapshot.messages.append(ConversationMessage(requestID: request.id, conversationID: request.conversationID,
                role: .assistant, text: "", status: .pending, scratchpadRevision: request.revision, observationID: request.observationID))
            if composer.string == question { composer.string = "" }
            saveNow(); updateAvailability(); refreshTranscript()
            responseTask = Task { [weak self, assistant] in
                do {
                    let response = try await assistant.reply(to: request)
                    guard let self, self.gate.finish(response) != nil else { return }
                    self.updateReply(requestID: request.id, text: response.text, status: .complete, mentions: response.exerciseMentions)
                } catch {
                    guard let self, self.gate.active?.id == request.id else { return }
                    self.gate.stop()
                    self.updateReply(requestID: request.id, text: "Reply unavailable. No automatic retry.", status: .failed)
                }
            }
        } catch {
            updateAvailability()
            status.stringValue = "Question not sent: \(error). Your text is still in the composer."
        }
    }
    private func updateReply(requestID: UUID, text: String, status: MessageStatus, mentions: [ExerciseMention] = []) {
        if let index = snapshot.messages.firstIndex(where: { $0.requestID == requestID && $0.role == .assistant }) {
            snapshot.messages[index].text = text; snapshot.messages[index].status = status
            snapshot.messages[index].exerciseMentions = ExerciseMention.validated(mentions, in: text)
        }
        updateAvailability(); refreshTranscript(); saveNow()
    }
    @objc private func stop() {
        if preparingRequest {
            responseTask?.cancel(); preparingRequest = false; updateAvailability()
            status.stringValue = "Stopped before sending. Your message stays here."; return
        }
        guard let request = gate.active else { return }
        gate.stop(); responseTask?.cancel(); responseTask = nil
        updateReply(requestID: request.id, text: "Stopped. No automatic resend.", status: .cancelled)
    }
    private func updateAvailability() {
        sendButton.isEnabled = !replacing && !replacementNeedsReopen && associationPane == nil && gate.active == nil && !preparingRequest
        stopButton.isEnabled = gate.active != nil || preparingRequest
        updateReplacementAvailability()
    }
    private func updateReplacementAvailability() {
        replaceButton.isHidden = !showingDiff || noteContext == nil || associationPane != nil
        replaceButton.isEnabled = snapshot.isActive && !snapshot.anchor.isUnrecorded
            && !replacing && !replacementNeedsReopen && gate.active == nil && !preparingRequest
            && boundaryTask == nil && editor.boundaryUndoManager?.checking != true
            && (try? noteContext?.association(for: snapshot.anchor.sessionID)) != nil
    }

    @objc public func replaceFromCurrentNotes() {
        updateReplacementAvailability()
        guard replaceButton.isEnabled, let noteContext, let window else { return }
        replacing = true; updateAvailability(); editor.isEditable = false
        replacementTask = Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await noteContext.refresh(for: .comparison)
                try Task.checkCancellation()
                self.saveTask?.cancel()
                guard self.saveNow() else { throw SnapshotStoreError.unavailable }
                let preview = try noteContext.replacementPreview(self.snapshot)
                self.showingDiff = true; self.compareButton?.state = .on
                self.editorScroll.isHidden = true; self.diffScroll.isHidden = false; self.renderComparison()
                let alert = NSAlert()
                alert.messageText = "Replace this scratchpad with current Notes?"
                alert.informativeText = "Only the verified session region will be copied into the scratchpad. Its previous content will remain in Previous planning. Conversation and unsent message stay attached. Notes will not change."
                alert.addButton(withTitle: "Cancel"); alert.addButton(withTitle: "Replace scratchpad")
                alert.beginSheetModal(for: window) { [weak self] response in
                    guard let self else { return }
                    if response == .alertSecondButtonReturn { self.confirmReplacement(preview) }
                    else { self.finishReplacement() }
                }
            } catch {
                self.status.stringValue = "Replacement unavailable: verify the session location and current Notes first. Scratchpad preserved."
                self.finishReplacement()
            }
        }
    }
    private func confirmReplacement(_ preview: NotesReplacementPreview) {
        replacementTask = Task { [weak self] in
            guard let self, let noteContext = self.noteContext else { return }
            defer { self.finishReplacement() }
            do {
                _ = try await noteContext.refresh(for: .comparison)
                try Task.checkCancellation()
                let current = try self.planningReferenceSnapshot()
                self.committingBoundary = true
                defer { self.committingBoundary = false }
                let next = try noteContext.replaceFromNotes(preview, current: current, store: self.store)
                self.snapshot = next; self.savedRevision = next.revision
                self.association = try noteContext.association(for: next.anchor.sessionID)
                self.editor.undoManager?.removeAllActions()
                self.editor.textStorage?.setAttributedString(try RichTextArchive.decode(next.richTextArchive))
                self.refreshTranscript(); self.renderComparison()
                self.status.stringValue = "Scratchpad replaced from Notes. Previous content retained in Previous planning; conversation preserved."
            } catch NotesReplacementError.persistenceUncertain {
                self.replacementNeedsReopen = true
                self.editor.undoManager?.removeAllActions(); self.saveTask?.cancel()
                self.status.stringValue = "Replacement could not be confirmed. Work is preserved on disk. Quit and reopen before editing; no retry was made."
            } catch {
                self.status.stringValue = "Notes or scratchpad changed, or location is no longer verified. Nothing replaced; compare again."
            }
        }
    }
    private func finishReplacement() {
        replacing = false; replacementTask = nil
        editor.isEditable = !replacementNeedsReopen && associationPane == nil
        composer.isEditable = !replacementNeedsReopen
        updateAvailability()
    }
    private func refreshTranscript() {
        let text = NSMutableAttributedString(string: "")
        var decorations: [ExerciseConversationView.Decoration] = []
        for message in snapshot.messages.filter({ $0.conversationID == snapshot.conversationID }) {
            if text.length > 0 { text.append(NSAttributedString(string: "\n\n")) }
            let freshness = message.role == .assistant && message.scratchpadRevision != snapshot.revision ? " · Scratchpad changed" : ""
            text.append(NSAttributedString(string: "\(message.role == .coach ? "You" : "Assistant") · r\(message.scratchpadRevision) · \(message.status.rawValue)\(freshness)\n"))
            let offset = text.length
            text.append(NSAttributedString(string: message.text))
            if message.role == .assistant && message.status == .complete {
                for mention in ExerciseMention.validated(message.exerciseMentions ?? [], in: message.text) {
                    decorations.append(.init(range: NSRange(location: offset + mention.range.location, length: mention.range.length),
                                             match: exerciseLookup(mention.text)))
                }
            }
        }
        if text.length > 0 { text.addAttributes([.font: NSFont.systemFont(ofSize: 15), .foregroundColor: NSColor.labelColor], range: NSRange(location: 0, length: text.length)) }
        transcript.display(text, decorations: decorations)
    }
    @objc public func copyForNotes() {
        guard !replacing, !replacementNeedsReopen else { return }
        saveTask?.cancel(); saveNow()
        let rich = NSAttributedString(attributedString: editor.attributedString())
        let copiedRevision = snapshot.revision
        let anchor = snapshot.anchor
        let context = noteContext
        let board = pasteboard
        var preparationFailure: String?
        status.stringValue = "Preparing Markdown copy…"
        checkedCopy.start(prepareAndPublish: {
            do { try ScratchpadRichTextExporter.publishMarkdown(rich, to: board) }
            catch ScratchpadExportError.invisibleListMarker {
                preparationFailure = "Copy blocked: a list paragraph has no visible bullet. Use Format → Body or Bulleted list on that paragraph."
                throw ScratchpadExportError.invisibleListMarker
            }
        }, verify: {
            guard let context else { return .unavailable }
            do {
                let document = try await context.refresh(for: .checkedCopy)
                // No recorded baseline exists yet; a successful read alone is
                // not evidence that this addition is safe to paste again.
                guard !anchor.isUnrecorded else { return .unavailable }
                let association = try context.association(for: anchor.sessionID)
                let latest = try document.evidence(in: association.range)
                // Legacy or manually reassociated evidence is not necessarily
                // the confirmed formatting baseline. Do not claim agreement.
                guard let baseline = anchor.sourceEvidence, baseline.text == anchor.baselineText else {
                    return latest.text == anchor.baselineText ? .unavailable : .conflict
                }
                return SessionComparison.handoffEquivalent(latest, baseline) ? .unchanged : .conflict
            } catch { return .unavailable }
        }, update: { [weak self] state in
            guard let self else { return }
            let suffix = self.snapshot.revision == copiedRevision ? "" : " · Scratchpad changed since copy"
            switch state {
            case .copiedChecking: self.status.stringValue = "Copied—checking Notes…" + suffix
            case .copiedVerified: self.status.stringValue = "Copied—Notes checked. Use Notes Paste as Markdown." + suffix
            case .copiedUnverified: self.status.stringValue = "Copied—Notes not verified. Check Notes before pasting." + suffix
            case .copiedConflict: self.status.stringValue = "Copied—Notes changed in this session. Compare before pasting; clipboard unchanged." + suffix
            case .failed: self.status.stringValue = preparationFailure ?? "Copy failed; no formatted handoff claimed."
            }
        })
    }
    @objc private func toggleDiff() {
        guard !replacing else { return }
        showingDiff.toggle()
        updateReplacementAvailability()
        compareButton?.state = showingDiff ? .on : .off
        comparisonTask?.cancel()
        comparisonGeneration = UUID()
        if showingDiff {
            if associationPane != nil {
                renderComparison()
                editorScroll.isHidden = true; diffScroll.isHidden = false
                return
            }
            if let noteContext {
                diff.string = "Checking Notes… Scratchpad preserved."
                let generation = comparisonGeneration
                comparisonTask = Task { [weak self] in
                    do {
                        _ = try await noteContext.refresh(for: .comparison)
                        guard !Task.isCancelled, let self, self.showingDiff, self.comparisonGeneration == generation else { return }
                        self.renderComparison()
                    } catch {
                        guard !Task.isCancelled, let self, self.showingDiff, self.comparisonGeneration == generation else { return }
                        self.diff.string = "Notes could not be verified. Scratchpad preserved; comparison is unavailable."
                    }
                }
            } else {
                renderComparison()
            }
            diff.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        }
        editorScroll.isHidden = showingDiff; diffScroll.isHidden = !showingDiff
        if !showingDiff { window?.makeFirstResponder(editor) }
    }
    private func renderComparison() {
        if let pane = associationPane {
            guard let range = pane.selectedRange else { diff.string = "Select a Notes region to compare with the read-only scratchpad."; return }
            let selected = (pane.document.snapshot.text as NSString).substring(with: range.nsRange)
            diff.string = "Text-only differences — formatting is not compared.\n− Only in Notes · + Only in scratchpad\nAssociation applies neither side.\n\n"
                + SessionComparison.text(before: selected, after: editor.string)
            return
        }
        if snapshot.anchor.isUnrecorded {
            if noteContext != nil, (try? insertionState()) != .notInserted {
                diff.string = "Notes changed or could not be verified. Session association needs review; scratchpad preserved."
                return
            }
            diff.string = "Unrecorded scratchpad r\(snapshot.revision) — proposed addition, not a replacement.\n"
                + "No Notes section is associated yet.\n\n" + SessionComparison.text(before: "", after: snapshot.text)
            return
        }
        guard let association else {
            diff.string = "Notes association is unresolved. Scratchpad is preserved; comparison is unavailable."; return
        }
        if noteContext != nil && (try? noteContext?.association(for: snapshot.anchor.sessionID)) == nil
            || association.observationID != note.observationID || !association.range.isParagraphAligned(in: note.text) {
            diff.string = "Notes association is unresolved. Scratchpad is preserved; comparison is unavailable."
            return
        }
        let title = noteContext == nil ? "Frozen synthetic source — NOT live Notes" : "Latest observed Notes"
        var comparison = SessionComparison.text(before: (note.text as NSString).substring(with: association.range.nsRange), after: snapshot.text)
        if let source = noteContext?.sourceDocument, let before = try? source.evidence(in: association.range),
           let current = try? ProgramDocumentReader.document(snapshot: NoteSnapshot(id: note.id, text: editor.string), richText: editor.attributedString()) {
            comparison = SessionComparison.handoffText(before: before, after: SessionSourceEvidence(paragraphs: current.paragraphs))
        }
        diff.string = "\(title) vs scratchpad r\(snapshot.revision)\n"
            + "Text-only comparison; formatting agreement not verified. Terminal empty body paragraphs are ignored when structured Notes context is available.\n\n"
            + comparison
    }
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard !replacing else { return false }
        endAssociationReview()
        editor.boundaryUndoManager?.cancelCheck(); boundaryTask?.cancel(); boundaryBrowser?.close()
        stop(); saveTask?.cancel(); return saveNow()
    }
    public func windowWillClose(_ notification: Notification) {
        planningTask?.cancel()
        checkedCopy.cancel()
        comparisonTask?.cancel()
        if let noteContext { Task { await noteContext.setVisible(false, workspace: snapshot.workspaceID) } }
    }
    public func flushAndStop() -> Bool {
        guard !replacing else { return false }
        planningTask?.cancel()
        endAssociationReview()
        editor.boundaryUndoManager?.cancelCheck(); boundaryTask?.cancel(); boundaryBrowser?.close()
        checkedCopy.cancel(); stop(); saveTask?.cancel(); return saveNow()
    }
    /// Called only after the complete snapshot has been durably set aside.
    public func retire(with preserved: WorkspaceSnapshot) {
        guard !preserved.isActive, preserved.workspaceID == snapshot.workspaceID else { return }
        snapshot = preserved
        planningTask?.cancel(); comparisonTask?.cancel(); saveTask?.cancel()
        noteContext?.unsubscribe(workspace: snapshot.workspaceID)
        if let noteContext { Task { await noteContext.setVisible(false, workspace: preserved.workspaceID) } }
        editor.isEditable = false; composer.isEditable = false
        sendButton.isEnabled = false; stopButton.isEnabled = false
        onActivate = nil; onPreviousPlanning = nil
        window?.delegate = nil; window?.close()
    }
}
