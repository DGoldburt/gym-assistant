// Synthetic capability evidence only; excluded from production targets.
import AppKit
import ApplicationServices

struct Message: Codable, Equatable { let role: String; let text: String }
struct Snapshot: Codable {
    let workspaceID: UUID
    let revision: Int
    let richText: Data
    let messages: [Message]
}
enum ProbeError: Error { case invalidArguments }
var failures = 0
func check(_ condition: Bool, _ name: String) {
    print("\(condition ? "PASS" : "FAIL") \(name)")
    if !condition { failures += 1 }
}
func fixture() -> NSAttributedString {
    let text = "Session 1\nWarmup\n\t•\tOverhead preparation\nA1 Dowel squat\nEND OF SYNTHETIC SESSION\n"
    let result = NSMutableAttributedString(string: text, attributes: [.font: NSFont.systemFont(ofSize: 14)])
    let heading = NSMutableParagraphStyle()
    heading.headerLevel = 2
    result.addAttributes([.font: NSFont.boldSystemFont(ofSize: 20), .paragraphStyle: heading], range: (text as NSString).range(of: "Session 1\n"))
    result.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 14), range: (text as NSString).range(of: "A1"))
    let list = NSMutableParagraphStyle()
    list.textLists = [NSTextList(markerFormat: .disc, options: 0)]
    result.addAttribute(.paragraphStyle, value: list, range: (text as NSString).range(of: "\t•\tOverhead preparation\n"))
    return result
}
func encode(_ text: NSAttributedString) throws -> Data {
    try text.data(from: NSRange(location: 0, length: text.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
}
func decode(_ data: Data) throws -> NSAttributedString {
    try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
}
func inspect(_ text: NSAttributedString, format: String = "RTF") {
    check(text.string == fixture().string, "\(format) text round-trip")
    if text.string != fixture().string { print("SYNTHETIC decoded text: \(String(reflecting: text.string))") }
    let boldRange = (text.string as NSString).range(of: "A1")
    let font = text.attribute(.font, at: boldRange.location, effectiveRange: nil) as? NSFont
    check(font.map { NSFontManager.shared.traits(of: $0).contains(.boldFontMask) } ?? false, "\(format) bold round-trip")
    let heading = text.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
    check(heading?.headerLevel == 2, "\(format) heading metadata round-trip (level=\(heading?.headerLevel ?? -1))")
    let range = (text.string as NSString).range(of: "Overhead preparation")
    let list = text.attribute(.paragraphStyle, at: range.location, effectiveRange: nil) as? NSParagraphStyle
    check(!(list?.textLists.isEmpty ?? true), "\(format) list metadata round-trip (lists=\(list?.textLists.count ?? 0))")
}
do {
    guard CommandLine.arguments.count == 3 else { throw ProbeError.invalidArguments }
    let mode = CommandLine.arguments[1]
    let url = URL(fileURLWithPath: CommandLine.arguments[2])
    guard url.path.hasPrefix("/private/tmp/gym-assistant-scratchpad-checkpoint/") else { throw ProbeError.invalidArguments }
    if mode == "permissions" {
        // Does not prompt, enumerate UI, or read Notes. This is this probe's
        // effective permission only, not a claim about the installed app.
        print("Accessibility permission for standalone probe: \(AXIsProcessTrusted() ? "available" : "unavailable")")
    } else if mode == "automation-permissions" {
        // Only checks existing target-specific permission; sends no Notes read
        // event and never requests user consent.
        let bundleID = "com.apple.Notes"
        var target = AEAddressDesc()
        let created = bundleID.withCString {
            AECreateDesc(DescType(typeApplicationBundleID), $0, bundleID.utf8.count, &target)
        }
        guard created == noErr else { throw ProbeError.invalidArguments }
        defer { AEDisposeDesc(&target) }
        let status = AEDeterminePermissionToAutomateTarget(&target, AEEventClass(kAECoreSuite), AEEventID(kAEGetData), false)
        print("Notes Automation permission for standalone probe: OSStatus \(status); no prompt or read event sent")
    } else if mode == "seed" {
        let source = fixture()
        let data = try encode(source)
        inspect(try decode(data))
        let editor = NSTextView(frame: NSRect(x: 0, y: 0, width: 500, height: 300))
        editor.isRichText = true
        editor.textStorage?.setAttributedString(source)
        editor.insertText(" (edited)", replacementRange: NSRange(location: source.length - 1, length: 0))
        check(editor.string.contains("(edited)"), "Native rich-text editor accepts editing")
        let board = NSPasteboard.withUniqueName()
        defer { board.releaseGlobally() }
        board.declareTypes([.rtf, .string], owner: nil)
        check(board.setData(data, forType: .rtf) && board.setString(source.string, forType: .string), "Isolated pasteboard accepts RTF and plain text")
        check(board.data(forType: .rtf) == data, "Isolated pasteboard preserves RTF bytes")
        let snapshot = Snapshot(workspaceID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, revision: 3, richText: data, messages: [Message(role: "coach", text: "What pairs well with A1?")])
        try JSONEncoder().encode(snapshot).write(to: url, options: .atomic)
        print("PASS Atomic synthetic snapshot written; verify in a new process")
    } else if mode == "archive-seed" {
        let archive = try NSKeyedArchiver.archivedData(withRootObject: fixture(), requiringSecureCoding: true)
        guard let restored = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: archive) else { throw ProbeError.invalidArguments }
        inspect(restored, format: "Secure attributed-string archive")
        let snapshot = Snapshot(workspaceID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, revision: 3, richText: archive, messages: [Message(role: "coach", text: "What pairs well with A1?")])
        try JSONEncoder().encode(snapshot).write(to: url, options: .atomic)
        print("PASS Atomic synthetic archive snapshot written")
    } else if mode == "archive-verify" {
        let snapshot = try JSONDecoder().decode(Snapshot.self, from: Data(contentsOf: url))
        check(snapshot.workspaceID.uuidString == "00000000-0000-0000-0000-000000000001" && snapshot.revision == 3, "Fresh-process archive workspace identity and revision restoration")
        check(snapshot.messages == [Message(role: "coach", text: "What pairs well with A1?")], "Fresh-process archive conversation restoration")
        guard let restored = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: snapshot.richText) else { throw ProbeError.invalidArguments }
        inspect(restored, format: "Secure attributed-string archive")
    } else if mode == "verify" {
        let snapshot = try JSONDecoder().decode(Snapshot.self, from: Data(contentsOf: url))
        check(snapshot.workspaceID.uuidString == "00000000-0000-0000-0000-000000000001" && snapshot.revision == 3, "Fresh-process workspace identity and revision restoration")
        check(snapshot.messages == [Message(role: "coach", text: "What pairs well with A1?")], "Fresh-process conversation restoration")
        inspect(try decode(snapshot.richText))
    } else { throw ProbeError.invalidArguments }
    exit(failures == 0 ? 0 : 1)
} catch {
    print("ERROR \(error)")
    exit(1)
}
