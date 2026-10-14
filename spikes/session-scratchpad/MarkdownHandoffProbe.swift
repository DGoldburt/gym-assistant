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
    var previousWasBullet = false
    for block in blocks {
        let isBullet: Bool
        if case .bullet = block.kind { isBullet = true } else { isBullet = false }
        if !lines.isEmpty && !(previousWasBullet && isBullet) { lines.append("") }
        previousWasBullet = isBullet
        var body = try inline(block.spans)
        // A body paragraph beginning with Markdown block syntax must stay literal.
        if case .paragraph = block.kind {
            let trimmed = body.drop(while: { $0 == " " })
            if !trimmed.hasPrefix("**") && (trimmed.first.map({ "#>+-*".contains($0) }) == true ||
                trimmed.prefix(2).allSatisfy({ $0.isNumber || $0 == "." }) && trimmed.contains(". ")) {
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
    return lines.joined(separator: "\n") + "\n"
}

var assertions = 0
var failures = 0
func check(_ condition: Bool, _ label: String) {
    assertions += 1
    if !condition { failures += 1 }
    print("\(condition ? "PASS" : "FAIL") \(label)")
}

struct NativeEvidence: Decodable {
    let noteID: String
    let html: String
    let text: String
}
if CommandLine.arguments.count == 4 && CommandLine.arguments[1] == "verify-native" {
    let before = try JSONDecoder().decode(NativeEvidence.self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2])))
    let after = try JSONDecoder().decode(NativeEvidence.self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[3])))
    check(before.noteID == "synthetic-fixture" && after.noteID == before.noteID, "Only guarded synthetic snapshots are compared")
    check(after.html.contains("<h2>COPY PROBE SERIAL Session 99</h2>") && after.html.contains("<h3>Warmup</h3>"), "Native Heading and Subheading retained")
    check(after.html.contains("<li><b>A1</b> Single-leg RDL") && after.html.contains("<b>B2</b> Dowel squat"), "Native bold retained in bullet and paragraph")
    check(after.text.contains("# Literal heading; [not a link] and *stars*"), "Literal block marker, brackets and stars survive native paste")
    check(after.text.contains("Client_code; 1. Literal count; C:\\training; <cue>"), "Underscore, backslash and angle-bracket literals survive native paste")
    check(after.html.contains("<li>Balance preparation</li>\n<li><b>A1</b>"), "Consecutive bullets share one native list")
    let prefix = before.html.components(separatedBy: "<div>LEFT RIGHT</div>")
    check(prefix.count == 2 && after.html.hasPrefix(prefix[0]), "Existing content before selected replacement is unchanged")
    check(!after.text.contains("LEFT RIGHT") && after.text.components(separatedBy: "COPY PROBE SERIAL Session 99").count == 2, "Only selected marker replaced, one session fixture inserted")
    print("RESULT \(assertions-failures)/\(assertions) captured-native fixture assertions; keyboard route and arbitrary rich-editor extraction NOT established")
    exit(failures == 0 ? 0 : 1)
}

let fixture = [
    Block(kind: .title, spans: [Span(text: "Session A", bold: false)]),
    Block(kind: .heading, spans: [Span(text: "Warmup", bold: false)]),
    Block(kind: .subheading, spans: [Span(text: "Strength", bold: false)]),
    Block(kind: .paragraph, spans: [Span(text: "# Literal heading; [not a link] and *stars*", bold: false)]),
    Block(kind: .bullet, spans: [Span(text: "A1", bold: true), Span(text: " Single-leg RDL", bold: false)])
]
let markdown = try serialize(fixture)
if CommandLine.arguments.count == 3 && ["emit-native", "emit-native-disc"].contains(CommandLine.arguments[1]) {
    let nativeFixture = [
        Block(kind: .heading, spans: [Span(text: "COPY PROBE SERIAL Session 99", bold: false)]),
        Block(kind: .subheading, spans: [Span(text: "Warmup", bold: false)]),
        Block(kind: .bullet, spans: [Span(text: "Balance preparation", bold: false)]),
        Block(kind: .bullet, spans: [Span(text: "A1", bold: true), Span(text: " Single-leg RDL — 3 × 8/side", bold: false)]),
        Block(kind: .paragraph, spans: [Span(text: "# Literal heading; [not a link] and *stars*", bold: false)]),
        Block(kind: .paragraph, spans: [Span(text: "Client_code; 1. Literal count; C:\\training; <cue>", bold: false)]),
        Block(kind: .paragraph, spans: [Span(text: "B2", bold: true), Span(text: " Dowel squat — light, controlled", bold: false)])
    ]
    let encoded = try serialize(nativeFixture)
    // Separate native marker control; preserve the existing hyphen serializer tests.
    let output = CommandLine.arguments[1] == "emit-native-disc"
        ? encoded.components(separatedBy: "\n").map { $0.hasPrefix("- ") ? "* " + $0.dropFirst(2) : $0 }.joined(separator: "\n")
        : encoded
    try Data(output.utf8).write(to: URL(fileURLWithPath: CommandLine.arguments[2]), options: .atomic)
    print("Emitted marked synthetic Markdown from typed blocks; native fidelity NOT established")
    exit(0)
}
check(markdown.contains("# Session A\n\n## Warmup\n\n### Strength"), "Explicit tiers serialize as Markdown headings")
check(markdown.contains("\\# Literal heading; \\[not a link\\] and \\*stars\\*"), "Literal Markdown punctuation is escaped")
check(markdown.contains("- **A1** Single-leg RDL"), "Bullet and bold label remain separate semantics")
let paragraphBold = try serialize([Block(kind: .paragraph, spans: [Span(text: "B2", bold: true), Span(text: " Dowel squat", bold: false)])])
check(paragraphBold == "**B2** Dowel squat\n", "Paragraph-leading bold marker is not escaped as literal block syntax")
let contiguousBullets = try serialize([Block(kind: .bullet, spans: [Span(text: "one", bold: false)]), Block(kind: .bullet, spans: [Span(text: "two", bold: false)])])
check(contiguousBullets == "- one\n- two\n", "Consecutive bullets remain one contiguous list without added blank paragraphs")
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
