import Testing
@testable import GymAssistantCore

@Suite("Deterministic exercise-name resolver")
struct DeterministicExerciseNameResolverTests {
    private let normalizer = BasicExerciseNameNormalizer()
    private let resolver = DeterministicExerciseNameResolver()

    @Test("Normalizer removes approved cosmetic differences")
    func approvedCosmeticNormalization() throws {
        #expect(try normalizer.normalize(" FRONT   SQUAT ") == "front squat")
        #expect(try normalizer.normalize("Front Squat!") == "front squat")
        #expect(try normalizer.normalize("Front Squat.") == "front squat")
    }

    @Test("Normalizer preserves meaningful punctuation")
    func meaningfulPunctuationIsPreserved() throws {
        #expect(try normalizer.normalize("1.5-Rep Squat") == "1.5-rep squat")
        #expect(try normalizer.normalize("A1") == "a1")
        #expect(try normalizer.normalize("Front Squat/Back Squat") == "front squat/back squat")
    }

    @Test("Only confirmed names establish deterministic identity")
    func confirmedNameOwnershipRequired() throws {
        #expect(try resolver.matchesConfirmedName(
            query: "  sl   rdl ",
            confirmedNames: ["SL RDL"]
        ))
        #expect(!(try resolver.matchesConfirmedName(
            query: "DB Floor Press",
            confirmedNames: ["Dumbbell Floor Press"]
        )))
        #expect(!(try resolver.matchesConfirmedName(
            query: "Coppenhagen",
            confirmedNames: ["Copenhagen Plank"]
        )))
    }
}
