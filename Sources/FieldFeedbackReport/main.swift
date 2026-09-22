import Foundation
import GymAssistantCore

do {
    let store = try FeedbackFileStore.applicationSupport()
    let interactions = try store.loadInteractions()
    let report = FeedbackEvaluator().evaluate(interactions)
    let prior = try store.loadLedger()
    let ledger = FeedbackLedger().updating(prior, with: report.signals)
    try store.saveLedger(ledger)
    let openEntries = ledger.filter { $0.disposition == .new || $0.disposition == .reproduced }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let output = try encoder.encode(report)
    print(String(decoding: output, as: UTF8.self))
    if ledger == prior {
        print("No new signal occurrences; replay was quiet.")
    } else {
        print("Ledger updated with new or reproduced signal evidence.")
    }
    let byKind = Dictionary(grouping: openEntries, by: { $0.signal.kind.rawValue })
        .mapValues { $0.count }
    let byDisposition = Dictionary(grouping: openEntries, by: { $0.disposition.rawValue })
        .mapValues { $0.count }
    print("Open signals requiring human review: \(openEntries.count)")
    print("Open signals by kind: \(formatCounts(byKind))")
    print("Open signals by disposition: \(formatCounts(byDisposition))")
    print("Ledger: \(ledger.count) durable signals at \(store.ledgerURL.path)")
    printTrendTable(report.interactionTrend)
    let packetBuilder = FeedbackReviewPacketBuilder()
    printReviewCases(packetBuilder.openCases(
        ledger: ledger,
        interactions: interactions
    ), store: store, heading: "Human review packet (private, bounded evidence)", includeDecisionOptions: true)
    printReviewCases(packetBuilder.acceptedBatchCases(
        ledger: ledger,
        interactions: interactions
    ), store: store, heading: "Accepted batch queue (private, bounded evidence)", includeDecisionOptions: false)
} catch {
    FileHandle.standardError.write(Data("Field feedback report failed: \(error)\n".utf8))
    exit(1)
}

private func formatCounts(_ counts: [String: Int]) -> String {
    guard !counts.isEmpty else { return "none" }
    return counts.keys.sorted().map { "\($0)=\(counts[$0]!)" }.joined(separator: ", ")
}

private func printTrendTable(_ trend: FeedbackInteractionTrend) {
    print("\nInteraction trend (recent \(trend.windowSize) versus preceding \(trend.windowSize); event cohorts, not report-run averages)")
    print("| Metric | Recent | Previous | Change |")
    print("|---|---:|---:|---:|")
    printTrendRow("Interactions", Double(trend.recent.interactionCount), Double(trend.previous.interactionCount), style: .count)
    printTrendRow("Cancellation rate", trend.recent.cancellationRate, trend.previous.cancellationRate, style: .percent)
    printTrendRow("Committed selections", Double(trend.recent.committedSelectionCount), Double(trend.previous.committedSelectionCount), style: .count)
    printTrendRow("Top-result acceptance", trend.recent.topResultAcceptanceRate, trend.previous.topResultAcceptanceRate, style: .percent)
    printTrendRow("Median selected rank", trend.recent.medianSelectedRank, trend.previous.medianSelectedRank, style: .decimal)
    printTrendRow("User flags", Double(trend.recent.userFlagCount), Double(trend.previous.userFlagCount), style: .count)
    printTrendRow("Focus-loss interaction rate", trend.recent.focusLossInteractionRate, trend.previous.focusLossInteractionRate, style: .percent)
    print("Window sample sizes: recent n=\(trend.recent.interactionCount), previous n=\(trend.previous.interactionCount). Treat sparse selection metrics cautiously.")
}

private enum MetricStyle { case count, percent, decimal }

private func printTrendRow(_ name: String, _ recent: Double?, _ previous: Double?, style: MetricStyle) {
    let change = recent.flatMap { recent in previous.map { recent - $0 } }
    print("| \(name) | \(formatMetric(recent, style: style)) | \(formatMetric(previous, style: style)) | \(formatMetric(change, style: style, signed: true)) |")
}

private func formatMetric(_ value: Double?, style: MetricStyle, signed: Bool = false) -> String {
    guard let value else { return "n/a" }
    let prefix = signed && value > 0 ? "+" : ""
    switch style {
    case .count: return "\(prefix)\(Int(value))"
    case .percent: return "\(prefix)\(String(format: "%.0f", value * 100))%"
    case .decimal: return "\(prefix)\(String(format: "%.1f", value))"
    }
}

private func printReviewCases(_ cases: [FeedbackReviewCase], store: FeedbackFileStore,
                              heading: String, includeDecisionOptions: Bool) {
    print("\n\(heading)")
    guard !cases.isEmpty else {
        print("None.")
        return
    }
    let dateFormatter = ISO8601DateFormatter()
    for (offset, reviewCase) in cases.enumerated() {
        let entry = reviewCase.entry
        print("\n[\(offset + 1)] Case \(entry.signal.id)")
        print("Category: \(entry.signal.kind.rawValue)")
        print("Summary: \(entry.signal.summary)")
        print("Disposition: \(entry.disposition.rawValue)")
        print("Occurrences: \(entry.occurrenceCount)")
        print("Observed: \(formatDate(reviewCase.firstObservedAt, with: dateFormatter)) to \(formatDate(reviewCase.lastObservedAt, with: dateFormatter))")

        let evidence = Array(reviewCase.interactions.prefix(3))
        for (evidenceOffset, interaction) in evidence.enumerated() {
            print("  Evidence \(evidenceOffset + 1): \(dateFormatter.string(from: interaction.recordedAt)); workflow=\(interaction.workflow.rawValue); outcome=\(interaction.outcome.kind.rawValue)")
            let screenshotURL = store.panelScreenshotURL(eventID: interaction.eventID)
            if FileManager.default.fileExists(atPath: screenshotURL.path) {
                print("    panel screenshot: \(screenshotURL.path)")
            }
            if entry.signal.kind == .focusFriction {
                print("    focus losses=\(interaction.deactivationCount); returned=\(interaction.returnedAfterDeactivation); return-to-outcome-ms=\(optional(interaction.lastReturnToOutcomeMilliseconds))")
            } else {
                print("    query/observation: \(interaction.queryOrObservation)")
                if let selectedRank = interaction.outcome.selectedRank {
                    print("    selected/highlighted rank: \(selectedRank)")
                }
                if let selectedName = interaction.outcome.selectedName {
                    print("    selected/highlighted name: \(selectedName)")
                }
                let visible = boundedCandidates(interaction)
                if visible.isEmpty {
                    print("    candidates: none")
                }
                for candidate in visible {
                    let matched = candidate.matchedName == candidate.preferredName
                        ? candidate.matchedName
                        : "\(candidate.matchedName) (exercise: \(candidate.preferredName))"
                    print("    #\(candidate.rank) \(matched); score=\(optional(candidate.score)); link=\(candidate.linkAllowed ? "allowed" : "disabled"); evidence=\(candidate.evidence.joined(separator: "; "))")
                }
                if interaction.candidates.count > visible.count {
                    print("    candidate snapshot bounded to \(visible.count) of \(interaction.candidates.count) rows")
                }
            }
        }
        if reviewCase.interactions.count > evidence.count {
            print("  Evidence bounded to \(evidence.count) of \(reviewCase.interactions.count) occurrences")
        }
    }
    if includeDecisionOptions {
        print("\nDecision options:")
        print("- Accept for batch — include this signal in a bounded improvement batch")
        print("- Defer — preserve it but intentionally postpone action")
        print("- Resolve — close it while retaining its evidence and history")
        print("- Keep open — make no ledger change")
        print("Disposition requires explicit user approval and the separate SetFieldFeedbackDisposition executable.")
    } else {
        print("\nThese accepted cases are read-only inputs to the next bounded intervention; the evaluator does not implement fixes.")
    }
}

private func boundedCandidates(_ interaction: FeedbackInteraction) -> [FeedbackCandidateSnapshot] {
    var result = Array(interaction.candidates.prefix(5))
    if let rank = interaction.outcome.selectedRank,
       let selected = interaction.candidates.first(where: { $0.rank == rank }),
       !result.contains(where: { $0.rank == rank }) {
        result.append(selected)
    }
    return result.sorted { $0.rank < $1.rank }
}

private func formatDate(_ date: Date?, with formatter: ISO8601DateFormatter) -> String {
    date.map(formatter.string(from:)) ?? "unknown"
}

private func optional<T>(_ value: T?) -> String {
    value.map(String.init(describing:)) ?? "none"
}
