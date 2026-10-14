import AppKit
import GymAssistantWorkspace

@MainActor public final class SessionBoundaryBrowser: NSWindowController, NSTextViewDelegate, NSWindowDelegate {
    public struct Owner {
        public let label: String
        public let range: SourceRange
        public init(label: String, range: SourceRange) { self.label = label; self.range = range }
    }
    private let sourceDocument: ProgramDocument
    private let owners: [Owner]
    private let applyRange: @MainActor (SourceRange) async throws -> Void
    private let text = NSTextView()
    private let status = NSTextField(wrappingLabelWithString: "")
    private let applyButton = NSButton(title: "Use highlighted paragraphs", target: nil, action: nil)
    private var task: Task<Void, Never>?

    public init(document: ProgramDocument, richText: NSAttributedString, selected: SourceRange,
                owners: [Owner], apply: @escaping @MainActor (SourceRange) async throws -> Void) {
        self.sourceDocument = document; self.owners = owners; self.applyRange = apply
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 700, height: 650),
                              styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        super.init(window: window)
        window.title = "Session boundary — read-only Notes"
        window.isReleasedWhenClosed = false
        window.delegate = self
        let help = NSTextField(wrappingLabelWithString: "Highlight the paragraphs for this session. Drag in the note or use Shift–Arrow keys to move the selection. Escape cancels; Command–Return uses the highlighted paragraphs. Existing scratchpad edits stay protected.")
        help.frame = NSRect(x: 18, y: 570, width: 664, height: 64)
        help.autoresizingMask = [.width, .minYMargin]
        window.contentView?.addSubview(help)
        let scroll = NSScrollView(frame: NSRect(x: 18, y: 104, width: 664, height: 454))
        scroll.autoresizingMask = [.width, .height]; scroll.hasVerticalScroller = true
        text.frame = NSRect(origin: .zero, size: scroll.frame.size)
        text.isEditable = false; text.isSelectable = true; text.isRichText = true
        text.isVerticallyResizable = true; text.isHorizontallyResizable = false
        text.autoresizingMask = [.width]; text.textContainer?.widthTracksTextView = true
        text.textStorage?.setAttributedString(richText)
        text.setAccessibilityLabel("Read-only note — highlighted session boundary")
        text.setSelectedRange(selected.nsRange); text.delegate = self
        scroll.documentView = text; window.contentView?.addSubview(scroll)
        status.frame = NSRect(x: 18, y: 46, width: 420, height: 50)
        status.autoresizingMask = [.width]
        window.contentView?.addSubview(status)
        applyButton.frame = NSRect(x: 443, y: 18, width: 240, height: 28)
        applyButton.autoresizingMask = [.minXMargin]
        applyButton.target = self; applyButton.action = #selector(applySelection)
        applyButton.keyEquivalent = "\r"; applyButton.keyEquivalentModifierMask = [.command]
        window.contentView?.addSubview(applyButton)
        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancelSelection))
        cancel.frame = NSRect(x: 18, y: 12, width: 90, height: 28)
        cancel.keyEquivalent = "\u{1b}"
        window.contentView?.addSubview(cancel)
        window.minSize = NSSize(width: 620, height: 450)
        updateSelection()
    }
    public required init?(coder: NSCoder) { nil }
    public func show() {
        showWindow(nil); window?.makeKeyAndOrderFront(nil); window?.makeFirstResponder(text)
        text.scrollRangeToVisible(text.selectedRange())
    }
    public func textViewDidChangeSelection(_ notification: Notification) { updateSelection() }
    private func selection() -> SourceRange? {
        let value = text.selectedRange()
        guard value.length > 0, value.location != NSNotFound else { return nil }
        let range = (sourceDocument.snapshot.text as NSString).paragraphRange(for: value)
        let candidate = SourceRange(location: range.location, length: range.length)
        return candidate.isParagraphAligned(in: sourceDocument.snapshot.text) ? candidate : nil
    }
    private func updateSelection() {
        guard let range = selection() else { status.stringValue = "Highlight at least one paragraph."; applyButton.isEnabled = false; return }
        if let owner = owners.first(where: { NSIntersectionRange($0.range.nsRange, range.nsRange).length > 0 }) {
            status.stringValue = "Overlaps the scratchpad for \(owner.label). Choose a non-overlapping boundary."
            applyButton.isEnabled = false; return
        }
        let neighbors = owners.filter { NSMaxRange($0.range.nsRange) == range.location || NSMaxRange(range.nsRange) == $0.range.location }
        let evidence = try? sourceDocument.evidence(in: range)
        let start = evidence?.paragraphs.first?.label ?? ""
        let end = evidence?.paragraphs.last?.label ?? ""
        status.stringValue = "From \(start.prefix(45)) through \(end.prefix(45))"
            + (neighbors.isEmpty ? "" : " · Adjacent: " + neighbors.map(\.label).joined(separator: ", "))
        applyButton.isEnabled = task == nil
    }
    @objc private func applySelection() {
        guard task == nil, applyButton.isEnabled, let range = selection() else { return }
        applyButton.isEnabled = false
        status.stringValue = "Checking the selected boundary…"
        task = Task { [weak self] in
            guard let self else { return }
            do {
                try await self.applyRange(range)
                self.close()
            } catch {
                switch error {
                case BoundaryChangeError.editedRegion:
                    self.status.stringValue = "Boundary unchanged. This would remove edited, added, or deleted scratchpad content."
                case BoundaryChangeError.uncertainCorrespondence:
                    self.status.stringValue = "Boundary unchanged. Earlier edits cannot be mapped reliably to Notes, so shrinking is blocked. Expansion is still available."
                case SessionAssociationError.occupied:
                    self.status.stringValue = "Boundary unchanged. Another session scratchpad owns part of this region."
                case WorkspaceError.staleAssociation, SessionAssociationError.stale, BoundaryChangeError.staleSource:
                    self.status.stringValue = "Notes changed. Reopen the boundary browser to use the current note."
                default:
                    self.status.stringValue = "Boundary unchanged. The selected paragraphs could not be safely applied."
                }
                self.applyButton.isEnabled = true
            }
            self.task = nil
        }
    }
    @objc private func cancelSelection() { task?.cancel(); task = nil; close() }
    public func windowWillClose(_ notification: Notification) { task?.cancel() }
}
