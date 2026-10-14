// Disposable read-only API probe. No Service registration or Notes writes.
import AppKit
import WebKit
import ApplicationServices

struct NativeFixtureEvidence: Encodable {
    let noteID: String
    let html: String
    let text: String
    let date: String
}
struct WatchSample: Encodable {
    let elapsed: Double
    let date: String
    let epoch: Double?
    let html: String // Guarded synthetic fixture only; never a real program.
}

@MainActor
final class NativeNotesProbe: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private let status = NSTextField(wrappingLabelWithString: "")
    private var capturedID: String?
    private var capturedBody: String?
    private var capturedDate: String?
    private let editor = NSTextView(frame: NSRect(x: 0, y: 0, width: 610, height: 160))
    private var watchTimer: Timer?
    private var samples: [WatchSample] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu()
        let applicationItem = NSMenuItem()
        let applicationMenu = NSMenu(title: "Gym Assistant Notes Capability Probe")
        applicationMenu.addItem(withTitle: "Quit Gym Assistant Notes Capability Probe", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        applicationItem.submenu = applicationMenu
        menu.addItem(applicationItem)
        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu
        menu.addItem(editItem)
        NSApp.mainMenu = menu
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 650, height: 860), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Gym Assistant Notes Capability Probe"
        window.isReleasedWhenClosed = false
        let read = NSButton(title: "Read selected synthetic note", target: self, action: #selector(readSelected))
        let refresh = NSButton(title: "Reread captured note", target: self, action: #selector(reread))
        let consent = NSButton(title: "Request Notes Automation access", target: self, action: #selector(requestAccess))
        let metadata = NSButton(title: "20 metadata-only reads", target: self, action: #selector(checkMetadata))
        read.frame = NSRect(x: 20, y: 595, width: 290, height: 35)
        refresh.frame = NSRect(x: 320, y: 595, width: 300, height: 35)
        consent.frame = NSRect(x: 20, y: 20, width: 340, height: 35)
        metadata.frame = NSRect(x: 370, y: 20, width: 250, height: 35)
        status.frame = NSRect(x: 20, y: 320, width: 610, height: 260)
        status.isSelectable = true
        window.contentView?.addSubview(read)
        window.contentView?.addSubview(refresh)
        window.contentView?.addSubview(consent)
        window.contentView?.addSubview(metadata)
        let inspect = NSButton(title: "Inspect synthetic clipboard", target: self, action: #selector(inspectClipboard))
        inspect.frame = NSRect(x: 20, y: 65, width: 280, height: 35)
        window.contentView?.addSubview(inspect)
        let reset = NSButton(title: "Load native rich fixture", target: self, action: #selector(loadRichFixture))
        reset.frame = NSRect(x: 320, y: 65, width: 300, height: 35)
        window.contentView?.addSubview(reset)
        for (index, item) in [("Copy div HTML control", #selector(copyHTML)), ("Copy RTFD candidate", #selector(copyRTFD))].enumerated() {
            let button = NSButton(title: item.0, target: self, action: item.1)
            button.frame = NSRect(x: 20 + index * 310, y: 700, width: 290, height: 35)
            window.contentView?.addSubview(button)
        }
        let control = NSButton(title: "Copy public RTF control", target: self, action: #selector(copyPublicControl))
        control.frame = NSRect(x: 20, y: 650, width: 290, height: 35)
        window.contentView?.addSubview(control)
        let watch = NSButton(title: "Watch fixture for 20 seconds", target: self, action: #selector(watchFixture))
        watch.frame = NSRect(x: 330, y: 650, width: 290, height: 35)
        window.contentView?.addSubview(watch)
        let race = NSButton(title: "Test 750ms delayed copy", target: self, action: #selector(delayedCopy))
        race.frame = NSRect(x: 20, y: 800, width: 290, height: 35)
        window.contentView?.addSubview(race)
        for (index, item) in [("Copy single-item HTML", #selector(copySingleHTML)), ("Copy WebArchive control", #selector(copyWebArchive))].enumerated() {
            let button = NSButton(title: item.0, target: self, action: item.1)
            button.frame = NSRect(x: 20 + index * 310, y: 750, width: 290, height: 35)
            window.contentView?.addSubview(button)
        }
        let markdown = NSButton(title: "Copy Markdown control", target: self, action: #selector(copyMarkdown))
        markdown.frame = NSRect(x: 330, y: 800, width: 290, height: 35)
        window.contentView?.addSubview(markdown)
        let scroll = NSScrollView(frame: NSRect(x: 20, y: 120, width: 610, height: 180))
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        editor.isRichText = true
        editor.isVerticallyResizable = true
        editor.autoresizingMask = [.width]
        scroll.documentView = editor
        window.contentView?.addSubview(scroll)
        window.contentView?.addSubview(status)
        status.stringValue = "Read-only synthetic fixture test. Read refuses other note titles. Consent is requested only through the explicit Notes Automation access button, with user approval."
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func permission(askUserIfNeeded: Bool = false) -> OSStatus {
        let bundleID = "com.apple.Notes"
        var target = AEAddressDesc()
        let created = bundleID.withCString { AECreateDesc(DescType(typeApplicationBundleID), $0, bundleID.utf8.count, &target) }
        guard created == noErr else { return OSStatus(created) }
        defer { AEDisposeDesc(&target) }
        return AEDeterminePermissionToAutomateTarget(&target, AEEventClass(kAECoreSuite), AEEventID(kAEGetData), askUserIfNeeded)
    }

    @objc private func requestAccess() {
        let access = permission(askUserIfNeeded: true)
        status.stringValue = access == noErr
            ? "Notes Automation permission available. No note read yet; use Read selected synthetic note."
            : "Notes Automation permission not available (OSStatus \(access)). No note read."
    }

    @objc private func loadRichFixture() {
        let text = "Session 99\nCOPY PROBE Warmup\n\t•\tSynthetic balance preparation\nA1 Synthetic squat\n"
        let rich = NSMutableAttributedString(string: text, attributes: [.font: NSFont.systemFont(ofSize: 17)])
        for (label, level, size) in [("Session 99", 2, 20.0), ("COPY PROBE Warmup", 3, 17.0)] {
            let style = NSMutableParagraphStyle()
            style.headerLevel = level
            rich.addAttributes([.font: NSFont.boldSystemFont(ofSize: size), .paragraphStyle: style], range: (text as NSString).range(of: label + "\n"))
        }
        let list = NSMutableParagraphStyle()
        list.textLists = [NSTextList(markerFormat: .disc, options: 0)]
        rich.addAttribute(.paragraphStyle, value: list, range: (text as NSString).range(of: "\t•\tSynthetic balance preparation\n"))
        rich.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 17), range: (text as NSString).range(of: "A1"))
        editor.textStorage?.setAttributedString(rich)
        window.makeFirstResponder(editor)
        editor.selectAll(nil)
        status.stringValue = "Native rich fixture selected. Use Command-C, then inspect or manually paste into the synthetic note. No Notes writes by this app."
    }

    @objc private func inspectClipboard() {
        let board = NSPasteboard.general
        guard let text = board.string(forType: .string), text.contains("COPY PROBE") else {
            status.stringValue = "Refusing non-synthetic clipboard; no rich payload inspected."
            return
        }
        let types = (board.types ?? []).map(\.rawValue).joined(separator: ", ")
        var report = ["Synthetic clipboard types: " + types]
        if let data = board.data(forType: NSPasteboard.PasteboardType("com.apple.notes.richtext")) {
            // Diagnostic of this explicitly marked test payload only. No private DB,
            // private frameworks, or production encoder/decoder is introduced.
            try? data.write(to: URL(fileURLWithPath: "/private/tmp/gym-assistant-scratchpad-checkpoint/synthetic-notes-clipboard.bin"), options: .atomic)
            let plist = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) != nil
            report.append("Marked Notes clipboard flavor: \(data.count) bytes; standard property list: \(plist)")
        }
        if let data = board.data(forType: .rtf),
           let rich = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil) {
            let range = (rich.string as NSString).range(of: "COPY PROBE")
            if range.location != NSNotFound {
                let style = rich.attribute(.paragraphStyle, at: range.location, effectiveRange: nil) as? NSParagraphStyle
                let font = rich.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont
                report.append("RTF warmup headerLevel: \(style?.headerLevel ?? -1); font size: \(font?.pointSize ?? -1)")
                report.append("Font: \(font?.fontName ?? "none"); paragraph style: \(String(describing: style))")
            }
            // Only the explicitly marked synthetic public RTF flavor, no private payloads.
            try? data.write(to: URL(fileURLWithPath: "/private/tmp/gym-assistant-scratchpad-checkpoint/synthetic-clipboard.rtf"), options: .atomic)
        }
        status.stringValue = report.joined(separator: "\n")
    }

    @objc private func copyHTML() {
        let html = """
        <div><h1>COPY PROBE DIV Title</h1></div>
        <div><h2>COPY PROBE DIV Heading</h2></div>
        <p>COPY PROBE DIV Body</p>
        <div><h3>COPY PROBE DIV Subheading</h3></div>
        """
        let board = NSPasteboard.general
        board.clearContents()
        board.setString(html, forType: .html)
        board.setString("COPY PROBE DIV Title\nCOPY PROBE DIV Heading\nCOPY PROBE DIV Body\nCOPY PROBE DIV Subheading\n", forType: .string)
        status.stringValue = "Copied exact div/h1/h2/h3 control: public.html plus plaintext only, no CSS or RTF. Inspect native paragraph styles and API headings after manual paste."
    }

    @objc private func copyRTFD() {
        guard editor.string.contains("COPY PROBE"),
              let data = try? editor.attributedString().data(from: NSRange(location: 0, length: editor.textStorage?.length ?? 0), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd]) else {
            status.stringValue = "Load the synthetic native fixture first."; return
        }
        let board = NSPasteboard.general
        board.clearContents()
        board.setData(data, forType: .rtfd)
        board.setString(editor.string, forType: .string)
        status.stringValue = "Copied RTFD-only candidate; no RTF/HTML flavor. Inspect actual Notes styles after manual paste."
    }

    private let publicControlHTML = "<div><h1>COPY PROBE ITEM Title</h1></div><div><h2>COPY PROBE ITEM Heading</h2></div><p>COPY PROBE ITEM Body</p><div><h3>COPY PROBE ITEM Subheading</h3></div>"
    private let publicControlText = "COPY PROBE ITEM Title\nCOPY PROBE ITEM Heading\nCOPY PROBE ITEM Body\nCOPY PROBE ITEM Subheading\n"

    private func publishControl(_ item: NSPasteboardItem, label: String) {
        let board = NSPasteboard.general
        board.clearContents()
        let success = board.writeObjects([item])
        let types = (board.types ?? []).map(\.rawValue).joined(separator: ", ")
        status.stringValue = "\(label): writeObjects \(success); items \(board.pasteboardItems?.count ?? 0); types \(types). Synthetic data only; no private Notes representation."
    }

    @objc private func copySingleHTML() {
        let item = NSPasteboardItem()
        item.setString(publicControlText, forType: .string)
        item.setData(Data(publicControlHTML.utf8), forType: .html)
        publishControl(item, label: "Single-item UTF-8 HTML control")
    }

    @objc private func copyWebArchive() {
        let resource = WebResource(data: Data(publicControlHTML.utf8), url: URL(string: "about:blank")!, mimeType: "text/html", textEncodingName: "UTF-8", frameName: "")!
        let archive = WebArchive(mainResource: resource, subresources: [], subframeArchives: [])!
        let item = NSPasteboardItem()
        item.setString(publicControlText, forType: .string)
        guard item.setData(archive.data, forType: NSPasteboard.PasteboardType("com.apple.webarchive")) else {
            status.stringValue = "WebArchive control could not register its representation; no publication."; return
        }
        publishControl(item, label: "Public WebArchive control")
    }

    @objc private func copyMarkdown() {
        let markdown = "# COPY PROBE MD Title\n\n## COPY PROBE MD Heading\n\nCOPY PROBE MD Body\n\n### COPY PROBE MD Subheading\n\n- Synthetic bullet\n- **A1** Synthetic squat\n"
        let item = NSPasteboardItem()
        item.setString(markdown, forType: .string)
        publishControl(item, label: "Plain Markdown control")
    }

    @objc private func copyPublicControl() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: "/private/tmp/gym-assistant-scratchpad-checkpoint/synthetic-clipboard.rtf")),
              let rich = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil),
              rich.string.contains("COPY PROBE") else { status.stringValue = "No marked synthetic RTF control available."; return }
        let board = NSPasteboard.general
        board.clearContents()
        board.setData(data, forType: .rtf)
        board.setString(rich.string, forType: .string)
        status.stringValue = "Copied synthetic public RTF control only; no com.apple.notes.richtext payload read or copied."
    }

    @objc private func delayedCopy() {
        let board = NSPasteboard.general
        board.clearContents()
        board.setString("COPY PROBE OLD CLIPBOARD", forType: .string)
        let start = Date()
        status.stringValue = "Copy pending for simulated 750ms preflight. Clipboard still holds synthetic OLD text. Paste only in the named fixture to test this race."
        Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                let board = NSPasteboard.general
                board.clearContents()
                board.setString("COPY PROBE NEW CLIPBOARD", forType: .string)
                self?.status.stringValue = "Delayed copy completed after \(String(format: "%.3f", Date().timeIntervalSince(start)))s; clipboard now holds NEW. This simulates a delayed preflight, not a measured Notes read."
            }
        }
    }

    private func scriptLiteral(_ text: String) -> String {
        "\"" + text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }

    @objc private func readSelected() { read(id: nil) }
    @objc private func reread() {
        guard let capturedID else { status.stringValue = "No captured target. Read the selected synthetic note first."; return }
        read(id: capturedID)
    }

    @objc private func checkMetadata() {
        guard permission() == noErr, let capturedID else { status.stringValue = "Capture the fixture first; no prompt or read sent."; return }
        let start = Date()
        var dates: [String] = []
        for _ in 0..<20 {
            let source = """
            tell application "Notes"
                set n to first note whose id is \(scriptLiteral(capturedID))
                if name of n is not "Gym assistant capability test" then error "Refusing non-fixture note"
                return (modification date of n) as string
            end tell
            """
            var error: NSDictionary?
            guard let date = NSAppleScript(source: source)?.executeAndReturnError(&error).stringValue, error == nil else {
                status.stringValue = "Metadata check failed; no body fallback. Completed \(dates.count)/20."
                return
            }
            dates.append(date)
        }
        status.stringValue = """
        PASS 20 captured-fixture metadata reads; body/plaintext not requested
        Elapsed: \(String(format: "%.3f", Date().timeIntervalSince(start))) seconds
        Dates all equal: \(Set(dates).count == 1)
        Date equals captured baseline: \(dates.first == capturedDate)
        This measures sequential reads, not a production monitor or rapid-edit reliability.
        """
    }

    @objc private func watchFixture() {
        guard permission() == noErr, let id = capturedID else { status.stringValue = "Read the fixture first."; return }
        watchTimer?.invalidate()
        samples = []
        let began = Date()
        status.stringValue = "Watching captured synthetic fixture for 20 seconds. Edit only that fixture through Notes. Experimental body/date sampling, not production polling."
        watchTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                if Date().timeIntervalSince(began) >= 20 {
                    self.watchTimer?.invalidate(); self.watchTimer = nil
                    let pairs = zip(self.samples, self.samples.dropFirst())
                    let bodyChanges = pairs.filter { $0.html != $1.html }.count
                    let collisions = zip(self.samples, self.samples.dropFirst()).filter { $0.html != $1.html && $0.date == $1.date }.count
                    let epochCollisions = zip(self.samples, self.samples.dropFirst()).filter { $0.html != $1.html && $0.epoch != nil && $0.epoch == $1.epoch }.count
                    try? JSONEncoder().encode(self.samples).write(to: URL(fileURLWithPath: "/private/tmp/gym-assistant-scratchpad-checkpoint/native-watch.json"), options: .atomic)
                    self.status.stringValue = "Watch finished: \(self.samples.count) body/date samples; \(bodyChanges) observed body transitions; \(collisions) equal text-date transitions; \(epochCollisions) equal native-date transitions. No edits by probe. Synthetic evidence saved."
                    return
                }
                let source = """
                tell application "Notes"
                    set n to first note whose id is \(self.scriptLiteral(id))
                    if name of n is not "Gym assistant capability test" then error "Refusing non-fixture note"
                    return {body of n, (modification date of n) as string, modification date of n}
                end tell
                """
                var error: NSDictionary?
                guard let result = NSAppleScript(source: source)?.executeAndReturnError(&error), error == nil,
                      let html = result.atIndex(1)?.stringValue, html.contains("END OF SYNTHETIC NOTE 2026-10-12"),
                      let date = result.atIndex(2)?.stringValue else {
                    self.watchTimer?.invalidate(); self.watchTimer = nil
                    self.status.stringValue = "Watch stopped after read/fixture failure; no fallback."; return
                }
                self.samples.append(WatchSample(elapsed: Date().timeIntervalSince(began), date: date,
                                               epoch: result.atIndex(3)?.dateValue?.timeIntervalSince1970, html: html))
            }
        }
    }

    private func read(id: String?) {
        let access = permission()
        guard access == noErr else {
            status.stringValue = "Native Notes Automation access unavailable (OSStatus \(access)). No Notes read event or permission prompt sent. Explicit approval is needed before requesting new access."
            return
        }
        let target: String
        if let id { target = "set n to first note whose id is \(scriptLiteral(id))" }
        else { target = "set selectedNotes to selection\nif (count of selectedNotes) is not 1 then error \"Select exactly one synthetic test note\"\nset n to item 1 of selectedNotes" }
        let source = """
        tell application "Notes"
            \(target)
            if name of n is not "Gym assistant capability test" then error "Refusing non-fixture note"
            return {id of n, body of n, plaintext of n, (modification date of n) as string}
        end tell
        """
        var error: NSDictionary?
        let readBegan = Date()
        guard let result = NSAppleScript(source: source)?.executeAndReturnError(&error), error == nil,
              let noteID = result.atIndex(1)?.stringValue,
              let html = result.atIndex(2)?.stringValue,
              let plain = result.atIndex(3)?.stringValue,
              let date = result.atIndex(4)?.stringValue else {
            status.stringValue = "Native read failed: \(error?[NSAppleScript.errorMessage] ?? "No valid result")"
            return
        }
        let readElapsed = Date().timeIntervalSince(readBegan)
        guard plain.contains("END OF SYNTHETIC NOTE 2026-10-12") else {
            status.stringValue = "Refusing fixture without expected synthetic end marker."
            return
        }
        let lines = (1...70).filter { plain.contains(String(format: "Context line %02d:", $0)) }.count
        let changed = capturedBody.map { $0 != html }
        let equalReportedDate = capturedDate == date
        if id == nil { capturedID = noteID; capturedBody = html; capturedDate = date }
        // Synthetic fixture output only, guarded above by title and end marker.
        // Opaque real Notes identity is intentionally not written to the artifact.
        let snapshot = NativeFixtureEvidence(noteID: "synthetic-fixture", html: html, text: plain, date: date)
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(snapshot)
            try data.write(to: URL(fileURLWithPath: "/private/tmp/gym-assistant-scratchpad-checkpoint/native-fixture.json"), options: .atomic)
        } catch { status.stringValue = "Fixture read succeeded but synthetic evidence save failed: \(error)"; return }
        let tags = ["h1", "h2", "h3"].map { tag in "\(tag): \(html.components(separatedBy: "<\(tag)").count - 1)" }.joined(separator: ", ")
        status.stringValue = """
        PASS Native read-only Notes API access
        Context lines present: \(lines)/70
        End marker: present
        HTML bytes: \(html.utf8.count); plain-text characters: \(plain.count)
        Native API body/id/date read: \(String(format: "%.3f", readElapsed)) seconds
        Modification date: \(date)
        \(id == nil ? "Captured target and baseline" : "Reread captured target, not current selection")
        Identity matches baseline: \(capturedID == noteID)
        HTML differs from baseline: \(changed.map(String.init) ?? "initial capture")
        Changed HTML with equal reported date: \(changed == true && equalReportedDate)
        Heading tags: \(tags)
        Synthetic HTML/plaintext evidence saved; real note ID omitted
        External edit marker: \(plain.contains("Synthetic row — external change"))
        Native reread marker: \(plain.contains("NATIVE REREAD CHECK"))
        """
    }
}

@main
struct ProbeMain {
    @MainActor static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let delegate = NativeNotesProbe()
        app.delegate = delegate
        app.run()
    }
}
