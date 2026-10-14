import AppKit
import GymAssistantWorkspace

@MainActor private final class ChatComposer: NSTextView {
    var submit: (() -> Void)?
    override func keyDown(with event: NSEvent) {
        if [36, 76].contains(event.keyCode), !event.modifierFlags.contains(.shift) { submit?(); return }
        super.keyDown(with: event)
    }
}

/// Offline development entry. Native Notes capture/monitor and Service integration
/// must be added before this controller can be used with real notes.
@MainActor public final class SessionScratchpadWindowController: NSWindowController, NSTextViewDelegate, NSWindowDelegate {
    public private(set) var snapshot: WorkspaceSnapshot
    private let store: WorkspaceSnapshotStore
    private let note: NoteSnapshot
    private let association: SessionAssociation
    private let profile: CoachingProfile
    private let assistant: any ProgrammingAssistant
    private let editor = NSTextView()
    private let transcript = NSTextView()
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

    public init(snapshot: WorkspaceSnapshot, store: WorkspaceSnapshotStore,
                note: NoteSnapshot, association: SessionAssociation, profile: CoachingProfile,
                assistant: any ProgrammingAssistant = FakeProgrammingAssistant()) throws {
        self.snapshot = snapshot; self.store = store; self.note = note
        self.association = association; self.profile = profile; self.assistant = assistant
        let rich = try RichTextArchive.decode(snapshot.richTextArchive)
        try snapshot.validate()
        guard rich.string == snapshot.text else { throw WorkspaceError.invalidArchive }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1050, height: 680),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        super.init(window: window)
        window.title = "Session scratchpad — offline synthetic test"
        window.isReleasedWhenClosed = false
        window.delegate = self
        snapshotDidRestore()
        configure(rich: rich)
        refreshTranscript()
        updateAvailability()
        saveNow()
    }
    public required init?(coder: NSCoder) { nil }
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
        let description = NSTextField(labelWithString: "Synthetic note · saved locally · fake assistant · no Notes/API access")
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
        compare.frame = NSRect(x: 16, y: 26, width: 195, height: 24)
        compare.toolTip = "Compare with the frozen synthetic source; live Notes monitoring is not connected."
        root.addSubview(compare)
        sendButton.target = self; sendButton.action = #selector(send)
        sendButton.frame = NSRect(x: 947, y: 54, width: 83, height: 26)
        sendButton.autoresizingMask = [.minXMargin]
        root.addSubview(sendButton)
        stopButton.target = self; stopButton.action = #selector(stop)
        stopButton.frame = NSRect(x: 857, y: 54, width: 83, height: 26)
        stopButton.autoresizingMask = [.minXMargin]
        root.addSubview(stopButton)
        status.frame = NSRect(x: 220, y: 27, width: 800, height: 20)
        status.identifier = NSUserInterfaceItemIdentifier("workspace-status")
        status.autoresizingMask = [.width]
        status.textColor = .secondaryLabelColor
        root.addSubview(status)
        window?.minSize = NSSize(width: 1000, height: 650)
    }
    public func show() {
        showWindow(nil); window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(editor)
        NSApp.activate(ignoringOtherApps: true)
    }
    public func textDidChange(_ notification: Notification) {
        let changedEditor = notification.object as AnyObject? === editor
        guard changedEditor || notification.object as AnyObject? === composer else { return }
        snapshot.composerText = composer.string
        if changedEditor { snapshot.text = editor.string; snapshot.revision += 1 }
        if changedEditor, gate.active != nil { status.stringValue = "Scratchpad changed · reply uses an earlier revision" }
        refreshTranscript()
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(500)) } catch { return }
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }
    @discardableResult private func saveNow() -> Bool {
        do {
            snapshot.text = editor.string
            snapshot.richTextArchive = try RichTextArchive.encode(editor.attributedString())
            snapshot.composerText = composer.string
            try store.save(snapshot)
            savedRevision = snapshot.revision
            status.stringValue = gate.active == nil ? "Saved scratchpad r\(snapshot.revision) locally · synthetic Notes unverified" : "Saved locally · reply in progress\(snapshot.revision == gate.active?.revision ? "" : " · Scratchpad changed")"
            return true
        } catch {
            status.stringValue = "Local save failed; last saved revision \(savedRevision.map(String.init) ?? "unknown"). Keep this window open."
            return false
        }
    }
    @objc private func send() { submit() }
    private func submit() {
        guard gate.active == nil else { status.stringValue = "Reply in progress — Stop or wait; follow-up stays here."; return }
        saveTask?.cancel()
        guard saveNow() else { return }
        do {
            let request = try ProgramContextAssembler.assemble(note: note, association: association,
                workspace: snapshot, profile: profile, question: composer.string, maximumContextBytes: 1_000_000)
            try gate.begin(request)
            snapshot.messages.append(ConversationMessage(requestID: request.id, conversationID: request.conversationID,
                role: .coach, text: request.question, status: .complete, scratchpadRevision: request.revision, observationID: request.observationID))
            snapshot.messages.append(ConversationMessage(requestID: request.id, conversationID: request.conversationID,
                role: .assistant, text: "", status: .pending, scratchpadRevision: request.revision, observationID: request.observationID))
            composer.string = ""
            saveNow(); updateAvailability(); refreshTranscript()
            responseTask = Task { [weak self, assistant] in
                do {
                    let response = try await assistant.reply(to: request)
                    guard let self, self.gate.finish(response) != nil else { return }
                    self.updateReply(requestID: request.id, text: response.text, status: .complete)
                } catch {
                    guard let self, self.gate.active?.id == request.id else { return }
                    self.gate.stop()
                    self.updateReply(requestID: request.id, text: "Reply unavailable. No automatic retry.", status: .failed)
                }
            }
        } catch { status.stringValue = "Question not sent: \(error). Your text is still in the composer." }
    }
    private func updateReply(requestID: UUID, text: String, status: MessageStatus) {
        if let index = snapshot.messages.firstIndex(where: { $0.requestID == requestID && $0.role == .assistant }) {
            snapshot.messages[index].text = text; snapshot.messages[index].status = status
        }
        updateAvailability(); refreshTranscript(); saveNow()
    }
    @objc private func stop() {
        guard let request = gate.active else { return }
        gate.stop(); responseTask?.cancel(); responseTask = nil
        updateReply(requestID: request.id, text: "Stopped. No automatic resend.", status: .cancelled)
    }
    private func updateAvailability() {
        sendButton.isEnabled = gate.active == nil
        stopButton.isEnabled = gate.active != nil
    }
    private func refreshTranscript() {
        transcript.string = snapshot.messages.filter { $0.conversationID == snapshot.conversationID }.map { message in
            let freshness = message.role == .assistant && message.scratchpadRevision != snapshot.revision ? " · Scratchpad changed" : ""
            return "\(message.role == .coach ? "You" : "Assistant") · r\(message.scratchpadRevision) · \(message.status.rawValue)\(freshness)\n\(message.text)"
        }.joined(separator: "\n\n")
    }
    @objc public func copyForNotes() {
        saveTask?.cancel(); saveNow()
        do {
            try ScratchpadRichTextExporter.publishMarkdown(editor.attributedString(), to: .general)
            status.stringValue = "Copied—Notes not verified. Synthetic test: use Notes Paste as Markdown."
        } catch { status.stringValue = "Copy failed; no formatted handoff claimed." }
    }
    @objc private func toggleDiff() {
        showingDiff.toggle()
        if showingDiff {
            diff.string = "Frozen synthetic source vs scratchpad r\(snapshot.revision) — NOT live Notes\n"
                + "Text-only comparison; formatting agreement not verified.\n\n"
                + SessionComparison.text(before: snapshot.anchor.baselineText, after: snapshot.text)
            diff.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        }
        editorScroll.isHidden = showingDiff; diffScroll.isHidden = !showingDiff
        if !showingDiff { window?.makeFirstResponder(editor) }
    }
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        stop(); saveTask?.cancel(); return saveNow()
    }
    public func flushAndStop() -> Bool { stop(); saveTask?.cancel(); return saveNow() }
}
