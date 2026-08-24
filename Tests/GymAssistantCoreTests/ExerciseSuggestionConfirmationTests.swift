import Foundation
import Testing
@testable import GymAssistantCore

@Suite("Exercise suggestion confirmation")
struct ExerciseSuggestionConfirmationTests {
    @Test("Accepted suggestion becomes a deterministic confirmed-name lookup")
    func acceptanceCreatesDurableAlias() throws {
        let fixture = try ConfirmationFixture()
        let exercise = try fixture.library.createExercise(preferredName: "Copenhagen Plank")
        let generator = ExerciseCandidateGenerator()

        #expect(try fixture.library.exactName(for: "Coppenhagen") == nil)
        #expect(generator.rank(
            query: "Coppenhagen",
            candidates: [exercise.preferredName.text]
        ).map(\.preferredName) == ["Copenhagen Plank"])

        let confirmation = ExerciseSuggestionConfirmation(library: fixture.library)
        let result = try confirmation.apply(
            enteredName: "Coppenhagen",
            decision: .accept(exerciseID: exercise.exercise.id)
        )

        guard case .aliasConfirmed(let confirmedAlias) = result else {
            Issue.record("Expected an accepted alias")
            return
        }
        #expect(confirmedAlias.exerciseID == exercise.exercise.id)
        #expect(confirmedAlias.provenance == .userConfirmed)

        let repeatedResult = try confirmation.apply(
            enteredName: "  COPPENHAGEN ",
            decision: .accept(exerciseID: exercise.exercise.id)
        )
        guard case .aliasConfirmed(let repeatedAlias) = repeatedResult else {
            Issue.record("Expected repeated acceptance to return the confirmed alias")
            return
        }
        #expect(repeatedAlias.id == confirmedAlias.id)
        #expect(repeatedAlias.exerciseID == confirmedAlias.exerciseID)
        #expect(repeatedAlias.normalizedText == confirmedAlias.normalizedText)
        #expect(repeatedAlias.provenance == confirmedAlias.provenance)

        let nextLookup = try fixture.library.exactName(for: "  COPPENHAGEN ")
        #expect(nextLookup?.id == confirmedAlias.id)
        #expect(nextLookup?.exerciseID == exercise.exercise.id)
    }

    @Test("Rejected suggestion creates no durable relationship")
    func rejectionDoesNotCreateAlias() throws {
        let fixture = try ConfirmationFixture()
        let exercise = try fixture.library.createExercise(preferredName: "Pallof Press")
        let generator = ExerciseCandidateGenerator()

        #expect(generator.rank(
            query: "Paloff Press",
            candidates: [exercise.preferredName.text]
        ).map(\.preferredName) == ["Pallof Press"])

        let result = try ExerciseSuggestionConfirmation(library: fixture.library).apply(
            enteredName: "Paloff Press",
            decision: .reject
        )

        #expect(result == .rejected)
        #expect(try fixture.library.exactName(for: "Paloff Press") == nil)
        #expect(generator.rank(
            query: "Paloff Press",
            candidates: [exercise.preferredName.text]
        ).map(\.preferredName) == ["Pallof Press"])
    }
}

private final class ConfirmationFixture {
    let directoryURL: URL
    let library: ExerciseLibrary

    init() throws {
        directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("gym-assistant-confirmation-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        library = try ExerciseLibrary(databaseURL: directoryURL.appendingPathComponent("exercise-library.sqlite"))
    }

    deinit {
        try? FileManager.default.removeItem(at: directoryURL)
    }
}
