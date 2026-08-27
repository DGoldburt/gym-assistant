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
    case reviewLibrary
    case cancel
}

private struct RankedCandidateItem {
    let exerciseID: ExerciseID
    let preferredName: String
    let aliases: [String]
    let matchedName: String
    let detail: String
    let selectable: Bool

    var otherNames: [String] {
        ([preferredName] + aliases).reduce(into: [String]()) { names, name in
            guard name != matchedName, !names.contains(name) else { return }
            names.append(name)
        }
    }
}

private enum RankedCandidateRow {
    case exercise(RankedCandidateItem)
    case alias(parent: RankedCandidateItem, name: String)
}

@MainActor
private final class RankedCandidateTableView: NSTableView {
    var onExpand: (() -> Void)?
    var onCollapse: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 124: onExpand?()
        case 123: onCollapse?()
        default: super.keyDown(with: event)
        }
    }
}

@MainActor
private final class RankedCandidateChooser: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    let tableView = RankedCandidateTableView()
    let scrollView = NSScrollView()
    var onSelectionChange: (() -> Void)?
    private var items: [RankedCandidateItem] = []
    private var rows: [RankedCandidateRow] = []
    private var expandedExerciseID: ExerciseID?

    override init() {
        super.init()
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("ranked-candidate"))
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.rowHeight = 46
        tableView.allowsEmptySelection = true
        tableView.allowsMultipleSelection = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.onExpand = { [weak self] in self?.expandSelection() }
        tableView.onCollapse = { [weak self] in self?.collapseSelection() }
        scrollView.borderType = .bezelBorder
        scrollView.hasVerticalScroller = true
        scrollView.documentView = tableView
    }

    var selectedItem: RankedCandidateItem? {
        guard rows.indices.contains(tableView.selectedRow) else { return nil }
        switch rows[tableView.selectedRow] {
        case .exercise(let item), .alias(let item, _): return item
        }
    }

    var selectedName: String? {
        guard rows.indices.contains(tableView.selectedRow) else { return nil }
        switch rows[tableView.selectedRow] {
        case .exercise(let item): return item.matchedName
        case .alias(_, let name): return name
        }
    }

    func setItems(_ items: [RankedCandidateItem], preselectTop: Bool = true) {
        self.items = items
        expandedExerciseID = nil
        rebuildRows()
        if preselectTop, !rows.isEmpty {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
            tableView.scrollRowToVisible(0)
        }
    }

    func moveSelection(_ delta: Int) {
        guard !rows.isEmpty else { return }
        let current = tableView.selectedRow
        let next: Int
        if current < 0 {
            next = delta >= 0 ? 0 : rows.count - 1
        } else {
            next = min(max(current + delta, 0), rows.count - 1)
        }
        tableView.selectRowIndexes(IndexSet(integer: next), byExtendingSelection: false)
        tableView.scrollRowToVisible(next)
    }

    func expandSelection() {
        guard rows.indices.contains(tableView.selectedRow),
              case .exercise(let item) = rows[tableView.selectedRow],
              !item.otherNames.isEmpty else { return }
        expandedExerciseID = item.exerciseID
        rebuildRows(selecting: item.exerciseID)
    }

    func collapseSelection() {
        guard let item = selectedItem, expandedExerciseID == item.exerciseID else { return }
        expandedExerciseID = nil
        rebuildRows(selecting: item.exerciseID)
    }

    func numberOfRows(in tableView: NSTableView) -> Int { rows.count }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        switch rows[row] {
        case .exercise:
            return 46
        case .alias:
            return 30
        }
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let container = NSView()
        let title: String
        let detail: String
        let indent: CGFloat
        let selectable: Bool
        switch rows[row] {
        case .exercise(let item):
            title = item.matchedName
            detail = exerciseDetail(for: item)
            indent = 0
            selectable = item.selectable
        case .alias(let item, let name):
            title = name
            detail = ""
            indent = 22
            selectable = item.selectable
        }

        let rowHeight = self.tableView(tableView, heightOfRow: row)
        let titleField = NSTextField(labelWithString: title)
        let titleY = detail.isEmpty ? (rowHeight - 20) / 2 : rowHeight - 24
        titleField.frame = NSRect(x: 8 + indent, y: titleY, width: max(0, tableView.bounds.width - 24 - indent), height: 20)
        titleField.font = .systemFont(ofSize: 15)
        container.addSubview(titleField)

        let detailField = NSTextField(labelWithString: detail)
        detailField.frame = NSRect(x: 8 + indent, y: 3, width: max(0, tableView.bounds.width - 24 - indent), height: 17)
        detailField.font = .systemFont(ofSize: 11)
        detailField.textColor = selectable ? .secondaryLabelColor : .systemRed
        container.addSubview(detailField)
        return container
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        onSelectionChange?()
    }

    private func rebuildRows(selecting exerciseID: ExerciseID? = nil) {
        rows = items.flatMap { item -> [RankedCandidateRow] in
            var result: [RankedCandidateRow] = [.exercise(item)]
            if expandedExerciseID == item.exerciseID {
                result.append(contentsOf: item.otherNames.map { .alias(parent: item, name: $0) })
            }
            return result
        }
        tableView.reloadData()
        guard !rows.isEmpty else {
            tableView.deselectAll(nil)
            return
        }
        if let exerciseID,
           let index = rows.firstIndex(where: {
               if case .exercise(let item) = $0 { return item.exerciseID == exerciseID }
               return false
           }) {
            tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
            tableView.scrollRowToVisible(index)
        }
    }

    private func exerciseDetail(for item: RankedCandidateItem) -> String {
        let otherNameSummary: String? = item.otherNames.isEmpty
            ? nil
            : "\(item.otherNames.count) \(item.otherNames.count == 1 ? "alias" : "aliases")"
        return ([item.detail] + [otherNameSummary].compactMap { $0 }).joined(separator: " · ")
    }
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
private final class ExerciseAutocompletePanel: NSObject, NSSearchFieldDelegate {
    private let search: ExerciseAutocompleteSearch
    private let panel: NSPanel
    private let searchField = AutocompleteSearchField()
    private let chooser = RankedCandidateChooser()
    private let statusField = NSTextField(labelWithString: "Type to search")
    private lazy var reviewButton = NSButton(
        title: "Review Library…  ⌘R",
        target: self,
        action: #selector(openLibraryReview)
    )
    private var matches: [ExerciseSearchMatch] = []
    private var result: AutocompletePanelResult = .cancel

    init(search: ExerciseAutocompleteSearch) {
        self.search = search
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 330),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        super.init()
        configurePanel()
    }

    func runModal() -> AutocompletePanelResult {
        let serviceDeadlineTimer = Timer(
            timeInterval: 105,
            target: self,
            selector: #selector(serviceDeadlineReached),
            userInfo: nil,
            repeats: false
        )
        RunLoop.main.add(serviceDeadlineTimer, forMode: .common)
        RunLoop.main.add(serviceDeadlineTimer, forMode: .modalPanel)
        let shortcutMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.keyCode == 53 {
                self.cancel()
                return nil
            }
            return event
        }
        defer {
            serviceDeadlineTimer.invalidate()
            if let shortcutMonitor {
                NSEvent.removeMonitor(shortcutMonitor)
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

    @objc private func serviceDeadlineReached() {
        WorkflowEventLog.write("autocomplete_service_deadline_reached")
        cancel()
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

        searchField.frame = NSRect(x: 24, y: 270, width: 592, height: 32)
        searchField.placeholderString = "Search exercises"
        searchField.font = .systemFont(ofSize: 16)
        searchField.delegate = self
        searchField.onMove = { [weak self] delta in self?.moveSelection(delta) }
        searchField.onExpand = { [weak self] in self?.expandSelection() }
        searchField.onCollapse = { [weak self] in self?.collapseSelection() }
        searchField.onChoose = { [weak self] in self?.chooseSelection() }
        searchField.onCancel = { [weak self] in self?.cancel() }
        content.addSubview(searchField)

        chooser.scrollView.frame = NSRect(x: 24, y: 52, width: 592, height: 202)
        chooser.tableView.tableColumns.first?.width = 576
        chooser.onSelectionChange = { [weak self] in self?.updateSelectionHint() }
        content.addSubview(chooser.scrollView)

        reviewButton.frame = NSRect(x: 24, y: 12, width: 166, height: 30)
        reviewButton.keyEquivalent = "r"
        reviewButton.keyEquivalentModifierMask = [.command]
        reviewButton.toolTip = "Open the observation review queue (Command-R)"
        content.addSubview(reviewButton)

        statusField.frame = NSRect(x: 200, y: 18, width: 416, height: 22)
        statusField.textColor = .secondaryLabelColor
        content.addSubview(statusField)
    }

    private func updateResults() {
        let updateStartedAt = Date()
        do {
            matches = try search.search(searchField.stringValue)
            chooser.setItems(matches.map(autocompleteCandidateItem), preselectTop: false)
            if searchField.stringValue.isEmpty {
                statusField.stringValue = "Type to search"
            } else if matches.isEmpty {
                statusField.stringValue = "Press Return to insert “\(searchField.stringValue)”"
            } else {
                statusField.stringValue = "↩ Insert query · ↓ Select top match"
            }
            WorkflowEventLog.write("autocomplete_results", details: [
                "query": searchField.stringValue,
                "resultCount": matches.count,
                "durationMs": Date().timeIntervalSince(updateStartedAt) * 1_000,
            ])
        } catch {
            matches = []
            chooser.setItems([])
            statusField.stringValue = "Search unavailable"
            WorkflowEventLog.write("autocomplete_error", details: ["message": String(describing: error)])
        }
    }

    private func resultDetail(for match: ExerciseSearchMatch) -> String {
        let evidence: String
        switch match.matchKind {
        case .normalizedName: evidence = "Exact"
        case .namePrefix: evidence = "Prefix"
        case .orderedTokenPrefix: evidence = "Token"
        case .lexicalContainment: evidence = "Contains"
        case .fuzzy: evidence = "Fuzzy"
        }

        return [evidence, compactScore(match.score)].joined(separator: " · ")
    }

    private func autocompleteCandidateItem(_ match: ExerciseSearchMatch) -> RankedCandidateItem {
        .init(
            exerciseID: match.exerciseID,
            preferredName: match.preferredName,
            aliases: match.aliases,
            matchedName: match.matchedName,
            detail: resultDetail(for: match),
            selectable: true
        )
    }

    private func moveSelection(_ delta: Int) {
        chooser.moveSelection(delta)
    }

    private func expandSelection() {
        chooser.expandSelection()
        if let item = chooser.selectedItem {
            WorkflowEventLog.write("autocomplete_aliases_expanded", details: ["preferredName": item.preferredName])
        }
    }

    private func collapseSelection() {
        chooser.collapseSelection()
    }

    private func chooseSelection() {
        if let insertion = chooser.selectedName {
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

    private func updateSelectionHint() {
        guard chooser.selectedName != nil, !matches.isEmpty else { return }
        statusField.stringValue = "Return inserts selected name"
    }

    private func cancel() {
        result = .cancel
        WorkflowEventLog.write("autocomplete_cancelled")
        NSApp.stopModal()
    }

    @objc private func openLibraryReview() {
        result = .reviewLibrary
        WorkflowEventLog.write("library_review_selected")
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
private final class LibraryReviewWindowController: NSObject, NSWindowDelegate {
    private let service: ExerciseIdentityReviewService
    private let window: NSWindow
    private let observationField = NSTextField(wrappingLabelWithString: "")
    private let metaField = NSTextField(labelWithString: "")
    private let sourceField = NSTextField(wrappingLabelWithString: "")
    private let statusField = NSTextField(labelWithString: "")
    private let chooser = RankedCandidateChooser()
    private lazy var linkButton = NSButton(
        title: "Link Selected",
        target: self,
        action: #selector(linkSelected)
    )
    private lazy var backButton = NSButton(
        title: "← Back",
        target: self,
        action: #selector(undoLastDecision)
    )
    private var queue: [ExerciseReviewQueueItem] = []
    private var current: ExerciseReviewQueueItem?
    private var candidates: [ExerciseReviewCandidate] = []
    private var skippedThisSession: Set<ExerciseObservationID> = []
    private var returnFocusTo: NSRunningApplication?
    private var shortcutMonitor: Any?
    private var pendingCount = 0
    private var skippedCount = 0
    private var lastUndoReceipt: ExerciseIdentityReviewUndoReceipt?
    private var feedbackMessage = ""

    init(service: ExerciseIdentityReviewService) {
        self.service = service
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 500),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        super.init()
        chooser.onSelectionChange = { [weak self] in self?.updateLinkAvailability() }
        configureWindow()
    }

    func show(returnFocusTo application: NSRunningApplication?) {
        returnFocusTo = application
        skippedThisSession.removeAll()
        lastUndoReceipt = nil
        feedbackMessage = ""
        reloadQueue()
        window.center()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(chooser.tableView)
        installShortcutMonitor()
        WorkflowEventLog.write("library_review_ready", details: ["queueCount": queue.count])
    }

    func windowWillClose(_ notification: Notification) {
        if let shortcutMonitor {
            NSEvent.removeMonitor(shortcutMonitor)
            self.shortcutMonitor = nil
        }
        WorkflowEventLog.write("library_review_closed")
        restoreFocus()
    }

    private func configureWindow() {
        window.title = "Gym Assistant — Review Library"
        window.isReleasedWhenClosed = false
        window.delegate = self
        let content = NSView(frame: window.contentRect(forFrameRect: window.frame))
        window.contentView = content

        observationField.frame = NSRect(x: 24, y: 432, width: 592, height: 42)
        observationField.font = .systemFont(ofSize: 22, weight: .semibold)
        content.addSubview(observationField)

        metaField.frame = NSRect(x: 24, y: 405, width: 592, height: 20)
        metaField.textColor = .secondaryLabelColor
        content.addSubview(metaField)

        sourceField.frame = NSRect(x: 24, y: 332, width: 592, height: 62)
        sourceField.font = .systemFont(ofSize: 12)
        sourceField.textColor = .secondaryLabelColor
        content.addSubview(sourceField)

        chooser.scrollView.frame = NSRect(x: 24, y: 112, width: 592, height: 208)
        chooser.tableView.tableColumns.first?.width = 576
        content.addSubview(chooser.scrollView)

        backButton.title = "← Back  ⌘Z"
        backButton.frame = NSRect(x: 24, y: 54, width: 120, height: 32)
        backButton.isEnabled = false
        content.addSubview(backButton)

        let deferButton = NSButton(title: "Skip & Next  ⌘S", target: self, action: #selector(skipCurrent))
        deferButton.frame = NSRect(x: 494, y: 54, width: 122, height: 32)
        content.addSubview(deferButton)

        let createButton = NSButton(title: "Create Exact  ⌘C", target: self, action: #selector(createCurrent))
        createButton.frame = NSRect(x: 240, y: 54, width: 154, height: 32)
        createButton.keyEquivalent = "c"
        createButton.keyEquivalentModifierMask = [.command]
        content.addSubview(createButton)

        linkButton.title = "Link  ⌘L"
        linkButton.frame = NSRect(x: 400, y: 54, width: 88, height: 32)
        linkButton.keyEquivalent = "l"
        linkButton.keyEquivalentModifierMask = [.command]
        linkButton.isEnabled = false
        content.addSubview(linkButton)

        statusField.frame = NSRect(x: 24, y: 18, width: 592, height: 22)
        statusField.textColor = .secondaryLabelColor
        content.addSubview(statusField)
    }

    private func reloadQueue(
        preferredObservationID: ExerciseObservationID? = nil,
        feedback: String = ""
    ) {
        do {
            let fullQueue = try service.reviewQueue()
            pendingCount = fullQueue.filter { $0.status == .pending }.count
            skippedCount = fullQueue.filter { $0.status == .deferred }.count
            queue = fullQueue.filter { !skippedThisSession.contains($0.observation.id) }
            if let preferredObservationID,
               let index = queue.firstIndex(where: { $0.observation.id == preferredObservationID }) {
                queue.insert(queue.remove(at: index), at: 0)
            }
            feedbackMessage = feedback
            current = queue.first
            candidates = []
            if let current {
                if case .review(_, let preparedCandidates) = try service.prepare(
                    observationID: current.observation.id
                ) {
                    candidates = preparedCandidates
                }
            }
            render()
        } catch {
            current = nil
            candidates = []
            render(error: error)
        }
    }

    private func render(error: Error? = nil) {
        if let error {
            window.title = "Gym Assistant — Review Library"
            observationField.stringValue = "Review unavailable"
            metaField.stringValue = ""
            sourceField.stringValue = ""
            statusField.stringValue = String(describing: error)
        } else if let current {
            window.title = "Gym Assistant — Review Library · \(pendingCount) to review · \(skippedCount) skipped"
            observationField.stringValue = current.observation.observedName
            let occurrenceSummary = current.observation.occurrenceCount == 1
                ? "Observed once"
                : "Observed \(current.observation.occurrenceCount) times"
            metaField.stringValue = occurrenceSummary
            sourceField.stringValue = current.occurrences.prefix(2).map { occurrence in
                let evidence = occurrence.evidence.isEmpty ? "" : "\n\(String(occurrence.evidence.prefix(220)))"
                return "Observed in: \(occurrence.sourceReference)\(evidence)"
            }.joined(separator: "\n")
            statusField.stringValue = feedbackMessage
        } else {
            window.title = "Gym Assistant — Review Library · 0 to review · \(skippedCount) skipped"
            observationField.stringValue = "Nothing needs review"
            metaField.stringValue = ""
            sourceField.stringValue = ""
            statusField.stringValue = ""
        }
        chooser.setItems(candidates.map(reviewCandidateItem), preselectTop: true)
        updateLinkAvailability()
        backButton.isEnabled = lastUndoReceipt != nil
    }

    @objc private func linkSelected() {
        guard let current, let selected = chooser.selectedItem,
              let candidate = candidates.first(where: { $0.exerciseID == selected.exerciseID }) else { return }
        guard candidate.linkAllowed else { return }
        applyDecision("Link") {
            try service.linkWithUndoReceipt(
                observationID: current.observation.id,
                to: candidate.exerciseID
            )
        }
    }

    @objc private func createCurrent() {
        guard let current else { return }
        applyDecision("Create") {
            try service.createWithUndoReceipt(observationID: current.observation.id)
        }
    }

    @objc private func skipCurrent() {
        guard let current else { return }
        applyDecision("Skip") {
            try service.skipWithUndoReceipt(observationID: current.observation.id)
        }
    }

    private func applyDecision(
        _ decision: String,
        operation: () throws -> (ExerciseIdentityReviewResult, ExerciseIdentityReviewUndoReceipt)
    ) {
        do {
            let observationID = current?.observation.id.rawValue ?? "unknown"
            let (_, receipt) = try operation()
            lastUndoReceipt = receipt
            if receipt.decision == .deferred {
                skippedThisSession.insert(receipt.observationID)
            }
            WorkflowEventLog.write("library_review_decision", details: [
                "decision": decision,
                "observationID": observationID,
            ])
            reloadQueue()
        } catch {
            NSSound.beep()
            statusField.stringValue = "Could not save: \(error)"
            WorkflowEventLog.write("library_review_error", details: ["message": String(describing: error)])
        }
    }

    @objc private func closeReview() {
        window.performClose(nil)
    }

    @objc private func undoLastDecision() {
        guard let receipt = lastUndoReceipt else { return }
        do {
            try service.undo(receipt)
            skippedThisSession.remove(receipt.observationID)
            lastUndoReceipt = nil
            let restored = receipt.previousStatus == .deferred ? "Skipped" : "Ready for review"
            reloadQueue(
                preferredObservationID: receipt.observationID,
                feedback: "Undid \(reviewDecisionLabel(receipt.decision)) · restored previous status: \(restored)"
            )
        } catch {
            NSSound.beep()
            statusField.stringValue = "Could not undo safely: \(error)"
        }
    }

    private func installShortcutMonitor() {
        guard shortcutMonitor == nil else { return }
        shortcutMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.window.isKeyWindow else { return event }
            if event.keyCode == 53 {
                self.closeReview()
                return nil
            }
            guard
                  event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [.command],
                  let key = event.charactersIgnoringModifiers?.lowercased() else { return event }
            switch key {
            case "c": self.createCurrent()
            case "l": self.linkSelected()
            case "s": self.skipCurrent()
            case "z":
                guard self.backButton.isEnabled else { return event }
                self.undoLastDecision()
            default: return event
            }
            return nil
        }
    }

    private func reviewCandidateItem(_ candidate: ExerciseReviewCandidate) -> RankedCandidateItem {
        return .init(
            exerciseID: candidate.exerciseID,
            preferredName: candidate.preferredName,
            aliases: candidate.aliases,
            matchedName: candidate.matchedName,
            detail: candidate.evidence.map(reviewEvidenceText).joined(separator: " · "),
            selectable: candidate.linkAllowed
        )
    }

    private func updateLinkAvailability() {
        linkButton.isEnabled = chooser.selectedItem?.selectable == true
    }

    private func restoreFocus() {
        guard let application = returnFocusTo,
              application.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return }
        application.activate(options: [.activateIgnoringOtherApps])
        returnFocusTo = nil
        WorkflowEventLog.write("invoking_application_reactivated", details: [
            "bundleIdentifier": application.bundleIdentifier ?? "unknown",
        ])
    }
}

private func reviewDecisionLabel(_ status: ExerciseObservationReviewStatus) -> String {
    switch status {
    case .created: return "Create"
    case .linked: return "Link"
    case .deferred: return "Skip"
    case .pending: return "review"
    }
}

private func reviewEvidenceText(_ evidence: ExerciseReviewEvidence) -> String {
    switch evidence {
    case .conservativeTransformation(let detail): return "Transform · \(detail)"
    case .lexicalSimilarity(let score): return "Lexical · \(compactScore(score))"
    case .prescriptionDifference(let detail): return "Prescription · \(detail)"
    case .identityConflict(let detail): return "Cannot link · \(detail)"
    }
}

private func compactScore(_ score: Double) -> String {
    if score == 1 { return "1.00" }
    let formatted = score >= 0.995
        ? String(format: "%.3f", score)
        : String(format: "%.2f", score)
    return formatted.hasPrefix("0") ? String(formatted.dropFirst()) : formatted
}

@MainActor
private final class ExerciseServiceProvider: NSObject {
    private let workflow: ExerciseNameWorkflow
    private let autocompleteSearch: ExerciseAutocompleteSearch
    private let identityReview: ExerciseIdentityReviewService
    private var libraryReviewWindow: LibraryReviewWindowController?

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
            identityReview = ExerciseIdentityReviewService(library: library)
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
            restoreFocus(to: invokingApplication)
        case .reviewLibrary:
            DispatchQueue.main.async { [weak self] in
                self?.showLibraryReview(returnFocusTo: invokingApplication)
            }
        case .cancel:
            restoreFocus(to: invokingApplication)
        }
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

    private func showLibraryReview(returnFocusTo application: NSRunningApplication?) {
        let controller: LibraryReviewWindowController
        if let libraryReviewWindow {
            controller = libraryReviewWindow
        } else {
            controller = LibraryReviewWindowController(service: identityReview)
            libraryReviewWindow = controller
        }
        controller.show(returnFocusTo: application)
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
