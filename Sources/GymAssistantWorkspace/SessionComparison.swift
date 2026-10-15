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

    /// One bounded changed hunk, avoiding stacked full copies in the comparison pane.
    public static func text(before: String, after: String) -> String {
        guard before != after else { return "No text differences." }
        let old = before.components(separatedBy: "\n")
        let new = after.components(separatedBy: "\n")
        var prefix = 0
        while prefix < min(old.count, new.count), old[prefix] == new[prefix] { prefix += 1 }
        var suffix = 0
        while suffix < min(old.count, new.count) - prefix,
              old[old.count - suffix - 1] == new[new.count - suffix - 1] { suffix += 1 }
        let beforeContext = old[max(0, prefix - 2)..<prefix].map { "  " + $0 }
        let removed = old[prefix..<(old.count - suffix)].map { "− " + $0 }
        let added = new[prefix..<(new.count - suffix)].map { "+ " + $0 }
        let afterContext = old[(old.count - suffix)..<min(old.count, old.count - suffix + 2)].map { "  " + $0 }
        return (beforeContext + removed + added + afterContext).joined(separator: "\n")
    }
}
