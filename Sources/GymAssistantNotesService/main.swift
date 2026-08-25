import AppKit
import GymAssistantCore

private enum WorkflowEventLog {
    static let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("gym-assistant-exercise-09-events.jsonl")

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

private enum AutocompletePanelResult {
    case insert(String)
    case cancel
}

private enum AutocompleteRow {
    case exercise(ExerciseSearchMatch)
    case alias(parent: ExerciseSearchMatch, name: String)
}

@MainActor
private final class AutocompleteSearchField: NSSearchField {
    var onMove: ((Int) -> Void)?
    var onExpand: (() -> Void)?
    var onCollapse: (() -> Void)?
    var onChoose: (() -> Void)?
    var onCancel: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 125: onMove?(1)
        case 126: onMove?(-1)
        case 124: onExpand?()
        case 123: onCollapse?()
        case 36, 76: onChoose?()
        case 53: onCancel?()
        default: super.keyDown(with: event)
        }
    }
}

@MainActor
private final class ExerciseAutocompletePanel: NSObject, NSTableViewDataSource, NSTableViewDelegate, NSSearchFieldDelegate {
    private let search: ExerciseAutocompleteSearch
    private let panel: NSPanel
    private let searchField = AutocompleteSearchField()
    private let tableView = NSTableView()
    private let statusField = NSTextField(labelWithString: "Type to search")
    private var matches: [ExerciseSearchMatch] = []
    private var rows: [AutocompleteRow] = []
    private var expandedExerciseID: ExerciseID?
    private var result: AutocompletePanelResult = .cancel

    init(search: ExerciseAutocompleteSearch) {
        self.search = search
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 330),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        super.init()
        configurePanel()
    }

    func runModal() -> AutocompletePanelResult {
        let escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event }
            self?.cancel()
            return nil
        }
        defer {
            if let escapeMonitor {
                NSEvent.removeMonitor(escapeMonitor)
            }
        }
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(searchField)
        WorkflowEventLog.write("autocomplete_ready")
        NSApp.runModal(for: panel)
        panel.orderOut(nil)
        return result
    }

    func numberOfRows(in tableView: NSTableView) -> Int { rows.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let container = NSView()
        let title: String
        let detail: String
        let indent: CGFloat
        switch rows[row] {
        case .exercise(let match):
            title = match.preferredName
            detail = match.aliases.isEmpty ? "" : "\(match.aliases.count) aliases · Right Arrow to view"
            indent = 0
        case .alias(_, let name):
            title = name
            detail = "Confirmed alias"
            indent = 22
        }

        let titleField = NSTextField(labelWithString: title)
        titleField.frame = NSRect(x: 8 + indent, y: 20, width: 440 - indent, height: 22)
        titleField.font = .systemFont(ofSize: 15)
        container.addSubview(titleField)

        let detailField = NSTextField(labelWithString: detail)
        detailField.frame = NSRect(x: 8 + indent, y: 3, width: 440 - indent, height: 17)
        detailField.font = .systemFont(ofSize: 11)
        detailField.textColor = .secondaryLabelColor
        container.addSubview(detailField)
        return container
    }

    func controlTextDidChange(_ notification: Notification) {
        updateResults()
    }

    func control(
        _ control: NSControl,
        textView: NSTextView,
        doCommandBy commandSelector: Selector
    ) -> Bool {
        switch commandSelector {
        case #selector(NSResponder.moveDown(_:)):
            moveSelection(1)
        case #selector(NSResponder.moveUp(_:)):
            moveSelection(-1)
        case #selector(NSResponder.moveRight(_:)):
            expandSelection()
        case #selector(NSResponder.moveLeft(_:)):
            collapseSelection()
        case #selector(NSResponder.insertNewline(_:)):
            chooseSelection()
        case #selector(NSResponder.cancelOperation(_:)):
            cancel()
        default:
            return false
        }
        return true
    }

    private func configurePanel() {
        panel.title = "Gym Assistant"
        panel.isReleasedWhenClosed = false
        let content = NSView(frame: panel.contentRect(forFrameRect: panel.frame))
        panel.contentView = content

        searchField.frame = NSRect(x: 24, y: 270, width: 472, height: 32)
        searchField.placeholderString = "Search exercises"
        searchField.font = .systemFont(ofSize: 16)
        searchField.delegate = self
        searchField.onMove = { [weak self] delta in self?.moveSelection(delta) }
        searchField.onExpand = { [weak self] in self?.expandSelection() }
        searchField.onCollapse = { [weak self] in self?.collapseSelection() }
        searchField.onChoose = { [weak self] in self?.chooseSelection() }
        searchField.onCancel = { [weak self] in self?.cancel() }
        content.addSubview(searchField)

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("autocomplete-result"))
        column.width = 456
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.rowHeight = 46
        tableView.allowsEmptySelection = true
        tableView.allowsMultipleSelection = false
        tableView.dataSource = self
        tableView.delegate = self

        let scrollView = NSScrollView(frame: NSRect(x: 24, y: 52, width: 472, height: 202))
        scrollView.borderType = .bezelBorder
        scrollView.hasVerticalScroller = true
        scrollView.documentView = tableView
        content.addSubview(scrollView)

        statusField.frame = NSRect(x: 24, y: 18, width: 472, height: 22)
        statusField.textColor = .secondaryLabelColor
        content.addSubview(statusField)
    }

    private func updateResults() {
        let updateStartedAt = Date()
        do {
            matches = try search.search(searchField.stringValue)
            expandedExerciseID = nil
            rebuildRows()
            if searchField.stringValue.isEmpty {
                statusField.stringValue = "Type to search"
            } else if matches.isEmpty {
                statusField.stringValue = "Press Return to insert “\(searchField.stringValue)”"
            } else {
                statusField.stringValue = "Return inserts · Right Arrow shows aliases · Escape cancels"
            }
            WorkflowEventLog.write("autocomplete_results", details: [
                "query": searchField.stringValue,
                "resultCount": matches.count,
                "durationMs": Date().timeIntervalSince(updateStartedAt) * 1_000,
            ])
        } catch {
            matches = []
            rows = []
            tableView.reloadData()
            statusField.stringValue = "Search unavailable"
            WorkflowEventLog.write("autocomplete_error", details: ["message": String(describing: error)])
        }
    }

    private func rebuildRows(selecting exerciseID: ExerciseID? = nil) {
        rows = matches.flatMap { match -> [AutocompleteRow] in
            var result: [AutocompleteRow] = [.exercise(match)]
            if expandedExerciseID == match.exerciseID {
                result.append(contentsOf: match.aliases.map { .alias(parent: match, name: $0) })
            }
            return result
        }
        tableView.reloadData()
        guard !rows.isEmpty else {
            tableView.deselectAll(nil)
            return
        }
        let selectedIndex = exerciseID.flatMap { id in
            rows.firstIndex { row in
                if case .exercise(let match) = row { return match.exerciseID == id }
                return false
            }
        } ?? 0
        tableView.selectRowIndexes(IndexSet(integer: selectedIndex), byExtendingSelection: false)
        tableView.scrollRowToVisible(selectedIndex)
    }

    private func moveSelection(_ delta: Int) {
        guard !rows.isEmpty else { return }
        let current = max(0, tableView.selectedRow)
        let next = min(max(current + delta, 0), rows.count - 1)
        tableView.selectRowIndexes(IndexSet(integer: next), byExtendingSelection: false)
        tableView.scrollRowToVisible(next)
    }

    private func expandSelection() {
        let row = tableView.selectedRow
        guard rows.indices.contains(row), case .exercise(let match) = rows[row], !match.aliases.isEmpty else {
            return
        }
        expandedExerciseID = match.exerciseID
        rebuildRows(selecting: match.exerciseID)
        WorkflowEventLog.write("autocomplete_aliases_expanded", details: ["preferredName": match.preferredName])
    }

    private func collapseSelection() {
        let row = tableView.selectedRow
        guard rows.indices.contains(row) else { return }
        let parent: ExerciseSearchMatch
        switch rows[row] {
        case .exercise(let match): parent = match
        case .alias(let match, _): parent = match
        }
        guard expandedExerciseID == parent.exerciseID else { return }
        expandedExerciseID = nil
        rebuildRows(selecting: parent.exerciseID)
    }

    private func chooseSelection() {
        let row = tableView.selectedRow
        if rows.indices.contains(row) {
            let insertion: String
            switch rows[row] {
            case .exercise(let match): insertion = match.preferredName
            case .alias(_, let name): insertion = name
            }
            result = .insert(insertion)
            WorkflowEventLog.write("autocomplete_chosen", details: ["insertion": insertion])
            NSApp.stopModal()
            return
        }

        guard !searchField.stringValue.isEmpty else { return }
        result = .insert(searchField.stringValue)
        WorkflowEventLog.write("autocomplete_query_inserted", details: ["insertion": searchField.stringValue])
        NSApp.stopModal()
    }

    private func cancel() {
        result = .cancel
        WorkflowEventLog.write("autocomplete_cancelled")
        NSApp.stopModal()
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
    private let autocompleteSearch: ExerciseAutocompleteSearch

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
            autocompleteSearch = ExerciseAutocompleteSearch(library: library)
        } catch {
            fatalError("Unable to initialize the exercise library: \(error)")
        }
        super.init()
    }

    @objc(autocompleteExercise:userData:error:)
    func autocompleteExercise(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        WorkflowEventLog.write("autocomplete_service_received")
        let invokingApplication = NSWorkspace.shared.frontmostApplication
        NSApp.activate(ignoringOtherApps: true)
        let panel = ExerciseAutocompletePanel(search: autocompleteSearch)
        switch panel.runModal() {
        case .insert(let text):
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
        case .cancel:
            break
        }
        restoreFocus(to: invokingApplication)
        WorkflowEventLog.write("autocomplete_service_returning")
    }

    @objc(reviewExercise:userData:error:)
    func reviewExercise(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        guard let selectedText = pasteboard.string(forType: .string) else {
            error.pointee = "Gym Assistant did not receive selected text." as NSString
            return
        }
        WorkflowEventLog.write("selection_service_received")
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

        WorkflowEventLog.write("selection_service_returning")
    }

    private func restoreFocus(to application: NSRunningApplication?) {
        guard let application, application.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
            return
        }
        application.activate(options: [.activateIgnoringOtherApps])
        WorkflowEventLog.write("invoking_application_reactivated", details: [
            "bundleIdentifier": application.bundleIdentifier ?? "unknown",
        ])
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
