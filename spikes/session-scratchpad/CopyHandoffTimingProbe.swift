// Isolated copy experiment: named pasteboard and injected Notes outcomes only.
// No Notes API, general clipboard, production target or model calls.
import AppKit

enum Verification { case pending, matched, conflict, unavailable }
enum Presentation: Equatable { case preparing, checking, verified, notVerified, conflict }
struct Operation: Equatable { let id: UUID; let revision: Int }

struct Handoff {
    private(set) var active: Operation?
    private(set) var published = false
    private(set) var status: Presentation = .preparing
    private(set) var result: Verification = .pending
    private(set) var pastDeadline = false

    mutating func begin(revision: Int) -> Operation {
        let token = Operation(id: UUID(), revision: revision)
        active = token; published = false; result = .pending
        pastDeadline = false; status = .preparing
        return token
    }
    mutating func publish(_ token: Operation) {
        guard token == active else { return }
        published = true; update()
    }
    mutating func deadline(_ token: Operation) {
        guard token == active else { return }
        pastDeadline = true; update()
    }
    mutating func finish(_ token: Operation, revision: Int, result: Verification) {
        guard token == active, token.revision == revision else { return }
        self.result = result; update()
    }
    private mutating func update() {
        guard published else { status = .preparing; return }
        switch result {
        case .pending: status = pastDeadline ? .notVerified : .checking
        case .matched: status = .verified
        case .conflict: status = .conflict
        case .unavailable: status = .notVerified
        }
    }
}

@main struct Probe {
    @MainActor static func main() throws {
        var total = 0, failures = 0
        func check(_ value: Bool, _ label: String) {
            total += 1; if !value { failures += 1 }
            print("\(value ? "PASS" : "FAIL") \(label)")
        }
        let board = NSPasteboard.withUniqueName()
        defer { board.releaseGlobally() }
        var model = Handoff()
        let token = model.begin(revision: 1)
        model.deadline(token)
        check(model.status == .preparing, "Deadline cannot claim Copied before publication")
        model.publish(token)
        check(model.status == .notVerified, "750ms event labels pending published content not verified")

        // Measured preparation/publication only. The Notes reader is absent.
        let started = ProcessInfo.processInfo.systemUptime
        let markdown = "## COPY PROBE Session A\n\n### Warmup\n\n" +
            (1...1000).map { "- **A\($0)** Synthetic exercise — 3 × 8/side; light and controlled" }.joined(separator: "\n") + "\n"
        let prepared = ProcessInfo.processInfo.systemUptime
        let rich = NSAttributedString(string: "COPY PROBE rich compatibility control\n" + markdown,
                                      attributes: [.font: NSFont.systemFont(ofSize: 17)])
        let rtf = try rich.data(from: NSRange(location: 0, length: rich.length),
                               documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        let encoded = ProcessInfo.processInfo.systemUptime
        let item = NSPasteboardItem()
        item.setString(markdown, forType: .string)
        item.setData(rtf, forType: .rtf)
        board.clearContents()
        check(board.writeObjects([item]), "Isolated multi-representation publication succeeds")
        let published = ProcessInfo.processInfo.systemUptime
        let before = board.changeCount
        let content = board.string(forType: .string)
        model.finish(token, revision: 1, result: .conflict)
        check(model.status == .conflict, "Late conflict updates app presentation")
        check(board.changeCount == before && board.string(forType: .string) == content,
              "Late conflict does not write clipboard")
        for (label, copied) in [("identical recopy", markdown), ("unrelated recopy", "Other user copy"),
                                ("later scratchpad copy", "Another scratchpad")] {
            board.clearContents(); board.setString(copied, forType: .string)
            let generation = board.changeCount
            model.finish(token, revision: 1, result: .conflict)
            check(board.changeCount == generation && board.string(forType: .string) == copied,
                  "App-only warning preserves \(label)")
        }
        let newer = model.begin(revision: 2)
        model.publish(newer)
        model.finish(token, revision: 1, result: .conflict)
        check(model.status == .checking, "Old operation cannot override newer warning state")
        model.finish(newer, revision: 3, result: .conflict)
        check(model.status == .checking, "Changed scratchpad revision rejects old result")
        model.finish(newer, revision: 2, result: .matched)
        check(model.status == .verified, "Current matching result can verify current operation")
        let early = model.begin(revision: 4)
        model.finish(early, revision: 4, result: .conflict)
        check(model.status == .preparing, "Early read completion still waits for publication")
        model.publish(early)
        check(model.status == .conflict, "Publication preserves already-known conflict")
        let unavailable = model.begin(revision: 5)
        model.publish(unavailable)
        model.finish(unavailable, revision: 5, result: .unavailable)
        check(model.status == .notVerified, "Reader failure cannot claim verified")
        print(String(format: "MEASURE 1000-line synthetic export: markdown %.1fms; RTF %.1fms; publication %.1fms; total %.1fms; %d UTF-8 bytes",
                     (prepared-started)*1000, (encoded-prepared)*1000, (published-encoded)*1000,
                     (published-started)*1000, markdown.utf8.count))
        print("RESULT \(total-failures)/\(total) isolated assertions; native Notes reader, real parallel scheduling, deadline timing and rich-editor serialization NOT tested")
        exit(failures == 0 ? 0 : 1)
    }
}
