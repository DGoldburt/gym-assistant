import Foundation

public enum NotesCopyVerification: Equatable, Sendable {
    case unchanged, conflict, unavailable
}

public enum CheckedCopyStatus: Equatable, Sendable {
    case copiedChecking, copiedVerified, copiedUnverified, copiedConflict, failed
}

/// Publication happens once. Verification may finish later, but can only update
/// the app, never the pasteboard. A newer copy supersedes older status callbacks.
@MainActor public final class CheckedScratchpadCopy {
    private var generation = UUID()
    private var verification: Task<Void, Never>?
    private var deadline: Task<Void, Never>?
    private var published = false
    private var result: NotesCopyVerification?
    private var expired = false
    private let waitLimit: Duration

    // Reserve 50ms for main-run-loop delivery within the accepted 750ms limit.
    // Native full-path measurement is still required; this is not a real-time
    // guarantee if the main thread is blocked during rich-text preparation.
    public init(waitLimit: Duration = .milliseconds(700)) { self.waitLimit = waitLimit }

    public func start(prepareAndPublish: @escaping @MainActor () throws -> Void,
                      verify: @escaping @MainActor () async -> NotesCopyVerification,
                      update: @escaping @MainActor (CheckedCopyStatus) -> Void) {
        cancel()
        let operation = generation
        published = false; result = nil; expired = false
        // Queue verification first so it can begin its off-main read before
        // main-actor rich-text preparation and pasteboard publication.
        verification = Task { [weak self] in
            guard !Task.isCancelled else { return }
            let outcome = await verify()
            guard let self, !Task.isCancelled, self.generation == operation else { return }
            self.result = outcome
            self.deadline?.cancel()
            if self.published { update(self.status()) }
        }
        deadline = Task { [weak self, waitLimit] in
            do { try await Task.sleep(for: waitLimit) } catch { return }
            guard let self, self.generation == operation else { return }
            self.expired = true
            if self.published { update(self.status()) }
        }
        Task { [weak self] in
            await Task.yield()
            guard let self, self.generation == operation else { return }
            do {
                try prepareAndPublish()
                self.published = true
                update(self.status())
            } catch {
                self.cancel()
                update(.failed)
            }
        }
    }

    public func cancel() {
        generation = UUID()
        verification?.cancel(); deadline?.cancel()
        verification = nil; deadline = nil
    }

    private func status() -> CheckedCopyStatus {
        switch result {
        case .unchanged: return .copiedVerified
        case .conflict: return .copiedConflict
        case .unavailable: return .copiedUnverified
        case nil: return expired ? .copiedUnverified : .copiedChecking
        }
    }
}
