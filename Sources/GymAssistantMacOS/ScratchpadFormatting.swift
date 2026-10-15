import AppKit

public enum ScratchpadFormat: Int, CaseIterable {
    case heading, subheading, body, bold, bulletedList
    public var title: String {
        switch self {
        case .heading: "Heading"
        case .subheading: "Subheading"
        case .body: "Body"
        case .bold: "Bold"
        case .bulletedList: "Bulleted list"
        }
    }
    public var key: String {
        switch self {
        case .heading: "2"
        case .subheading: "3"
        case .body: "0"
        case .bold: "b"
        case .bulletedList: "7"
        }
    }
    public var modifiers: NSEvent.ModifierFlags { self == .bold ? [.command] : [.command, .option] }
}

/// Semantic transforms independent of window routing and snapshot persistence.
@MainActor enum ScratchpadFormatting {
    static func paragraphRange(_ selection: NSRange, in text: NSString) -> NSRange {
        text.paragraphRange(for: selection)
    }
    static func apply(_ command: ScratchpadFormat, to rich: NSAttributedString, selection: NSRange) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: rich)
        if command == .bold {
            var allBold = true
            rich.enumerateAttribute(.font, in: selection) { font, _, _ in
                if !NSFontManager.shared.traits(of: font as? NSFont ?? .systemFont(ofSize: 16)).contains(.boldFontMask) { allBold = false }
            }
            rich.enumerateAttribute(.font, in: selection) { font, range, _ in
                let original = font as? NSFont ?? .systemFont(ofSize: 16)
                let converted = allBold ? NSFontManager.shared.convert(original, toNotHaveTrait: .boldFontMask)
                    : NSFontManager.shared.convert(original, toHaveTrait: .boldFontMask)
                result.addAttribute(.font, value: converted, range: range)
            }
            return result
        }
        let text = rich.string as NSString
        let affected = paragraphRange(selection, in: text)
        var ranges: [NSRange] = []
        var offset = affected.location
        while offset < NSMaxRange(affected) {
            let range = text.paragraphRange(for: NSRange(location: offset, length: 0))
            ranges.append(range); offset = NSMaxRange(range)
        }
        for range in ranges.reversed() {
            let paragraph = NSMutableAttributedString(attributedString: rich.attributedSubstring(from: range))
            let old = rich.attribute(.paragraphStyle, at: range.location, effectiveRange: nil) as? NSParagraphStyle
            if !(old?.textLists.isEmpty ?? true), paragraph.string.hasPrefix("\t"),
               let end = paragraph.string.dropFirst().firstIndex(of: "\t") {
                paragraph.deleteCharacters(in: NSRange(location: 0, length: (String(paragraph.string[...end]) as NSString).length))
            }
            let style = (old?.mutableCopy() as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
            style.headerLevel = command == .heading ? 2 : command == .subheading ? 3 : 0
            style.textLists = command == .bulletedList ? [NSTextList(markerFormat: .disc, options: 0)] : []
            style.firstLineHeadIndent = 0; style.headIndent = 0
            if command == .bulletedList { paragraph.insert(NSAttributedString(string: "\t•\t"), at: 0) }
            paragraph.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: paragraph.length))
            if style.headerLevel > 0 || (old?.headerLevel ?? 0) > 0 {
                paragraph.addAttribute(.font, value: style.headerLevel > 0
                    ? NSFont.boldSystemFont(ofSize: style.headerLevel == 2 ? 22 : 18) : NSFont.systemFont(ofSize: 16),
                    range: NSRange(location: 0, length: paragraph.length))
            }
            result.replaceCharacters(in: range, with: paragraph)
        }
        return result
    }
}
