import Foundation
import Testing
@testable import GymAssistantCore

@Suite("Exercise name workflow")
struct ExerciseNameWorkflowTests {
    @Test("Obvious existing input bypasses review and writes")
    func exactExisting() throws {
        let fixture = try WorkflowFixture()
        let frontSquat = try fixture.library.createExercise(preferredName: "Front Squat")
        let before = try fixture.library.allPreferredNames()

        #expect(try fixture.workflow.lookup("  FRONT   SQUAT! ") == .exact(.init(
            exerciseID: frontSquat.exercise.id,
            preferredName: "Front Squat"
        )))
        #expect(try fixture.library.allPreferredNames().map(\.id) == before.map(\.id))
    }

    @Test("Ambiguous input remains reviewable without a write")
    func ambiguousReview() throws {
        let fixture = try WorkflowFixture()
        let copenhagen = try fixture.library.createExercise(preferredName: "Copenhagen Plank")

        guard case .review(let candidates) = try fixture.workflow.lookup("Short-Lever Copenhagen Plank") else {
            Issue.record("Expected a reviewable candidate")
            return
        }
        #expect(candidates.first?.exerciseID == copenhagen.exercise.id)
        #expect(candidates.first?.preferredName == "Copenhagen Plank")
        #expect(try fixture.library.exactName(for: "Short-Lever Copenhagen Plank") == nil)
    }

    @Test("Truly new input creates one immediately usable name")
    func trulyNew() throws {
        let fixture = try WorkflowFixture()
        let enteredName = "Tall Kneeling Bottoms-Up KB Press"

        #expect(try fixture.workflow.lookup(enteredName) == .noMatch)
        let created = try fixture.workflow.create(name: enteredName)

        let stored = try fixture.library.exactName(for: enteredName)
        #expect(stored?.exerciseID == created.exerciseID)
        #expect(stored?.text == enteredName)
        #expect(try fixture.library.allPreferredNames().count == 1)
    }

    @Test("Mistaken new input links to existing instead of creating")
    func mistakenNewLinksExisting() throws {
        let fixture = try WorkflowFixture()
        let existing = try fixture.library.createExercise(preferredName: "B-Stance RDL")

        guard case .review(let candidates) = try fixture.workflow.lookup("Kickstand RDL") else {
            Issue.record("Expected an existing candidate")
            return
        }
        #expect(candidates.first?.exerciseID == existing.exercise.id)

        let linked = try fixture.workflow.link(
            enteredName: "Kickstand RDL",
            to: existing.exercise.id
        )
        #expect(linked.preferredName == "B-Stance RDL")
        #expect(try fixture.library.exactName(for: "Kickstand RDL")?.exerciseID == existing.exercise.id)
        #expect(try fixture.library.allPreferredNames().count == 1)
    }
}

private final class WorkflowFixture {
    let directoryURL: URL
    let library: ExerciseLibrary
    let workflow: ExerciseNameWorkflow

    init() throws {
        directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("gym-assistant-workflow-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        library = try ExerciseLibrary(databaseURL: directoryURL.appendingPathComponent("exercise-library.sqlite"))
        workflow = ExerciseNameWorkflow(library: library)
    }

    deinit {
        try? FileManager.default.removeItem(at: directoryURL)
    }
}
