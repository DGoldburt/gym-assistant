import Foundation

public enum SessionComparison {
    /// Handoff-only equivalence. Never use this to rewrite persisted text, choose
    /// a session identity, or advance its confirmed baseline without validation.
    public static func handoffEquivalent(_ before: SessionSourceEvidence, _ after: SessionSourceEvidence) -> Bool {
        handoffParagraphs(before) == handoffParagraphs(after)
    }

    public static func handoffText(before: SessionSourceEvidence, after: SessionSourceEvidence) -> String {
        text(before: handoffParagraphs(before).map(\.text).joined(),
             after: handoffParagraphs(after).map(\.text).joined())
    }

    private static func handoffParagraphs(_ evidence: SessionSourceEvidence) -> [ProgramParagraph] {
        var paragraphs = evidence.paragraphs
        while let last = paragraphs.last, last.headingLevel == 0,
              last.listStyle?.isEmpty != false,
              ["\n", "\r\n", "\r"].contains(last.text) {
            paragraphs.removeLast()
        }
        return paragraphs
    }

    /// Line-level changes in one pane, retaining two lines of context per change.
    public static func text(before: String, after: String) -> String {
        guard before != after else { return "No text differences." }
        let old = before.components(separatedBy: "\n")
        let new = after.components(separatedBy: "\n")
        var removed = Set<Int>(), inserted = Set<Int>()
        for change in new.difference(from: old) {
            switch change {
            case .remove(let offset, _, _): removed.insert(offset)
            case .insert(let offset, _, _): inserted.insert(offset)
            }
        }
        var rows: [(text: String, changed: Bool)] = []
        var i = 0, j = 0
        while i < old.count || j < new.count {
            if i < old.count, removed.contains(i) { rows.append(("− " + old[i], true)); i += 1 }
            else if j < new.count, inserted.contains(j) { rows.append(("+ " + new[j], true)); j += 1 }
            else if i < old.count, j < new.count { rows.append(("  " + old[i], false)); i += 1; j += 1 }
            else { break }
        }
        var visible = Set<Int>()
        for index in rows.indices where rows[index].changed {
            visible.formUnion(max(0, index - 2)...min(rows.count - 1, index + 2))
        }
        var output: [String] = [], previous = -1
        for index in visible.sorted() {
            if previous >= 0 && index > previous + 1 { output.append("…") }
            output.append(rows[index].text); previous = index
        }
        return output.joined(separator: "\n")
    }
}
