import AppKit
import GymAssistantWorkspace

/// Supported first-slice semantic paragraphs. Unknown list/heading styles fail visibly.
@MainActor public enum ScratchpadRichTextExporter {
    private enum RowKind { case body, heading, list, blank }
    private static func escaped(_ value: String) -> String {
        value.reduce(into: "") { output, char in
            if "\\*_`[]<>#".contains(char) { output.append("\\") }
            output.append(char)
        }
    }
    public static func markdown(_ rich: NSAttributedString) throws -> String {
        let source = rich.string as NSString
        var rows: [(text: String, kind: RowKind)] = []
        var offset = 0
        while offset < source.length {
            let range = source.paragraphRange(for: NSRange(location: offset, length: 0))
            let raw = source.substring(with: range).trimmingCharacters(in: .newlines)
            let style = rich.attribute(.paragraphStyle, at: range.location, effectiveRange: nil) as? NSParagraphStyle
            let level = style?.headerLevel ?? 0
            guard (0...3).contains(level), (style?.textLists.count ?? 0) <= 1 else { throw WorkspaceError.invalidArchive }
            let list = style?.textLists.first
            if let list, ![NSTextList.MarkerFormat.disc, .hyphen].contains(list.markerFormat) {
                throw WorkspaceError.invalidArchive
            }
            var start = range.location
            var length = (raw as NSString).length
            if list != nil, raw.hasPrefix("\t"), let end = raw.dropFirst().firstIndex(of: "\t") {
                let prefix = String(raw[...end])
                start += (prefix as NSString).length; length -= (prefix as NSString).length
            }
            let bodyRange = NSRange(location: start, length: max(0, length))
            var body = ""
            var hasUnsupportedContent = false
            rich.enumerateAttributes(in: bodyRange) { attrs, span, _ in
                if attrs[.attachment] != nil || attrs[.link] != nil { hasUnsupportedContent = true }
                let value = source.substring(with: span)
                let bold = (attrs[.font] as? NSFont).map { NSFontManager.shared.traits(of: $0).contains(.boldFontMask) } ?? false
                if (attrs[.font] as? NSFont).map({ NSFontManager.shared.traits(of: $0).contains(.italicFontMask) }) == true
                    || attrs[.underlineStyle] != nil || attrs[.strikethroughStyle] != nil {
                    hasUnsupportedContent = true
                }
                let escapedValue = escaped(value)
                if bold, !value.trimmingCharacters(in: .whitespaces).isEmpty {
                    let leading = String(escapedValue.prefix(while: { $0.isWhitespace }))
                    let trailing = String(escapedValue.reversed().prefix(while: { $0.isWhitespace }).reversed())
                    let middle = escapedValue.dropFirst(leading.count).dropLast(trailing.count)
                    body += leading + "**" + middle + "**" + trailing
                } else { body += escapedValue }
            }
            guard !hasUnsupportedContent else { throw WorkspaceError.invalidArchive }
            let prefix: String
            if level > 0 { prefix = String(repeating: "#", count: level) + " " }
            else if let list { prefix = list.markerFormat == .disc ? "* " : "- " }
            else { prefix = "" }
            // Escape body-only block syntax, not generated bold or list markup.
            if prefix.isEmpty, !body.hasPrefix("**"), let first = body.first, ">+-".contains(first) {
                body = "\\" + body
            }
            if prefix.isEmpty {
                let marker = try NSRegularExpression(pattern: #"^[0-9]+([.)])\s"#)
                if let match = marker.firstMatch(in: body, range: NSRange(location: 0, length: (body as NSString).length)),
                   let range = Range(match.range(at: 1), in: body) { body.insert("\\", at: range.lowerBound) }
            }
            let kind: RowKind = level > 0 ? .heading : list != nil ? .list : body.isEmpty ? .blank : .body
            rows.append((prefix + body, kind))
            offset = NSMaxRange(range)
        }
        var output = ""
        for index in rows.indices {
            if index > 0 {
                switch (rows[index - 1].kind, rows[index].kind) {
                case (.body, .body):
                    // Native Notes imports Markdown hard breaks as distinct
                    // paragraphs without soft-break trailing spaces.
                    output += "  \n"
                case (.list, .body), (.list, .heading):
                    // Without a separator, Notes can swallow body text into the
                    // preceding list. This visible spacing limitation remains
                    // an acceptance decision, not an exact-fidelity claim.
                    output += "\n\n"
                default:
                    output += "\n"
                }
            }
            output += rows[index].text
        }
        return output + "\n"
    }
    public static func publishMarkdown(_ rich: NSAttributedString, to board: NSPasteboard) throws {
        let text = try markdown(rich)
        let item = NSPasteboardItem()
        guard item.setString(text, forType: .string) else { throw WorkspaceError.invalidArchive }
        board.clearContents()
        guard board.writeObjects([item]) else { throw SnapshotStoreError.unavailable }
    }
}
