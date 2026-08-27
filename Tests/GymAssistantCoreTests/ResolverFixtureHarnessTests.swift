import Foundation
import Testing
@testable import GymAssistantCore

@Suite("Resolver fixture harness")
struct ResolverFixtureHarnessTests {
    @Test("Unimplemented resolver reports useful category totals")
    func unimplementedResolverReport() throws {
        let document = try loadFixtureDocument()
        let report = try ResolverFixtureHarness().evaluate(document, using: StubResolver())

        #expect(report.total == 37)
        #expect(report.passes == 17)
        #expect(report.falseMerges == 0)
        #expect(report.missedExpectedMatches == 10)
        #expect(report.candidateRankingFailures == 10)
        #expect(report.protectedCandidateLeaks == 0)
        #expect(!report.succeeded)
    }

    @Test("Deterministic confirmed-name resolver clears expected matches without false merges")
    func deterministicResolverReport() throws {
        let document = try loadFixtureDocument()
        let report = try ResolverFixtureHarness().evaluate(
            document,
            using: DeterministicFixtureResolver()
        )

        #expect(report.total == 37)
        #expect(report.passes == 27)
        #expect(report.falseMerges == 0)
        #expect(report.missedExpectedMatches == 0)
        #expect(report.candidateRankingFailures == 10)
        #expect(report.protectedCandidateLeaks == 0)
        #expect(!report.succeeded)
    }

    @Test("Candidate generator ranks review cases and excludes protected conflicts")
    func candidateGeneratorReport() throws {
        let document = try loadFixtureDocument()
        let report = try ResolverFixtureHarness().evaluate(document, using: FixtureResolver())

        #expect(report.total == 37)
        #expect(report.passes == 37)
        #expect(report.falseMerges == 0)
        #expect(report.missedExpectedMatches == 0)
        #expect(report.candidateRankingFailures == 0)
        #expect(report.protectedCandidateLeaks == 0)
        #expect(report.authoritativeScoreLeaks == 0)
        #expect(report.succeeded)
    }

    @Test("Perfect review-candidate scores fail the fixture contract")
    func authoritativeScoreLeakClassification() throws {
        let document = try loadFixtureDocument()
        let report = try ResolverFixtureHarness().evaluate(
            document,
            using: PerfectScoreCandidateResolver()
        )

        #expect(report.authoritativeScoreLeaks == document.categories.suggestReview.count)
        #expect(!report.succeeded)
    }

    @Test("Wrong automatic decisions are classified as false merges")
    func falseMergeClassification() throws {
        let document = try loadFixtureDocument()
        let report = try ResolverFixtureHarness().evaluate(
            document,
            using: StubResolver(automaticMatch: "Incorrect Exercise")
        )

        #expect(report.falseMerges == 37)
        #expect(report.missedExpectedMatches == 0)
        #expect(report.candidateRankingFailures == 0)
    }
}

private struct PerfectScoreCandidateResolver: ResolverFixtureResolving {
    func resolve(_ input: ResolverFixtureInput) throws -> ResolverFixtureObservation {
        guard let candidate = input.candidatePreferredNames.first else {
            return .init()
        }
        return .init(
            rankedCandidates: [candidate],
            rankedCandidateScores: [1]
        )
    }
}

private struct DeterministicFixtureResolver: ResolverFixtureResolving {
    private let resolver = DeterministicExerciseNameResolver()

    func resolve(_ input: ResolverFixtureInput) throws -> ResolverFixtureObservation {
        guard let knownExercise = input.knownExercise else {
            return ResolverFixtureObservation()
        }
        guard try resolver.matchesConfirmedName(
            query: input.query,
            confirmedNames: knownExercise.confirmedNames
        ) else {
            return ResolverFixtureObservation()
        }
        return ResolverFixtureObservation(automaticMatch: knownExercise.preferredName)
    }
}

private struct FixtureResolver: ResolverFixtureResolving {
    private let resolver = DeterministicExerciseNameResolver()
    private let candidateGenerator = ExerciseCandidateGenerator()

    func resolve(_ input: ResolverFixtureInput) throws -> ResolverFixtureObservation {
        if let knownExercise = input.knownExercise,
           try resolver.matchesConfirmedName(
               query: input.query,
               confirmedNames: knownExercise.confirmedNames
           ) {
            return .init(automaticMatch: knownExercise.preferredName)
        }

        let rankings = candidateGenerator.rank(
            query: input.query,
            candidates: input.candidatePreferredNames
        )
        return .init(
            rankedCandidates: rankings.map(\.preferredName),
            rankedCandidateScores: rankings.map(\.score)
        )
    }
}

private struct StubResolver: ResolverFixtureResolving {
    var automaticMatch: String?

    init(automaticMatch: String? = nil) {
        self.automaticMatch = automaticMatch
    }

    func resolve(_ input: ResolverFixtureInput) throws -> ResolverFixtureObservation {
        ResolverFixtureObservation(automaticMatch: automaticMatch)
    }
}

private func loadFixtureDocument() throws -> ResolverFixtureDocument {
    let fixtureURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent("Tests/Fixtures/resolver-cases.json")
    return try JSONDecoder().decode(
        ResolverFixtureDocument.self,
        from: Data(contentsOf: fixtureURL)
    )
}
