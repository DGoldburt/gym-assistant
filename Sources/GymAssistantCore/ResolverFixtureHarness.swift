import Foundation

public struct ResolverFixtureDocument: Decodable, Sendable {
    public let schemaVersion: Int
    public let normalizationAssumptions: [String]
    public let categories: ResolverFixtureCategories
}

public struct ResolverFixtureCategories: Decodable, Sendable {
    public let mustMatch: [MustMatchFixture]
    public let mustNotMatch: [MustNotMatchFixture]
    public let suggestReview: [SuggestReviewFixture]

    private enum CodingKeys: String, CodingKey {
        case mustMatch = "MUST_MATCH"
        case mustNotMatch = "MUST_NOT_MATCH"
        case suggestReview = "SUGGEST_REVIEW"
    }
}

public struct FixtureExerciseVocabulary: Decodable, Sendable {
    public let preferredName: String
    public let confirmedNames: [String]
}

public struct MustMatchFixture: Decodable, Sendable {
    public let id: String
    public let query: String
    public let exercise: FixtureExerciseVocabulary
    public let basis: String
    public let reason: String
}

public struct MustNotMatchFixture: Decodable, Sendable {
    public let id: String
    public let query: String
    public let candidatePreferredName: String
    public let protectedModifier: String
    public let reason: String
}

public struct SuggestReviewFixture: Decodable, Sendable {
    public let id: String
    public let query: String
    public let candidatePreferredNames: [String]
    public let reason: String
}

public struct ResolverFixtureInput: Sendable {
    public let query: String
    public let knownExercise: FixtureExerciseVocabulary?
    public let candidatePreferredNames: [String]
}

public struct ResolverFixtureObservation: Equatable, Sendable {
    public let automaticMatch: String?
    public let rankedCandidates: [String]

    public init(automaticMatch: String? = nil, rankedCandidates: [String] = []) {
        self.automaticMatch = automaticMatch
        self.rankedCandidates = rankedCandidates
    }
}

public protocol ResolverFixtureResolving {
    func resolve(_ input: ResolverFixtureInput) throws -> ResolverFixtureObservation
}

public enum ResolverFixtureFailureKind: String, Sendable {
    case falseMerge = "FALSE_MERGE"
    case missedExpectedMatch = "MISSED_EXPECTED_MATCH"
    case candidateRankingFailure = "CANDIDATE_RANKING_FAILURE"
    case protectedCandidateLeak = "PROTECTED_CANDIDATE_LEAK"
}

public struct ResolverFixtureFailure: Equatable, Sendable {
    public let fixtureID: String
    public let kind: ResolverFixtureFailureKind
    public let detail: String
}

public struct ResolverFixtureReport: Sendable {
    public let total: Int
    public let passes: Int
    public let failures: [ResolverFixtureFailure]

    public var falseMerges: Int { count(.falseMerge) }
    public var missedExpectedMatches: Int { count(.missedExpectedMatch) }
    public var candidateRankingFailures: Int { count(.candidateRankingFailure) }
    public var protectedCandidateLeaks: Int { count(.protectedCandidateLeak) }
    public var succeeded: Bool { failures.isEmpty }

    private func count(_ kind: ResolverFixtureFailureKind) -> Int {
        failures.lazy.filter { $0.kind == kind }.count
    }
}

public struct ResolverFixtureHarness: Sendable {
    public init() {}

    public func evaluate(
        _ document: ResolverFixtureDocument,
        using resolver: some ResolverFixtureResolving
    ) throws -> ResolverFixtureReport {
        var passes = 0
        var failures: [ResolverFixtureFailure] = []

        for fixture in document.categories.mustMatch {
            let observation = try resolver.resolve(.init(
                query: fixture.query,
                knownExercise: fixture.exercise,
                candidatePreferredNames: [fixture.exercise.preferredName]
            ))
            switch observation.automaticMatch {
            case fixture.exercise.preferredName:
                passes += 1
            case nil:
                failures.append(.init(
                    fixtureID: fixture.id,
                    kind: .missedExpectedMatch,
                    detail: "Expected automatic match to \(fixture.exercise.preferredName.debugDescription); got unresolved."
                ))
            case let wrongMatch?:
                failures.append(.init(
                    fixtureID: fixture.id,
                    kind: .falseMerge,
                    detail: "Expected \(fixture.exercise.preferredName.debugDescription); automatically matched \(wrongMatch.debugDescription)."
                ))
            }
        }

        for fixture in document.categories.mustNotMatch {
            let observation = try resolver.resolve(.init(
                query: fixture.query,
                knownExercise: nil,
                candidatePreferredNames: [fixture.candidatePreferredName]
            ))
            if let automaticMatch = observation.automaticMatch {
                failures.append(.init(
                    fixtureID: fixture.id,
                    kind: .falseMerge,
                    detail: "Protected \(fixture.protectedModifier); automatically matched \(automaticMatch.debugDescription)."
                ))
            } else if observation.rankedCandidates.contains(fixture.candidatePreferredName) {
                failures.append(.init(
                    fixtureID: fixture.id,
                    kind: .protectedCandidateLeak,
                    detail: "Protected \(fixture.protectedModifier); conflicting candidate \(fixture.candidatePreferredName.debugDescription) was suggested."
                ))
            } else {
                passes += 1
            }
        }

        for fixture in document.categories.suggestReview {
            let observation = try resolver.resolve(.init(
                query: fixture.query,
                knownExercise: nil,
                candidatePreferredNames: fixture.candidatePreferredNames
            ))
            if let automaticMatch = observation.automaticMatch {
                failures.append(.init(
                    fixtureID: fixture.id,
                    kind: .falseMerge,
                    detail: "Review was required; automatically matched \(automaticMatch.debugDescription)."
                ))
            } else if observation.rankedCandidates.first == fixture.candidatePreferredNames.first {
                passes += 1
            } else {
                failures.append(.init(
                    fixtureID: fixture.id,
                    kind: .candidateRankingFailure,
                    detail: "Expected first candidate \(fixture.candidatePreferredNames.first?.debugDescription ?? "<none>"); got \(observation.rankedCandidates.first?.debugDescription ?? "<none>")."
                ))
            }
        }

        return ResolverFixtureReport(
            total: document.categories.mustMatch.count
                + document.categories.mustNotMatch.count
                + document.categories.suggestReview.count,
            passes: passes,
            failures: failures
        )
    }
}
