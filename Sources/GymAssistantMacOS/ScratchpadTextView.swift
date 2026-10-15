import AppKit

@MainActor final class ScratchpadTextView: NSTextView {
    var returnToBody: (() -> Void)?
    override func insertNewline(_ sender: Any?) {
        let selected = selectedRange()
        guard selected.location != NSNotFound, !string.isEmpty else { super.insertNewline(sender); return }
        let source = string as NSString
        let offset = min(selected.location, source.length - 1)
        let style = textStorage?.attribute(.paragraphStyle, at: offset, effectiveRange: nil) as? NSParagraphStyle
        guard style?.textLists.first?.markerFormat == .disc else { super.insertNewline(sender); return }
        let paragraph = source.paragraphRange(for: NSRange(location: offset, length: 0))
        let content = source.substring(with: paragraph).trimmingCharacters(in: .newlines)
        if content == "\t•\t" && selected.length == 0 {
            returnToBody?()
        } else {
            // NSTextView does not synthesize visible list markers for this
            // manually styled editor. insertText uses its normal edit/undo and
            // delegate path, so inserted markers participate in protection/save.
            insertText("\n\t•\t", replacementRange: selected)
        }
    }
}
