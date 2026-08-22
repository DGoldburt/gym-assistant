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
