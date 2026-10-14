// Structured synthetic boundary experiment. No production parser or Notes access.
import Foundation

struct Paragraph: Equatable { let text: String; let heading: Int? }
struct Candidate { let start: Int; let end: Int; let needsClassification: Bool }
final class FixtureHTMLReader: NSObject, XMLParserDelegate {
    var paragraphs: [Paragraph] = []
    var depth = 0
    var blockDepth: Int?
    var text = ""
    var heading: Int?
    func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String]) {
        depth += 1
        if blockDepth == nil && ["div", "li", "p", "h1", "h2", "h3", "h4"].contains(name) {
            blockDepth = depth; text = ""; heading = nil
        }
        if name.hasPrefix("h"), let level = Int(name.dropFirst()), (1...6).contains(level) { heading = level }
        if name == "br" { text += "\n" }
    }
    func parser(_ parser: XMLParser, foundCharacters string: String) { if blockDepth != nil { text += string } }
    func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?, qualifiedName: String?) {
        if blockDepth == depth {
            paragraphs.append(Paragraph(text: text, heading: heading)); blockDepth = nil
        }
        depth -= 1
    }
}
func parseFixture(_ html: String) -> [Paragraph]? {
    let reader = FixtureHTMLReader()
    let parser = XMLParser(data: Data(("<root>" + html + "</root>").utf8))
    parser.shouldResolveExternalEntities = false
    parser.delegate = reader
    return parser.parse() ? reader.paragraphs : nil
}
func classifySession(_ text: String) -> Bool {
    text.range(of: #"^Session\s+([0-9]+|[A-Za-z]+[0-9]*)(?:\s*[:–—-].*)?$"#,
               options: [.regularExpression, .caseInsensitive]) != nil
}
func detect(_ paragraphs: [Paragraph]) -> [Candidate] {
    let sessionLevel = paragraphs.filter { classifySession($0.text) }.compactMap(\.heading).min()
    var boundaries: [(Int, Bool)] = []
    for (index, paragraph) in paragraphs.enumerated() {
        if index == 0 && paragraph.heading == 1 && !classifySession(paragraph.text) { continue } // Fixture note title.
        let label = paragraph.text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if label == "parking lot" { continue } // Explicit attached context exception.
        if label == "warmup" || label.range(of: #"^week\s+[0-9]+$"#, options: .regularExpression) != nil { continue }
        if classifySession(paragraph.text) {
            if let level = paragraph.heading, let peer = sessionLevel, level > peer { continue }
            boundaries.append((index, false))
        } else if let level = paragraph.heading, level <= (sessionLevel ?? 2) {
            // Strong boundary without known classification: never swallow into previous session.
            // This deliberately does not add typo spellings to the Session regex.
            boundaries.append((index, true))
        }
    }
    return boundaries.enumerated().map { index, pair in
        Candidate(start: pair.0, end: index + 1 < boundaries.count ? boundaries[index + 1].0 : paragraphs.count,
                  needsClassification: pair.1)
    }
}
func skeleton(_ paragraphs: [Paragraph], candidate: Candidate) -> [String] {
    var attached = false
    return paragraphs[candidate.start..<candidate.end].compactMap { paragraph in
        if paragraph.text.lowercased() == "parking lot" { attached = true }
        guard !attached, paragraph.heading != nil else { return nil }
        return paragraph.text
    }
}
var count = 0
var failures = 0
func check(_ condition: @autoclosure () -> Bool, _ label: String) {
    count += 1; let passed = condition(); failures += passed ? 0 : 1
    print("\(passed ? "PASS" : "FAIL") \(label)")
}
let html = """
<div><b><h1>Synthetic program note</h1></b></div>
<div><b><h2>Session 12</h2></b></div><div><b><h3>Warmup</h3></b></div><ul><li>Balance work</li></ul>
<div><b><h2>Sesion 13</h2></b></div><div><b><h3>Warmup</h3></b></div><div>A1 Row</div>
<div><b><h2>Session A</h2></b></div><div><h3>Week 1</h3></div><div>A1 Squat</div>
<div><h3>Week 2</h3></div><div>A1 Squat progression</div><div><h3>Week 3</h3></div><div>A1 Squat progression</div>
<div><h2>Parking Lot</h2></div><div>Try a carry next week</div>
"""
if let paragraphs = parseFixture(html) {
    let candidates = detect(paragraphs)
    check(paragraphs[1].heading == 2 && paragraphs[2].heading == 3, "Native-style HTML retains higher session/lower warmup hierarchy")
    check(candidates.count == 3, "Hierarchy identifies three session-like regions, not title/warmups/weeks")
    check(paragraphs[candidates[1].start].text == "Sesion 13", "Misspelled high-confidence boundary is not swallowed")
    check(candidates[1].needsClassification, "Unknown heading classification needs confirmation, not inferred identity")
    check(candidates[0].end == candidates[1].start, "Previous session stops at misspelled peer boundary")
    let final = candidates[2]
    let texts = paragraphs[final.start..<final.end].map(\.text)
    check(texts.contains("Week 1") && texts.contains("Week 2") && texts.contains("Week 3"), "All lettered-session progressions remain together")
    check(texts.contains("Parking Lot") && texts.contains("Try a carry next week"), "Trailing peer-level Parking Lot belongs to final scratchpad")
    check(!skeleton(paragraphs, candidate: final).contains("Parking Lot") && !skeleton(paragraphs, candidate: final).contains("Try a carry next week"), "Parking Lot never seeds new-session skeleton")
    check(skeleton(paragraphs, candidate: final) == ["Session A", "Week 1", "Week 2", "Week 3"], "Skeleton includes structural headings only")
    var typo = paragraphs
    typo[4] = Paragraph(text: "Seison thirteen", heading: 2)
    check(detect(typo).count == 3 && detect(typo)[1].needsClassification, "Arbitrary misspelling handled by hierarchy, not a spelling list")
    var unrelated = paragraphs
    unrelated[4] = Paragraph(text: "Injury discussion", heading: 2)
    check(detect(unrelated)[1].needsClassification, "Peer heading is a boundary candidate, not automatically a training session")
    var higherParking = paragraphs
    higherParking[14] = Paragraph(text: "Parking Lot", heading: 1)
    check(detect(higherParking).count == 3 && detect(higherParking).last?.end == paragraphs.count, "Parking Lot exception survives a higher heading level")
    check(parseFixture("<div><h2>Unclosed") == nil, "Malformed fixture is rejected, not silently normalized")
} else { check(false, "Read synthetic native-style HTML") }
if CommandLine.arguments.count == 3 && CommandLine.arguments[1] == "native" {
    struct Evidence: Decodable { let noteID: String; let html: String; let text: String }
    do {
        let path = CommandLine.arguments[2]
        guard path.hasPrefix("/private/tmp/gym-assistant-scratchpad-checkpoint/native-") else { throw NSError(domain: "Fixture", code: 1) }
        let evidence = try JSONDecoder().decode(Evidence.self, from: Data(contentsOf: URL(fileURLWithPath: path)))
        guard evidence.noteID == "synthetic-fixture", evidence.text.contains("END OF SYNTHETIC NOTE 2026-10-12"),
              let blocks = parseFixture(evidence.html.replacingOccurrences(of: "<br>", with: "<br/>")) else { throw NSError(domain: "Fixture", code: 2) }
        let native = detect(blocks)
        check(native.count == 2, "Native captured hierarchy exposes two regions, not warmups or Parking Lot")
        check(blocks[native[0].start].text == "Session 12" && blocks[native[1].start].text == "Sesion 13", "Native typo remains an independent boundary candidate")
        check(native[1].needsClassification, "Native typo classification is unconfirmed, not silent identity")
        check(blocks.filter { $0.text == "Warmup" }.allSatisfy { $0.heading == 3 }, "Native lower-level warmups read as h3")
        let final = native[1]
        check(blocks[final.start..<final.end].contains { $0.text == "Parking Lot" }, "Actual peer-level Parking Lot retained with final region")
        check(!skeleton(blocks, candidate: final).contains("Parking Lot"), "Actual Parking Lot excluded from structural skeleton")
    } catch { check(false, "Read guarded native hierarchy fixture: \(error)") }
} else if CommandLine.arguments.count != 1 { check(false, "Usage: hierarchy-probe [native native-fixture.json]") }
print("RESULT \(count - failures)/\(count) hierarchy assertions passed; fixture parser, not arbitrary Notes parser or classification UI")
exit(failures == 0 ? 0 : 1)
