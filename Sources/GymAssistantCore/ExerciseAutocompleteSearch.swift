import Foundation

public enum ExerciseSearchMatchKind: Int, Comparable, Sendable {
    case normalizedName = 0
    case namePrefix = 1
    case orderedTokenPrefix = 2
    case lexicalContainment = 3
    case fuzzy = 4

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct ExerciseSearchMatch: Equatable, Sendable {
    public let exerciseID: ExerciseID
    public let preferredName: String
    public let aliases: [String]
    public let matchedName: String
    public let matchedNameIsPreferred: Bool
    public let matchKind: ExerciseSearchMatchKind
    public let score: Double

    public init(
        exerciseID: ExerciseID,
        preferredName: String,
        aliases: [String],
        matchedName: String,
        matchedNameIsPreferred: Bool,
        matchKind: ExerciseSearchMatchKind,
        score: Double
    ) {
        self.exerciseID = exerciseID
        self.preferredName = preferredName
        self.aliases = aliases
        self.matchedName = matchedName
        self.matchedNameIsPreferred = matchedNameIsPreferred
        self.matchKind = matchKind
        self.score = score
    }
}

public final class ExerciseAutocompleteSearch {
    private let library: ExerciseLibrary
    private let normalizer: BasicExerciseNameNormalizer
    private let fuzzyRanker: ExerciseTextCandidateRanker

    public init(
        library: ExerciseLibrary,
        normalizer: BasicExerciseNameNormalizer = .init(),
        fuzzyThreshold: Double = 0.35
    ) {
        self.library = library
        self.normalizer = normalizer
        fuzzyRanker = ExerciseTextCandidateRanker(
            policy: .autocomplete(minimumScore: fuzzyThreshold)
        )
    }

    public func search(_ query: String, limit: Int = 5) throws -> [ExerciseSearchMatch] {
        guard limit > 0, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let normalizedQuery = try normalizer.normalize(query)
        let preferredNames = try library.allPreferredNames()
        let allNames = try library.allNames()
        let preferredByExercise = Dictionary(uniqueKeysWithValues: preferredNames.map { ($0.exerciseID, $0) })
        let namesByExercise = Dictionary(grouping: allNames, by: \ExerciseName.exerciseID)

        var bestByExercise: [ExerciseID: RankedName] = [:]
        for name in allNames {
            guard let preferred = preferredByExercise[name.exerciseID],
                  let ranked = rank(
                    query: normalizedQuery,
                    name: name,
                    isPreferred: name.id == preferred.id
                  ) else {
                continue
            }

            if let current = bestByExercise[name.exerciseID], !nameRanksBefore(ranked, current) {
                continue
            }
            bestByExercise[name.exerciseID] = ranked
        }

        return bestByExercise.compactMap { exerciseID, ranked -> ExerciseSearchMatch? in
            guard let preferred = preferredByExercise[exerciseID] else { return nil }
            let aliases = namesByExercise[exerciseID, default: []]
                .filter { $0.id != preferred.id }
                .map(\.text)
                .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
            return ExerciseSearchMatch(
                exerciseID: exerciseID,
                preferredName: preferred.text,
                aliases: aliases,
                matchedName: ranked.name.text,
                matchedNameIsPreferred: ranked.isPreferred,
                matchKind: ranked.kind,
                score: ranked.score
            )
        }
        .sorted { lhs, rhs in
            guard let left = bestByExercise[lhs.exerciseID],
                  let right = bestByExercise[rhs.exerciseID] else { return false }
            if coreRanksBefore(left, right) { return true }
            if coreRanksBefore(right, left) { return false }
            let nameOrder = lhs.preferredName.localizedCaseInsensitiveCompare(rhs.preferredName)
            if nameOrder != .orderedSame { return nameOrder == .orderedAscending }
            return lhs.exerciseID.rawValue.uuidString < rhs.exerciseID.rawValue.uuidString
        }
        .prefix(limit)
        .map { $0 }
    }

    private struct RankedName {
        let name: ExerciseName
        let isPreferred: Bool
        let kind: ExerciseSearchMatchKind
        let unmatchedCharacters: Int
        let score: Double
    }

    private func rank(query: String, name: ExerciseName, isPreferred: Bool) -> RankedName? {
        let candidate = name.normalizedText
        let queryTokens = tokens(query)
        let candidateTokens = tokens(candidate)
        let kind: ExerciseSearchMatchKind
        let score: Double

        if candidate == query {
            kind = .normalizedName
            score = 1
        } else if candidate.hasPrefix(query) {
            kind = .namePrefix
            score = ExerciseTextCandidateRanker.maximumScoredCandidateScore
        } else if orderedTokenPrefixes(queryTokens, in: candidateTokens) {
            kind = .orderedTokenPrefix
            score = ExerciseTextCandidateRanker.maximumScoredCandidateScore
        } else if candidate.contains(query) || queryTokens.allSatisfy({ queryToken in
            candidateTokens.contains(where: { $0.contains(queryToken) })
        }) {
            kind = .lexicalContainment
            score = ExerciseTextCandidateRanker.maximumScoredCandidateScore
        } else {
            guard let sharedScore = fuzzyRanker.score(query: query, candidate: candidate) else {
                return nil
            }
            score = sharedScore
            kind = .fuzzy
        }

        return RankedName(
            name: name,
            isPreferred: isPreferred,
            kind: kind,
            unmatchedCharacters: max(0, candidate.count - query.count),
            score: score
        )
    }

    private func coreRanksBefore(_ lhs: RankedName, _ rhs: RankedName) -> Bool {
        if lhs.kind != rhs.kind { return lhs.kind < rhs.kind }
        if lhs.kind == .fuzzy, lhs.score != rhs.score {
            return lhs.score > rhs.score
        }
        if lhs.unmatchedCharacters != rhs.unmatchedCharacters {
            return lhs.unmatchedCharacters < rhs.unmatchedCharacters
        }
        if lhs.isPreferred != rhs.isPreferred { return lhs.isPreferred }
        return false
    }

    private func nameRanksBefore(_ lhs: RankedName, _ rhs: RankedName) -> Bool {
        if coreRanksBefore(lhs, rhs) { return true }
        if coreRanksBefore(rhs, lhs) { return false }
        let textOrder = lhs.name.text.localizedCaseInsensitiveCompare(rhs.name.text)
        if textOrder != .orderedSame { return textOrder == .orderedAscending }
        return lhs.name.id.rawValue.uuidString < rhs.name.id.rawValue.uuidString
    }

    private func tokens(_ text: String) -> [String] {
        text.split { !$0.isLetter && !$0.isNumber }.map(String.init)
    }

    private func orderedTokenPrefixes(_ query: [String], in candidate: [String]) -> Bool {
        guard !query.isEmpty else { return false }
        var candidateIndex = 0
        for queryToken in query {
            while candidateIndex < candidate.count && !candidate[candidateIndex].hasPrefix(queryToken) {
                candidateIndex += 1
            }
            guard candidateIndex < candidate.count else { return false }
            candidateIndex += 1
        }
        return true
    }

}
