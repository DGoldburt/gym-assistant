import Darwin
import Foundation
import GymAssistantCore

private struct UnimplementedResolver: ResolverFixtureResolving {
    func resolve(_ input: ResolverFixtureInput) throws -> ResolverFixtureObservation {
        ResolverFixtureObservation()
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
    let report = try ResolverFixtureHarness().evaluate(document, using: UnimplementedResolver())

    print("Resolver fixture report")
    print("total: \(report.total)")
    print("passes: \(report.passes)")
    print("false merges: \(report.falseMerges)")
    print("missed expected matches: \(report.missedExpectedMatches)")
    print("candidate ranking failures: \(report.candidateRankingFailures)")

    for failure in report.failures {
        print("[\(failure.kind.rawValue)] \(failure.fixtureID): \(failure.detail)")
    }

    exit(report.succeeded ? 0 : 1)
} catch {
    print("Unable to run resolver fixtures: \(error)")
    exit(2)
}
