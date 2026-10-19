import AppKit
import GymAssistantWorkspace

/// Read-only Notes selection embedded where the conversation normally appears.
@MainActor final class SessionAssociationPane: NSView, NSTextViewDelegate, NSSearchFieldDelegate {
    private(set) var document: ProgramDocument
    private var owners: [SessionBoundaryBrowser.Owner]
    private let source = NSTextView()
    private let search = NSSearchField()
    private let status = NSTextField(wrappingLabelWithString: "")
    private let confirm = NSButton(title: "Associate selected session", target: nil, action: nil)
    private var task: Task<Void, Never>?
    var selectionChanged: ((SourceRange?) -> Void)?
    var apply: ((SourceRange, ProgramDocument) async throws -> Void)?
    var cancel: (() -> Void)?

    init(frame: NSRect, document: ProgramDocument, rich: NSAttributedString, owners: [SessionBoundaryBrowser.Owner]) {
        self.document = document; self.owners = owners
        super.init(frame: frame)
        autoresizingMask = [.minXMargin, .height]
        let title = NSTextField(labelWithString: "Find this session in Notes")
        title.frame = NSRect(x: 0, y: frame.height - 25, width: frame.width, height: 22)
        title.autoresizingMask = [.width, .minYMargin]; addSubview(title)
        GymAssistantAppearance.sectionLabel(title)
        search.frame = NSRect(x: 0, y: frame.height - 58, width: frame.width, height: 26)
        search.placeholderString = "Find heading"; search.delegate = self
        search.autoresizingMask = [.width, .minYMargin]; addSubview(search)
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 130, width: frame.width, height: frame.height - 198))
        scroll.autoresizingMask = [.width, .height]; scroll.hasVerticalScroller = true
        source.frame = NSRect(origin: .zero, size: scroll.frame.size)
        source.isEditable = false; source.isSelectable = true; source.isRichText = true
        source.isVerticallyResizable = true; source.autoresizingMask = [.width]
        source.textContainer?.widthTracksTextView = true
        source.textStorage?.setAttributedString(rich); source.delegate = self
        source.identifier = .init("association-source")
        source.setAccessibilityLabel("Read-only Notes; select session paragraphs with Shift–Arrow or drag")
        scroll.documentView = source; addSubview(scroll)
        status.frame = NSRect(x: 0, y: 50, width: frame.width, height: 75)
        status.autoresizingMask = [.width]; status.identifier = .init("association-status"); addSubview(status)
        GymAssistantAppearance.supportingText(status)
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelReview))
        cancelButton.frame = NSRect(x: 0, y: 5, width: 80, height: 30)
        cancelButton.keyEquivalent = "\u{1b}"; addSubview(cancelButton)
        confirm.frame = NSRect(x: 100, y: 5, width: frame.width - 100, height: 30)
        confirm.autoresizingMask = [.width]; confirm.target = self; confirm.action = #selector(confirmSelection)
        confirm.keyEquivalent = "\r"; confirm.keyEquivalentModifierMask = [.command]
        confirm.identifier = .init("association-confirm"); addSubview(confirm)
        GymAssistantAppearance.primary(confirm)
        search.nextKeyView = source
        updateSelection()
    }
    required init?(coder: NSCoder) { nil }
    func focus() { window?.makeFirstResponder(search) }
    func suggestHeading(_ heading: String) {
        let matches = document.candidates().filter { $0.label == heading }
        if matches.count == 1, let candidate = matches.first {
            source.setSelectedRange(candidate.range.nsRange)
            source.scrollRangeToVisible(candidate.range.nsRange)
        }
        updateSelection()
    }
    func updateOwners(_ owners: [SessionBoundaryBrowser.Owner]) { self.owners = owners; updateSelection() }
    var selectedRange: SourceRange? {
        let selected = source.selectedRange()
        guard selected.length > 0, selected.location != NSNotFound else { return nil }
        let range = (document.snapshot.text as NSString).paragraphRange(for: selected)
        let value = SourceRange(location: range.location, length: range.length)
        return value.isParagraphAligned(in: document.snapshot.text) ? value : nil
    }
    func refresh(document: ProgramDocument, rich: NSAttributedString, owners: [SessionBoundaryBrowser.Owner]) {
        // Old offsets must not be reused when Notes changes during review.
        task?.cancel(); task = nil
        self.document = document; self.owners = owners
        source.textStorage?.setAttributedString(rich); source.setSelectedRange(NSRange(location: 0, length: 0))
        updateSelection()
        status.stringValue = "Notes changed. Select the session again and review Differences before confirming."
    }
    func controlTextDidChange(_ notification: Notification) {
        let query = search.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, let index = document.paragraphs.firstIndex(where: {
            $0.headingLevel > 0 && $0.label.localizedCaseInsensitiveContains(query)
        }) else { return }
        let start = document.ranges[index]
        let range = document.candidates().first(where: { $0.range.location == start.location })?.range ?? start
        source.setSelectedRange(range.nsRange); source.scrollRangeToVisible(range.nsRange); updateSelection()
    }
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        guard control === search, commandSelector == #selector(NSResponder.insertTab(_:)) else { return false }
        window?.makeFirstResponder(source)
        return true
    }
    func textViewDidChangeSelection(_ notification: Notification) { updateSelection() }
    private func updateSelection() {
        selectionChanged?(selectedRange)
        guard let range = selectedRange else {
            status.stringValue = "Select session paragraphs. Shift–Arrow or drag adjusts the highlighted region."
            confirm.isEnabled = false; return
        }
        if let owner = owners.first(where: { NSIntersectionRange($0.range.nsRange, range.nsRange).length > 0 }) {
            status.stringValue = "Owned by \(owner.label). Select a non-overlapping region."
            confirm.isEnabled = false; return
        }
        status.stringValue = "Associate this Notes section with this scratchpad. Neither version will be replaced. Content differences will remain."
        confirm.isEnabled = task == nil
    }
    @objc private func confirmSelection() {
        guard task == nil, confirm.isEnabled, let range = selectedRange else { return }
        let preview = document
        confirm.isEnabled = false
        task = Task { [weak self] in
            guard let self else { return }
            do { try await self.apply?(range, preview) }
            catch {
                guard !Task.isCancelled else { return }
                self.status.stringValue = "Association unchanged. Review current Notes and ownership, then select again."
            }
            self.task = nil; self.confirm.isEnabled = false
        }
    }
    @objc private func cancelReview() { stop(); cancel?() }
    func stop() { task?.cancel(); task = nil }
}
