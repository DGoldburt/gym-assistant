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

public struct ExerciseObservationOccurrence: Equatable, Sendable {
    public let sourceReference: String
    public let evidence: String
    public let occurrenceCount: Int

    public init(sourceReference: String, evidence: String, occurrenceCount: Int) {
        self.sourceReference = sourceReference
        self.evidence = evidence
        self.occurrenceCount = occurrenceCount
    }
}

public struct ExerciseObservationIngestion: Equatable, Sendable {
    public let id: String
    public let sourceKind: String
    public let sourceReference: String
    public let sourceFingerprint: String

    public init(id: String, sourceKind: String, sourceReference: String, sourceFingerprint: String) {
        self.id = id
        self.sourceKind = sourceKind
        self.sourceReference = sourceReference
        self.sourceFingerprint = sourceFingerprint
    }
}

public struct IngestedExerciseObservation: Equatable, Sendable {
    public let observation: StagedExerciseObservation
    public let occurrences: [ExerciseObservationOccurrence]

    public init(
        observation: StagedExerciseObservation,
        occurrences: [ExerciseObservationOccurrence]
    ) {
        self.observation = observation
        self.occurrences = occurrences
    }
}

public struct ExerciseObservationIngestionReport: Equatable, Sendable {
    public let alreadyIngested: Bool
    public let observationCount: Int
    public let occurrenceCount: Int
}

public struct ExerciseReviewQueueItem: Equatable, Sendable {
    public let observation: StagedExerciseObservation
    public let status: ExerciseObservationReviewStatus
    public let occurrences: [ExerciseObservationOccurrence]
}

public struct ExerciseObservationFeedbackRecord: Equatable, Sendable {
    public let observation: StagedExerciseObservation
    public let status: ExerciseObservationReviewStatus
    public let resolvedExerciseID: ExerciseID?
    public let evidenceSnapshot: String
    public let occurrences: [ExerciseObservationOccurrence]
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
    public let aliases: [String]
    public let matchedName: String
    public let evidence: [ExerciseReviewEvidence]
    public let linkAllowed: Bool
}

public struct ExerciseReviewTextRelation: Equatable, Sendable {
    public let evidence: ExerciseReviewEvidence
    public let linkAllowed: Bool
}

public struct ExerciseReviewCandidateEvaluator: Sendable {
    private let generator: ExerciseCandidateGenerator

    public init(candidateGenerator: ExerciseCandidateGenerator = .init()) {
        generator = candidateGenerator
    }

    public func evaluate(observation: String, candidate: String) -> ExerciseReviewTextRelation? {
        if let relation = explicitRelationship(observation: observation, candidate: candidate) {
            return relation
        }
        if let transformation = ReviewRelationshipPolicy.transformation(
            observation: observation,
            candidate: candidate
        ) {
            return .init(
                evidence: .conservativeTransformation(transformation),
                linkAllowed: true
            )
        }
        let forward = generator.rank(query: observation, candidates: [candidate]).first?.score
        let reverse = generator.rank(query: candidate, candidates: [observation]).first?.score
        guard let score = [forward, reverse].compactMap({ $0 }).max() else { return nil }
        return .init(evidence: .lexicalSimilarity(score: score), linkAllowed: true)
    }

    public func explicitRelationship(
        observation: String,
        candidate: String
    ) -> ExerciseReviewTextRelation? {
        guard let relation = ReviewRelationshipPolicy.relation(
            observation: observation,
            candidate: candidate
        ) else { return nil }
        switch relation {
        case .prescription(let reason):
            return .init(evidence: .prescriptionDifference(reason), linkAllowed: true)
        case .identityConflict(let reason):
            return .init(evidence: .identityConflict(reason), linkAllowed: false)
        }
    }
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

public struct ExerciseIdentityReviewUndoReceipt: Equatable, Sendable {
    public let observationID: ExerciseObservationID
    public let decision: ExerciseObservationReviewStatus
    public let previousStatus: ExerciseObservationReviewStatus
    public let resolvedExerciseID: ExerciseID?
    let previousEvidenceSnapshot: String
}

public enum ExerciseIdentityReviewError: Error, Equatable {
    case invalidOccurrenceCount
    case observationNotFound(ExerciseObservationID)
    case candidateNotLinkable(ExerciseID)
    case observationIDConflict(ExerciseObservationID)
    case incompatibleRepeatedDecision
    case sameExerciseCannotRemainSeparate
    case invalidIngestion
    case ingestionConflict(String)
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

    public func ingest(
        _ ingestion: ExerciseObservationIngestion,
        observations: [IngestedExerciseObservation]
    ) throws -> ExerciseObservationIngestionReport {
        guard !ingestion.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !ingestion.sourceKind.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !ingestion.sourceReference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !ingestion.sourceFingerprint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !observations.isEmpty,
              observations.allSatisfy({ item in
                  item.observation.occurrenceCount > 0 &&
                      !item.occurrences.isEmpty &&
                      item.occurrences.allSatisfy { $0.occurrenceCount > 0 } &&
                      Set(item.occurrences.map { "\($0.sourceReference)\u{0}\($0.evidence)" }).count
                        == item.occurrences.count
              }) else {
            throw ExerciseIdentityReviewError.invalidIngestion
        }
        return try library.ingestReviewObservations(ingestion, observations: observations)
    }

    public func feedbackRecords() throws -> [ExerciseObservationFeedbackRecord] {
        try library.reviewObservationFeedbackRecords()
    }

    public func reviewQueue() throws -> [ExerciseReviewQueueItem] {
        try library.reviewQueueItems().filter { item in
            try library.exactName(for: item.observation.observedName) == nil
        }
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
        let namesByExercise = Dictionary(grouping: allNames, by: \ExerciseName.exerciseID)
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
                if let forwardScore = rankedByName[name.text] {
                    rankedByName[name.text] = min(forwardScore, reverseScore)
                } else {
                    rankedByName[name.text] = reverseScore
                }
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
                        aliases: aliases(for: name.exerciseID, preferred: preferred, namesByExercise: namesByExercise),
                        matchedName: name.text,
                        evidence: [.prescriptionDifference(reason)],
                        linkAllowed: true
                    )
                case .identityConflict(let reason):
                    candidate = .init(
                        exerciseID: name.exerciseID,
                        preferredName: preferred.text,
                        aliases: aliases(for: name.exerciseID, preferred: preferred, namesByExercise: namesByExercise),
                        matchedName: name.text,
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
                    aliases: aliases(for: name.exerciseID, preferred: preferred, namesByExercise: namesByExercise),
                    matchedName: name.text,
                    evidence: [.conservativeTransformation(transformation)],
                    linkAllowed: true
                )
            } else if let score = rankedByName[name.text] {
                candidate = .init(
                    exerciseID: name.exerciseID,
                    preferredName: preferred.text,
                    aliases: aliases(for: name.exerciseID, preferred: preferred, namesByExercise: namesByExercise),
                    matchedName: name.text,
                    evidence: [.lexicalSimilarity(score: score)],
                    linkAllowed: true
                )
            } else {
                candidate = nil
            }

            guard let candidate else { continue }
            if let existing = bestByExercise[name.exerciseID] {
                let existingPriority = evidencePriority(existing)
                let candidatePriority = evidencePriority(candidate)
                if existingPriority > candidatePriority ||
                    (existingPriority == candidatePriority &&
                     !lexicalEvidenceRanksBefore(candidate, existing)) {
                    continue
                }
            }
            bestByExercise[name.exerciseID] = candidate
        }

        let candidates = bestByExercise.values.sorted { lhs, rhs in
            if lhs.linkAllowed != rhs.linkAllowed { return lhs.linkAllowed }
            if lexicalEvidenceRanksBefore(lhs, rhs) { return true }
            if lexicalEvidenceRanksBefore(rhs, lhs) { return false }
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

    public func linkWithUndoReceipt(
        observationID: ExerciseObservationID,
        to exerciseID: ExerciseID
    ) throws -> (ExerciseIdentityReviewResult, ExerciseIdentityReviewUndoReceipt) {
        guard let stored = try library.storedReviewObservation(observationID) else {
            throw ExerciseIdentityReviewError.observationNotFound(observationID)
        }
        let result = try link(observationID: observationID, to: exerciseID)
        return (result, .init(
            observationID: observationID,
            decision: .linked,
            previousStatus: stored.status,
            resolvedExerciseID: exerciseID,
            previousEvidenceSnapshot: stored.evidenceSnapshot
        ))
    }

    public func createWithUndoReceipt(
        observationID: ExerciseObservationID
    ) throws -> (ExerciseIdentityReviewResult, ExerciseIdentityReviewUndoReceipt) {
        guard let stored = try library.storedReviewObservation(observationID) else {
            throw ExerciseIdentityReviewError.observationNotFound(observationID)
        }
        let result = try create(observationID: observationID)
        let decision: ExerciseObservationReviewStatus
        let exerciseID: ExerciseID
        switch result {
        case .created(let match):
            decision = .created
            exerciseID = match.exerciseID
        case .linked(let match):
            decision = .linked
            exerciseID = match.exerciseID
        default:
            throw ExerciseIdentityReviewError.incompatibleRepeatedDecision
        }
        return (result, .init(
            observationID: observationID,
            decision: decision,
            previousStatus: stored.status,
            resolvedExerciseID: exerciseID,
            previousEvidenceSnapshot: stored.evidenceSnapshot
        ))
    }

    public func skipWithUndoReceipt(
        observationID: ExerciseObservationID
    ) throws -> (ExerciseIdentityReviewResult, ExerciseIdentityReviewUndoReceipt) {
        guard let stored = try library.storedReviewObservation(observationID) else {
            throw ExerciseIdentityReviewError.observationNotFound(observationID)
        }
        let result = try deferDecision(observationID: observationID)
        return (result, .init(
            observationID: observationID,
            decision: .deferred,
            previousStatus: stored.status,
            resolvedExerciseID: nil,
            previousEvidenceSnapshot: stored.evidenceSnapshot
        ))
    }

    public func undo(_ receipt: ExerciseIdentityReviewUndoReceipt) throws {
        try library.undoReviewDecisionAtomically(receipt)
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

    private func aliases(
        for exerciseID: ExerciseID,
        preferred: ExerciseName,
        namesByExercise: [ExerciseID: [ExerciseName]]
    ) -> [String] {
        namesByExercise[exerciseID, default: []]
            .filter { $0.id != preferred.id }
            .map(\.text)
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private func lexicalEvidenceRanksBefore(
        _ lhs: ExerciseReviewCandidate,
        _ rhs: ExerciseReviewCandidate
    ) -> Bool {
        guard case .lexicalSimilarity(let lhsScore) = lhs.evidence.first,
              case .lexicalSimilarity(let rhsScore) = rhs.evidence.first else { return false }
        return lhsScore > rhsScore
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
