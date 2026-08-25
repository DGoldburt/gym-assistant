import Foundation

struct ExerciseTextCandidatePolicy: Sendable {
    let minimumScore: Double
    let usesReviewEquivalences: Bool
    let excludesProtectedConflicts: Bool

    static func identityReview(minimumScore: Double = 0.45) -> Self {
        .init(
            minimumScore: minimumScore,
            usesReviewEquivalences: true,
            excludesProtectedConflicts: true
        )
    }

    static func autocomplete(minimumScore: Double = 0.35) -> Self {
        .init(
            minimumScore: minimumScore,
            usesReviewEquivalences: true,
            excludesProtectedConflicts: true
        )
    }
}

struct ExerciseTextCandidateRanker: Sendable {
    let policy: ExerciseTextCandidatePolicy

    func score(query: String, candidate: String) -> Double? {
        if policy.excludesProtectedConflicts,
           ProtectedModifierPolicy.conflicts(query: query, candidate: candidate) {
            return nil
        }

        let queryTokens = rankingTokens(query)
        let candidateTokens = rankingTokens(candidate)
        guard !queryTokens.isEmpty, !candidateTokens.isEmpty else { return nil }

        let querySet = Set(queryTokens)
        let candidateSet = Set(candidateTokens)
        let intersection = querySet.intersection(candidateSet).count
        let containment = Double(intersection) / Double(min(querySet.count, candidateSet.count))
        let union = querySet.union(candidateSet).count
        let jaccard = union == 0 ? 0 : Double(intersection) / Double(union)
        let wholePhrase = editSimilarity(
            querySet.sorted().joined(separator: " "),
            candidateSet.sorted().joined(separator: " ")
        )
        let tokenSimilarity = queryTokens.map { queryToken in
            candidateTokens.map { editSimilarity(queryToken, $0) }.max() ?? 0
        }.reduce(0, +) / Double(queryTokens.count)
        let isShortSingleToken = queryTokens.count == 1 && queryTokens[0].count <= 4
        let shortPrefixSimilarity = isShortSingleToken
            ? candidateTokens.map {
                editSimilarity(queryTokens[0], String($0.prefix(queryTokens[0].count)))
            }.max() ?? 0
            : 0
        let score = max(
            containment * 0.7 + jaccard * 0.3,
            wholePhrase,
            tokenSimilarity,
            shortPrefixSimilarity
        )
        let effectiveMinimum = isShortSingleToken ? max(policy.minimumScore, 0.7) : policy.minimumScore
        return score >= effectiveMinimum ? score : nil
    }

    private func rankingTokens(_ text: String) -> [String] {
        let rawTokens = text.lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)

        guard policy.usesReviewEquivalences else { return rawTokens }

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
        return tokens
    }

    private func editSimilarity(_ lhs: String, _ rhs: String) -> Double {
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

enum ProtectedModifierPolicy {
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
