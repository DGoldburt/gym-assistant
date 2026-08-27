import Foundation
import Testing
@testable import GymAssistantCore

@Suite("Exercise identity review")
struct ExerciseIdentityReviewTests {
    @Test("Confirmed normalized names reuse identity without writing")
    func exactConfirmedNameIsAutomaticAndReadOnly() throws {
        let fixture = try ReviewFixture()
        let existing = try fixture.library.createExercise(preferredName: "Front Squat")
        try fixture.stage("  FRONT   SQUAT! ", id: "exact")
        let before = try fixture.library.allNames()

        #expect(try fixture.service.prepare(observationID: .init(rawValue: "exact")) == .alreadyResolved(.init(
            exerciseID: existing.exercise.id,
            preferredName: "Front Squat"
        )))
        #expect(try fixture.library.allNames() == before)
    }

    @Test("Review candidates expose transformations, prescriptions, and identity conflicts")
    func candidateEvidenceAndLinkability() throws {
        let fixture = try ReviewFixture()
        _ = try fixture.library.createExercise(preferredName: "Dumbbell Floor Press")
        _ = try fixture.library.createExercise(preferredName: "Long-Lever Copenhagen Plank")
        _ = try fixture.library.createExercise(preferredName: "Reverse Lunge")

        try fixture.stage("DB Floor Press", id: "db")
        try fixture.stage("Short-Lever Copenhagen Plank", id: "copenhagen")
        try fixture.stage("Lateral Lunge", id: "lunge")

        let db = try fixture.candidates("db")
        #expect(db.first?.linkAllowed == true)
        #expect(db.first?.evidence == [.conservativeTransformation("approved abbreviation expansion")])

        let copenhagen = try fixture.candidates("copenhagen")
        #expect(copenhagen.first(where: { $0.preferredName == "Long-Lever Copenhagen Plank" })?.linkAllowed == true)
        #expect(copenhagen.first(where: { $0.preferredName == "Long-Lever Copenhagen Plank" })?.evidence == [
            .prescriptionDifference("lever length changes the prescription")
        ])

        let lunge = try fixture.candidates("lunge")
        let reverseLunge = lunge.first { $0.preferredName == "Reverse Lunge" }
        #expect(reverseLunge?.linkAllowed == false)
        #expect(reverseLunge?.evidence == [.identityConflict("plane of motion changes the exercise identity")])
        #expect(try fixture.library.allNames().count == 3)
    }

    @Test("Lexical review checks both comparison directions")
    func bidirectionalLexicalEvidence() throws {
        let fixture = try ReviewFixture()
        _ = try fixture.library.createExercise(preferredName: "Tall Kneeling Press")
        try fixture.stage("Tall Kneeling Bottoms Up Kettlebell Press", id: "bidirectional")

        let candidate = try fixture.candidates("bidirectional").first {
            $0.preferredName == "Tall Kneeling Press"
        }
        #expect(candidate?.linkAllowed == true)
        guard case .lexicalSimilarity(let score) = candidate?.evidence.first else {
            Issue.record("Expected bidirectional lexical evidence")
            return
        }
        #expect(score >= 0.45)
    }

    @Test("A close full-name match outranks a shorter contained name")
    func fullNameClosenessOutranksShortContainment() throws {
        let fixture = try ReviewFixture()
        _ = try fixture.library.createExercise(preferredName: "Air squat")
        _ = try fixture.library.createExercise(preferredName: "Air squat jump")
        try fixture.stage("Air squat jumps", id: "air-squat-jumps")

        let candidates = try fixture.candidates("air-squat-jumps")
        #expect(candidates.prefix(2).map(\.preferredName) == ["Air squat jump", "Air squat"])
        guard case .lexicalSimilarity(let closerScore) = candidates.first?.evidence.first,
              case .lexicalSimilarity(let shorterScore) = candidates.dropFirst().first?.evidence.first else {
            Issue.record("Expected lexical evidence for both candidates")
            return
        }
        #expect(closerScore > shorterScore)
        #expect(shorterScore < 0.999)
    }

    @Test("Review keeps the winning alias while presenting one exercise identity")
    func reviewCandidatePreservesWinningAlias() throws {
        let fixture = try ReviewFixture()
        let rdl = try fixture.library.createExercise(preferredName: "Romanian Deadlift")
        _ = try fixture.library.addName("RDL", to: rdl.exercise.id)
        try fixture.stage("RDLs", id: "alias-winner")

        let candidate = try #require(fixture.candidates("alias-winner").first)
        #expect(candidate.preferredName == "Romanian Deadlift")
        #expect(candidate.matchedName == "RDL")
        #expect(candidate.aliases == ["RDL"])
    }

    @Test("Link requires reviewable evidence and persists imported alias once")
    func linkIsExplicitAndIdempotent() throws {
        let fixture = try ReviewFixture()
        let floorPress = try fixture.library.createExercise(preferredName: "Dumbbell Floor Press")
        try fixture.stage("DB Floor Press", id: "db")

        let first = try fixture.service.link(
            observationID: .init(rawValue: "db"),
            to: floorPress.exercise.id
        )
        let second = try fixture.service.link(
            observationID: .init(rawValue: "db"),
            to: floorPress.exercise.id
        )

        #expect(first == second)
        #expect(try fixture.library.exactName(for: "DB Floor Press")?.provenance == .importedConfirmed)
        #expect(try fixture.library.allNames().count == 2)
    }

    @Test("Identity conflicts cannot be linked")
    func conflictCannotLink() throws {
        let fixture = try ReviewFixture()
        let reverse = try fixture.library.createExercise(preferredName: "Reverse Lunge")
        try fixture.stage("Lateral Lunge", id: "lunge")

        #expect(throws: ExerciseIdentityReviewError.candidateNotLinkable(reverse.exercise.id)) {
            try fixture.service.link(
                observationID: .init(rawValue: "lunge"),
                to: reverse.exercise.id
            )
        }
        #expect(try fixture.library.allNames().count == 1)
    }

    @Test("Create uses only observed wording and is repeatable")
    func createUsesObservationWithoutEditableName() throws {
        let fixture = try ReviewFixture()
        try fixture.stage("Lateral Goblet Lunge", id: "create")

        let first = try fixture.service.create(observationID: .init(rawValue: "create"))
        let second = try fixture.service.create(observationID: .init(rawValue: "create"))

        #expect(first == second)
        #expect(try fixture.library.exactName(for: "Lateral Goblet Lunge") != nil)
        #expect(try fixture.library.exactName(for: "Reverse Goblet Lunge") == nil)
        #expect(try fixture.library.allNames().count == 1)
    }

    @Test("Deferred observations survive reopening and write no identity")
    func deferralIsDurable() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("gym-assistant-review-reopen-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let databaseURL = directory.appendingPathComponent("library.sqlite")

        do {
            let library = try ExerciseLibrary(databaseURL: databaseURL)
            let service = ExerciseIdentityReviewService(library: library)
            try service.stage(.init(
                id: .init(rawValue: "defer"),
                observedName: "Unclear setup note",
                source: .init(adapter: "fixture", reference: "row-1"),
                occurrenceCount: 1
            ))
            #expect(try service.deferDecision(observationID: .init(rawValue: "defer")) == .deferred)
            #expect(try library.allNames().isEmpty)
        }

        let reopened = try ExerciseLibrary(databaseURL: databaseURL)
        let service = ExerciseIdentityReviewService(library: reopened)
        guard case .review(let status, _) = try service.prepare(observationID: .init(rawValue: "defer")) else {
            Issue.record("Expected deferred review state")
            return
        }
        #expect(status == .deferred)
        #expect(try reopened.allNames().isEmpty)
    }

    @Test("Back atomically restores prior status and removes only the decision's identity write")
    func undoLastReviewDecision() throws {
        let createFixture = try ReviewFixture()
        try createFixture.stage("New Contralateral RDL", id: "create-undo")
        let (_, createReceipt) = try createFixture.service.createWithUndoReceipt(
            observationID: .init(rawValue: "create-undo")
        )
        #expect(try createFixture.library.allNames().count == 1)
        try createFixture.service.undo(createReceipt)
        #expect(try createFixture.library.allNames().isEmpty)
        guard case .review(let createStatus, _) = try createFixture.service.prepare(
            observationID: .init(rawValue: "create-undo")
        ) else {
            Issue.record("Expected the created observation to return to review")
            return
        }
        #expect(createStatus == .pending)

        let linkFixture = try ReviewFixture()
        let floorPress = try linkFixture.library.createExercise(preferredName: "Dumbbell Floor Press")
        try linkFixture.stage("DB Floor Press", id: "link-undo")
        let (_, linkReceipt) = try linkFixture.service.linkWithUndoReceipt(
            observationID: .init(rawValue: "link-undo"),
            to: floorPress.exercise.id
        )
        #expect(try linkFixture.library.allNames().count == 2)
        try linkFixture.service.undo(linkReceipt)
        #expect(try linkFixture.library.allNames().count == 1)
        #expect(try linkFixture.library.exactName(for: "DB Floor Press") == nil)

        let skipFixture = try ReviewFixture()
        try skipFixture.stage("Unclear exercise", id: "skip-undo")
        let (_, skipReceipt) = try skipFixture.service.skipWithUndoReceipt(
            observationID: .init(rawValue: "skip-undo")
        )
        try skipFixture.service.undo(skipReceipt)
        guard case .review(let skipStatus, _) = try skipFixture.service.prepare(
            observationID: .init(rawValue: "skip-undo")
        ) else {
            Issue.record("Expected the skipped observation to return to review")
            return
        }
        #expect(skipStatus == .pending)
    }

    @Test("Keep Separate applies only to two existing identities and is idempotent")
    func keepSeparateExistingIdentities() throws {
        let fixture = try ReviewFixture()
        let first = try fixture.library.createExercise(preferredName: "Strict Press")
        let second = try fixture.library.createExercise(preferredName: "Push Press")

        #expect(try fixture.service.keepSeparate(
            firstExerciseID: first.exercise.id,
            secondExerciseID: second.exercise.id
        ) == .keptSeparate)
        #expect(try fixture.service.keepSeparate(
            firstExerciseID: second.exercise.id,
            secondExerciseID: first.exercise.id
        ) == .keptSeparate)
        #expect(try fixture.library.separateExerciseDecisionCount() == 1)
        #expect(try fixture.library.allNames().count == 2)
    }

    @Test("Review-policy fixture dispositions are complete")
    func fixtureReport() throws {
        let document = try JSONDecoder().decode(
            ReviewFixtureDocument.self,
            from: Data(contentsOf: reviewFixtureURL())
        )
        #expect(document.cases.count == 6)

        for item in document.cases {
            let fixture = try ReviewFixture()
            _ = try fixture.library.createExercise(preferredName: item.candidate)
            try fixture.stage(item.observation, id: item.id)
            let candidate = try fixture.candidates(item.id).first { $0.preferredName == item.candidate }
            let actual = candidate?.linkAllowed == true ? "linkableWithConfirmation" : "identityConflict"
            #expect(actual == item.expectedDisposition, "\(item.id): expected \(item.expectedDisposition), got \(actual)")
        }
    }

    @Test("Staging is repeatable but an ID cannot be reused for different evidence")
    func stagedIdentityIsStable() throws {
        let fixture = try ReviewFixture()
        try fixture.stage("Front Squat", id: "stable")
        try fixture.stage("Front Squat", id: "stable")

        #expect(throws: ExerciseIdentityReviewError.observationIDConflict(.init(rawValue: "stable"))) {
            try fixture.stage("Reverse Lunge", id: "stable")
        }
    }

    @Test("Review queue is resumable and resolved identities leave it")
    func reviewQueueLifecycle() throws {
        let fixture = try ReviewFixture()
        try fixture.stage("First New Exercise", id: "first")
        try fixture.stage("Second New Exercise", id: "second")
        try fixture.stage("Third New Exercise", id: "third")

        #expect(try fixture.service.reviewQueue().map(\.observation.id.rawValue) == ["first", "second", "third"])
        _ = try fixture.service.deferDecision(observationID: .init(rawValue: "first"))
        #expect(try fixture.service.reviewQueue().map(\.observation.id.rawValue) == ["second", "third", "first"])

        _ = try fixture.service.create(observationID: .init(rawValue: "second"))
        let remaining = try fixture.service.reviewQueue()
        #expect(remaining.count == 2)
        #expect(remaining.map(\.observation.id.rawValue) == ["third", "first"])
        #expect(remaining.last?.status == .deferred)
    }
}

private struct ReviewFixtureDocument: Decodable {
    let cases: [ReviewFixtureCase]
}

private struct ReviewFixtureCase: Decodable {
    let id: String
    let observation: String
    let candidate: String
    let expectedDisposition: String
}

private func reviewFixtureURL() -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures/identity-review-cases.json")
}

private final class ReviewFixture {
    let directoryURL: URL
    let library: ExerciseLibrary
    let service: ExerciseIdentityReviewService

    init() throws {
        directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("gym-assistant-identity-review-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        library = try ExerciseLibrary(databaseURL: directoryURL.appendingPathComponent("library.sqlite"))
        service = ExerciseIdentityReviewService(library: library)
    }

    func stage(_ name: String, id: String) throws {
        try service.stage(.init(
            id: .init(rawValue: id),
            observedName: name,
            source: .init(adapter: "fixture", reference: id),
            occurrenceCount: 1
        ))
    }

    func candidates(_ id: String) throws -> [ExerciseReviewCandidate] {
        guard case .review(_, let candidates) = try service.prepare(
            observationID: .init(rawValue: id)
        ) else { return [] }
        return candidates
    }

    deinit {
        try? FileManager.default.removeItem(at: directoryURL)
    }
}
