import AppKit
import GymAssistantWorkspace

public struct PlanningReference {
    public let snapshot: WorkspaceSnapshot
    public let savedAt: Date?
    public let includesOpenEditor: Bool
    public let verifiedHeading: String?
}

/// A read-only view of local planning, not a history extractor or an editor.
@MainActor public final class PreviousPlanningWindow: NSWindowController, NSWindowDelegate {
    private let records: [PlanningReference]
    private let chooser = NSPopUpButton()
    private let detail = NSTextField(wrappingLabelWithString: "")
    private let scratchpad = NSTextView()
    private let conversation = NSTextView()

    public init(records: [PlanningReference]) throws {
        self.records = records
        // Validate before constructing a window; never display a partially decoded record.
        for record in records { _ = try RichTextArchive.decode(record.snapshot.richTextArchive) }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 980, height: 620),
            styleMask: [.titled, .closable], backing: .buffered, defer: false)
        super.init(window: window)
        window.title = "Previous planning — read only"; window.isReleasedWhenClosed = false
        window.delegate = self
        guard let root = window.contentView else { return }
        chooser.frame = NSRect(x: 20, y: 568, width: 940, height: 30)
        chooser.identifier = .init("previous-planning-chooser")
        chooser.target = self; chooser.action = #selector(selectRecord)
        for (index, record) in records.enumerated() {
            let group = record.verifiedHeading.map { "Session: " + $0 } ?? "Other planning for this note"
            chooser.addItem(withTitle: "\(index + 1). \(group) — originally \(record.snapshot.anchor.recordedHeading)")
        }
        chooser.isEnabled = !records.isEmpty; root.addSubview(chooser)
        detail.frame = NSRect(x: 20, y: 493, width: 940, height: 65)
        detail.identifier = .init("previous-planning-detail"); root.addSubview(detail)
        addText(scratchpad, title: "Scratchpad", id: "previous-planning-scratchpad", x: 20, root: root)
        addText(conversation, title: "Conversation", id: "previous-planning-conversation", x: 500, root: root)
        let help = NSTextField(wrappingLabelWithString: "Select and copy any passage into your current scratchpad or Parking Lot. This window changes neither saved planning nor Notes. Close to return to programming.")
        help.frame = NSRect(x: 20, y: 15, width: 940, height: 40); root.addSubview(help)
        selectRecord()
    }
    public required init?(coder: NSCoder) { nil }
    private func addText(_ text: NSTextView, title: String, id: String, x: CGFloat, root: NSView) {
        let label = NSTextField(labelWithString: title)
        label.frame = NSRect(x: x, y: 467, width: 450, height: 20); root.addSubview(label)
        let scroll = NSScrollView(frame: NSRect(x: x, y: 65, width: 460, height: 395))
        scroll.hasVerticalScroller = true; scroll.borderType = .lineBorder
        text.frame = scroll.bounds; text.isEditable = false; text.isSelectable = true
        text.isVerticallyResizable = true; text.autoresizingMask = [.width]
        text.textContainer?.widthTracksTextView = true; text.textContainerInset = NSSize(width: 10, height: 10)
        text.font = .systemFont(ofSize: 15); text.identifier = .init(id)
        text.setAccessibilityLabel(title + " — read only")
        scroll.documentView = text; root.addSubview(scroll)
    }
    @objc private func selectRecord() {
        guard records.indices.contains(chooser.indexOfSelectedItem) else {
            detail.stringValue = "No saved planning for this note yet."
            return
        }
        let record = records[chooser.indexOfSelectedItem]
        let date = record.savedAt?.formatted(date: .abbreviated, time: .shortened) ?? "unknown"
        detail.stringValue = "Original heading: \(record.snapshot.anchor.recordedHeading) · revision \(record.snapshot.revision) · Saved file modified: \(date)\n"
            + (record.includesOpenEditor ? "Includes the open editor as captured when this browser opened. " : "Saved local content. ")
            + (record.verifiedHeading == nil ? "Current session location is not verified; no session association is implied." : "Session location verified when this browser opened.")
        do { scratchpad.textStorage?.setAttributedString(try RichTextArchive.decode(record.snapshot.richTextArchive)) }
        catch { scratchpad.string = "This saved scratchpad could not be displayed safely." }
        conversation.string = record.snapshot.messages.map {
            "\($0.role.rawValue.capitalized) [\($0.status.rawValue)]\n\($0.text)"
        }.joined(separator: "\n\n")
        if !record.snapshot.composerText.isEmpty {
            conversation.string += "\n\nUnsent message\n" + record.snapshot.composerText
        }
        if conversation.string.isEmpty { conversation.string = "No conversation saved." }
        scratchpad.scrollToBeginningOfDocument(nil); conversation.scrollToBeginningOfDocument(nil)
    }
    public func show() {
        showWindow(nil); window?.center(); window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(chooser)
    }
    public func windowDidBecomeKey(_ notification: Notification) {
        Self.installReadOnlyMenus(for: window)
    }
    static func installReadOnlyMenus(for window: NSWindow?) {
        // Do not leave the underlying editor's formatting/copy-for-Notes actions
        // targeted at a different window while browsing a read-only reference.
        let menu = NSMenu()
        let app = NSMenuItem(); app.submenu = NSMenu()
        app.submenu?.addItem(withTitle: "Quit Gym Assistant", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(app)
        let edit = NSMenuItem(title: "Edit", action: nil, keyEquivalent: ""); edit.submenu = NSMenu(title: "Edit")
        edit.submenu?.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.submenu?.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        menu.addItem(edit)
        let windows = NSMenuItem(title: "Window", action: nil, keyEquivalent: ""); windows.submenu = NSMenu(title: "Window")
        let close = NSMenuItem(title: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        close.target = window; windows.submenu?.addItem(close); menu.addItem(windows)
        NSApp.mainMenu = menu
    }
}
