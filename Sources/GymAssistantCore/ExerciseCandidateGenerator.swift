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
    private let ranker: ExerciseTextCandidateRanker

    public init(minimumScore: Double = 0.45) {
        ranker = ExerciseTextCandidateRanker(policy: .identityReview(minimumScore: minimumScore))
    }

    public func rank(query: String, candidates: [String]) -> [RankedExerciseCandidate] {
        candidates.compactMap { candidate in
            guard let score = ranker.score(query: query, candidate: candidate) else { return nil }
            return RankedExerciseCandidate(preferredName: candidate, score: score)
        }
        .sorted {
            if $0.score == $1.score { return $0.preferredName < $1.preferredName }
            return $0.score > $1.score
        }
    }
}
