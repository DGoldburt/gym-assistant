import AppKit
import GymAssistantWorkspace

public enum ProgramDocumentReadError: Error { case unsupportedHTML, inconsistentText }

/// A deliberately bounded semantic importer. It never renders web content or
/// resolves external resources. Unknown formatting is rejected, not discarded.
@MainActor public enum ProgramDocumentReader {
    public static func document(snapshot: NoteSnapshot, richText: NSAttributedString) throws -> ProgramDocument {
        guard richText.string == snapshot.text else { throw ProgramDocumentReadError.inconsistentText }
        let source = richText.string as NSString
        var paragraphs: [ProgramParagraph] = []
        var offset = 0
        while offset < source.length {
            let range = source.paragraphRange(for: NSRange(location: offset, length: 0))
            let style = richText.attribute(.paragraphStyle, at: offset, effectiveRange: nil) as? NSParagraphStyle
            var marks: [ProgramParagraph.Mark] = []
            richText.enumerateAttributes(in: range) { attributes, span, _ in
                let relative = SourceRange(location: span.location - offset, length: span.length)
                if let font = attributes[.font] as? NSFont {
                    let traits = NSFontManager.shared.traits(of: font)
                    if traits.contains(.boldFontMask) { marks.append(.init(range: relative, kind: .bold)) }
                    if traits.contains(.italicFontMask) { marks.append(.init(range: relative, kind: .italic)) }
                }
                if let underline = attributes[.underlineStyle] as? NSNumber, underline.intValue != 0 {
                    marks.append(.init(range: relative, kind: .underline))
                }
                if let link = attributes[.link] { marks.append(.init(range: relative, kind: .link, value: String(describing: link))) }
            }
            paragraphs.append(ProgramParagraph(text: source.substring(with: range), headingLevel: style?.headerLevel ?? 0,
                listStyle: style?.textLists.map { $0.markerFormat.rawValue }.joined(separator: "/"), marks: marks))
            offset = NSMaxRange(range)
        }
        return try ProgramDocument(snapshot: snapshot, paragraphs: paragraphs)
    }

    public static func read(_ raw: NoteSnapshot) throws -> (ProgramDocument, NSAttributedString) {
        let parser = SemanticNotesHTML()
        let rich = try parser.read(raw.html)
        // All ranges/context use this same semantic representation of the HTML,
        // rather than mixing Notes plaintext offsets with formatted-text offsets.
        let canonical = NoteSnapshot(id: raw.id, observationID: raw.observationID,
            text: rich.string, html: raw.html, modifiedAt: raw.modifiedAt)
        return (try document(snapshot: canonical, richText: rich), rich)
    }
}

@MainActor private final class SemanticNotesHTML: NSObject, @preconcurrency XMLParserDelegate {
    private let output = NSMutableAttributedString(string: "")
    private var current = NSMutableAttributedString(string: "")
    private var tags: [String] = []
    private var heading = 0
    private var bullet = false
    private var invalid = false
    private let supported: Set<String> = ["root", "div", "p", "h1", "h2", "h3", "br", "b", "strong", "ul", "li", "span"]

    func read(_ html: String) throws -> NSAttributedString {
        // Notes exports HTML fragments. Normalize only the observed void/entity
        // spellings, not arbitrary malformed markup. DTDs/entities are forbidden.
        guard !html.localizedCaseInsensitiveContains("<!doctype"), !html.contains("<!ENTITY") else {
            throw ProgramDocumentReadError.unsupportedHTML
        }
        let normalized = html.replacingOccurrences(of: "<br>", with: "<br/>")
            .replacingOccurrences(of: "&nbsp;", with: "&#160;")
        let xml = XMLParser(data: Data(("<root>" + normalized + "</root>").utf8))
        xml.shouldResolveExternalEntities = false
        xml.delegate = self
        guard xml.parse(), !invalid else { throw ProgramDocumentReadError.unsupportedHTML }
        flush()
        return output.copy() as! NSAttributedString
    }

    func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String]) {
        guard supported.contains(name), attributes.isEmpty else { invalid = true; parser.abortParsing(); return }
        if name == "ul" && tags.contains("ul") { invalid = true; parser.abortParsing(); return }
        if ["div", "p", "li"].contains(name), current.length > 0 { flush() }
        tags.append(name)
        if name == "li" { bullet = true }
        if ["h1", "h2", "h3"].contains(name) { heading = Int(name.dropFirst())! }
        if name == "br" { flush(force: true) }
    }

    func parser(_ parser: XMLParser, foundCharacters text: String) {
        if current.length == 0 && text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !tags.contains("div") && !tags.contains("p") && !tags.contains("li") { return }
        let bold = tags.contains("b") || tags.contains("strong") || heading > 0
        let font = bold ? NSFont.boldSystemFont(ofSize: heading == 2 ? 22 : 16) : NSFont.systemFont(ofSize: 16)
        current.append(NSAttributedString(string: text, attributes: [.font: font]))
    }

    func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?, qualifiedName: String?) {
        if ["div", "p", "li", "h1", "h2", "h3"].contains(name) { flush() }
        if name == "li" { bullet = false }
        if ["h1", "h2", "h3"].contains(name) { heading = 0 }
        if tags.last == name { tags.removeLast() }
    }

    private func flush(force: Bool = false) {
        guard current.length > 0 || force else { return }
        if !current.string.hasSuffix("\n") { current.append(NSAttributedString(string: "\n")) }
        let style = NSMutableParagraphStyle()
        style.headerLevel = heading
        if bullet {
            style.textLists = [NSTextList(markerFormat: .disc, options: 0)]
            current.insert(NSAttributedString(string: "\t•\t"), at: 0)
        }
        current.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: current.length))
        output.append(current)
        current = NSMutableAttributedString(string: "")
    }
}
