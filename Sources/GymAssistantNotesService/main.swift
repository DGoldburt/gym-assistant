import AppKit
import GymAssistantCore

private enum WorkflowEventLog {
    static let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("gym-assistant-exercise-08-events.jsonl")

    static func write(_ event: String, details: [String: Any] = [:]) {
        var payload = details
        payload["event"] = event
        payload["timeMs"] = Date().timeIntervalSince1970 * 1_000
        guard var data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]) else {
            return
        }
        data.append(0x0A)
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
        guard let handle = try? FileHandle(forWritingTo: url) else { return }
        defer { try? handle.close() }
        _ = try? handle.seekToEnd()
        try? handle.write(contentsOf: data)
    }
}

private enum PanelResult {
    case link(ExerciseWorkflowCandidate)
    case create(name: String)
    case cancel
}

@MainActor
private final class ExerciseWorkflowPanel: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    private let selectedText: String
    private let candidates: [ExerciseWorkflowCandidate]
    private let panel: NSPanel
    private let content = NSView()
    private let tableView = NSTableView()
    private let nameField = NSTextField()
    private lazy var continueButton = NSButton(
        title: "Continue",
        target: self,
        action: #selector(chooseResult)
    )
    private var result: PanelResult = .cancel

    init(selectedText: String, candidates: [ExerciseWorkflowCandidate]) {
        self.selectedText = selectedText
        self.candidates = candidates
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 290),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        super.init()
        panel.title = "Gym Assistant"
        panel.isReleasedWhenClosed = false
        content.frame = panel.contentRect(forFrameRect: panel.frame)
        panel.contentView = content
        showResults()
    }

    func runModal() -> PanelResult {
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(tableView)
        WorkflowEventLog.write("results_ready", details: ["candidateCount": candidates.count])
        NSApp.runModal(for: panel)
        panel.orderOut(nil)
        return result
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        candidates.count + 1
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let title = row < candidates.count
            ? candidates[row].preferredName
            : "Create New Exercise…"
        let field = NSTextField(labelWithString: title)
        field.font = .systemFont(ofSize: 16, weight: row < candidates.count ? .regular : .semibold)
        return field
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        continueButton.title = tableView.selectedRow < candidates.count
            ? "Link Existing"
            : "Continue"
    }

    @objc private func chooseResult() {
        let row = tableView.selectedRow
        guard row >= 0 else { return }
        if row < candidates.count {
            result = .link(candidates[row])
            WorkflowEventLog.write("link_confirmed", details: ["preferredName": candidates[row].preferredName])
            NSApp.stopModal()
        } else {
            WorkflowEventLog.write("create_selected")
            showCreateForm()
        }
    }

    @objc private func cancel() {
        result = .cancel
        WorkflowEventLog.write("cancelled")
        NSApp.stopModal()
    }

    @objc private func saveNewExercise() {
        let name = nameField.stringValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !name.isEmpty else {
            NSSound.beep()
            return
        }
        result = .create(name: name)
        WorkflowEventLog.write("create_confirmed", details: ["name": name])
        NSApp.stopModal()
    }

    @objc private func backToResults() {
        WorkflowEventLog.write("create_back")
        showResults()
        panel.makeFirstResponder(tableView)
    }

    private func clearContent() {
        content.subviews.forEach { $0.removeFromSuperview() }
    }

    private func showResults() {
        clearContent()

        let prompt = NSTextField(labelWithString: candidates.isEmpty
            ? "No existing match. Create a new exercise or press Escape to cancel."
            : "Choose an existing exercise, create a new one, or press Escape to cancel.")
        prompt.frame = NSRect(x: 24, y: 240, width: 432, height: 28)
        prompt.font = .systemFont(ofSize: 14)
        content.addSubview(prompt)

        if tableView.tableColumns.isEmpty {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("workflow-result"))
            column.width = 416
            tableView.addTableColumn(column)
            tableView.headerView = nil
            tableView.rowHeight = 34
            tableView.allowsEmptySelection = false
            tableView.allowsMultipleSelection = false
            tableView.dataSource = self
            tableView.delegate = self
            tableView.target = self
            tableView.doubleAction = #selector(chooseResult)
        }
        tableView.reloadData()
        tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        tableViewSelectionDidChange(Notification(name: NSTableView.selectionDidChangeNotification))

        let scrollView = NSScrollView(frame: NSRect(x: 24, y: 66, width: 432, height: 160))
        scrollView.borderType = .bezelBorder
        scrollView.hasVerticalScroller = candidates.count > 3
        scrollView.documentView = tableView
        content.addSubview(scrollView)

        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        cancelButton.frame = NSRect(x: 264, y: 18, width: 92, height: 32)
        cancelButton.keyEquivalent = "\u{1b}"
        content.addSubview(cancelButton)

        continueButton.frame = NSRect(x: 364, y: 18, width: 92, height: 32)
        continueButton.keyEquivalent = "\r"
        content.addSubview(continueButton)
    }

    private func showCreateForm() {
        clearContent()

        let heading = NSTextField(labelWithString: "Create New Exercise")
        heading.frame = NSRect(x: 24, y: 230, width: 432, height: 32)
        heading.font = .systemFont(ofSize: 20, weight: .semibold)
        content.addSubview(heading)

        let label = NSTextField(labelWithString: "Name")
        label.frame = NSRect(x: 24, y: 184, width: 432, height: 22)
        label.font = .systemFont(ofSize: 14)
        content.addSubview(label)

        nameField.stringValue = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
        nameField.frame = NSRect(x: 24, y: 142, width: 432, height: 32)
        nameField.font = .systemFont(ofSize: 16)
        content.addSubview(nameField)

        let note = NSTextField(labelWithString: "Only this name will be saved. Return creates it; Escape goes back.")
        note.frame = NSRect(x: 24, y: 100, width: 432, height: 24)
        note.textColor = .secondaryLabelColor
        content.addSubview(note)

        let backButton = NSButton(title: "Back", target: self, action: #selector(backToResults))
        backButton.frame = NSRect(x: 264, y: 18, width: 92, height: 32)
        backButton.keyEquivalent = "\u{1b}"
        content.addSubview(backButton)

        let createButton = NSButton(title: "Create", target: self, action: #selector(saveNewExercise))
        createButton.frame = NSRect(x: 364, y: 18, width: 92, height: 32)
        createButton.keyEquivalent = "\r"
        content.addSubview(createButton)

        panel.makeFirstResponder(nameField)
        nameField.selectText(nil)
        WorkflowEventLog.write("create_form_ready")
    }
}

@MainActor
private final class ExerciseServiceProvider: NSObject {
    private let workflow: ExerciseNameWorkflow

    override init() {
        do {
            let baseURL = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("Gym Assistant", isDirectory: true)
            try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
            let library = try ExerciseLibrary(databaseURL: baseURL.appendingPathComponent("exercise-library.sqlite"))
            workflow = ExerciseNameWorkflow(library: library)
        } catch {
            fatalError("Unable to initialize the exercise library: \(error)")
        }
        super.init()
    }

    @objc(resolveExercise:userData:error:)
    func resolveExercise(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        guard let selectedText = pasteboard.string(forType: .string) else {
            error.pointee = "Gym Assistant did not receive selected text." as NSString
            return
        }
        WorkflowEventLog.write("service_received")
        NSApp.activate(ignoringOtherApps: true)

        do {
            let replacement: String?
            switch try workflow.lookup(selectedText) {
            case .exact(let match):
                WorkflowEventLog.write("exact_match", details: ["preferredName": match.preferredName])
                replacement = match.preferredName
            case .review(let candidates):
                replacement = try handlePanel(selectedText: selectedText, candidates: candidates)
            case .noMatch:
                replacement = try handlePanel(selectedText: selectedText, candidates: [])
            }

            if let replacement {
                pasteboard.clearContents()
                pasteboard.setString(replacement, forType: .string)
            }
        } catch let workflowError {
            error.pointee = "Gym Assistant could not complete the workflow: \(workflowError)" as NSString
            WorkflowEventLog.write("workflow_error", details: ["message": String(describing: workflowError)])
        }

        WorkflowEventLog.write("service_returning")
    }

    private func handlePanel(
        selectedText: String,
        candidates: [ExerciseWorkflowCandidate]
    ) throws -> String? {
        switch ExerciseWorkflowPanel(selectedText: selectedText, candidates: candidates).runModal() {
        case .link(let candidate):
            return try workflow.link(enteredName: selectedText, to: candidate.exerciseID).preferredName
        case .create(let name):
            return try workflow.create(name: name).preferredName
        case .cancel:
            return nil
        }
    }
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate {
    private let serviceProvider = ExerciseServiceProvider()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = serviceProvider
        NSUpdateDynamicServices()
        WorkflowEventLog.write("application_launched")
    }
}

@main
@MainActor
private struct Main {
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        application.run()
    }
}
