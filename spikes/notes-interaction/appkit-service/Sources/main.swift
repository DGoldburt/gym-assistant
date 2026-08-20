import AppKit

private enum SpikeEventLog {
    private static let eventURL = URL(fileURLWithPath: "/private/tmp/gym-assistant-notes-spike-events.jsonl")
    private static let trialURL = URL(fileURLWithPath: "/private/tmp/gym-assistant-notes-spike-current-trial.txt")

    static var currentTrial: String {
        (try? String(contentsOf: trialURL, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)) ?? "unlabeled"
    }

    static func write(_ event: String) {
        let payload: [String: Any] = [
            "event": event,
            "timeMs": Date().timeIntervalSince1970 * 1_000,
            "trial": currentTrial,
        ]
        guard var data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]) else {
            return
        }
        data.append(0x0A)

        if !FileManager.default.fileExists(atPath: eventURL.path) {
            FileManager.default.createFile(atPath: eventURL.path, contents: nil)
        }
        guard let handle = try? FileHandle(forWritingTo: eventURL) else { return }
        defer { try? handle.close() }
        _ = try? handle.seekToEnd()
        try? handle.write(contentsOf: data)
    }

    static func recordSettledState() {
        let shouldTerminate = currentTrial.hasPrefix("C")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(17)) {
            write("visible_proxy")
            if shouldTerminate {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                    NSApp.terminate(nil)
                }
            }
        }
    }
}

@MainActor
final class ExerciseChooser: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    private let exercises: [String]
    private let panel: NSPanel
    private let tableView = NSTableView()

    init(exercises: [String]) {
        self.exercises = exercises
        self.panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 250),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        super.init()
        configurePanel()
    }

    func runModal() -> String? {
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(tableView)
        SpikeEventLog.write("chooser_ready")
        let response = NSApp.runModal(for: panel)
        panel.orderOut(nil)

        guard response == .OK, tableView.selectedRow >= 0 else {
            return nil
        }
        return exercises[tableView.selectedRow]
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        exercises.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let field = NSTextField(labelWithString: exercises[row])
        field.font = .systemFont(ofSize: 16)
        return field
    }

    @objc private func replace() {
        SpikeEventLog.write("confirm")
        NSApp.stopModal(withCode: .OK)
    }

    @objc private func cancel() {
        SpikeEventLog.write("cancel")
        NSApp.stopModal(withCode: .cancel)
    }

    @objc private func replaceFromDoubleClick() {
        guard tableView.clickedRow >= 0 else { return }
        tableView.selectRowIndexes(IndexSet(integer: tableView.clickedRow), byExtendingSelection: false)
        replace()
    }

    private func configurePanel() {
        panel.title = "Choose an exercise"
        panel.isReleasedWhenClosed = false

        let content = NSView(frame: panel.contentRect(forFrameRect: panel.frame))
        panel.contentView = content

        let prompt = NSTextField(labelWithString: "Use ↑/↓ to choose, Return to replace, or Escape to cancel.")
        prompt.frame = NSRect(x: 24, y: 205, width: 392, height: 24)
        prompt.font = .systemFont(ofSize: 14)
        content.addSubview(prompt)

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("exercise"))
        column.width = 380
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.rowHeight = 32
        tableView.allowsEmptySelection = false
        tableView.allowsMultipleSelection = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.target = self
        tableView.doubleAction = #selector(replaceFromDoubleClick)
        tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)

        let scrollView = NSScrollView(frame: NSRect(x: 24, y: 64, width: 392, height: 132))
        scrollView.borderType = .bezelBorder
        scrollView.hasVerticalScroller = false
        scrollView.documentView = tableView
        content.addSubview(scrollView)

        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        cancelButton.frame = NSRect(x: 224, y: 18, width: 92, height: 32)
        cancelButton.keyEquivalent = "\u{1b}"
        content.addSubview(cancelButton)

        let replaceButton = NSButton(title: "Replace", target: self, action: #selector(replace))
        replaceButton.frame = NSRect(x: 324, y: 18, width: 92, height: 32)
        replaceButton.keyEquivalent = "\r"
        replaceButton.bezelStyle = .rounded
        content.addSubview(replaceButton)
    }
}

@MainActor
final class ExerciseServiceProvider: NSObject {
    private let exercises = [
        "Front Squat",
        "Single-Leg Romanian Deadlift",
        "Aussie Pull-up",
    ]

    @objc(chooseExercise:userData:error:)
    func chooseExercise(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        SpikeEventLog.write("service_received")
        guard pasteboard.string(forType: .string) != nil else {
            error.pointee = "The service did not receive selected text." as NSString
            return
        }

        NSApp.activate(ignoringOtherApps: true)

        let chooser = ExerciseChooser(exercises: exercises)
        let replacement = chooser.runModal()

        guard let replacement else {
            NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Notes")
                .first?
                .activate(options: [.activateAllWindows])
            SpikeEventLog.write("service_returning")
            SpikeEventLog.recordSettledState()
            return
        }

        pasteboard.clearContents()
        pasteboard.setString(replacement, forType: .string)

        NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Notes")
            .first?
            .activate(options: [.activateAllWindows])
        SpikeEventLog.write("service_returning")
        SpikeEventLog.recordSettledState()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let serviceProvider = ExerciseServiceProvider()

    func applicationDidFinishLaunching(_ notification: Notification) {
        SpikeEventLog.write("application_launched")
        NSApp.servicesProvider = serviceProvider
        NSUpdateDynamicServices()
    }
}

@main
@MainActor
struct Main {
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        application.run()
    }
}
