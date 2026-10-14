// Isolated pasteboard experiment. Never uses NSPasteboard.general or real Notes data.
import AppKit

struct CopyToken: Equatable {
    let id: UUID
    let publicationChangeCount: Int
}

final class CopyOwner {
    private var active: CopyToken?

    func publish(_ text: String, to board: NSPasteboard) -> CopyToken {
        board.clearContents()
        precondition(board.setString(text, forType: .string))
        let token = CopyToken(id: UUID(), publicationChangeCount: board.changeCount)
        active = token
        return token
    }

    func stillOwns(_ token: CopyToken, on board: NSPasteboard) -> Bool {
        active == token && board.changeCount == token.publicationChangeCount
    }

    func replaceWithWarning(_ token: CopyToken, on board: NSPasteboard) -> Bool {
        guard stillOwns(token, on: board) else { return false }
        // The public API has no compare-and-write operation. Another process can
        // copy between this guard and clearContents(), so this is not a safe
        // production implementation of the coach's strict ownership contract.
        board.clearContents()
        let published = board.setString("Program may be out of date—review Notes.", forType: .string)
        active = nil
        return published
    }
}

let board = NSPasteboard.withUniqueName()
let owner = CopyOwner()
var assertions = 0
var failures = 0
func check(_ condition: Bool, _ label: String) {
    assertions += 1
    if !condition { failures += 1 }
    print("\(condition ? "PASS" : "FAIL") \(label)")
}

let first = owner.publish("Synthetic Session A", to: board)
check(owner.stillOwns(first, on: board), "Fresh operation owns its published generation")
check(owner.replaceWithWarning(first, on: board), "Uninterrupted operation can replace its own copy")
check(board.string(forType: .string) == "Program may be out of date—review Notes.", "Warning replaces entire synthetic copy")

let second = owner.publish("Synthetic Session B", to: board)
board.clearContents()
board.setString("Synthetic Session B", forType: .string)
check(!owner.stillOwns(second, on: board), "Identical later copy invalidates ownership")
check(!owner.replaceWithWarning(second, on: board), "Identical later copy remains untouched")
check(board.string(forType: .string) == "Synthetic Session B", "App-only warning is required after identical recopy")

let third = owner.publish("Synthetic Session C", to: board)
board.clearContents()
board.setString("Unrelated user copy", forType: .string)
check(!owner.replaceWithWarning(third, on: board), "Different later copy remains untouched")
check(board.string(forType: .string) == "Unrelated user copy", "Unrelated clipboard contents survive")

let fourth = owner.publish("Synthetic Session D", to: board)
let fifth = owner.publish("Synthetic Session D", to: board)
check(!owner.stillOwns(fourth, on: board), "Later scratchpad operation invalidates older result")
check(owner.stillOwns(fifth, on: board), "Latest scratchpad operation owns its own generation")

let guardPassed = owner.stillOwns(fifth, on: board)
board.clearContents()
board.setString("Copied during guard/write gap", forType: .string)
check(guardPassed && !owner.stillOwns(fifth, on: board), "Intervening copy defeats a prior ownership check")
check(!owner.replaceWithWarning(fifth, on: board), "Recheck detects simulated interleaving before write")
check(board.string(forType: .string) == "Copied during guard/write gap", "Intervening copy remains intact")

print("RESULT \(assertions - failures)/\(assertions) isolated pasteboard assertions passed; atomic cross-process replacement NOT established")
exit(failures == 0 ? 0 : 1)
