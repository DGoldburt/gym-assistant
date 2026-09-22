import Foundation

public enum FeedbackWorkflow: String, Codable, Sendable {
    case autocomplete
    case identityReview
}

public enum FeedbackOutcomeKind: String, Codable, Sendable {
    case insertedCandidate, insertedQuery, linked, created, skipped, backed, cancelled, opened
}

public struct FeedbackCandidateSnapshot: Codable, Equatable, Sendable {
    public let rank: Int
    public let exerciseID: String
    public let preferredName: String
    public let matchedName: String
    public let aliases: [String]
    public let evidence: [String]
    public let score: Double?
    public let linkAllowed: Bool

    public init(rank: Int, exerciseID: String, preferredName: String, matchedName: String,
                aliases: [String], evidence: [String], score: Double?, linkAllowed: Bool) {
        self.rank = rank
        self.exerciseID = exerciseID
        self.preferredName = preferredName
        self.matchedName = matchedName
        self.aliases = aliases
        self.evidence = evidence
        self.score = score
        self.linkAllowed = linkAllowed
    }
}

public struct FeedbackOutcome: Codable, Equatable, Sendable {
    public let kind: FeedbackOutcomeKind
    public let selectedRank: Int?
    public let selectedName: String?

    public init(kind: FeedbackOutcomeKind, selectedRank: Int? = nil, selectedName: String? = nil) {
        self.kind = kind
        self.selectedRank = selectedRank
        self.selectedName = selectedName
    }
}

public struct FeedbackInteraction: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1
    public let schemaVersion: Int
    public let eventID: UUID
    public let sessionID: UUID
    public let recordedAt: Date
    public let workflow: FeedbackWorkflow
    public let queryOrObservation: String
    public let observationID: String?
    public let candidates: [FeedbackCandidateSnapshot]
    public let outcome: FeedbackOutcome
    public let durationMilliseconds: Int?
    public let aliasesExpanded: Bool
    public let deactivationCount: Int
    public let returnedAfterDeactivation: Bool
    public let lastReturnToOutcomeMilliseconds: Int?
    public let userFlagged: Bool

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, eventID, sessionID, recordedAt, workflow, queryOrObservation,
             observationID, candidates, outcome, durationMilliseconds, aliasesExpanded,
             deactivationCount, returnedAfterDeactivation, lastReturnToOutcomeMilliseconds,
             userFlagged
    }

    public init(schemaVersion: Int = FeedbackInteraction.currentSchemaVersion,
                eventID: UUID = UUID(), sessionID: UUID, recordedAt: Date = Date(),
                workflow: FeedbackWorkflow, queryOrObservation: String, observationID: String? = nil,
                candidates: [FeedbackCandidateSnapshot], outcome: FeedbackOutcome,
                durationMilliseconds: Int? = nil, aliasesExpanded: Bool = false,
                deactivationCount: Int = 0, returnedAfterDeactivation: Bool = false,
                lastReturnToOutcomeMilliseconds: Int? = nil,
                userFlagged: Bool = false) {
        self.schemaVersion = schemaVersion
        self.eventID = eventID
        self.sessionID = sessionID
        self.recordedAt = recordedAt
        self.workflow = workflow
        self.queryOrObservation = queryOrObservation
        self.observationID = observationID
        self.candidates = candidates
        self.outcome = outcome
        self.durationMilliseconds = durationMilliseconds
        self.aliasesExpanded = aliasesExpanded
        self.deactivationCount = deactivationCount
        self.returnedAfterDeactivation = returnedAfterDeactivation
        self.lastReturnToOutcomeMilliseconds = lastReturnToOutcomeMilliseconds
        self.userFlagged = userFlagged
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try values.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? Self.currentSchemaVersion
        eventID = try values.decode(UUID.self, forKey: .eventID)
        sessionID = try values.decode(UUID.self, forKey: .sessionID)
        recordedAt = try values.decode(Date.self, forKey: .recordedAt)
        workflow = try values.decode(FeedbackWorkflow.self, forKey: .workflow)
        queryOrObservation = try values.decode(String.self, forKey: .queryOrObservation)
        observationID = try values.decodeIfPresent(String.self, forKey: .observationID)
        candidates = try values.decode([FeedbackCandidateSnapshot].self, forKey: .candidates)
        outcome = try values.decode(FeedbackOutcome.self, forKey: .outcome)
        durationMilliseconds = try values.decodeIfPresent(Int.self, forKey: .durationMilliseconds)
        aliasesExpanded = try values.decode(Bool.self, forKey: .aliasesExpanded)
        deactivationCount = try values.decode(Int.self, forKey: .deactivationCount)
        returnedAfterDeactivation = try values.decode(Bool.self, forKey: .returnedAfterDeactivation)
        lastReturnToOutcomeMilliseconds = try values.decodeIfPresent(Int.self, forKey: .lastReturnToOutcomeMilliseconds)
        userFlagged = try values.decode(Bool.self, forKey: .userFlagged)
    }
}

public struct FeedbackSignal: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case userFlag, scoreInversion, exactTransformBelowLexical, protectedConflictLinkable,
             unstableReplay, frequentNonTopChoice, focusFriction
    }
    public let id: String
    public let kind: Kind
    public let summary: String
    public let eventIDs: [UUID]

    public init(id: String, kind: Kind, summary: String, eventIDs: [UUID]) {
        self.id = id; self.kind = kind; self.summary = summary; self.eventIDs = eventIDs
    }
}

public enum FeedbackSignalDisposition: String, Codable, Sendable {
    case new, reproduced, acceptedForBatch, deferred, resolved
}

public struct FeedbackDispositionChange: Codable, Equatable, Sendable {
    public let from: FeedbackSignalDisposition
    public let to: FeedbackSignalDisposition
    public let changedAt: Date
    public let authority: String
    public let rationale: String?

    public init(from: FeedbackSignalDisposition, to: FeedbackSignalDisposition,
                changedAt: Date = Date(), authority: String, rationale: String? = nil) {
        self.from = from
        self.to = to
        self.changedAt = changedAt
        self.authority = authority
        self.rationale = rationale
    }
}

public struct FeedbackLedgerEntry: Codable, Equatable, Sendable {
    public let signal: FeedbackSignal
    public var occurrenceCount: Int
    public var disposition: FeedbackSignalDisposition
    public var lastSeenAt: Date
    public var dispositionHistory: [FeedbackDispositionChange]

    public init(signal: FeedbackSignal, occurrenceCount: Int,
                disposition: FeedbackSignalDisposition, lastSeenAt: Date,
                dispositionHistory: [FeedbackDispositionChange] = []) {
        self.signal = signal
        self.occurrenceCount = occurrenceCount
        self.disposition = disposition
        self.lastSeenAt = lastSeenAt
        self.dispositionHistory = dispositionHistory
    }

    private enum CodingKeys: String, CodingKey {
        case signal, occurrenceCount, disposition, lastSeenAt, dispositionHistory
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        signal = try values.decode(FeedbackSignal.self, forKey: .signal)
        occurrenceCount = try values.decode(Int.self, forKey: .occurrenceCount)
        disposition = try values.decode(FeedbackSignalDisposition.self, forKey: .disposition)
        lastSeenAt = try values.decode(Date.self, forKey: .lastSeenAt)
        dispositionHistory = try values.decodeIfPresent(
            [FeedbackDispositionChange].self,
            forKey: .dispositionHistory
        ) ?? []
    }
}

public struct FeedbackReviewCase: Equatable, Sendable {
    public let entry: FeedbackLedgerEntry
    public let firstObservedAt: Date?
    public let lastObservedAt: Date?
    public let interactions: [FeedbackInteraction]
}

public struct FeedbackReviewPacketBuilder: Sendable {
    public init() {}

    public func openCases(ledger: [FeedbackLedgerEntry],
                          interactions: [FeedbackInteraction]) -> [FeedbackReviewCase] {
        cases(
            ledger: ledger,
            interactions: interactions,
            dispositions: [.new, .reproduced]
        )
    }

    public func acceptedBatchCases(ledger: [FeedbackLedgerEntry],
                                   interactions: [FeedbackInteraction]) -> [FeedbackReviewCase] {
        cases(
            ledger: ledger,
            interactions: interactions,
            dispositions: [.acceptedForBatch]
        )
    }

    private func cases(ledger: [FeedbackLedgerEntry],
                       interactions: [FeedbackInteraction],
                       dispositions: Set<FeedbackSignalDisposition>) -> [FeedbackReviewCase] {
        let byID = Dictionary(uniqueKeysWithValues: interactions.map { ($0.eventID, $0) })
        return ledger
            .filter { dispositions.contains($0.disposition) }
            .map { entry in
                let evidence = entry.signal.eventIDs.compactMap { byID[$0] }
                    .sorted { $0.recordedAt < $1.recordedAt }
                return FeedbackReviewCase(
                    entry: entry,
                    firstObservedAt: evidence.first?.recordedAt,
                    lastObservedAt: evidence.last?.recordedAt,
                    interactions: evidence
                )
            }
            .sorted {
                ($0.firstObservedAt ?? .distantFuture, $0.entry.signal.id)
                    < ($1.firstObservedAt ?? .distantFuture, $1.entry.signal.id)
            }
    }
}

public struct FeedbackReport: Codable, Equatable, Sendable {
    public let interactionCount: Int
    public let signals: [FeedbackSignal]
    public let topResultAcceptanceRate: Double?
    public let medianSelectedRank: Double?
    public let rawQueryInsertionCount: Int
    public let skipCount: Int
    public let identityReviewUndoCount: Int
    public let cancellationCount: Int
    public let identityReviewSessionCount: Int
    public let identityReviewZeroDecisionSessionCount: Int
    public let identityReviewDecisionCount: Int
    public let identityReviewDecisionsPerSession: Double?
    public let identityReviewSkipRate: Double?
    public let identityReviewMedianTimeToFirstDecisionMilliseconds: Double?
    public let interactionTrend: FeedbackInteractionTrend
}

public struct FeedbackMetricWindow: Codable, Equatable, Sendable {
    public let interactionCount: Int
    public let cancellationRate: Double?
    public let committedSelectionCount: Int
    public let topResultAcceptanceRate: Double?
    public let medianSelectedRank: Double?
    public let userFlagCount: Int
    public let focusLossInteractionRate: Double?
}

public struct FeedbackInteractionTrend: Codable, Equatable, Sendable {
    public let windowSize: Int
    public let recent: FeedbackMetricWindow
    public let previous: FeedbackMetricWindow
}

public struct FeedbackEvaluator: Sendable {
    public init() {}

    public func evaluate(_ interactions: [FeedbackInteraction]) -> FeedbackReport {
        var signals: [FeedbackSignal] = []
        for interaction in interactions {
            if interaction.userFlagged {
                signals.append(signal(.userFlag, interaction, "User flagged a surprising result"))
            }
            if hasScoreInversion(interaction.candidates) {
                signals.append(signal(.scoreInversion, interaction, "A lower-scored candidate ranked above a higher-scored candidate"))
            }
            if exactTransformRanksBelowLexical(interaction.candidates) {
                signals.append(signal(.exactTransformBelowLexical, interaction, "An approved exact transformation ranked below lexical evidence"))
            }
            if interaction.candidates.contains(where: { $0.linkAllowed && $0.evidence.contains(where: { $0.localizedCaseInsensitiveContains("cannot link") || $0.localizedCaseInsensitiveContains("conflict") }) }) {
                signals.append(signal(.protectedConflictLinkable, interaction, "A protected identity conflict was linkable"))
            }
            if interaction.deactivationCount > 0 {
                signals.append(signal(.focusFriction, interaction, "The interaction lost focus before completion"))
            }
        }
        signals.append(contentsOf: unstableReplaySignals(interactions))
        let selectedRanks = interactions.compactMap { interaction -> Int? in
            switch interaction.outcome.kind {
            case .insertedCandidate, .linked:
                return interaction.outcome.selectedRank
            default:
                return nil
            }
        }.sorted()
        let top = selectedRanks.filter { $0 == 1 }.count
        if selectedRanks.count >= 3, top * 2 < selectedRanks.count {
            let key = "frequentNonTopChoice|aggregate"
            signals.append(.init(
                id: Self.stableID(key),
                kind: .frequentNonTopChoice,
                summary: "More than half of candidate selections were below the top-ranked result",
                eventIDs: interactions.filter {
                    ($0.outcome.kind == .insertedCandidate || $0.outcome.kind == .linked)
                        && ($0.outcome.selectedRank ?? 1) > 1
                }.map(\.eventID)
            ))
        }
        let reviewSessions = Dictionary(
            grouping: interactions.filter { $0.workflow == .identityReview },
            by: \.sessionID
        )
        let reviewDecisionKinds: Set<FeedbackOutcomeKind> = [.linked, .created, .skipped]
        let reviewDecisionCount = reviewSessions.values.reduce(into: 0) { count, events in
            count += events.filter { reviewDecisionKinds.contains($0.outcome.kind) }.count
        }
        let reviewZeroDecisionSessionCount = reviewSessions.values.filter { events in
            !events.contains { reviewDecisionKinds.contains($0.outcome.kind) }
        }.count
        let firstDecisionDurations = reviewSessions.values.compactMap { events -> Int? in
            events
                .filter { reviewDecisionKinds.contains($0.outcome.kind) }
                .min { $0.recordedAt < $1.recordedAt }?
                .durationMilliseconds
        }.sorted()
        let reviewSkipCount = interactions.filter {
            $0.workflow == .identityReview && $0.outcome.kind == .skipped
        }.count
        let orderedInteractions = interactions.sorted { $0.recordedAt < $1.recordedAt }
        let trendWindowSize = 10
        let recentInteractions = Array(orderedInteractions.suffix(trendWindowSize))
        let previousEnd = max(0, orderedInteractions.count - recentInteractions.count)
        let previousInteractions = Array(orderedInteractions.prefix(previousEnd).suffix(trendWindowSize))
        return FeedbackReport(
            interactionCount: interactions.count,
            signals: signals,
            topResultAcceptanceRate: selectedRanks.isEmpty ? nil : Double(top) / Double(selectedRanks.count),
            medianSelectedRank: median(selectedRanks),
            rawQueryInsertionCount: interactions.filter { $0.outcome.kind == .insertedQuery }.count,
            skipCount: interactions.filter { $0.outcome.kind == .skipped }.count,
            identityReviewUndoCount: interactions.filter {
                $0.workflow == .identityReview && $0.outcome.kind == .backed
            }.count,
            cancellationCount: interactions.filter { $0.outcome.kind == .cancelled }.count,
            identityReviewSessionCount: reviewSessions.count,
            identityReviewZeroDecisionSessionCount: reviewZeroDecisionSessionCount,
            identityReviewDecisionCount: reviewDecisionCount,
            identityReviewDecisionsPerSession: reviewSessions.isEmpty
                ? nil
                : Double(reviewDecisionCount) / Double(reviewSessions.count),
            identityReviewSkipRate: reviewDecisionCount == 0
                ? nil
                : Double(reviewSkipCount) / Double(reviewDecisionCount),
            identityReviewMedianTimeToFirstDecisionMilliseconds: median(firstDecisionDurations),
            interactionTrend: .init(
                windowSize: trendWindowSize,
                recent: metricWindow(recentInteractions),
                previous: metricWindow(previousInteractions)
            )
        )
    }

    private func metricWindow(_ interactions: [FeedbackInteraction]) -> FeedbackMetricWindow {
        let selectedRanks = interactions.compactMap { interaction -> Int? in
            guard interaction.outcome.kind == .insertedCandidate || interaction.outcome.kind == .linked else {
                return nil
            }
            return interaction.outcome.selectedRank
        }.sorted()
        return .init(
            interactionCount: interactions.count,
            cancellationRate: interactions.isEmpty ? nil : Double(interactions.filter { $0.outcome.kind == .cancelled }.count) / Double(interactions.count),
            committedSelectionCount: selectedRanks.count,
            topResultAcceptanceRate: selectedRanks.isEmpty ? nil : Double(selectedRanks.filter { $0 == 1 }.count) / Double(selectedRanks.count),
            medianSelectedRank: median(selectedRanks),
            userFlagCount: interactions.filter(\.userFlagged).count,
            focusLossInteractionRate: interactions.isEmpty ? nil : Double(interactions.filter { $0.deactivationCount > 0 }.count) / Double(interactions.count)
        )
    }

    private func signal(_ kind: FeedbackSignal.Kind, _ interaction: FeedbackInteraction, _ summary: String) -> FeedbackSignal {
        let key = "\(kind.rawValue)|\(interaction.workflow.rawValue)|\(interaction.queryOrObservation.lowercased())"
        return .init(id: Self.stableID(key), kind: kind, summary: summary, eventIDs: [interaction.eventID])
    }

    private func hasScoreInversion(_ candidates: [FeedbackCandidateSnapshot]) -> Bool {
        zip(candidates, candidates.dropFirst()).contains { left, right in
            guard let a = left.score, let b = right.score else { return false }
            return a < b
        }
    }

    private func exactTransformRanksBelowLexical(_ candidates: [FeedbackCandidateSnapshot]) -> Bool {
        guard let transform = candidates.firstIndex(where: { $0.evidence.contains(where: { $0.localizedCaseInsensitiveContains("transform") }) }),
              let lexical = candidates.firstIndex(where: { $0.evidence.contains(where: { $0.localizedCaseInsensitiveContains("lexical") }) }) else { return false }
        return transform > lexical
    }

    private func median(_ values: [Int]) -> Double? {
        guard !values.isEmpty else { return nil }
        let middle = values.count / 2
        return values.count.isMultiple(of: 2) ? Double(values[middle - 1] + values[middle]) / 2 : Double(values[middle])
    }

    private func unstableReplaySignals(_ interactions: [FeedbackInteraction]) -> [FeedbackSignal] {
        let grouped = Dictionary(grouping: interactions) {
            "\($0.workflow.rawValue)|\($0.queryOrObservation.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())"
        }
        return grouped.compactMap { key, values in
            guard values.count > 1 else { return nil }
            let orders = Set(values.map { $0.candidates.map(\.exerciseID).joined(separator: "|") })
            guard orders.count > 1 else { return nil }
            return .init(
                id: Self.stableID("unstableReplay|\(key)"),
                kind: .unstableReplay,
                summary: "Equivalent input produced different candidate ordering",
                eventIDs: values.map(\.eventID)
            )
        }
    }

    private static func stableID(_ text: String) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in text.utf8 { hash = (hash ^ UInt64(byte)) &* 1_099_511_628_211 }
        return String(format: "%016llx", hash)
    }
}

public struct FeedbackLedger: Sendable {
    public enum LedgerError: Error, Equatable {
        case signalNotFound(String)
        case automaticDispositionNotUserSettable(FeedbackSignalDisposition)
    }

    public init() {}

    public func updating(_ entries: [FeedbackLedgerEntry], with signals: [FeedbackSignal], at date: Date = Date()) -> [FeedbackLedgerEntry] {
        var byID = Dictionary(uniqueKeysWithValues: entries.map { ($0.signal.id, $0) })
        for signal in signals {
            if var existing = byID[signal.id] {
                let newEventIDs = signal.eventIDs.filter { !existing.signal.eventIDs.contains($0) }
                guard !newEventIDs.isEmpty else { continue }
                existing.occurrenceCount += newEventIDs.count
                existing = .init(
                    signal: .init(
                        id: existing.signal.id,
                        kind: existing.signal.kind,
                        summary: existing.signal.summary,
                        eventIDs: existing.signal.eventIDs + newEventIDs
                    ),
                    occurrenceCount: existing.occurrenceCount,
                    disposition: existing.disposition == .new ? .reproduced : existing.disposition,
                    lastSeenAt: date,
                    dispositionHistory: existing.dispositionHistory
                )
                byID[signal.id] = existing
            } else {
                byID[signal.id] = .init(signal: signal, occurrenceCount: 1, disposition: .new, lastSeenAt: date)
            }
        }
        return byID.values.sorted { $0.signal.id < $1.signal.id }
    }

    public func settingDisposition(_ entries: [FeedbackLedgerEntry], signalID: String,
                                   to disposition: FeedbackSignalDisposition,
                                   authority: String, rationale: String? = nil,
                                   at date: Date = Date()) throws -> [FeedbackLedgerEntry] {
        guard [.acceptedForBatch, .deferred, .resolved].contains(disposition) else {
            throw LedgerError.automaticDispositionNotUserSettable(disposition)
        }
        guard let index = entries.firstIndex(where: { $0.signal.id == signalID }) else {
            throw LedgerError.signalNotFound(signalID)
        }
        var updated = entries
        let prior = updated[index].disposition
        guard prior != disposition else { return updated }
        updated[index].disposition = disposition
        updated[index].dispositionHistory.append(.init(
            from: prior,
            to: disposition,
            changedAt: date,
            authority: authority,
            rationale: rationale
        ))
        return updated
    }
}

public struct FeedbackFileStore: Sendable {
    public enum StoreError: Error, Equatable {
        case unsupportedSchemaVersion(found: Int, supported: Int)
    }
    public let directory: URL
    public init(directory: URL) { self.directory = directory }

    public static func applicationSupport() throws -> FeedbackFileStore {
        let base = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return .init(directory: base.appendingPathComponent("Gym Assistant/Field Feedback", isDirectory: true))
    }

    public var eventsURL: URL { directory.appendingPathComponent("interactions.jsonl") }
    public var ledgerURL: URL { directory.appendingPathComponent("signal-ledger.json") }
    public var screenshotsDirectoryURL: URL { directory.appendingPathComponent("panel-screenshots", isDirectory: true) }

    public func panelScreenshotURL(eventID: UUID) -> URL {
        screenshotsDirectoryURL.appendingPathComponent("\(eventID.uuidString).png")
    }

    public func savePanelScreenshot(_ pngData: Data, eventID: UUID) throws {
        try prepareDirectory()
        try FileManager.default.createDirectory(
            at: screenshotsDirectoryURL,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        let url = panelScreenshotURL(eventID: eventID)
        try pngData.write(to: url, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }

    public func append(_ interaction: FeedbackInteraction) throws {
        try prepareDirectory()
        let lineEncoder = JSONEncoder()
        lineEncoder.dateEncodingStrategy = .secondsSince1970
        lineEncoder.outputFormatting = [.sortedKeys]
        var data = try lineEncoder.encode(interaction); data.append(0x0A)
        if !FileManager.default.fileExists(atPath: eventsURL.path) {
            FileManager.default.createFile(atPath: eventsURL.path, contents: nil, attributes: [.posixPermissions: 0o600])
        }
        let handle = try FileHandle(forWritingTo: eventsURL)
        defer { try? handle.close() }
        try handle.seekToEnd(); try handle.write(contentsOf: data)
    }

    public func loadInteractions() throws -> [FeedbackInteraction] {
        guard FileManager.default.fileExists(atPath: eventsURL.path) else { return [] }
        return try Data(contentsOf: eventsURL).split(separator: 0x0A).map {
            let interaction = try decoder.decode(FeedbackInteraction.self, from: Data($0))
            guard interaction.schemaVersion == FeedbackInteraction.currentSchemaVersion else {
                throw StoreError.unsupportedSchemaVersion(
                    found: interaction.schemaVersion,
                    supported: FeedbackInteraction.currentSchemaVersion
                )
            }
            return interaction
        }
    }

    public func loadLedger() throws -> [FeedbackLedgerEntry] {
        guard FileManager.default.fileExists(atPath: ledgerURL.path) else { return [] }
        return try decoder.decode([FeedbackLedgerEntry].self, from: Data(contentsOf: ledgerURL))
    }

    public func saveLedger(_ entries: [FeedbackLedgerEntry]) throws {
        try prepareDirectory()
        let data = try encoder.encode(entries)
        try data.write(to: ledgerURL, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: ledgerURL.path)
    }

    private var encoder: JSONEncoder { let value = JSONEncoder(); value.dateEncodingStrategy = .secondsSince1970; value.outputFormatting = [.prettyPrinted, .sortedKeys]; return value }
    private var decoder: JSONDecoder { let value = JSONDecoder(); value.dateDecodingStrategy = .secondsSince1970; return value }
    private func prepareDirectory() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
    }
}
