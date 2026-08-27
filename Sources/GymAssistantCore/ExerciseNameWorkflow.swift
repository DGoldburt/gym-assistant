public struct ExerciseWorkflowMatch: Equatable, Sendable {
    public let exerciseID: ExerciseID
    public let preferredName: String

    public init(exerciseID: ExerciseID, preferredName: String) {
        self.exerciseID = exerciseID
        self.preferredName = preferredName
    }
}

public struct ExerciseWorkflowCandidate: Equatable, Sendable {
    public let exerciseID: ExerciseID
    public let preferredName: String
    public let score: Double

    public init(exerciseID: ExerciseID, preferredName: String, score: Double) {
        self.exerciseID = exerciseID
        self.preferredName = preferredName
        self.score = score
    }
}

public enum ExerciseWorkflowLookup: Equatable, Sendable {
    case exact(ExerciseWorkflowMatch)
    case review([ExerciseWorkflowCandidate])
    case noMatch
}

public final class ExerciseNameWorkflow {
    private let library: ExerciseLibrary
    private let candidateGenerator: ExerciseCandidateGenerator

    public init(
        library: ExerciseLibrary,
        candidateGenerator: ExerciseCandidateGenerator = .init()
    ) {
        self.library = library
        self.candidateGenerator = candidateGenerator
    }

    public func lookup(_ enteredName: String) throws -> ExerciseWorkflowLookup {
        if let confirmedName = try library.exactName(for: enteredName),
           let preferredName = try library.preferredName(for: confirmedName.exerciseID) {
            return .exact(.init(
                exerciseID: confirmedName.exerciseID,
                preferredName: preferredName.text
            ))
        }

        let preferredNames = try library.allPreferredNames()
        let namesByText = Dictionary(uniqueKeysWithValues: preferredNames.map { ($0.text, $0) })
        let ranked = candidateGenerator.rank(
            query: enteredName,
            candidates: preferredNames.map(\.text)
        ).compactMap { candidate -> ExerciseWorkflowCandidate? in
            guard let name = namesByText[candidate.preferredName] else { return nil }
            return .init(
                exerciseID: name.exerciseID,
                preferredName: name.text,
                score: candidate.score
            )
        }

        return ranked.isEmpty ? .noMatch : .review(ranked)
    }

    public func create(name: String) throws -> ExerciseWorkflowMatch {
        let created = try library.createExercise(preferredName: name, provenance: .userConfirmed)
        return .init(exerciseID: created.exercise.id, preferredName: created.preferredName.text)
    }

    public func link(enteredName: String, to exerciseID: ExerciseID) throws -> ExerciseWorkflowMatch {
        _ = try ExerciseSuggestionConfirmation(library: library).apply(
            enteredName: enteredName,
            decision: .accept(exerciseID: exerciseID)
        )
        guard let preferredName = try library.preferredName(for: exerciseID) else {
            throw ExerciseLibraryError.exerciseNotFound(exerciseID)
        }
        return .init(exerciseID: exerciseID, preferredName: preferredName.text)
    }

    public func makePreferred(name: String, for exerciseID: ExerciseID) throws -> ExerciseWorkflowMatch {
        let preferred = try library.setPreferredName(name, for: exerciseID)
        return .init(exerciseID: exerciseID, preferredName: preferred.text)
    }
}
