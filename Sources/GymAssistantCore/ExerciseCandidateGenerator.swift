import Foundation

public struct RankedExerciseCandidate: Equatable, Sendable {
    public let preferredName: String
    public let score: Double

    public init(preferredName: String, score: Double) {
        self.preferredName = preferredName
        self.score = score
    }
}

public struct ExerciseCandidateGenerator: Sendable {
    private let minimumScore: Double

    public init(minimumScore: Double = 0.45) {
        self.minimumScore = minimumScore
    }

    public func rank(query: String, candidates: [String]) -> [RankedExerciseCandidate] {
        candidates.compactMap { candidate in
            guard !ProtectedModifierPolicy.conflicts(query: query, candidate: candidate) else {
                return nil
            }
            let score = similarity(query, candidate)
            guard score >= minimumScore else { return nil }
            return RankedExerciseCandidate(preferredName: candidate, score: score)
        }
        .sorted {
            if $0.score == $1.score { return $0.preferredName < $1.preferredName }
            return $0.score > $1.score
        }
    }

    private func similarity(_ lhs: String, _ rhs: String) -> Double {
        let left = rankingTokens(lhs)
        let right = rankingTokens(rhs)
        guard !left.isEmpty, !right.isEmpty else { return 0 }

        let intersection = left.intersection(right).count
        let containment = Double(intersection) / Double(min(left.count, right.count))
        let union = left.union(right).count
        let jaccard = union == 0 ? 0 : Double(intersection) / Double(union)
        let lexical = normalizedEditSimilarity(left.sorted().joined(separator: " "), right.sorted().joined(separator: " "))
        return max(containment * 0.7 + jaccard * 0.3, lexical)
    }

    private func rankingTokens(_ text: String) -> Set<String> {
        let rawTokens = text.lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)

        var tokens: [String] = []
        for token in rawTokens {
            switch token {
            case "1", "single": tokens.append("one")
            case "australian": tokens.append("aussie")
            case "row": tokens.append(contentsOf: ["pull", "up"])
            case "kickstand": tokens.append(contentsOf: ["b", "stance"])
            case "bulgarian": tokens.append(contentsOf: ["rear", "foot", "elevated"])
            case "rainbow": tokens.append("rotation")
            case "hamstring": break
            default: tokens.append(token)
            }
        }
        return Set(tokens)
    }

    private func normalizedEditSimilarity(_ lhs: String, _ rhs: String) -> Double {
        let longest = max(lhs.count, rhs.count)
        guard longest > 0 else { return 1 }
        return 1 - Double(levenshteinDistance(lhs, rhs)) / Double(longest)
    }

    private func levenshteinDistance(_ lhs: String, _ rhs: String) -> Int {
        let left = Array(lhs)
        let right = Array(rhs)
        var previous = Array(0...right.count)

        for (leftIndex, leftCharacter) in left.enumerated() {
            var current = [leftIndex + 1]
            for (rightIndex, rightCharacter) in right.enumerated() {
                current.append(min(
                    current[rightIndex] + 1,
                    previous[rightIndex + 1] + 1,
                    previous[rightIndex] + (leftCharacter == rightCharacter ? 0 : 1)
                ))
            }
            previous = current
        }
        return previous[right.count]
    }
}

private enum ProtectedModifierPolicy {
    private static let opposingDimensions = [
        ["b stance", "single leg"],
        ["supinated grip", "neutral grip"],
        ["high to low", "low to high"],
        ["lateral lunge", "reverse lunge"],
        ["short lever", "long lever"],
        ["half kneeling", "standing"],
        ["strict press", "push press"],
        ["chest supported", "bent over"],
        ["goblet squat", "barbell front squat"],
        ["box squat", "squat to target"]
    ]

    private static let queryModifiersThatCannotDisappear = [
        "paused", "deficit", "incline", "banded", "anti rotation"
    ]

    static func conflicts(query: String, candidate: String) -> Bool {
        let query = comparable(query)
        let candidate = comparable(candidate)

        if movementPattern(query) != nil,
           movementPattern(candidate) != nil,
           movementPattern(query) != movementPattern(candidate) {
            return true
        }

        if opposingDimensions.contains(where: {
            let queryValues = $0.filter(query.contains)
            let candidateValues = $0.filter(candidate.contains)
            return !queryValues.isEmpty && !candidateValues.isEmpty && queryValues != candidateValues
        }) {
            return true
        }

        if queryModifiersThatCannotDisappear.contains(where: {
            query.contains($0) && !candidate.contains($0)
        }) {
            return true
        }

        if candidate.contains("single leg") && !query.contains("single leg") {
            return true
        }

        return false
    }

    private static func comparable(_ text: String) -> String {
        " " + text.lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .split { !$0.isLetter && !$0.isNumber }
            .joined(separator: " ") + " "
    }

    private static func movementPattern(_ text: String) -> String? {
        if text.contains(" squat ") { return "squat" }
        if text.contains(" deadlift ") || text.contains(" rdl ") { return "hinge" }
        return nil
    }
}
