import Foundation
import Testing
@testable import GymAssistantCore

@Suite("Private field feedback")
struct FieldFeedbackTests {
    private let sessionID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

    @Test("Evaluator catches ordering, transform, conflict, focus, and explicit flags")
    func anomaliesAreDeterministic() {
        let interaction = FeedbackInteraction(
            eventID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            sessionID: sessionID,
            workflow: .identityReview,
            queryOrObservation: "DL",
            candidates: [
                candidate(1, "Squat", ["Lexical · .45"], score: 0.45, linkAllowed: true),
                candidate(2, "Deadlift", ["Transform · approved abbreviation expansion"], score: 0.50, linkAllowed: true),
                candidate(3, "Squat DL", ["Cannot link · squat versus hinge"], score: nil, linkAllowed: true),
            ],
            outcome: .init(kind: .skipped),
            deactivationCount: 1,
            userFlagged: true
        )

        let report = FeedbackEvaluator().evaluate([interaction])
        #expect(Set(report.signals.map(\.kind)) == [
            .userFlag, .scoreInversion, .exactTransformBelowLexical,
            .protectedConflictLinkable, .focusFriction,
        ])
        #expect(report.skipCount == 1)
    }

    @Test("Replaying identical evidence does not inflate the ledger")
    func ledgerReplayIsIdempotent() {
        let event = FeedbackInteraction(
            eventID: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            sessionID: sessionID,
            workflow: .autocomplete,
            queryOrObservation: "test",
            candidates: [],
            outcome: .init(kind: .cancelled),
            userFlagged: true
        )
        let signals = FeedbackEvaluator().evaluate([event]).signals
        let first = FeedbackLedger().updating([], with: signals)
        let second = FeedbackLedger().updating(first, with: signals)
        #expect(first == second)
        #expect(second.single?.occurrenceCount == 1)
        #expect(second.single?.disposition == .new)
    }

    @Test("Open review packet joins durable cases to bounded source interactions")
    func reviewPacketJoinsEvidence() {
        let event = FeedbackInteraction(
            eventID: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
            sessionID: sessionID,
            recordedAt: Date(timeIntervalSince1970: 500),
            workflow: .autocomplete,
            queryOrObservation: "fixture query",
            candidates: [candidate(1, "Fixture", ["Lexical"], score: 0.8, linkAllowed: true)],
            outcome: .init(kind: .opened, selectedRank: 1),
            userFlagged: true
        )
        let ledger = FeedbackLedger().updating([], with: FeedbackEvaluator().evaluate([event]).signals)
        let packet = FeedbackReviewPacketBuilder().openCases(ledger: ledger, interactions: [event])
        #expect(packet.count == 1)
        #expect(packet[0].entry.signal.kind == .userFlag)
        #expect(packet[0].firstObservedAt == event.recordedAt)
        #expect(packet[0].interactions == [event])
    }

    @Test("Accepted cases remain discoverable outside the open review queue")
    func acceptedBatchQueue() throws {
        let event = FeedbackInteraction(
            eventID: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
            sessionID: sessionID,
            recordedAt: Date(timeIntervalSince1970: 600),
            workflow: .autocomplete,
            queryOrObservation: "fixture",
            candidates: [],
            outcome: .init(kind: .opened),
            userFlagged: true
        )
        let initial = FeedbackLedger().updating([], with: FeedbackEvaluator().evaluate([event]).signals)
        let accepted = try FeedbackLedger().settingDisposition(
            initial,
            signalID: initial[0].signal.id,
            to: .acceptedForBatch,
            authority: "test"
        )
        let builder = FeedbackReviewPacketBuilder()
        #expect(builder.openCases(ledger: accepted, interactions: [event]).isEmpty)
        let batch = builder.acceptedBatchCases(ledger: accepted, interactions: [event])
        #expect(batch.count == 1)
        #expect(batch[0].entry.disposition == .acceptedForBatch)
        #expect(batch[0].interactions == [event])
    }

    @Test("Only human dispositions can be set and every change is retained")
    func dispositionsAreValidatedAndAudited() throws {
        let signal = FeedbackSignal(id: "case-1", kind: .userFlag, summary: "Fixture", eventIDs: [])
        let entry = FeedbackLedgerEntry(
            signal: signal,
            occurrenceCount: 1,
            disposition: .new,
            lastSeenAt: Date(timeIntervalSince1970: 10)
        )
        let changedAt = Date(timeIntervalSince1970: 20)
        let updated = try FeedbackLedger().settingDisposition(
            [entry],
            signalID: "case-1",
            to: .deferred,
            authority: "explicit-user-approval-via-codex",
            rationale: "Needs a later product batch",
            at: changedAt
        )
        #expect(updated[0].disposition == .deferred)
        #expect(updated[0].dispositionHistory == [
            .init(from: .new, to: .deferred, changedAt: changedAt,
                  authority: "explicit-user-approval-via-codex",
                  rationale: "Needs a later product batch")
        ])
        #expect(throws: FeedbackLedger.LedgerError.automaticDispositionNotUserSettable(.new)) {
            try FeedbackLedger().settingDisposition(
                updated, signalID: "case-1", to: .new, authority: "not-allowed"
            )
        }
    }

    @Test("Trend compares the most recent ten interactions with the preceding ten")
    func rollingInteractionTrend() {
        var interactions: [FeedbackInteraction] = []
        for index in 0..<20 {
            let outcome: FeedbackOutcome = index < 10
                ? .init(kind: .cancelled)
                : .init(kind: .insertedCandidate, selectedRank: index == 19 ? 2 : 1)
            interactions.append(FeedbackInteraction(
                sessionID: sessionID,
                recordedAt: Date(timeIntervalSince1970: Double(index)),
                workflow: .autocomplete,
                queryOrObservation: "fixture-\(index)",
                candidates: [],
                outcome: outcome,
                deactivationCount: index >= 15 ? 1 : 0,
                userFlagged: index == 19
            ))
        }
        let trend = FeedbackEvaluator().evaluate(interactions).interactionTrend
        #expect(trend.windowSize == 10)
        #expect(trend.previous.interactionCount == 10)
        #expect(trend.previous.cancellationRate == 1)
        #expect(trend.recent.interactionCount == 10)
        #expect(trend.recent.cancellationRate == 0)
        #expect(trend.recent.committedSelectionCount == 10)
        #expect(trend.recent.topResultAcceptanceRate == 0.9)
        #expect(trend.recent.userFlagCount == 1)
        #expect(trend.recent.focusLossInteractionRate == 0.5)
    }

    @Test("Existing ledger entries decode with empty disposition history")
    func legacyLedgerEntryDecodes() throws {
        let json = """
        {
          "signal":{"id":"case-1","kind":"userFlag","summary":"Fixture","eventIDs":[]},
          "occurrenceCount":1,
          "disposition":"new",
          "lastSeenAt":10
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let entry = try decoder.decode(FeedbackLedgerEntry.self, from: Data(json.utf8))
        #expect(entry.dispositionHistory.isEmpty)
    }

    @Test("Private JSONL store round-trips typed interactions")
    func privateStoreRoundTrip() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FeedbackFileStore(directory: directory)
        let event = FeedbackInteraction(
            sessionID: sessionID,
            recordedAt: Date(timeIntervalSince1970: 1_700_000_000),
            workflow: .autocomplete,
            queryOrObservation: "front squat",
            candidates: [],
            outcome: .init(kind: .insertedQuery),
            deactivationCount: 1,
            returnedAfterDeactivation: true,
            lastReturnToOutcomeMilliseconds: 1_500
        )
        try store.append(event)
        #expect(try store.loadInteractions() == [event])
        let permissions = try FileManager.default.attributesOfItem(atPath: store.eventsURL.path)[.posixPermissions] as? NSNumber
        #expect(permissions?.intValue == 0o600)
    }

    @Test("Explicit-flag panel screenshots are stored privately by event ID")
    func privatePanelScreenshotStorage() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FeedbackFileStore(directory: directory)
        let eventID = UUID(uuidString: "77777777-7777-7777-7777-777777777777")!
        let fixture = Data([0x89, 0x50, 0x4E, 0x47])
        try store.savePanelScreenshot(fixture, eventID: eventID)
        let url = store.panelScreenshotURL(eventID: eventID)
        #expect(try Data(contentsOf: url) == fixture)
        let permissions = try FileManager.default.attributesOfItem(atPath: url.path)[.posixPermissions] as? NSNumber
        #expect(permissions?.intValue == 0o600)
    }

    @Test("Store rejects an unsupported event schema version")
    func rejectsUnsupportedSchema() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FeedbackFileStore(directory: directory)
        try store.append(.init(
            schemaVersion: 999,
            sessionID: sessionID,
            workflow: .autocomplete,
            queryOrObservation: "fixture",
            candidates: [],
            outcome: .init(kind: .cancelled)
        ))
        #expect(throws: FeedbackFileStore.StoreError.unsupportedSchemaVersion(found: 999, supported: 1)) {
            try store.loadInteractions()
        }
    }

    @Test("Evaluator detects unstable replay ordering")
    func unstableReplay() {
        let first = FeedbackInteraction(
            sessionID: sessionID,
            workflow: .autocomplete,
            queryOrObservation: "row",
            candidates: [candidate(1, "A", ["Lexical · .8"], score: 0.8, linkAllowed: true), candidate(2, "B", ["Lexical · .7"], score: 0.7, linkAllowed: true)],
            outcome: .init(kind: .cancelled)
        )
        let second = FeedbackInteraction(
            sessionID: sessionID,
            workflow: .autocomplete,
            queryOrObservation: " ROW ",
            candidates: [candidate(2, "B", ["Lexical · .7"], score: 0.7, linkAllowed: true), candidate(1, "A", ["Lexical · .8"], score: 0.8, linkAllowed: true)],
            outcome: .init(kind: .cancelled)
        )
        #expect(FeedbackEvaluator().evaluate([first, second]).signals.contains { $0.kind == .unstableReplay })
    }

    @Test("Evaluator identifies repeated non-top selections only with enough evidence")
    func frequentNonTopSelection() {
        let interactions = (1...3).map { rank in
            FeedbackInteraction(
                sessionID: sessionID,
                workflow: .autocomplete,
                queryOrObservation: "query-\(rank)",
                candidates: [],
                outcome: .init(kind: .insertedCandidate, selectedRank: rank == 1 ? 1 : 2)
            )
        }
        let report = FeedbackEvaluator().evaluate(interactions)
        #expect(report.signals.contains { $0.kind == .frequentNonTopChoice })
    }

    @Test("Highlighted rows in reports are not counted as committed selections")
    func reportedHighlightIsNotASelection() {
        let inserted = FeedbackInteraction(
            sessionID: sessionID,
            workflow: .autocomplete,
            queryOrObservation: "query",
            candidates: [],
            outcome: .init(kind: .insertedCandidate, selectedRank: 1)
        )
        let flagged = FeedbackInteraction(
            sessionID: sessionID,
            workflow: .identityReview,
            queryOrObservation: "observation",
            candidates: [],
            outcome: .init(kind: .opened, selectedRank: 29),
            userFlagged: true
        )
        let report = FeedbackEvaluator().evaluate([inserted, flagged])
        #expect(report.medianSelectedRank == 1)
        #expect(report.topResultAcceptanceRate == 1)
    }

    @Test("Evaluator derives library-review session metrics without new raw fields")
    func identityReviewSessionMetrics() {
        let secondSessionID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let thirdSessionID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
        let interactions = [
            FeedbackInteraction(
                sessionID: sessionID,
                recordedAt: Date(timeIntervalSince1970: 100),
                workflow: .identityReview,
                queryOrObservation: "first",
                candidates: [],
                outcome: .init(kind: .linked),
                durationMilliseconds: 1_000
            ),
            FeedbackInteraction(
                sessionID: sessionID,
                recordedAt: Date(timeIntervalSince1970: 110),
                workflow: .identityReview,
                queryOrObservation: "second",
                candidates: [],
                outcome: .init(kind: .skipped),
                durationMilliseconds: 400
            ),
            FeedbackInteraction(
                sessionID: secondSessionID,
                recordedAt: Date(timeIntervalSince1970: 200),
                workflow: .identityReview,
                queryOrObservation: "third",
                candidates: [],
                outcome: .init(kind: .created),
                durationMilliseconds: 3_000
            ),
            FeedbackInteraction(
                sessionID: thirdSessionID,
                recordedAt: Date(timeIntervalSince1970: 300),
                workflow: .identityReview,
                queryOrObservation: "fourth",
                candidates: [],
                outcome: .init(kind: .cancelled),
                durationMilliseconds: 250
            ),
            FeedbackInteraction(
                sessionID: UUID(),
                recordedAt: Date(timeIntervalSince1970: 400),
                workflow: .autocomplete,
                queryOrObservation: "ignored",
                candidates: [],
                outcome: .init(kind: .insertedCandidate, selectedRank: 1),
                durationMilliseconds: 100
            ),
        ]

        let report = FeedbackEvaluator().evaluate(interactions)
        #expect(report.identityReviewSessionCount == 3)
        #expect(report.identityReviewZeroDecisionSessionCount == 1)
        #expect(report.identityReviewDecisionCount == 3)
        #expect(report.identityReviewDecisionsPerSession == 1.0)
        #expect(report.identityReviewSkipRate == 1.0 / 3.0)
        #expect(report.identityReviewMedianTimeToFirstDecisionMilliseconds == 2_000)
    }

    private func candidate(_ rank: Int, _ name: String, _ evidence: [String], score: Double?, linkAllowed: Bool) -> FeedbackCandidateSnapshot {
        .init(rank: rank, exerciseID: "id-\(rank)", preferredName: name, matchedName: name,
              aliases: [], evidence: evidence, score: score, linkAllowed: linkAllowed)
    }
}

private extension Array {
    var single: Element? { count == 1 ? self[0] : nil }
}
