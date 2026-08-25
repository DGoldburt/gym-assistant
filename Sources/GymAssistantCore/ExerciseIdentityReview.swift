import Foundation

public struct ExerciseObservationID: Hashable, Sendable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct ExerciseObservationSource: Equatable, Sendable {
    public let adapter: String
    public let reference: String

    public init(adapter: String, reference: String) {
        self.adapter = adapter
        self.reference = reference
    }
}

public struct StagedExerciseObservation: Equatable, Sendable {
    public let id: ExerciseObservationID
    public let observedName: String
    public let source: ExerciseObservationSource
    public let occurrenceCount: Int

    public init(
        id: ExerciseObservationID,
        observedName: String,
        source: ExerciseObservationSource,
        occurrenceCount: Int
    ) {
        self.id = id
        self.observedName = observedName
        self.source = source
        self.occurrenceCount = occurrenceCount
    }
}

public enum ExerciseReviewEvidence: Equatable, Sendable {
    case conservativeTransformation(String)
    case lexicalSimilarity(score: Double)
    case prescriptionDifference(String)
    case identityConflict(String)
}

public struct ExerciseReviewCandidate: Equatable, Sendable {
    public let exerciseID: ExerciseID
    public let preferredName: String
    public let evidence: [ExerciseReviewEvidence]
    public let linkAllowed: Bool
}

public enum ExerciseObservationReviewStatus: String, Equatable, Sendable {
    case pending
    case deferred
    case linked
    case created
}

public enum ExerciseReviewPreparation: Equatable, Sendable {
    case alreadyResolved(ExerciseWorkflowMatch)
    case review(status: ExerciseObservationReviewStatus, candidates: [ExerciseReviewCandidate])
}

public enum ExerciseIdentityReviewResult: Equatable, Sendable {
    case linked(ExerciseWorkflowMatch)
    case created(ExerciseWorkflowMatch)
    case deferred
    case keptSeparate
}

public enum ExerciseIdentityReviewError: Error, Equatable {
    case invalidOccurrenceCount
    case observationNotFound(ExerciseObservationID)
    case candidateNotLinkable(ExerciseID)
    case observationIDConflict(ExerciseObservationID)
    case incompatibleRepeatedDecision
    case sameExerciseCannotRemainSeparate
}

public final class ExerciseIdentityReviewService {
    private let library: ExerciseLibrary
    private let candidateGenerator: ExerciseCandidateGenerator

    public init(library: ExerciseLibrary, candidateGenerator: ExerciseCandidateGenerator = .init()) {
        self.library = library
        self.candidateGenerator = candidateGenerator
    }

    public func stage(_ observation: StagedExerciseObservation) throws {
        guard observation.occurrenceCount > 0 else {
            throw ExerciseIdentityReviewError.invalidOccurrenceCount
        }
        if let existing = try library.storedReviewObservation(observation.id),
           existing.observation.observedName != observation.observedName.trimmingCharacters(in: .whitespacesAndNewlines)
            || existing.observation.source != observation.source {
            throw ExerciseIdentityReviewError.observationIDConflict(observation.id)
        }
        try library.stageReviewObservation(observation)
    }

    public func prepare(observationID: ExerciseObservationID) throws -> ExerciseReviewPreparation {
        guard let stored = try library.storedReviewObservation(observationID) else {
            throw ExerciseIdentityReviewError.observationNotFound(observationID)
        }

        if let existing = try library.exactName(for: stored.observedName),
           let preferred = try library.preferredName(for: existing.exerciseID) {
            return .alreadyResolved(.init(exerciseID: existing.exerciseID, preferredName: preferred.text))
        }

        let preferredNames = try library.allPreferredNames()
        let allNames = try library.allNames()
        let preferredByExercise = Dictionary(uniqueKeysWithValues: preferredNames.map { ($0.exerciseID, $0) })
        let forwardRanked = candidateGenerator.rank(
            query: stored.observedName,
            candidates: allNames.map(\.text)
        )
        var rankedByName = Dictionary(uniqueKeysWithValues: forwardRanked.map { ($0.preferredName, $0.score) })
        for name in allNames {
            let reverseScore = candidateGenerator.rank(
                query: name.text,
                candidates: [stored.observedName]
            ).first?.score
            if let reverseScore {
                rankedByName[name.text] = max(rankedByName[name.text] ?? 0, reverseScore)
            }
        }

        var bestByExercise: [ExerciseID: ExerciseReviewCandidate] = [:]
        for name in allNames {
            guard let preferred = preferredByExercise[name.exerciseID] else { continue }
            let candidate: ExerciseReviewCandidate?
            if let relation = ReviewRelationshipPolicy.relation(
                observation: stored.observedName,
                candidate: name.text
            ) {
                switch relation {
                case .prescription(let reason):
                    candidate = .init(
                        exerciseID: name.exerciseID,
                        preferredName: preferred.text,
                        evidence: [.prescriptionDifference(reason)],
                        linkAllowed: true
                    )
                case .identityConflict(let reason):
                    candidate = .init(
                        exerciseID: name.exerciseID,
                        preferredName: preferred.text,
                        evidence: [.identityConflict(reason)],
                        linkAllowed: false
                    )
                }
            } else if let transformation = ReviewRelationshipPolicy.transformation(
                observation: stored.observedName,
                candidate: name.text
            ) {
                candidate = .init(
                    exerciseID: name.exerciseID,
                    preferredName: preferred.text,
                    evidence: [.conservativeTransformation(transformation)],
                    linkAllowed: true
                )
            } else if let score = rankedByName[name.text] {
                candidate = .init(
                    exerciseID: name.exerciseID,
                    preferredName: preferred.text,
                    evidence: [.lexicalSimilarity(score: score)],
                    linkAllowed: true
                )
            } else {
                candidate = nil
            }

            guard let candidate else { continue }
            if let existing = bestByExercise[name.exerciseID],
               evidencePriority(existing) >= evidencePriority(candidate) {
                continue
            }
            bestByExercise[name.exerciseID] = candidate
        }

        let candidates = bestByExercise.values.sorted { lhs, rhs in
            if lhs.linkAllowed != rhs.linkAllowed { return lhs.linkAllowed }
            return lhs.preferredName.localizedCaseInsensitiveCompare(rhs.preferredName) == .orderedAscending
        }

        return .review(status: stored.status, candidates: candidates)
    }

    public func link(
        observationID: ExerciseObservationID,
        to exerciseID: ExerciseID
    ) throws -> ExerciseIdentityReviewResult {
        guard let stored = try library.storedReviewObservation(observationID) else {
            throw ExerciseIdentityReviewError.observationNotFound(observationID)
        }
        if stored.status == .linked, stored.resolvedExerciseID == exerciseID,
           let preferred = try library.preferredName(for: exerciseID) {
            return .linked(.init(exerciseID: exerciseID, preferredName: preferred.text))
        }
        guard stored.status == .pending || stored.status == .deferred else {
            throw ExerciseIdentityReviewError.incompatibleRepeatedDecision
        }
        guard case .review(_, let candidates) = try prepare(observationID: observationID),
              candidates.contains(where: { $0.exerciseID == exerciseID && $0.linkAllowed }) else {
            throw ExerciseIdentityReviewError.candidateNotLinkable(exerciseID)
        }

        _ = try library.linkReviewObservationAtomically(
            observationID,
            observedName: stored.observedName,
            to: exerciseID
        )
        guard let preferred = try library.preferredName(for: exerciseID) else {
            throw ExerciseLibraryError.exerciseNotFound(exerciseID)
        }
        return .linked(.init(exerciseID: exerciseID, preferredName: preferred.text))
    }

    public func create(observationID: ExerciseObservationID) throws -> ExerciseIdentityReviewResult {
        guard let stored = try library.storedReviewObservation(observationID) else {
            throw ExerciseIdentityReviewError.observationNotFound(observationID)
        }
        if stored.status == .created, let exerciseID = stored.resolvedExerciseID,
           let preferred = try library.preferredName(for: exerciseID) {
            return .created(.init(exerciseID: exerciseID, preferredName: preferred.text))
        }
        guard stored.status == .pending || stored.status == .deferred else {
            throw ExerciseIdentityReviewError.incompatibleRepeatedDecision
        }
        if let existing = try library.exactName(for: stored.observedName),
           let preferred = try library.preferredName(for: existing.exerciseID) {
            try library.resolveReviewObservation(
                observationID,
                status: .linked,
                exerciseID: existing.exerciseID
            )
            return .linked(.init(
                exerciseID: existing.exerciseID,
                preferredName: preferred.text
            ))
        }
        let created = try library.createReviewObservationAtomically(
            observationID,
            observedName: stored.observedName
        )
        let match = ExerciseWorkflowMatch(
            exerciseID: created.exercise.id,
            preferredName: created.preferredName.text
        )
        return .created(match)
    }

    public func deferDecision(observationID: ExerciseObservationID) throws -> ExerciseIdentityReviewResult {
        guard let stored = try library.storedReviewObservation(observationID) else {
            throw ExerciseIdentityReviewError.observationNotFound(observationID)
        }
        if stored.status == .deferred { return .deferred }
        guard stored.status == .pending else {
            throw ExerciseIdentityReviewError.incompatibleRepeatedDecision
        }
        let snapshot = try candidateSnapshot(observationID)
        try library.deferReviewObservation(observationID, evidenceSnapshot: snapshot)
        return .deferred
    }

    public func keepSeparate(
        firstExerciseID: ExerciseID,
        secondExerciseID: ExerciseID
    ) throws -> ExerciseIdentityReviewResult {
        guard firstExerciseID != secondExerciseID else {
            throw ExerciseIdentityReviewError.sameExerciseCannotRemainSeparate
        }
        try library.recordSeparateExercises(firstExerciseID, secondExerciseID)
        return .keptSeparate
    }

    private func candidateSnapshot(_ id: ExerciseObservationID) throws -> String {
        guard case .review(_, let candidates) = try prepare(observationID: id) else { return "" }
        return candidates.map { candidate in
            "\(candidate.exerciseID.rawValue.uuidString)|\(candidate.linkAllowed)|\(candidate.preferredName)"
        }.joined(separator: "\n")
    }

    private func evidencePriority(_ candidate: ExerciseReviewCandidate) -> Int {
        guard let evidence = candidate.evidence.first else { return 0 }
        switch evidence {
        case .identityConflict: return 4
        case .prescriptionDifference: return 3
        case .conservativeTransformation: return 2
        case .lexicalSimilarity: return 1
        }
    }
}

enum ReviewRelationshipPolicy {
    enum Relation {
        case prescription(String)
        case identityConflict(String)
    }

    static func relation(observation: String, candidate: String) -> Relation? {
        let pair = Set([comparable(observation), comparable(candidate)])
        if pair == Set(["lateral lunge", "reverse lunge"]) {
            return .identityConflict("plane of motion changes the exercise identity")
        }
        if pair == Set(["single leg squat", "single leg romanian deadlift"]) {
            return .identityConflict("squat and hinge are different movement identities")
        }

        let combined = pair.joined(separator: " ")
        if combined.contains("copenhagen plank") &&
            (combined.contains("short lever") || combined.contains("long lever")) {
            return .prescription("lever length changes the prescription")
        }
        if combined.contains("touch down") &&
            (combined.contains("rnt") || combined.contains("sec negative")) {
            return .prescription("RNT or eccentric duration is preserved in the confirmed name")
        }
        return nil
    }

    static func transformation(observation: String, candidate: String) -> String? {
        let expandedObservation = expandAbbreviations(observation)
        let expandedCandidate = expandAbbreviations(candidate)
        guard expandedObservation == expandedCandidate,
              comparable(observation) != comparable(candidate) else { return nil }
        return "approved abbreviation expansion"
    }

    private static func expandAbbreviations(_ text: String) -> String {
        comparable(text).split(separator: " ").flatMap { token -> [String] in
            switch token {
            case "db": return ["dumbbell"]
            case "kb": return ["kettlebell"]
            case "sl": return ["single", "leg"]
            default: return [String(token)]
            }
        }.joined(separator: " ")
    }

    private static func comparable(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .split { !$0.isLetter && !$0.isNumber }
            .joined(separator: " ")
    }
}
