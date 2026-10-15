import AppKit
import Testing
@testable import GymAssistantMacOS

@MainActor private final class UndoCounter {
    var value = 1
}

@Suite("Boundary undo preflight") @MainActor struct ValidatedBoundaryUndoManagerTests {
    @Test func ordinaryUndoDoesNotValidateAndCancelledBoundaryKeepsStack() async throws {
        let undo = ValidatedBoundaryUndoManager(), counter = UndoCounter()
        undo.groupsByEvent = false
        var validations = 0
        undo.beginUndoGrouping()
        undo.registerUndo(withTarget: counter) { $0.value = 0 }
        undo.setActionName("Typing")
        undo.endUndoGrouping()
        undo.undo()
        #expect(counter.value == 0)
        #expect(!undo.checking)
        undo.beginBoundaryGroup()
        undo.registerUndo(withTarget: counter) { $0.value = 2 }
        undo.nameBoundaryAction {
            validations += 1
            try await Task.sleep(for: .seconds(10))
        }
        undo.endBoundaryGroup()
        #expect(undo.undoMenuItemTitle == "Undo Adjust session boundary")
        undo.undo()
        #expect(undo.checking)
        undo.cancelCheck()
        for _ in 0..<100 {
            if !undo.checking { break }
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(!undo.checking)
        #expect(counter.value == 0)
        #expect(undo.canUndo)
        #expect(validations == 1)
    }

    @Test func boundaryGroupingSeparatesEarlierAndLaterTyping() async throws {
        let undo = ValidatedBoundaryUndoManager(), counter = UndoCounter()
        undo.groupsByEvent = false
        var validations = 0
        undo.beginUndoGrouping()
        undo.registerUndo(withTarget: counter) { $0.value = 0 }
        undo.setActionName("Typing")
        // Simulate an open event group from earlier typing.
        undo.beginBoundaryGroup()
        undo.registerUndo(withTarget: counter) { $0.value = 2 }
        undo.nameBoundaryAction { validations += 1 }
        undo.endBoundaryGroup()
        undo.beginUndoGrouping()
        undo.registerUndo(withTarget: counter) { $0.value = 3 }
        undo.setActionName("Typing")
        undo.endUndoGrouping()
        undo.undo()
        #expect(counter.value == 3)
        #expect(validations == 0)
        undo.undo()
        for _ in 0..<100 {
            if !undo.checking { break }
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(counter.value == 2)
        #expect(validations == 1)
        undo.undo()
        #expect(counter.value == 0)
    }
}
