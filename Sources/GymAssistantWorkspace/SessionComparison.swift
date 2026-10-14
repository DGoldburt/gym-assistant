import Foundation

public enum SessionComparison {
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
