import Foundation
import GymAssistantCore

do {
    guard CommandLine.arguments.count == 1 else {
        throw DispositionCommandError.argumentsNotAccepted
    }

    print("Gym Assistant signal disposition batch")
    print("Queue one or more human-controlled changes. Leave the case ID blank when finished.")
    var proposals: [DispositionProposal] = []
    while true {
        print("Signal case ID:", terminator: " ")
        guard let signalID = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw DispositionCommandError.missingInput("signal case ID")
        }
        if signalID.isEmpty { break }
        guard !proposals.contains(where: { $0.signalID == signalID }) else {
            throw DispositionCommandError.duplicateSignalID(signalID)
        }

        print("Disposition [accepted-for-batch | deferred | resolved]:", terminator: " ")
        guard let dispositionText = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines),
              let disposition = parseDisposition(dispositionText) else {
            throw DispositionCommandError.invalidDisposition
        }
        print("Optional rationale (blank for none):", terminator: " ")
        guard let rationaleText = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw DispositionCommandError.missingInput("rationale")
        }
        proposals.append(.init(
            signalID: signalID,
            disposition: disposition,
            rationale: rationaleText.isEmpty ? nil : rationaleText
        ))
    }

    guard !proposals.isEmpty else {
        print("Cancelled; no changes were queued.")
        exit(0)
    }
    print("Queued changes:")
    for proposal in proposals {
        let rationale = proposal.rationale.map { " — \($0)" } ?? ""
        print("- \(proposal.signalID): \(proposal.disposition.rawValue)\(rationale)")
    }
    print("Apply all \(proposals.count) changes atomically? Type APPLY:", terminator: " ")
    guard readLine() == "APPLY" else {
        print("Cancelled; ledger unchanged.")
        exit(0)
    }

    let store = try FeedbackFileStore.applicationSupport()
    let prior = try store.loadLedger()
    let updated = try proposals.reduce(prior) { entries, proposal in
        try FeedbackLedger().settingDisposition(
            entries,
            signalID: proposal.signalID,
            to: proposal.disposition,
            authority: "explicit-user-approval-via-codex",
            rationale: proposal.rationale
        )
    }
    try store.saveLedger(updated)
    for proposal in proposals {
        guard let result = updated.first(where: { $0.signal.id == proposal.signalID }) else {
            throw FeedbackLedger.LedgerError.signalNotFound(proposal.signalID)
        }
        print("Saved: case \(proposal.signalID) is \(result.disposition.rawValue). History entries: \(result.dispositionHistory.count).")
    }
} catch {
    FileHandle.standardError.write(Data("Disposition failed: \(error)\n".utf8))
    exit(1)
}

private enum DispositionCommandError: Error {
    case argumentsNotAccepted
    case missingInput(String)
    case invalidDisposition
    case duplicateSignalID(String)
}

private struct DispositionProposal {
    let signalID: String
    let disposition: FeedbackSignalDisposition
    let rationale: String?
}

private func parseDisposition(_ value: String) -> FeedbackSignalDisposition? {
    switch value.lowercased() {
    case "accepted-for-batch", "acceptedforbatch": .acceptedForBatch
    case "deferred": .deferred
    case "resolved": .resolved
    default: nil
    }
}
