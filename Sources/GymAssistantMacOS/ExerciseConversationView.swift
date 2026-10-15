import AppKit
import GymAssistantWorkspace

/// Display-only annotations: no links, exercise actions or changes to copy text.
@MainActor final class ExerciseConversationView: NSTextView {
    struct Decoration { let range: NSRange; let match: ExerciseMentionMatch }
    private(set) var decorations: [Decoration] = []
    private let labelPopover = NSPopover()

    func focusFirstMention() {
        setSelectedRange(decorations.first?.range ?? NSRange(location: 0, length: 0))
        window?.makeFirstResponder(self)
        scrollRangeToVisible(selectedRange())
        showLabelForSelection()
    }

    func display(_ text: NSAttributedString, decorations: [Decoration]) {
        labelPopover.close()
        self.decorations = decorations.filter { $0.match != .unavailable }
        let rich = NSMutableAttributedString(attributedString: text)
        for decoration in self.decorations {
            let style = NSUnderlineStyle.single.rawValue |
                (decoration.match == .notMatched ? NSUnderlineStyle.patternDot.rawValue : 0)
            rich.addAttributes([.underlineStyle: style, .underlineColor: NSColor.tertiaryLabelColor,
                                .toolTip: decoration.match.label], range: decoration.range)
        }
        textStorage?.setAttributedString(rich)
    }

    override func becomeFirstResponder() -> Bool {
        let accepted = super.becomeFirstResponder()
        if accepted { showLabelForSelection() }
        return accepted
    }

    override func resignFirstResponder() -> Bool { labelPopover.close(); return super.resignFirstResponder() }

    override func keyDown(with event: NSEvent) {
        // Tab traverses only exercise mentions; at either end normal focus traversal resumes.
        if event.keyCode == 48, !event.modifierFlags.contains(.command), !event.modifierFlags.contains(.option) {
            let selection = selectedRange()
            let backward = event.modifierFlags.contains(.shift)
            let next = backward ? decorations.last(where: { $0.range.location < selection.location })
                : decorations.first(where: { $0.range.location >= NSMaxRange(selection) && $0.range != selection })
            if let next {
                setSelectedRange(next.range); scrollRangeToVisible(next.range); showLabelForSelection(); return
            }
            labelPopover.close()
            if backward { window?.selectPreviousKeyView(self) } else { window?.selectNextKeyView(self) }
            return
        }
        labelPopover.close()
        super.keyDown(with: event)
    }

    private func showLabelForSelection() {
        guard let decoration = decorations.first(where: {
            NSLocationInRange(selectedRange().location, $0.range)
        }), let layoutManager, let textContainer, window != nil else { return }
        let label = NSTextField(labelWithString: decoration.match.label)
        label.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        label.sizeToFit()
        let controller = NSViewController()
        controller.view = NSView(frame: NSRect(x: 0, y: 0, width: label.frame.width + 16, height: label.frame.height + 12))
        label.frame.origin = NSPoint(x: 8, y: 6); controller.view.addSubview(label)
        labelPopover.contentViewController = controller; labelPopover.behavior = .transient
        let glyphs = layoutManager.glyphRange(forCharacterRange: decoration.range, actualCharacterRange: nil)
        let rect = layoutManager.boundingRect(forGlyphRange: glyphs, in: textContainer)
            .offsetBy(dx: textContainerOrigin.x, dy: textContainerOrigin.y)
        labelPopover.show(relativeTo: rect, of: self, preferredEdge: .maxY)
    }
}
