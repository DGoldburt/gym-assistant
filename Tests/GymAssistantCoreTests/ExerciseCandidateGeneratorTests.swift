import Testing
@testable import GymAssistantCore

@Suite("Exercise candidate generator")
struct ExerciseCandidateGeneratorTests {
    private let generator = ExerciseCandidateGenerator()

    @Test("Ranks reviewable spelling and wording similarities")
    func ranksReviewableSimilarities() {
        #expect(generator.rank(
            query: "Paloff Press",
            candidates: ["Pallof Press", "Nordic Curl"]
        ).map(\.preferredName) == ["Pallof Press"])

        #expect(generator.rank(
            query: "Single-Arm Overhead Carry",
            candidates: ["One-Arm Overhead Carry"]
        ).map(\.preferredName) == ["One-Arm Overhead Carry"])
    }

    @Test("Excludes conflicting protected modifiers")
    func excludesProtectedModifierConflicts() {
        let conflicts = [
            ("Incline Dumbbell Bench Press", "Dumbbell Bench Press"),
            ("Single-Leg Squat", "Single-Leg Romanian Deadlift"),
            ("Half-Kneeling Landmine Press", "Standing Landmine Press"),
            ("Paused Back Squat", "Back Squat"),
            ("Goblet Squat", "Barbell Front Squat"),
            ("Short-Lever Copenhagen Plank", "Long-Lever Copenhagen Plank")
        ]

        for (query, candidate) in conflicts {
            #expect(generator.rank(query: query, candidates: [candidate]).isEmpty)
        }
    }

    @Test("Leaves unqualified Copenhagen reviewable")
    func leavesUnqualifiedCopenhagenReviewable() {
        #expect(generator.rank(
            query: "Short-Lever Copenhagen Plank",
            candidates: ["Copenhagen Plank"]
        ).map(\.preferredName) == ["Copenhagen Plank"])
    }
}
