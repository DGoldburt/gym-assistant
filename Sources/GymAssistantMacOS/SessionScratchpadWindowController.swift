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
    private var note: NoteSnapshot
    private var association: SessionAssociation
    private let profile: CoachingProfile
    private let assistant: any ProgrammingAssistant
    private let noteContext: SessionNoteContext?
    private let pasteboard: NSPasteboard
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
    private var boundaryBrowser: SessionBoundaryBrowser?
    private var preferencesWindow: ProgrammingPreferencesWindow?
    private var preparingRequest = false
    private let checkedCopy = CheckedScratchpadCopy()
    private var comparisonTask: Task<Void, Never>?
    private var comparisonGeneration = UUID()

    public init(snapshot: WorkspaceSnapshot, store: WorkspaceSnapshotStore,
                note: NoteSnapshot, association: SessionAssociation, profile: CoachingProfile,
                assistant: any ProgrammingAssistant = FakeProgrammingAssistant(), noteContext: SessionNoteContext? = nil,
                pasteboard: NSPasteboard = .general) throws {
        self.snapshot = snapshot; self.store = store; self.note = note
        self.association = association; self.profile = profile; self.assistant = assistant
        self.noteContext = noteContext
        self.pasteboard = pasteboard
        let rich = try RichTextArchive.decode(snapshot.richTextArchive)
        try snapshot.validate()
        guard rich.string == snapshot.text else { throw WorkspaceError.invalidArchive }
        if let savedRange = snapshot.boundaryProtection?.sourceRange, savedRange != association.range {
            guard savedRange.isParagraphAligned(in: note.text),
                  snapshot.anchor.sourceEvidence?.text == (note.text as NSString).substring(with: savedRange.nsRange) else {
                throw WorkspaceError.staleAssociation
            }
            self.association = SessionAssociation(sessionID: association.sessionID, noteID: association.noteID,
                                                  observationID: note.observationID, range: savedRange)
        }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1050, height: 680),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        super.init(window: window)
        window.title = noteContext == nil ? "Session scratchpad — offline synthetic test" : "Session scratchpad"
        window.isReleasedWhenClosed = false
        window.delegate = self
        snapshotDidRestore()
        configure(rich: rich)
        if snapshot.boundaryProtection == nil {
            self.snapshot.boundaryProtection = BoundaryEditProtection(sourceRange: self.association.range)
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
        if let noteContext { Task { await noteContext.setVisible(true, workspace: snapshot.workspaceID) } }
    }

    private func sourceChanged() {
        guard let noteContext else { return }
        if let document = noteContext.sourceDocument { note = document.snapshot }
        if let fresh = try? noteContext.association(for: snapshot.anchor.sessionID) {
            if fresh.range != association.range {
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
        guard noteContext == nil else {
            status.stringValue = "Live Notes boundary review is not connected yet. Existing scratchpad is preserved."; return
        }
        do {
            let rich = NSAttributedString(string: note.text, attributes: [.font: NSFont.systemFont(ofSize: 15)])
            let document = try ProgramDocumentReader.document(snapshot: note, richText: rich)
            boundaryBrowser = SessionBoundaryBrowser(document: document, richText: rich, selected: association.range,
                owners: [], apply: { [weak self] range in
                    guard let self else { throw WorkspaceError.staleAssociation }
                    try Task.checkCancellation()
                    try self.applyBoundary(range, document: document, source: rich)
                })
            boundaryBrowser?.show()
        } catch { status.stringValue = "Boundary unavailable: \(error)" }
    }

    @objc public func showProgrammingPreferences() {
        if preferencesWindow == nil { preferencesWindow = ProgrammingPreferencesWindow(profile: profile) }
        preferencesWindow?.show()
    }

    func applyBoundary(_ range: SourceRange, document: ProgramDocument, source: NSAttributedString) throws {
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
        editor.undoManager?.registerUndo(withTarget: self) { target in
            target.restoreBoundary(rich: before, association: previousAssociation, anchor: previousAnchor, protection: previousProtection)
        }
        editor.undoManager?.setActionName("Adjust session boundary")
        association = SessionAssociation(sessionID: association.sessionID, noteID: association.noteID,
                                         observationID: association.observationID, range: range)
        snapshot.anchor.sourceEvidence = try document.evidence(in: range)
        snapshot.boundaryProtection = protection
        editor.undoManager?.disableUndoRegistration()
        editor.textStorage?.setAttributedString(rich)
        editor.undoManager?.enableUndoRegistration()
        snapshot.revision += 1
        saveNow(); refreshTranscript()
    }

    private func restoreBoundary(rich: NSAttributedString, association previous: SessionAssociation,
                                 anchor: SessionAnchor, protection: BoundaryEditProtection?) {
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
        association = previous; snapshot.anchor = anchor; snapshot.boundaryProtection = protection
        editor.undoManager?.disableUndoRegistration()
        editor.textStorage?.setAttributedString(rich)
        editor.undoManager?.enableUndoRegistration()
        snapshot.revision += 1; saveNow(); refreshTranscript()
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
                    self.association = try noteContext.association(for: self.snapshot.anchor.sessionID)
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
            let request = try ProgramContextAssembler.assemble(note: note, association: association,
                workspace: snapshot, profile: profile, question: question, maximumContextBytes: 1_000_000)
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
        if preparingRequest {
            responseTask?.cancel(); preparingRequest = false; updateAvailability()
            status.stringValue = "Stopped before sending. Your message stays here."; return
        }
        guard let request = gate.active else { return }
        gate.stop(); responseTask?.cancel(); responseTask = nil
        updateReply(requestID: request.id, text: "Stopped. No automatic resend.", status: .cancelled)
    }
    private func updateAvailability() {
        sendButton.isEnabled = gate.active == nil && !preparingRequest
        stopButton.isEnabled = gate.active != nil || preparingRequest
    }
    private func refreshTranscript() {
        transcript.string = snapshot.messages.filter { $0.conversationID == snapshot.conversationID }.map { message in
            let freshness = message.role == .assistant && message.scratchpadRevision != snapshot.revision ? " · Scratchpad changed" : ""
            return "\(message.role == .coach ? "You" : "Assistant") · r\(message.scratchpadRevision) · \(message.status.rawValue)\(freshness)\n\(message.text)"
        }.joined(separator: "\n\n")
    }
    @objc public func copyForNotes() {
        saveTask?.cancel(); saveNow()
        let rich = NSAttributedString(attributedString: editor.attributedString())
        let copiedRevision = snapshot.revision
        let anchor = snapshot.anchor
        let context = noteContext
        let board = pasteboard
        status.stringValue = "Preparing Markdown copy…"
        checkedCopy.start(prepareAndPublish: {
            try ScratchpadRichTextExporter.publishMarkdown(rich, to: board)
        }, verify: {
            guard let context else { return .unavailable }
            do {
                let document = try await context.refresh(for: .checkedCopy)
                let association = try context.association(for: anchor.sessionID)
                let latest = try document.evidence(in: association.range)
                guard latest.text == anchor.baselineText else { return .conflict }
                // Legacy or manually reassociated evidence is not necessarily
                // the confirmed formatting baseline. Do not claim agreement.
                guard let baseline = anchor.sourceEvidence, baseline.text == anchor.baselineText else { return .unavailable }
                return latest == baseline ? .unchanged : .conflict
            } catch { return .unavailable }
        }, update: { [weak self] state in
            guard let self else { return }
            let suffix = self.snapshot.revision == copiedRevision ? "" : " · Scratchpad changed since copy"
            switch state {
            case .copiedChecking: self.status.stringValue = "Copied—checking Notes…" + suffix
            case .copiedVerified: self.status.stringValue = "Copied—Notes checked. Use Notes Paste as Markdown." + suffix
            case .copiedUnverified: self.status.stringValue = "Copied—Notes not verified. Check Notes before pasting." + suffix
            case .copiedConflict: self.status.stringValue = "Copied—Notes changed in this session. Compare before pasting; clipboard unchanged." + suffix
            case .failed: self.status.stringValue = "Copy failed; no formatted handoff claimed."
            }
        })
    }
    @objc private func toggleDiff() {
        showingDiff.toggle()
        comparisonTask?.cancel()
        comparisonGeneration = UUID()
        if showingDiff {
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
        if noteContext != nil && (try? noteContext?.association(for: snapshot.anchor.sessionID)) == nil
            || association.observationID != note.observationID || !association.range.isParagraphAligned(in: note.text) {
            diff.string = "Notes association is unresolved. Scratchpad is preserved; comparison is unavailable."
            return
        }
        let title = noteContext == nil ? "Frozen synthetic source — NOT live Notes" : "Latest observed Notes"
        diff.string = "\(title) vs scratchpad r\(snapshot.revision)\n"
            + "Text-only comparison; formatting agreement not verified.\n\n"
            + SessionComparison.text(before: (note.text as NSString).substring(with: association.range.nsRange), after: snapshot.text)
    }
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        stop(); saveTask?.cancel(); return saveNow()
    }
    public func windowWillClose(_ notification: Notification) {
        checkedCopy.cancel()
        comparisonTask?.cancel()
        if let noteContext { Task { await noteContext.setVisible(false, workspace: snapshot.workspaceID) } }
    }
    public func flushAndStop() -> Bool { checkedCopy.cancel(); stop(); saveTask?.cancel(); return saveNow() }
}
