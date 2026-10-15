import Foundation
import GymAssistantWorkspace

/// One instance per captured NoteID, shared by that note's workspace windows.
/// A batch includes only requests received before its read starts. Requests that
/// arrive during a native read wait for a later read, never its older observation.
public actor NotesRefreshCoordinator {
    public enum Reason: Sendable { case resume, chat, comparison, checkedCopy, boundary }
    private let reader: any NotesContextReading
    private var state: NotesObservationState
    private var pending: [CheckedContinuation<NoteSnapshot, any Error>] = []
    private var worker: Task<Void, Never>?
    private var idleRequested = false
    private var visible = false
    private var generation = 0
    private var retryAfter = ContinuousClock.now
    private var failures = 0
    private var polling: Task<Void, Never>?
    private var deferredBody: Task<Void, Never>?
    private var firstChange: ContinuousClock.Instant?
    private var bodyRequested = false
    private var listeners: [UUID: AsyncStream<NotesObservationState>.Continuation] = [:]

    public init(noteID: NoteID, reader: any NotesContextReading) {
        self.reader = reader
        state = NotesObservationState(noteID: noteID)
    }

    deinit { polling?.cancel(); deferredBody?.cancel() }

    public func observation() -> NotesObservationState { state }

    public func observations() -> AsyncStream<NotesObservationState> {
        let id = UUID()
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            listeners[id] = continuation
            continuation.yield(state)
            continuation.onTermination = { [weak self] _ in Task { await self?.removeListener(id) } }
        }
    }
    private func removeListener(_ id: UUID) { listeners.removeValue(forKey: id) }
    private func publish() { for listener in listeners.values { listener.yield(state) } }

    func waitUntilIdle() async { await worker?.value }
    func waitForScheduledRefresh() async {
        await deferredBody?.value
        await worker?.value
    }

    /// The window registry supplies aggregate visibility, not each window's
    /// independent Boolean. Suspending invalidates any in-flight completion.
    public func setVisible(_ value: Bool) {
        guard value != visible else { return }
        visible = value
        generation += 1
        polling?.cancel()
        if !value {
            idleRequested = false
            cancelDeferredBody()
            bodyRequested = false
        } else {
            polling = Task { [weak self] in
                while !Task.isCancelled {
                    do { try await Task.sleep(for: .seconds(5)) } catch { return }
                    guard let self else { return }
                    await self.idleTick()
                }
            }
        }
    }

    public func validate(for reason: Reason) async throws -> NoteSnapshot {
        try Task.checkCancellation()
        let result = try await withCheckedThrowingContinuation { continuation in
            pending.append(continuation)
            startWorker()
        }
        try Task.checkCancellation()
        return result
    }

    /// Called by visible-window cadence (five seconds) or reactivation. Repeated
    /// ticks coalesce. Explicit reactivation bypasses automatic error backoff.
    public func idleTick(reactivated: Bool = false) {
        guard visible, reactivated || ContinuousClock.now >= retryAfter else { return }
        idleRequested = true
        startWorker()
    }

    private func startWorker() {
        guard worker == nil else { return }
        worker = Task { await self.drain() }
    }

    private func drain() async {
        while !pending.isEmpty || idleRequested || bodyRequested {
            let batch = pending
            pending.removeAll()
            idleRequested = false
            let scheduledBody = bodyRequested
            bodyRequested = false
            let capturedGeneration = generation
            do {
                // Consumer requests always need a body read, even with an equal
                // modification date. Idle-only work can use metadata first.
                let needsBody: Bool
                if batch.isEmpty && !scheduledBody {
                    guard visible else { continue }
                    let metadata = try await reader.metadata(id: state.noteID)
                    guard capturedGeneration == generation else { throw NotesReadError.unavailable }
                    if try state.requiresBody(after: metadata) { scheduleChangedBody() }
                    needsBody = false
                } else { needsBody = true }
                guard capturedGeneration == generation else { throw NotesReadError.unavailable }
                if needsBody {
                    cancelDeferredBody()
                    let snapshot = try await reader.read(id: state.noteID)
                    guard capturedGeneration == generation else { throw NotesReadError.unavailable }
                    try state.accept(snapshot)
                    publish()
                    for continuation in batch { continuation.resume(returning: snapshot) }
                }
                failures = 0
                retryAfter = .now
            } catch {
                let failure = (error as? NotesReadError) ?? .unavailable
                state.failed(failure)
                publish()
                // Ticks queued while the failed read was running must respect
                // the new backoff too. Explicit consumers remain queued.
                idleRequested = false
                failures = min(failures + 1, 4)
                retryAfter = .now.advanced(by: .seconds(5 * (1 << failures)))
                for continuation in batch { continuation.resume(throwing: failure) }
            }
        }
        worker = nil
    }

    private func cancelDeferredBody() {
        deferredBody?.cancel()
        deferredBody = nil
        firstChange = nil
    }

    private func scheduleChangedBody() {
        let now = ContinuousClock.now
        if firstChange == nil { firstChange = now }
        let deadline = min(now.advanced(by: .milliseconds(500)), firstChange!.advanced(by: .seconds(2)))
        deferredBody?.cancel()
        let token = generation
        deferredBody = Task { [weak self] in
            do { try await Task.sleep(until: deadline, clock: .continuous) } catch { return }
            await self?.enqueueChangedBody(generation: token)
        }
    }

    private func enqueueChangedBody(generation token: Int) {
        guard token == generation, visible else { return }
        bodyRequested = true
        startWorker()
    }
}
