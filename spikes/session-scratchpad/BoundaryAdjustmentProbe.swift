// Disposable synthetic boundary policy test. No Notes, clipboard, or production UI.
import Foundation
import CryptoKit

struct Observation: Equatable {
    let noteID: String
    let text: String
    var digest: String { SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined() }
    var paragraphs: [NSRange] {
        let text = text as NSString
        var result: [NSRange] = []
        var start = 0
        while start < text.length {
            let range = text.paragraphRange(for: NSRange(location: start, length: 0))
            result.append(range)
            start = NSMaxRange(range)
        }
        return result
    }
}
struct Piece: Equatable {
    let source: NSRange
    let text: String
    let protected: Bool // Includes additions and deleted-text tombstones.
}
struct Workspace: Equatable {
    let id: String
    let noteID: String
    let observationDigest: String
    var range: NSRange
    var pieces: [Piece]
    var revision: Int
    var reliableCorrespondence: Bool
    let conversation: [String]
    let baseline: String
    var text: String { pieces.map(\.text).joined() }
}
struct Owner { let workspaceID: String; let range: NSRange }
struct Preview {
    let before: Workspace
    let after: Workspace
    let addedText: String
    let abuttingOwners: [String]
}
enum BoundaryError: Error, Equatable {
    case stale, invalidRange, editedRegion, uncertainCorrespondence
    case occupied(String), changedSincePreview
}

func pieces(in range: NSRange, observation: Observation) -> [Piece] {
    observation.paragraphs.filter { NSIntersectionRange($0, range).length > 0 }.map {
        Piece(source: $0, text: (observation.text as NSString).substring(with: $0), protected: false)
    }
}
func validate(_ range: NSRange, workspace: Workspace, observation: Observation, owners: [Owner]) throws {
    guard workspace.noteID == observation.noteID, workspace.observationDigest == observation.digest else { throw BoundaryError.stale }
    let boundaries = Set(observation.paragraphs.map(\.location) + [(observation.text as NSString).length])
    guard range.length > 0, boundaries.contains(range.location), boundaries.contains(NSMaxRange(range)) else { throw BoundaryError.invalidRange }
    if let owner = owners.first(where: { $0.workspaceID != workspace.id && NSIntersectionRange($0.range, range).length > 0 }) {
        throw BoundaryError.occupied(owner.workspaceID)
    }
}
func preview(_ range: NSRange, workspace: Workspace, observation: Observation, owners: [Owner]) throws -> Preview {
    try validate(range, workspace: workspace, observation: observation, owners: owners)
    // One endpoint move at a time; wholly disjoint ranges are not a shrink/expand.
    guard range.location == workspace.range.location || NSMaxRange(range) == NSMaxRange(workspace.range),
          NSIntersectionRange(range, workspace.range).length > 0 else { throw BoundaryError.invalidRange }
    let shrinking = range.location > workspace.range.location || NSMaxRange(range) < NSMaxRange(workspace.range)
    if shrinking {
        guard workspace.reliableCorrespondence else { throw BoundaryError.uncertainCorrespondence }
        for piece in workspace.pieces where piece.protected {
            if piece.source.length == 0 {
                // Conservatively protect additions anchored exactly on a cut edge.
                let point = piece.source.location
                if (range.location > workspace.range.location && point <= range.location) ||
                    (NSMaxRange(range) < NSMaxRange(workspace.range) && point >= NSMaxRange(range)) {
                    throw BoundaryError.editedRegion
                }
            } else if NSIntersectionRange(piece.source, range).length != piece.source.length {
                throw BoundaryError.editedRegion
            }
        }
    }
    var after = workspace
    var added = ""
    if shrinking {
        after.pieces = workspace.pieces.filter {
            $0.source.length == 0 || NSIntersectionRange($0.source, range).length == $0.source.length
        }
    } else if range.location < workspace.range.location {
        let edge = NSRange(location: range.location, length: workspace.range.location - range.location)
        let prefix = pieces(in: edge, observation: observation)
        added = prefix.map(\.text).joined()
        after.pieces = prefix + workspace.pieces
    } else if NSMaxRange(range) > NSMaxRange(workspace.range) {
        let edge = NSRange(location: NSMaxRange(workspace.range), length: NSMaxRange(range) - NSMaxRange(workspace.range))
        let suffix = pieces(in: edge, observation: observation)
        added = suffix.map(\.text).joined()
        after.pieces = workspace.pieces + suffix
    }
    after.range = range
    after.revision += 1
    let neighbors = owners.filter { $0.workspaceID != workspace.id &&
        (NSMaxRange($0.range) == range.location || $0.range.location == NSMaxRange(range)) }.map(\.workspaceID)
    return Preview(before: workspace, after: after, addedText: added, abuttingOwners: neighbors)
}
func apply(_ preview: Preview, to workspace: inout Workspace, observation: Observation, owners: [Owner]) throws {
    guard workspace == preview.before else { throw BoundaryError.changedSincePreview }
    try validate(preview.after.range, workspace: workspace, observation: observation, owners: owners)
    workspace = preview.after
}
func undo(_ preview: Preview, workspace: inout Workspace, observation: Observation, owners: [Owner]) throws {
    guard workspace == preview.after else { throw BoundaryError.changedSincePreview }
    try validate(preview.before.range, workspace: workspace, observation: observation, owners: owners)
    let nextRevision = workspace.revision + 1
    workspace = preview.before
    workspace.revision = nextRevision
}

var assertions = 0
var failures = 0
func check(_ condition: @autoclosure () -> Bool, _ name: String) {
    assertions += 1
    let passed = condition()
    failures += passed ? 0 : 1
    print("\(passed ? "PASS" : "FAIL") \(name)")
}
func rejects(_ expected: BoundaryError, _ name: String, _ operation: () throws -> Void) {
    do { try operation(); check(false, name) }
    catch let error as BoundaryError { check(error == expected, name) }
    catch { check(false, name) }
}
let source = Observation(noteID: "synthetic-note", text: "Context\nSession A\nA1 Row\nB1 Carry\nParking Lot\nIdea\nNext workspace\n")
let paragraphs = source.paragraphs
func range(_ first: Int, _ last: Int) -> NSRange {
    NSRange(location: paragraphs[first].location, length: NSMaxRange(paragraphs[last]) - paragraphs[first].location)
}
let start = range(1, 3)
let initial = Workspace(id: "current", noteID: source.noteID, observationDigest: source.digest,
                        range: start, pieces: pieces(in: start, observation: source), revision: 0,
                        reliableCorrespondence: true, conversation: ["Keep carry light"], baseline: "unchanged confirmed baseline")
let owners = [Owner(workspaceID: "neighbor", range: range(6, 6))]
do {
    var edited = initial
    edited.pieces[1] = Piece(source: paragraphs[2], text: "A1 Coach-chosen row variation\n", protected: true)
    let expansion = try preview(range(1, 5), workspace: edited, observation: source, owners: owners)
    check(edited.range == start && edited.revision == 0, "Preview does not mutate scratchpad or bounds")
    check(expansion.addedText == "Parking Lot\nIdea\n", "Expansion preview contains only new edge Notes content")
    check(expansion.after.text.contains("Coach-chosen") && expansion.after.text.hasSuffix("Parking Lot\nIdea\n"), "Expansion preserves existing edits")
    check(expansion.abuttingOwners == ["neighbor"], "Exact abutment allowed and owning workspace identified")
    rejects(.occupied("neighbor"), "Overlap identifies blocking owner") { _ = try preview(range(1, 6), workspace: edited, observation: source, owners: owners) }
    var current = edited
    try apply(expansion, to: &current, observation: source, owners: owners)
    check(current.range == range(1, 5) && current.text == expansion.after.text, "Confirmed expansion applies content and bounds together")
    check(current.id == edited.id && current.conversation == edited.conversation && current.baseline == edited.baseline, "Expansion preserves identity, conversation and existing baseline")
    try undo(expansion, workspace: &current, observation: source, owners: owners)
    check(current.range == edited.range && current.text == edited.text && current.revision == 2, "Undo restores content and bounds atomically with monotonic revision")
    let shrink = try preview(range(1, 2), workspace: edited, observation: source, owners: owners)
    check(shrink.after.text == "Session A\nA1 Coach-chosen row variation\n", "Untouched trailing region may shrink without removing earlier edit")
    rejects(.editedRegion, "Bottom shrink cannot cross edited region") { _ = try preview(range(1, 1), workspace: edited, observation: source, owners: owners) }
    rejects(.editedRegion, "Top shrink cannot cross edited region") { _ = try preview(range(3, 3), workspace: edited, observation: source, owners: owners) }
    var deletion = initial
    deletion.pieces[2] = Piece(source: paragraphs[3], text: "", protected: true)
    rejects(.editedRegion, "Deleted-text tombstone still protects edited region") { _ = try preview(range(1, 2), workspace: deletion, observation: source, owners: owners) }
    var addition = initial
    addition.pieces.append(Piece(source: NSRange(location: paragraphs[3].location, length: 0), text: "Coach addition\n", protected: true))
    rejects(.editedRegion, "Coach-added edge text cannot be shrunk away") { _ = try preview(range(1, 2), workspace: addition, observation: source, owners: owners) }
    var uncertain = edited
    uncertain.reliableCorrespondence = false
    rejects(.uncertainCorrespondence, "Reordered/uncertain correspondence blocks destructive shrink") { _ = try preview(range(1, 2), workspace: uncertain, observation: source, owners: owners) }
    let uncertainExpansion = try preview(range(1, 5), workspace: uncertain, observation: source, owners: owners)
    check(uncertainExpansion.after.text.contains("Coach-chosen"), "Uncertain correspondence still permits preserving expansion")
    rejects(.invalidRange, "Partial-paragraph boundary refused") { _ = try preview(NSRange(location: start.location + 1, length: start.length - 1), workspace: initial, observation: source, owners: owners) }
    let changedNotes = Observation(noteID: source.noteID, text: source.text + "New Notes edit\n")
    var unchanged = edited
    rejects(.stale, "Changed Notes invalidates expansion preview") { try apply(expansion, to: &unchanged, observation: changedNotes, owners: owners) }
    check(unchanged == edited, "Failed apply changes neither content nor bounds")
    var laterEdit = edited
    laterEdit.revision += 1
    rejects(.changedSincePreview, "Scratchpad edit invalidates expansion preview") { try apply(expansion, to: &laterEdit, observation: source, owners: owners) }
    var undoTarget = expansion.after
    rejects(.stale, "Undo cannot restore stale source ranges") { try undo(expansion, workspace: &undoTarget, observation: changedNotes, owners: owners) }
    let occupying = [Owner(workspaceID: "new-owner", range: range(1, 1))]
    rejects(.occupied("new-owner"), "Undo cannot take another workspace's range") { try undo(expansion, workspace: &undoTarget, observation: source, owners: occupying) }
    check(undoTarget == expansion.after, "Refused undo preserves current scratchpad and range")
    undoTarget.revision += 1
    rejects(.changedSincePreview, "Undo cannot erase later scratchpad edits") { try undo(expansion, workspace: &undoTarget, observation: source, owners: owners) }
    let prefix = try preview(range(0, 3), workspace: edited, observation: source, owners: [])
    check(prefix.after.text == "Context\n" + edited.text, "Top expansion inserts only new prefix")
} catch { check(false, "Unexpected fixture error: \(error)") }
print("RESULT \(assertions - failures)/\(assertions) synthetic boundary-policy assertions passed; no native editor/undo or automatic edit tracking tested")
exit(failures == 0 ? 0 : 1)
