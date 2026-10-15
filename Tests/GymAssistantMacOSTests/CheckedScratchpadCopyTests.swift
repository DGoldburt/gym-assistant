import Foundation
import Testing
@testable import GymAssistantMacOS

@MainActor private final class CopyVerificationLatch {
    var started = false
    var continuation: CheckedContinuation<NotesCopyVerification, Never>?
    func wait() async -> NotesCopyVerification {
        started = true
        return await withCheckedContinuation { continuation = $0 }
    }
    func finish(_ value: NotesCopyVerification) { continuation?.resume(returning: value); continuation = nil }
}

@Suite("Concurrent checked copy") @MainActor struct CheckedScratchpadCopyTests {
    private func eventually(_ predicate: () -> Bool) async throws {
        for _ in 0..<100 {
            if predicate() { return }
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(predicate())
    }

    @Test func publishesBeforeVerificationAndLateConflictNeverRepublishes() async throws {
        let copy = CheckedScratchpadCopy(waitLimit: .milliseconds(20))
        let latch = CopyVerificationLatch()
        var publications = 0
        var states: [CheckedCopyStatus] = []
        copy.start(prepareAndPublish: { publications += 1 }, verify: { await latch.wait() }, update: { states.append($0) })
        try await eventually { states.contains(.copiedUnverified) }
        #expect(latch.started)
        #expect(publications == 1)
        latch.finish(.conflict)
        try await eventually { states.last == .copiedConflict }
        #expect(publications == 1)
        copy.cancel()
    }

    @Test func newerCopyIgnoresOlderCheckEvenIfCancellationIsIgnored() async throws {
        let copy = CheckedScratchpadCopy()
        let old = CopyVerificationLatch()
        var publications = 0
        var oldStates: [CheckedCopyStatus] = []
        var newStates: [CheckedCopyStatus] = []
        copy.start(prepareAndPublish: { publications += 1 }, verify: { await old.wait() }, update: { oldStates.append($0) })
        try await eventually { publications == 1 && old.started }
        let previous = oldStates
        copy.start(prepareAndPublish: { publications += 1 }, verify: { .unchanged }, update: { newStates.append($0) })
        try await eventually { newStates.last == .copiedVerified }
        old.finish(.conflict)
        try await Task.sleep(for: .milliseconds(10))
        #expect(oldStates == previous)
        #expect(publications == 2)
        copy.cancel()
    }

    @Test func publicationFailureNeverClaimsCopiedAndCloseSuppressesLateResult() async throws {
        let copy = CheckedScratchpadCopy(waitLimit: .milliseconds(20))
        let latch = CopyVerificationLatch()
        var states: [CheckedCopyStatus] = []
        copy.start(prepareAndPublish: { throw CocoaError(.fileWriteUnknown) }, verify: { await latch.wait() }, update: { states.append($0) })
        // Failure may cancel verification before it starts. Neither scheduling
        // order may report that the clipboard was published.
        try await eventually { states == [.failed] }
        latch.finish(.unchanged)
        try await Task.sleep(for: .milliseconds(30))
        #expect(states == [.failed])
        let second = CopyVerificationLatch()
        copy.start(prepareAndPublish: {}, verify: { await second.wait() }, update: { states.append($0) })
        // Under main-actor load the 20ms deadline may already have elapsed when
        // this task resumes. Both states mean publication with a pending check;
        // the dedicated timeout test above asserts deadline behavior separately.
        try await eventually {
            second.started && (states.last == .copiedChecking || states.last == .copiedUnverified)
        }
        copy.cancel()
        let before = states
        second.finish(.conflict)
        try await Task.sleep(for: .milliseconds(30))
        #expect(states == before)
    }
}
