// Synthetic serializer experiment, not a production editor adapter or Notes paste test.
import Foundation

enum BlockKind {
    case title, heading, subheading, paragraph, bullet
}

struct Span {
    let text: String
    let bold: Bool
}

struct Block {
    let kind: BlockKind
    let spans: [Span]
}

enum ExportError: Error { case multilineSpan, emptyBlock }

func escaped(_ text: String) -> String {
    var result = ""
    for character in text {
        if "\\*_\u{60}[]<>".contains(character) { result.append("\\") }
        result.append(character)
    }
    return result
}

func inline(_ spans: [Span]) throws -> String {
    guard !spans.isEmpty, spans.contains(where: { !$0.text.isEmpty }) else { throw ExportError.emptyBlock }
    var result = ""
    for span in spans {
        guard !span.text.contains("\n") && !span.text.contains("\r") else { throw ExportError.multilineSpan }
        let value = escaped(span.text)
        if span.bold {
            let leading = String(value.prefix(while: { $0 == " " }))
            let trailing = String(value.reversed().prefix(while: { $0 == " " }).reversed())
            let middle = String(value.dropFirst(leading.count).dropLast(trailing.count))
            result += middle.isEmpty ? value : leading + "**" + middle + "**" + trailing
        } else {
            result += value
        }
    }
    return result
}

func serialize(_ blocks: [Block]) throws -> String {
    var lines: [String] = []
    for block in blocks {
        var body = try inline(block.spans)
        // A body paragraph beginning with Markdown block syntax must stay literal.
        if case .paragraph = block.kind {
            let trimmed = body.drop(while: { $0 == " " })
            if trimmed.first.map({ "#>+-*".contains($0) }) == true ||
                trimmed.prefix(2).allSatisfy({ $0.isNumber || $0 == "." }) && trimmed.contains(". ") {
                if let first = body.firstIndex(where: { $0 != " " }) { body.insert("\\", at: first) }
            }
        }
        switch block.kind {
        case .title: lines.append("# " + body)
        case .heading: lines.append("## " + body)
        case .subheading: lines.append("### " + body)
        case .paragraph: lines.append(body)
        case .bullet: lines.append("- " + body)
        }
    }
    return lines.joined(separator: "\n\n") + "\n"
}

var assertions = 0
var failures = 0
func check(_ condition: Bool, _ label: String) {
    assertions += 1
    if !condition { failures += 1 }
    print("\(condition ? "PASS" : "FAIL") \(label)")
}

let fixture = [
    Block(kind: .title, spans: [Span(text: "Session A", bold: false)]),
    Block(kind: .heading, spans: [Span(text: "Warmup", bold: false)]),
    Block(kind: .subheading, spans: [Span(text: "Strength", bold: false)]),
    Block(kind: .paragraph, spans: [Span(text: "# Literal heading; [not a link] and *stars*", bold: false)]),
    Block(kind: .bullet, spans: [Span(text: "A1", bold: true), Span(text: " Single-leg RDL", bold: false)])
]
let markdown = try serialize(fixture)
check(markdown.contains("# Session A\n\n## Warmup\n\n### Strength"), "Explicit tiers serialize as Markdown headings")
check(markdown.contains("\\# Literal heading; \\[not a link\\] and \\*stars\\*"), "Literal Markdown punctuation is escaped")
check(markdown.contains("- **A1** Single-leg RDL"), "Bullet and bold label remain separate semantics")
let leadingSpace = try serialize([Block(kind: .bullet, spans: [Span(text: " ", bold: false), Span(text: "A1", bold: true)])])
check(leadingSpace == "-  **A1**\n", "Leading user whitespace is retained pending a native paste check")
check(markdown.hasSuffix("\n"), "Export terminates with one newline")
do {
    _ = try serialize([Block(kind: .paragraph, spans: [Span(text: "line one\nline two", bold: false)])])
    check(false, "Embedded newline must be rejected until paragraph policy is specified")
} catch ExportError.multilineSpan {
    check(true, "Embedded newline is rejected rather than silently reflowed")
}
print("RESULT \(assertions - failures)/\(assertions) synthetic Markdown assertions passed; native Notes fidelity and rich-editor extraction NOT established")
exit(failures == 0 ? 0 : 1)
