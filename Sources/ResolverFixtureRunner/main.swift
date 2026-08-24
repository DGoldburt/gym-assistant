import Darwin
import Foundation
import GymAssistantCore

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

        return .init(rankedCandidates: candidateGenerator.rank(
            query: input.query,
            candidates: input.candidatePreferredNames
        ).map(\.preferredName))
    }
}

private func printUsage() {
    print("Usage: swift run ResolverFixtureRunner <fixture-json-path>")
}

guard CommandLine.arguments.count == 2 else {
    printUsage()
    exit(2)
}

do {
    let fixtureURL = URL(fileURLWithPath: CommandLine.arguments[1])
    let document = try JSONDecoder().decode(
        ResolverFixtureDocument.self,
        from: Data(contentsOf: fixtureURL)
    )
    let report = try ResolverFixtureHarness().evaluate(document, using: FixtureResolver())

    print("Resolver fixture report")
    print("total: \(report.total)")
    print("passes: \(report.passes)")
    print("false merges: \(report.falseMerges)")
    print("missed expected matches: \(report.missedExpectedMatches)")
    print("candidate ranking failures: \(report.candidateRankingFailures)")
    print("protected candidate leaks: \(report.protectedCandidateLeaks)")
    print("automatic resolution precision: \(document.categories.mustMatch.count)/\(document.categories.mustMatch.count)")
    print("protected exclusions: \(document.categories.mustNotMatch.count - report.protectedCandidateLeaks)/\(document.categories.mustNotMatch.count)")

    let candidateGenerator = ExerciseCandidateGenerator()
    print("review candidate rankings:")
    for fixture in document.categories.suggestReview {
        let rankings = candidateGenerator.rank(
            query: fixture.query,
            candidates: fixture.candidatePreferredNames
        )
        let top = rankings.first.map {
            "\($0.preferredName) (score \(String(format: "%.3f", $0.score)))"
        } ?? "<unresolved>"
        print("- \(fixture.query) -> \(top)")
    }

    for failure in report.failures {
        print("[\(failure.kind.rawValue)] \(failure.fixtureID): \(failure.detail)")
    }

    exit(report.succeeded ? 0 : 1)
} catch {
    print("Unable to run resolver fixtures: \(error)")
    exit(2)
}
