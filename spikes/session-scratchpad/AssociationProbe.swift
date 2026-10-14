// Synthetic model experiment only. No Notes, clipboard, app, or production code.
import Foundation
import CryptoKit

struct NoteObservation {
    let noteID: String
    let text: String
    var digest: String {
        SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
struct NativeFixtureEvidence: Decodable {
    let noteID: String
    let text: String
    let html: String
}
struct Section: Equatable {
    let label: String
    let range: NSRange
    let body: String
}
struct Anchor: Codable, Equatable {
    let sessionID: String
    let label: String
    let baselineBody: String
    let scratchpad: String
    let closed: Bool
}
// Fixture-only durable envelope, not the production persistence format.
struct SavedWorkspace: Codable, Equatable {
    let anchor: Anchor
    let revision: Int
    let conversation: [String]
}
struct SavedFixture: Codable, Equatable {
    let noteID: String
    let workspaces: [SavedWorkspace]
}
struct Resolution {
    var mappings: [String: Section] = [:]
    var unresolved: Set<String> = []
    var duplicates: Set<String> = []
}
struct Confirmation {
    let sessionID: String
    let noteID: String
    let observationDigest: String
    let range: NSRange
}
struct Registry: Equatable {
    let noteID: String
    let observationDigest: String
    var mappings: [String: NSRange]
}
enum ConfirmationError: Error { case stale, unknownSession, invalidRange, occupied }

let labelPattern = try! NSRegularExpression(
    pattern: #"^[\t ]*Session[\t ]+([0-9]+|[A-Za-z]+[0-9]*)(?:[\t ]*[:–—-][\t ]*[^\r\n]*)?[\t ]*$"#,
    options: [.caseInsensitive])

func paragraphs(_ text: String) -> [NSRange] {
    let source = text as NSString
    var ranges: [NSRange] = []
    var offset = 0
    while offset < source.length {
        let range = source.paragraphRange(for: NSRange(location: offset, length: 0))
        ranges.append(range)
        offset = NSMaxRange(range)
    }
    return ranges
}

func sections(_ observation: NoteObservation) -> [Section] {
    let source = observation.text as NSString
    let headings: [(NSRange, String)] = paragraphs(observation.text).compactMap { range in
        let line = source.substring(with: range).trimmingCharacters(in: .newlines)
        let nsLine = line as NSString
        guard let match = labelPattern.firstMatch(in: line, range: NSRange(location: 0, length: nsLine.length)) else { return nil }
        return (range, nsLine.substring(with: match.range(at: 1)).uppercased())
    }
    return headings.enumerated().map { index, heading in
        let end = index + 1 < headings.count ? headings[index + 1].0.location : source.length
        let bodyStart = NSMaxRange(heading.0)
        return Section(label: heading.1,
                       range: NSRange(location: heading.0.location, length: end - heading.0.location),
                       body: source.substring(with: NSRange(location: bodyStart, length: end - bodyStart)))
    }
}

func resolve(_ anchors: [Anchor], in observation: NoteObservation) -> Resolution {
    let candidates = sections(observation)
    let groups = Dictionary(grouping: candidates, by: \.label)
    let duplicates = Set(groups.filter { $0.value.count > 1 }.keys)
    var result = Resolution(duplicates: duplicates)
    // Duplicate labels are surfaced for correction, never hidden by body matching.
    guard duplicates.isEmpty else {
        result.unresolved = Set(anchors.map(\.sessionID))
        return result
    }
    // Ignore only the outer label. Compare complete actual body, not fuzzy hashes.
    for anchor in anchors {
        let matches = candidates.filter { $0.body == anchor.baselineBody }
        let owners = anchors.filter { $0.baselineBody == anchor.baselineBody }
        if !anchor.baselineBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           matches.count == 1, owners.count == 1 {
            result.mappings[anchor.sessionID] = matches[0]
        } else {
            result.unresolved.insert(anchor.sessionID)
        }
    }
    return result
}

func confirm(_ payload: Confirmation, anchors: [Anchor], observation: NoteObservation,
             registry: inout Registry) throws {
    guard payload.noteID == observation.noteID, payload.observationDigest == observation.digest else { throw ConfirmationError.stale }
    guard registry.noteID == observation.noteID, registry.observationDigest == observation.digest else { throw ConfirmationError.stale }
    guard anchors.contains(where: { $0.sessionID == payload.sessionID }) else { throw ConfirmationError.unknownSession }
    let boundaries = Set(paragraphs(observation.text).map(\.location) + [(observation.text as NSString).length])
    guard payload.range.length > 0, boundaries.contains(payload.range.location), boundaries.contains(NSMaxRange(payload.range)) else { throw ConfirmationError.invalidRange }
    // Reject overlapping manual ranges, not just equal candidate starts.
    guard !registry.mappings.contains(where: { $0.key != payload.sessionID && NSIntersectionRange($0.value, payload.range).length > 0 }) else { throw ConfirmationError.occupied }
    registry.mappings[payload.sessionID] = payload.range
    // No scratchpad or baseline write is available in this operation.
}

var count = 0
var failures = 0
func check(_ condition: @autoclosure () -> Bool, _ name: String) {
    count += 1
    let passed = condition()
    if !passed { failures += 1 }
    print("\(passed ? "PASS" : "FAIL") \(name)")
}
func rejects(_ name: String, _ operation: () throws -> Void) {
    do { try operation(); check(false, name) } catch { check(true, name) }
}
func observe(_ text: String) -> NoteObservation { NoteObservation(noteID: "synthetic-note", text: text) }
func anchor(_ id: String, _ section: Section, closed: Bool = false) -> Anchor {
    Anchor(sessionID: id, label: section.label, baselineBody: section.body,
           scratchpad: "Coach scratchpad \(id) with unsaved choices", closed: closed)
}

let weekly = observe("Synthetic title\nSession A\nWeek 1\nA1 Dowel squat\nWeek 2\nA1 Dowel squat progression\nWeek 3\nA1 Dowel squat progression\nSession B: next block\nWeek 1\nA1 Row\n")
let weeklySections = sections(weekly)
check(weeklySections.count == 2, "Weeks 1–3 remain inside two lettered sessions")
check(weeklySections[0].body.contains("Week 3") && !weeklySections[0].body.contains("A1 Row"), "Whole lettered progression, no next-session leakage")
check((weekly.text as NSString).substring(with: weeklySections[0].range) == "Session A\nWeek 1\nA1 Dowel squat\nWeek 2\nA1 Dowel squat progression\nWeek 3\nA1 Dowel squat progression\n", "Exact session start-inclusive/end-exclusive range")
check(weeklySections[1].label == "B", "Descriptive suffix excluded from label")
check(sections(observe("session E10 — progression\nWeek 1\nA1 Row\n")).first?.label == "E10", "Case-insensitive alphanumeric session label")
check(sections(observe("I discussed Session 13 with the coach\nA1 Row\n")).isEmpty, "Incidental session mention is not a boundary")
check(sections(observe("Session A is helpful\nA1 Row\n")).isEmpty, "Unmarked prose suffix is not a boundary")

let original = observe("Session 12\nA1 Squat 🏋️\nSession 13\nA1 Press\nSession 14\nA1 Row\n")
let oldSections = sections(original)
let anchors = oldSections.enumerated().map { anchor("workspace-\($0.offset)", $0.element, closed: $0.offset == 1) }
let scratchpadsBefore = anchors.map(\.scratchpad)
let renumbered = observe("Session 13\nA1 Squat 🏋️\nSession 14\nA1 Press\nSession 15\nA1 Row\n")
let moved = resolve(anchors, in: renumbered)
check(moved.mappings.count == 3 && moved.unresolved.isEmpty, "Bulk renumbering preserves all three local IDs")
check(moved.mappings["workspace-1"]?.label == "14", "Closed workspace follows its body, not colliding label 13")
check(anchors.map(\.scratchpad) == scratchpadsBefore, "Reassociation cannot rewrite scratchpads")
check((renumbered.text as NSString).substring(with: moved.mappings["workspace-1"]!.range) == "Session 14\nA1 Press\n", "UTF-16 range remains correct after emoji")
let reordered = observe("Session 15\nA1 Row\nSession 13\nA1 Squat 🏋️\nSession 14\nA1 Press\n")
check(resolve(anchors, in: reordered).mappings["workspace-2"]?.range.location == 0, "Moved section follows distinctive content, not ordinal")
let inserted = observe("Session 1\nA1 Carry\n" + renumbered.text)
check(resolve(anchors, in: inserted).mappings.count == 3, "Earlier insertion does not create replacement workspaces")
let duplicate = observe("Session 13\nA1 Squat 🏋️\nSession 13\nA1 Press\nSession 14\nA1 Row\n")
let duplicateResult = resolve(anchors, in: duplicate)
check(duplicateResult.duplicates == ["13"] && duplicateResult.mappings.isEmpty, "Temporary duplicates exposed; no silent numbering fix")
check(resolve(anchors, in: renumbered).mappings.count == 3, "Correction reuses existing identities")
let identical = observe("Session 1\nA1 Row\nSession 2\nA1 Row\n")
let twins = sections(identical).enumerated().map { anchor("twin-\($0.offset)", $0.element) }
check(resolve(twins, in: identical).mappings.isEmpty, "Identical bodies require confirmation despite unique labels")
let empty = observe("Session 1\nSession 2\n")
let blanks = sections(empty).enumerated().map { anchor("empty-\($0.offset)", $0.element) }
check(resolve(blanks, in: empty).unresolved.count == 2, "Empty sessions do not infer identity from order")
let changed = observe(renumbered.text.replacingOccurrences(of: "A1 Press", with: "A1 Push-up"))
check(resolve(anchors, in: changed).unresolved == ["workspace-1"], "Concurrent changed body pauses only unresolved workspace")
check(resolve(anchors, in: observe("Session 15\nA1 Row\n")).unresolved.count == 2, "Deleted sessions preserve unresolved identities")

// Rebase verified mappings together on the new observation. Unresolved anchors
// retain their old evidence separately; their obsolete offsets reserve no target.
var registry = Registry(noteID: changed.noteID, observationDigest: changed.digest,
                        mappings: resolve(anchors, in: changed).mappings.mapValues(\.range))
let changedSection = sections(changed)[1]
let payload = Confirmation(sessionID: "workspace-1", noteID: changed.noteID, observationDigest: changed.digest, range: changedSection.range)
do {
    try confirm(payload, anchors: anchors, observation: changed, registry: &registry)
    check(registry.mappings["workspace-1"] == changedSection.range, "Explicit confirmation binds existing identity to selected range")
} catch { check(false, "Explicit confirmation binds existing identity to selected range") }
check(anchors[1].baselineBody == "A1 Press\n" && anchors.map(\.scratchpad) == scratchpadsBefore, "Identity confirmation does not accept external content or overwrite scratchpad")
let registryBefore = registry
var staleRegistry = Registry(noteID: renumbered.noteID, observationDigest: renumbered.digest, mappings: moved.mappings.mapValues(\.range))
rejects("Valid confirmation cannot collide with old-snapshot registry offsets") { try confirm(payload, anchors: anchors, observation: changed, registry: &staleRegistry) }
rejects("Stale observation confirmation rejected") { try confirm(payload, anchors: anchors, observation: inserted, registry: &registry) }
let otherNote = NoteObservation(noteID: "other-synthetic-note", text: changed.text)
rejects("Other-note confirmation rejected even with identical content") { try confirm(payload, anchors: anchors, observation: otherNote, registry: &registry) }
let collision = Confirmation(sessionID: "workspace-0", noteID: changed.noteID, observationDigest: changed.digest, range: changedSection.range)
rejects("Occupied target cannot steal another workspace") { try confirm(collision, anchors: anchors, observation: changed, registry: &registry) }
check(registry == registryBefore, "Failed confirmations leave registry intact")
let unsupported = observe("Workout Monday\nA1 Squat\nB1 Row\n")
check(sections(unsupported).isEmpty, "Unsupported label requires manual preview, not guessed session")
let manualRange = NSRange(location: 0, length: (unsupported.text as NSString).length)
let manual = Confirmation(sessionID: "workspace-0", noteID: unsupported.noteID, observationDigest: unsupported.digest, range: manualRange)
var manualRegistry = Registry(noteID: unsupported.noteID, observationDigest: unsupported.digest, mappings: [:])
do {
    try confirm(manual, anchors: anchors, observation: unsupported, registry: &manualRegistry)
    check(manualRegistry.mappings["workspace-0"] == manualRange, "Paragraph-aligned manual range supported")
} catch { check(false, "Paragraph-aligned manual range supported") }
let overlap = Confirmation(sessionID: "workspace-1", noteID: unsupported.noteID, observationDigest: unsupported.digest, range: paragraphs(unsupported.text)[1])
rejects("Overlapping manual range rejected") { try confirm(overlap, anchors: anchors, observation: unsupported, registry: &manualRegistry) }
let partial = Confirmation(sessionID: "workspace-1", noteID: unsupported.noteID, observationDigest: unsupported.digest, range: NSRange(location: 2, length: 4))
rejects("Partial-paragraph range rejected") { try confirm(partial, anchors: anchors, observation: unsupported, registry: &manualRegistry) }
if CommandLine.arguments.count == 5 && ["lifecycle-write", "lifecycle-read"].contains(CommandLine.arguments[1]) {
    do {
        let inputPath = CommandLine.arguments[2]
        let statePath = CommandLine.arguments[3]
        let afterPath = CommandLine.arguments[4]
        let prefix = "/private/tmp/gym-assistant-scratchpad-checkpoint/"
        guard [inputPath, afterPath].allSatisfy({ $0.hasPrefix(prefix + "native-") }),
              statePath == prefix + "association-lifecycle.json" else { throw ConfirmationError.invalidRange }
        func captured(_ path: String) throws -> NoteObservation {
            let fixture = try JSONDecoder().decode(NativeFixtureEvidence.self, from: Data(contentsOf: URL(fileURLWithPath: path)))
            guard fixture.noteID == "synthetic-fixture", !fixture.html.isEmpty,
                  fixture.text.contains("Gym assistant capability test"),
                  fixture.text.contains("END OF SYNTHETIC NOTE 2026-10-12") else { throw ConfirmationError.invalidRange }
            return NoteObservation(noteID: fixture.noteID, text: fixture.text)
        }
        let before = try captured(inputPath)
        let expected = SavedFixture(noteID: before.noteID, workspaces: sections(before).enumerated().map {
            SavedWorkspace(anchor: anchor("persisted-\($0.offset)", $0.element, closed: $0.offset == 1),
                           revision: $0.offset + 7, conversation: ["Coach question \($0.offset)", "Synthetic reply \($0.offset)"])
        })
        if CommandLine.arguments[1] == "lifecycle-write" {
            try JSONEncoder().encode(expected).write(to: URL(fileURLWithPath: statePath), options: .atomic)
            check(expected.workspaces.count == 4, "Save four captured-fixture workspaces with stable identities")
        } else {
            let saved = try JSONDecoder().decode(SavedFixture.self, from: Data(contentsOf: URL(fileURLWithPath: statePath)))
            check(saved == expected, "Fresh process restores exact scratchpads, revisions, conversations and closed state")
            let after = try captured(afterPath)
            let anchors = saved.workspaces.map(\.anchor)
            let result = resolve(anchors, in: after)
            check(result.mappings.count == 4 && result.unresolved.isEmpty, "Reopened saved identities follow captured native renumbering")
            check(result.mappings["persisted-1"]?.label == "14" && anchors[1].closed, "Closed workspace does not steal old label 13 on reopen")
            check(result.mappings["persisted-3"]?.body.contains("Week 3") == true, "Reopened lettered workspace retains all weeks")
            let changed = NoteObservation(noteID: after.noteID, text: after.text.replacingOccurrences(of: anchors[1].baselineBody, with: "Externally changed session content\n"))
            check(resolve(anchors, in: changed).unresolved.contains("persisted-1"), "Changed body on reopen requires review rather than a label guess")
            check(saved == expected, "Reassociation and unresolved results never mutate saved coach content")
            let shifted = NoteObservation(noteID: after.noteID, text: "New surrounding prose\n" + after.text)
            check(resolve(anchors, in: shifted).mappings.count == 4, "Moved offsets on reopen retain all saved identities")
            let wrongNote = NoteObservation(noteID: "other-fixture", text: after.text)
            var wrongRegistry = Registry(noteID: wrongNote.noteID, observationDigest: wrongNote.digest, mappings: [:])
            let payload = Confirmation(sessionID: anchors[0].sessionID, noteID: saved.noteID, observationDigest: wrongNote.digest, range: sections(wrongNote)[0].range)
            rejects("Reopened workspace cannot confirm association to another note") {
                try confirm(payload, anchors: anchors, observation: wrongNote, registry: &wrongRegistry)
            }
        }
    } catch { check(false, "Fixture lifecycle: \(error)") }
} else if CommandLine.arguments.count == 5 && CommandLine.arguments[1] == "native" {
    do {
        func load(_ path: String) throws -> (NoteObservation, String) {
            guard path.hasPrefix("/private/tmp/gym-assistant-scratchpad-checkpoint/native-") else { throw ConfirmationError.invalidRange }
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let json = try JSONDecoder().decode(NativeFixtureEvidence.self, from: data)
            let text = json.text
            guard json.noteID == "synthetic-fixture",
                  text.contains("Gym assistant capability test"), text.contains("END OF SYNTHETIC NOTE 2026-10-12"),
                  !json.html.isEmpty else { throw ConfirmationError.invalidRange }
            return (NoteObservation(noteID: "synthetic-fixture", text: text), json.html)
        }
        let (before, beforeHTML) = try load(CommandLine.arguments[2])
        let (collision, _) = try load(CommandLine.arguments[3])
        let (after, _) = try load(CommandLine.arguments[4])
        let candidates = sections(before)
        let nativeAnchors = candidates.enumerated().map { anchor("native-workspace-\($0.offset)", $0.element, closed: $0.offset == 1) }
        check(candidates.map(\.label) == ["12", "13", "99", "A"], "Native plaintext exposes exact expected session boundaries")
        check(beforeHTML.contains("<h3>Warmup</h3>"), "Native API preserves the coach-created semantic Subheading")
        let letter = candidates.first { $0.label == "A" }
        check(letter?.body.contains("Week 1") == true && letter?.body.contains("Week 2") == true && letter?.body.contains("Week 3") == true, "Native lettered session includes all three weeks")
        let during = resolve(nativeAnchors, in: collision)
        check(during.duplicates == ["13"] && during.mappings.isEmpty, "Live temporary collision requires correction, not label-based rebinding")
        let result = resolve(nativeAnchors, in: after)
        check(result.mappings.count == 4 && result.unresolved.isEmpty, "All native-snapshot workspace IDs survive bulk renumbering")
        check(result.mappings["native-workspace-0"]?.label == "13", "Native first session follows distinctive unchanged body")
        check(result.mappings["native-workspace-1"]?.label == "14", "Native closed second workspace is not stolen by new label 13")
        check(result.mappings["native-workspace-3"]?.label == "A", "Native multiweek workspace remains one identity")
        check(candidates.enumerated().allSatisfy { result.mappings["native-workspace-\($0.offset)"]?.body == $0.element.body }, "Native association excludes only renamed outer heading text")
        print("Native snapshot checks use API-captured plaintext; rich-format equality and confirmation UI remain untested")
    } catch { check(false, "Read and validate synthetic native snapshots: \(error)") }
} else if CommandLine.arguments.count != 1 {
    check(false, "Usage: association-probe [native before.json collision.json after.json | lifecycle-write/read before.json state.json after.json]")
}
print("RESULT \(count - failures)/\(count) association assertions passed; production and rich-structure parsing not tested")
exit(failures == 0 ? 0 : 1)
