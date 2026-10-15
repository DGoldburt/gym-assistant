import Foundation

/// A provider identifies an exercise mention, never its canonical identity.
/// Offsets are UTF-16, relative to the unchanged response text.
public struct ExerciseMention: Codable, Equatable, Sendable {
    public let text: String
    public let range: SourceRange
    public init(text: String, range: SourceRange) { self.text = text; self.range = range }

    public static func validated(_ mentions: [ExerciseMention], in text: String) -> [ExerciseMention] {
        var end = 0
        return mentions.sorted { $0.range.location < $1.range.location }.filter { mention in
            let range = mention.range.nsRange
            guard range.location >= end, range.length > 0,
                  range.location <= (text as NSString).length,
                  range.length <= (text as NSString).length - range.location,
                  let swiftRange = Range(range, in: text), String(text[swiftRange]) == mention.text,
                  !mention.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
            end = range.location + range.length
            return true
        }
    }
}

public enum ExerciseMentionMatch: Equatable, Sendable {
    case inLibrary(canonicalName: String)
    case notMatched
    case unavailable

    public var label: String {
        switch self {
        case .inLibrary(let name): return "In library · " + name
        case .notMatched: return "Not matched"
        case .unavailable: return "Library unavailable"
        }
    }
}
