import AppKit

/// Boundary actions need asynchronous preflight before Cocoa advances its stack.
/// Ordinary text/formatting undo remains synchronous and does not read Notes.
@MainActor final class ValidatedBoundaryUndoManager: UndoManager {
    private var validations: [String: @MainActor () async throws -> Void] = [:]
    private var task: Task<Void, Never>?
    private(set) var checking = false
    var didChangeChecking: ((Bool) -> Void)?
    var didFail: ((any Error) -> Void)?

    func nameBoundaryAction(validate: @escaping @MainActor () async throws -> Void) {
        let key = "boundary-" + UUID().uuidString
        validations[key] = validate
        setActionName(key)
    }
    override var undoActionName: String {
        validations[super.undoActionName] == nil ? super.undoActionName : "Adjust session boundary"
    }
    override var redoActionName: String {
        validations[super.redoActionName] == nil ? super.redoActionName : "Adjust session boundary"
    }
    override var undoMenuItemTitle: String { undoMenuTitle(forUndoActionName: undoActionName) }
    override var redoMenuItemTitle: String { redoMenuTitle(forUndoActionName: redoActionName) }
    override var canUndo: Bool { !checking && super.canUndo }
    override var canRedo: Bool { !checking && super.canRedo }
    override func undo() { perform(redo: false) }
    override func redo() { perform(redo: true) }
    private func perform(redo: Bool) {
        guard !checking else { return }
        let key = redo ? super.redoActionName : super.undoActionName
        guard let validation = validations[key] else { advance(redo: redo); return }
        checking = true; didChangeChecking?(true)
        task = Task { [weak self] in
            guard let self else { return }
            do {
                try await validation()
                // Validation may persist the candidate. It must check cancellation
                // before persistence; no suspension is permitted after that save.
                self.checking = false
                self.advance(redo: redo)
            } catch { self.didFail?(error) }
            self.checking = false; self.task = nil; self.didChangeChecking?(false)
        }
    }
    private func advance(redo: Bool) {
        if redo { super.redo() } else { super.undo() }
    }
    func cancelCheck() { task?.cancel() }

    func beginBoundaryGroup() {
        // NSTextView may still have an event-level typing group. Keep a boundary
        // action separate so a later text action cannot hide its preflight key.
        while groupingLevel > 0 { endUndoGrouping() }
        beginUndoGrouping()
    }
    func endBoundaryGroup() { endUndoGrouping() }
}
