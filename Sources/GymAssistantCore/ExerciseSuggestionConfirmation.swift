public enum ExerciseSuggestionDecision: Sendable {
    case accept(exerciseID: ExerciseID)
    case reject
}

public enum ExerciseSuggestionDecisionResult: Equatable, Sendable {
    case aliasConfirmed(ExerciseName)
    case rejected
}

public struct ExerciseSuggestionConfirmation {
    private let library: ExerciseLibrary

    public init(library: ExerciseLibrary) {
        self.library = library
    }

    public func apply(
        enteredName: String,
        decision: ExerciseSuggestionDecision
    ) throws -> ExerciseSuggestionDecisionResult {
        switch decision {
        case .accept(let exerciseID):
            let name = try library.addName(
                enteredName,
                to: exerciseID,
                provenance: .userConfirmed
            )
            return .aliasConfirmed(name)
        case .reject:
            return .rejected
        }
    }
}
