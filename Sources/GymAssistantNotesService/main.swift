import AppKit
import GymAssistantCore
import UniformTypeIdentifiers

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

private enum FieldFeedbackRecorder {
    static func append(_ interaction: FeedbackInteraction, panelScreenshot: Data? = nil) {
        // Disposable foreground trials must not append synthetic events to the
        // user's private feedback ledger.
        guard ProcessInfo.processInfo.environment["GYM_ASSISTANT_DATABASE_PATH"] == nil else { return }
        do {
            let store = try FeedbackFileStore.applicationSupport()
            try store.append(interaction)
            if let panelScreenshot {
                try store.savePanelScreenshot(panelScreenshot, eventID: interaction.eventID)
            }
        }
        catch { WorkflowEventLog.write("field_feedback_write_failed", details: ["message": String(describing: error)]) }
    }
}

@MainActor
private func panelScreenshotPNG(_ window: NSWindow) -> Data? {
    guard let view = window.contentView?.superview ?? window.contentView else { return nil }
    let bounds = view.bounds
    guard !bounds.isEmpty, let bitmap = view.bitmapImageRepForCachingDisplay(in: bounds) else { return nil }
    view.cacheDisplay(in: bounds, to: bitmap)
    return bitmap.representation(using: .png, properties: [:])
}

private enum AutocompletePanelResult {
    case insert(String)
    case maintenance(LibraryMaintenanceNavigation)
    case cancel
}

private struct RankedCandidateItem {
    let exerciseID: ExerciseID
    let preferredName: String
    let aliases: [String]
    let matchedName: String
    let detail: String
    let selectable: Bool
    var nameIDs: [String: ExerciseNameID] = [:]

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
    private var expansion = ExerciseChooserExpansion()

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

    var selectedNameID: ExerciseNameID? {
        guard let item = selectedItem, let name = selectedName else { return nil }
        return item.nameIDs[name]
    }

    var isAliasSelected: Bool {
        guard rows.indices.contains(tableView.selectedRow) else { return false }
        if case .alias = rows[tableView.selectedRow] { return true }
        return false
    }

    var selectedExerciseRank: Int? {
        guard let selectedItem, let index = items.firstIndex(where: { $0.exerciseID == selectedItem.exerciseID }) else { return nil }
        return index + 1
    }

    func setItems(_ items: [RankedCandidateItem], preselectTop: Bool = true) {
        self.items = items
        expansion.reset()
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
        expansion.expand(item.exerciseID)
        rebuildRows(selecting: item.exerciseID)
    }

    func collapseSelection() {
        guard let item = selectedItem, expansion.expandedIDs.contains(item.exerciseID) else { return }
        expansion.collapse(item.exerciseID)
        rebuildRows(selecting: item.exerciseID)
    }

    func restoreSelection(exerciseID: ExerciseID, name: String?) {
        guard let item = items.first(where: { $0.exerciseID == exerciseID }) else { return }
        if let name, name != item.matchedName, item.otherNames.contains(name) {
            expansion.expand(exerciseID)
            rebuildRows(selecting: exerciseID)
        }
        if let index = rows.firstIndex(where: { row in
            switch row {
            case .exercise(let candidate): return candidate.exerciseID == exerciseID && candidate.matchedName == name
            case .alias(let parent, let alias): return parent.exerciseID == exerciseID && alias == name
            }
        }) {
            tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        }
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
            if expansion.expandedIDs.contains(item.exerciseID) {
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
private final class ExerciseAutocompletePanel: NSObject, NSSearchFieldDelegate, NSWindowDelegate {
    private let search: ExerciseAutocompleteSearch
    private let panel: NSPanel
    private let searchField = AutocompleteSearchField()
    private let chooser = RankedCandidateChooser()
    private let statusField = NSTextField(labelWithString: "Type to search")
    private lazy var reviewButton = NSButton(
        title: "Add Exercises…  ⌘R",
        target: self,
        action: #selector(openLibraryReview)
    )
    private lazy var editButton = NSButton(title: "Edit Library…  ⌘E", target: self, action: #selector(openLibraryEdit))
    private var matches: [ExerciseSearchMatch] = []
    private var result: AutocompletePanelResult = .cancel
    private let sessionID = UUID()
    private let startedAt = Date()
    private var aliasesExpanded = false
    private var deactivationCount = 0
    private var returnedAfterDeactivation = false
    private var lastReturnAt: Date?
    private lazy var reportButton: NSButton = {
        let button = NSButton(image: NSImage(systemSymbolName: "exclamationmark.bubble", accessibilityDescription: "Report Issue")!, target: self, action: #selector(reportIssue))
        button.bezelStyle = .inline
        button.isBordered = false
        button.toolTip = "Report a surprising result (Shift-Command-R)"
        return button
    }()

    init(search: ExerciseAutocompleteSearch) {
        self.search = search
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 330),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        super.init()
        panel.delegate = self
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
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if modifiers == [.command, .shift], event.charactersIgnoringModifiers?.lowercased() == "r" {
                self.reportIssue()
                return nil
            }
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
        reviewButton.toolTip = "Add an exercise or import candidates (Command-R)"
        content.addSubview(reviewButton)

        editButton.frame = NSRect(x: 200, y: 12, width: 166, height: 30)
        editButton.keyEquivalent = "e"
        editButton.keyEquivalentModifierMask = [.command]
        editButton.isEnabled = true
        content.addSubview(editButton)

        statusField.frame = NSRect(x: 375, y: 18, width: 241, height: 22)
        statusField.textColor = .secondaryLabelColor
        content.addSubview(statusField)

        reportButton.frame = NSRect(x: 588, y: 270, width: 28, height: 28)
        content.addSubview(reportButton)
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
            selectable: true,
            nameIDs: Dictionary(uniqueKeysWithValues: match.confirmedNames.map { ($0.text, $0.id) })
        )
    }

    private func moveSelection(_ delta: Int) {
        chooser.moveSelection(delta)
    }

    private func expandSelection() {
        chooser.expandSelection()
        aliasesExpanded = true
        if let item = chooser.selectedItem {
            WorkflowEventLog.write("autocomplete_aliases_expanded", details: ["preferredName": item.preferredName])
        }
    }

    private func collapseSelection() {
        chooser.collapseSelection()
    }

    private func chooseSelection() {
        if let insertion = chooser.selectedName {
            record(.init(kind: .insertedCandidate, selectedRank: chooser.selectedExerciseRank, selectedName: insertion))
            result = .insert(insertion)
            WorkflowEventLog.write("autocomplete_chosen", details: ["insertion": insertion])
            NSApp.stopModal()
            return
        }

        guard !searchField.stringValue.isEmpty else { return }
        record(.init(kind: .insertedQuery, selectedName: searchField.stringValue))
        result = .insert(searchField.stringValue)
        WorkflowEventLog.write("autocomplete_query_inserted", details: ["insertion": searchField.stringValue])
        NSApp.stopModal()
    }

    private func updateSelectionHint() {
        guard chooser.selectedName != nil, !matches.isEmpty else { return }
        statusField.stringValue = "Return inserts selected name"
    }

    private func cancel() {
        record(.init(kind: .cancelled))
        result = .cancel
        WorkflowEventLog.write("autocomplete_cancelled")
        NSApp.stopModal()
    }

    @objc private func openLibraryReview() {
        record(.init(kind: .opened))
        result = .maintenance(.init(route: .add, query: searchField.stringValue, selection: selectedLibraryIdentity))
        WorkflowEventLog.write("add_exercises_selected")
        NSApp.stopModal()
    }

    private var selectedLibraryIdentity: LibraryMaintenanceSelection? {
        guard let item = chooser.selectedItem, let nameID = chooser.selectedNameID else { return nil }
        return .init(exerciseID: item.exerciseID, nameID: nameID)
    }

    @objc private func openLibraryEdit() {
        record(.init(kind: .opened))
        result = .maintenance(.init(route: .edit, query: searchField.stringValue, selection: selectedLibraryIdentity))
        WorkflowEventLog.write("edit_library_selected")
        NSApp.stopModal()
    }

    @objc private func reportIssue() {
        record(
            .init(kind: .opened, selectedRank: chooser.selectedExerciseRank, selectedName: chooser.selectedName),
            flagged: true
        )
        statusField.stringValue = "Issue captured — you can keep working"
    }

    func windowDidResignKey(_ notification: Notification) {
        guard panel.isVisible else { return }
        deactivationCount += 1
    }

    func windowDidBecomeKey(_ notification: Notification) {
        if deactivationCount > 0 {
            returnedAfterDeactivation = true
            lastReturnAt = Date()
        }
    }

    private func record(_ outcome: FeedbackOutcome, flagged: Bool = false) {
        let snapshots = matches.enumerated().map { index, match in
            FeedbackCandidateSnapshot(
                rank: index + 1,
                exerciseID: match.exerciseID.rawValue.uuidString,
                preferredName: match.preferredName,
                matchedName: match.matchedName,
                aliases: match.aliases,
                evidence: [resultDetail(for: match)],
                score: match.score,
                linkAllowed: true
            )
        }
        let interaction = FeedbackInteraction(
            sessionID: sessionID,
            workflow: .autocomplete,
            queryOrObservation: searchField.stringValue,
            candidates: snapshots,
            outcome: outcome,
            durationMilliseconds: Int(Date().timeIntervalSince(startedAt) * 1_000),
            aliasesExpanded: aliasesExpanded,
            deactivationCount: deactivationCount,
            returnedAfterDeactivation: returnedAfterDeactivation,
            lastReturnToOutcomeMilliseconds: lastReturnAt.map { Int(Date().timeIntervalSince($0) * 1_000) },
            userFlagged: flagged
        )
        FieldFeedbackRecorder.append(
            interaction,
            panelScreenshot: flagged ? panelScreenshotPNG(panel) : nil
        )
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
    var onReturnToImport: (() -> Void)?
    private lazy var queueView = NSSegmentedControl(labels: ["To review", "Skipped"], trackingMode: .selectOne, target: self, action: #selector(changeQueueView))
    private var showsSourceDetails = false
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
        title: "Undo",
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
    private var sessionID = UUID()
    private var interactionStartedAt = Date()
    private var aliasesExpanded = false
    private var deactivationCount = 0
    private var returnedAfterDeactivation = false
    private var lastReturnAt: Date?
    private lazy var reportButton: NSButton = {
        let button = NSButton(image: NSImage(systemSymbolName: "exclamationmark.bubble", accessibilityDescription: "Report Issue")!, target: self, action: #selector(reportIssue))
        button.bezelStyle = .inline
        button.isBordered = false
        button.toolTip = "Report a surprising result (Shift-Command-R)"
        return button
    }()

    init(service: ExerciseIdentityReviewService, window: NSWindow) {
        self.service = service
        self.window = window
        super.init()
        chooser.onSelectionChange = { [weak self] in self?.updateLinkAvailability() }
        configureWindow()
    }

    func show(returnFocusTo application: NSRunningApplication?) {
        configureWindow()
        returnFocusTo = application
        reloadQueue(feedback: feedbackMessage)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(chooser.tableView)
        installShortcutMonitor()
        WorkflowEventLog.write("library_review_ready", details: ["queueCount": queue.count])
    }

    func resetSession() {
        showsSourceDetails = false
        skippedThisSession.removeAll()
        lastUndoReceipt = nil
        feedbackMessage = ""
        sessionID = UUID()
        interactionStartedAt = Date()
        aliasesExpanded = false
        deactivationCount = 0
        returnedAfterDeactivation = false
        lastReturnAt = nil
        queueView.selectedSegment = 0
    }

    func deactivate() {
        if let shortcutMonitor { NSEvent.removeMonitor(shortcutMonitor) }
        shortcutMonitor = nil
    }

    func windowWillClose(_ notification: Notification) {
        record(.init(kind: .cancelled))
        if let shortcutMonitor {
            NSEvent.removeMonitor(shortcutMonitor)
            self.shortcutMonitor = nil
        }
        WorkflowEventLog.write("library_review_closed")
        restoreFocus()
    }

    func windowDidResignKey(_ notification: Notification) {
        guard window.isVisible else { return }
        deactivationCount += 1
    }

    func windowDidBecomeKey(_ notification: Notification) {
        if deactivationCount > 0 {
            returnedAfterDeactivation = true
            lastReturnAt = Date()
        }
    }

    private func configureWindow() {
        window.title = "Gym Assistant — Review candidates"
        window.isReleasedWhenClosed = false
        let content = NSView(frame: window.contentRect(forFrameRect: window.frame))
        window.contentView = content

        observationField.frame = NSRect(x: 24, y: 400, width: 592, height: 42)
        observationField.font = .systemFont(ofSize: 22, weight: .semibold)
        content.addSubview(observationField)

        metaField.frame = NSRect(x: 24, y: 376, width: 440, height: 20)
        metaField.textColor = .secondaryLabelColor
        content.addSubview(metaField)

        sourceField.frame = NSRect(x: 24, y: 316, width: 592, height: 52)
        sourceField.font = .systemFont(ofSize: 12)
        sourceField.textColor = .secondaryLabelColor
        if showsSourceDetails { content.addSubview(sourceField) }
        let detailsButton = NSButton(title: showsSourceDetails ? "Hide Details  ⌘D" : "Details  ⌘D", target: self, action: #selector(toggleSourceDetails))
        detailsButton.frame = NSRect(x: 466, y: 370, width: 150, height: 28)
        detailsButton.keyEquivalent = "d"
        detailsButton.keyEquivalentModifierMask = [.command]
        content.addSubview(detailsButton)

        chooser.scrollView.frame = NSRect(x: 24, y: 110, width: 592, height: showsSourceDetails ? 194 : 250)
        chooser.tableView.tableColumns.first?.width = 576
        content.addSubview(chooser.scrollView)

        backButton.title = "Undo  ⌘Z"
        backButton.toolTip = "Undo the last review decision in this session; later library edits may prevent undo."
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

        reportButton.frame = NSRect(x: 588, y: 450, width: 28, height: 28)
        content.addSubview(reportButton)

        queueView.frame = NSRect(x: 24, y: 450, width: 240, height: 30)
        queueView.selectedSegment = max(0, queueView.selectedSegment)
        queueView.toolTip = "To review: Command-1 · Skipped: Command-2"
        content.addSubview(queueView)
        // Keep queue navigation distinct from undoing a decision.
        let parentBack = NSButton(title: "← Import  Esc", target: self, action: #selector(closeReview))
        parentBack.frame = NSRect(x: 430, y: 450, width: 150, height: 28)
        content.addSubview(parentBack)
    }

    @objc private func toggleSourceDetails() {
        let selectedID = chooser.selectedItem?.exerciseID
        let selectedName = chooser.selectedName
        showsSourceDetails.toggle()
        configureWindow()
        render()
        if let selectedID { chooser.restoreSelection(exerciseID: selectedID, name: selectedName) }
        window.makeFirstResponder(chooser.tableView)
    }

    @objc private func changeQueueView() {
        skippedThisSession.removeAll()
        reloadQueue()
    }

    private func reloadQueue(
        preferredObservationID: ExerciseObservationID? = nil,
        feedback: String = ""
    ) {
        do {
            let fullQueue = try service.reviewQueue()
            pendingCount = fullQueue.filter { $0.status == .pending }.count
            skippedCount = fullQueue.filter { $0.status == .deferred }.count
            let status: ExerciseObservationReviewStatus = queueView.selectedSegment == 1 ? .deferred : .pending
            queue = fullQueue.filter { $0.status == status && !skippedThisSession.contains($0.observation.id) }
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
            window.title = "Gym Assistant — Review candidates"
            observationField.stringValue = "Review unavailable"
            metaField.stringValue = ""
            sourceField.stringValue = ""
            statusField.stringValue = String(describing: error)
        } else if let current {
            window.title = "Gym Assistant — Review candidates · \(pendingCount) to review · \(skippedCount) skipped"
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
            window.title = "Gym Assistant — Review candidates · \(pendingCount) to review · \(skippedCount) skipped"
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
            let outcomeKind: FeedbackOutcomeKind = decision == "Link" ? .linked : decision == "Create" ? .created : .skipped
            record(.init(kind: outcomeKind, selectedRank: chooser.selectedExerciseRank, selectedName: chooser.selectedName))
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
            interactionStartedAt = Date()
            aliasesExpanded = false
            deactivationCount = 0
            returnedAfterDeactivation = false
            lastReturnAt = nil
        } catch {
            NSSound.beep()
            statusField.stringValue = "Could not save: \(error)"
            WorkflowEventLog.write("library_review_error", details: ["message": String(describing: error)])
        }
    }

    @objc private func closeReview() {
        deactivate()
        onReturnToImport?()
    }

    @objc private func undoLastDecision() {
        guard let receipt = lastUndoReceipt else { return }
        do {
            record(.init(kind: .backed))
            try service.undo(receipt)
            skippedThisSession.remove(receipt.observationID)
            lastUndoReceipt = nil
            let restored = receipt.previousStatus == .deferred ? "Skipped" : "Ready for review"
            queueView.selectedSegment = receipt.previousStatus == .deferred ? 1 : 0
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
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard modifiers == [.command] || modifiers == [.command, .shift],
                  let key = event.charactersIgnoringModifiers?.lowercased() else { return event }
            switch key {
            case "1" where modifiers == [.command]:
                self.queueView.selectedSegment = 0
                self.changeQueueView()
            case "2" where modifiers == [.command]:
                self.queueView.selectedSegment = 1
                self.changeQueueView()
            case "c": self.createCurrent()
            case "l": self.linkSelected()
            case "s": self.skipCurrent()
            case "d": self.toggleSourceDetails()
            case "z":
                guard self.backButton.isEnabled else { return event }
                self.undoLastDecision()
            case "r" where modifiers == [.command, .shift]: self.reportIssue()
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
            detail: showsSourceDetails || !candidate.linkAllowed
                ? candidate.evidence.map(reviewEvidenceText).joined(separator: " · ")
                : "Suggested match · confirm to link",
            selectable: candidate.linkAllowed
        )
    }

    private func updateLinkAvailability() {
        linkButton.isEnabled = chooser.selectedItem?.selectable == true
    }

    @objc private func reportIssue() {
        record(
            .init(kind: .opened, selectedRank: chooser.selectedExerciseRank, selectedName: chooser.selectedName),
            flagged: true
        )
        feedbackMessage = "Issue captured — you can keep reviewing"
        statusField.stringValue = feedbackMessage
    }

    private func record(_ outcome: FeedbackOutcome, flagged: Bool = false) {
        guard let current else { return }
        let snapshots = candidates.enumerated().map { index, candidate in
            FeedbackCandidateSnapshot(
                rank: index + 1,
                exerciseID: candidate.exerciseID.rawValue.uuidString,
                preferredName: candidate.preferredName,
                matchedName: candidate.matchedName,
                aliases: candidate.aliases,
                evidence: candidate.evidence.map(reviewEvidenceText),
                score: candidate.evidence.compactMap { evidence in
                    if case .lexicalSimilarity(let score) = evidence { return score }
                    return nil
                }.first,
                linkAllowed: candidate.linkAllowed
            )
        }
        let interaction = FeedbackInteraction(
            sessionID: sessionID,
            workflow: .identityReview,
            queryOrObservation: current.observation.observedName,
            observationID: current.observation.id.rawValue,
            candidates: snapshots,
            outcome: outcome,
            durationMilliseconds: Int(Date().timeIntervalSince(interactionStartedAt) * 1_000),
            aliasesExpanded: aliasesExpanded,
            deactivationCount: deactivationCount,
            returnedAfterDeactivation: returnedAfterDeactivation,
            lastReturnToOutcomeMilliseconds: lastReturnAt.map { Int(Date().timeIntervalSince($0) * 1_000) },
            userFlagged: flagged
        )
        FieldFeedbackRecorder.append(
            interaction,
            panelScreenshot: flagged ? panelScreenshotPNG(window) : nil
        )
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

@MainActor
private final class LibraryEditWindowController: NSObject, NSWindowDelegate, NSSearchFieldDelegate {
    private let library: ExerciseLibrary
    private let edits: ExerciseLibraryEditService
    private let imports: LibraryImportService
    private let search: ExerciseAutocompleteSearch
    private let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 640, height: 500),
                                  styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
    private let review: LibraryReviewWindowController
    private var navigation = LibraryMaintenanceNavigation(route: .add, query: "", selection: nil)
    private var returnFocusTo: NSRunningApplication?
    private var shortcutMonitor: Any?
    private let nameField = NSTextField()
    private var previousActivationPolicy: NSApplication.ActivationPolicy?
    private let primarySearchField = AutocompleteSearchField()
    private let primaryChooser = RankedCandidateChooser()
    private let duplicateSearchField = AutocompleteSearchField()
    private let duplicateChooser = RankedCandidateChooser()
    private let duplicateWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 560, height: 380),
                                           styleMask: [.titled], backing: .buffered, defer: false)
    private var searchField: AutocompleteSearchField { findingDuplicate ? duplicateSearchField : primarySearchField }
    private var chooser: RankedCandidateChooser { findingDuplicate ? duplicateChooser : primaryChooser }
    private var editingWindow: NSWindow { findingDuplicate ? duplicateWindow : window }
    private var parentEditQuery = ""
    private var splitButton: NSButton?
    private var duplicateButton: NSButton?
    private var movingAliasID: ExerciseNameID?
    private let statusField = NSTextField(wrappingLabelWithString: "")
    private var detail: ExerciseLibraryDetail?
    private var findingDuplicate = false
    private var visibleEditMatches: [ExerciseSearchMatch] = []
    private var retainedDuplicateMatches: [ExerciseSearchMatch]?
    private var refreshingSearchResults = false
    private var importURL: URL?
    private var importPreview: LibraryImportPreview?
    private var feedback = ""

    init(library: ExerciseLibrary, reviewService: ExerciseIdentityReviewService) {
        self.library = library
        edits = .init(library: library)
        imports = .init(library: library)
        search = .init(library: library)
        review = LibraryReviewWindowController(service: reviewService, window: window)
        super.init()
        window.isReleasedWhenClosed = false
        window.delegate = self
        nameField.delegate = self
        duplicateWindow.isReleasedWhenClosed = false
        for field in [primarySearchField, duplicateSearchField] {
            field.delegate = self
            field.onMove = { [weak self] in self?.chooser.moveSelection($0) }
            field.onExpand = { [weak self] in self?.chooser.expandSelection() }
            field.onCollapse = { [weak self] in self?.chooser.collapseSelection() }
            field.onChoose = { [weak self] in self?.chooseExercise() }
            field.onCancel = { [weak self] in self?.back() }
        }
        primaryChooser.onSelectionChange = { [weak self] in self?.selectSearchResult() }
        duplicateChooser.onSelectionChange = { [weak self] in self?.selectSearchResult() }
        review.onReturnToImport = { [weak self] in self?.navigate(.importSource) }
    }

    func show(navigation: LibraryMaintenanceNavigation, returnFocusTo application: NSRunningApplication?) {
        dismissDuplicateSheet()
        review.resetSession()
        self.navigation = navigation
        returnFocusTo = application
        findingDuplicate = false
        retainedDuplicateMatches = nil
        feedback = ""
        render()
        window.center()
        if previousActivationPolicy == nil { previousActivationPolicy = NSApp.activationPolicy() }
        if !NSApp.setActivationPolicy(.regular) {
            showError(ExerciseLibraryError.database(message: "Could not show Gym Assistant in the Dock"))
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        focusRoute()
        installShortcutMonitor()
    }

    func windowWillClose(_ notification: Notification) {
        dismissDuplicateSheet()
        saveDrafts()
        review.deactivate()
        if let shortcutMonitor { NSEvent.removeMonitor(shortcutMonitor) }
        shortcutMonitor = nil
        if let previousActivationPolicy {
            NSApp.setActivationPolicy(previousActivationPolicy)
            self.previousActivationPolicy = nil
        }
        if let application = returnFocusTo,
           application.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            application.activate(options: [.activateIgnoringOtherApps])
        }
    }

    func bringToFront() -> Bool {
        guard window.isVisible || window.isMiniaturized else { return false }
        if window.isMiniaturized { window.deminiaturize(nil) }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        return true
    }

    private func saveDrafts() {
        if navigation.route == .add { navigation.creationDraft = nameField.stringValue }
        if navigation.route == .edit {
            navigation.editQuery = searchField.stringValue
        }
    }

    func windowDidResignKey(_ notification: Notification) {
        if navigation.route == .reviewCandidates { review.windowDidResignKey(notification) }
    }

    func windowDidBecomeKey(_ notification: Notification) {
        if navigation.route == .reviewCandidates { review.windowDidBecomeKey(notification) }
    }

    private func navigate(_ route: LibraryMaintenanceRoute) {
        saveDrafts()
        clearFeedback()
        review.deactivate()
        navigation.show(route)
        render()
        focusRoute()
    }

    private func focusRoute() {
        switch navigation.route {
        case .add: window.makeFirstResponder(nameField)
        case .edit:
            editingWindow.makeFirstResponder(searchField)
        case .importSource: window.makeFirstResponder(window.contentView?.subviews.compactMap { $0 as? NSButton }.first { $0.title.hasPrefix("Review candidates") })
        case .reviewCandidates: break
        }
        editingWindow.recalculateKeyViewLoop()
    }

    private func render() {
        if findingDuplicate {
            duplicateWindow.contentView = NSView(frame: NSRect(x: 0, y: 0, width: 560, height: 380))
            do { try renderEdit() } catch { showError(error) }
            return
        }
        if navigation.route == .reviewCandidates {
            review.show(returnFocusTo: returnFocusTo)
            return
        }
        let content = NSView(frame: NSRect(x: 0, y: 0, width: 640, height: 500))
        window.contentView = content
        statusField.frame = NSRect(x: 24, y: 16, width: 592, height: 52)
        statusField.textColor = .secondaryLabelColor
        statusField.stringValue = feedback
        content.addSubview(statusField)
        do {
            switch navigation.route {
            case .add:
                window.title = "Gym Assistant — Add Exercises"
                label("Name", x: 24, y: 399, width: 592, height: 24)
                nameField.frame = NSRect(x: 24, y: 356, width: 592, height: 32)
                nameField.placeholderString = "Exercise name"
                nameField.stringValue = navigation.creationDraft
                content.addSubview(nameField)
                button("Save Exercise", selector: #selector(createExercise), x: 24, y: 303, width: 160, key: "\r", command: false)
                let count = try imports.pendingReviewCount()
                let importButton = button(count == 0 ? "Import…" : "Import…  (\(count))", selector: #selector(showImport), x: 24, y: 235, width: 180, key: "i")
                importButton.setAccessibilityLabel(count == 0 ? "Import" : "Import, \(count) candidates awaiting review")
            case .edit: try renderEdit()
            case .importSource: try renderImport()
            case .reviewCandidates: break
            }
        } catch { showError(error) }
    }

    private func renderEdit() throws {
        editingWindow.title = findingDuplicate ? "Merge with…" : "Gym Assistant — Edit Library"
        let width: CGFloat = findingDuplicate ? 512 : 592
        let top: CGFloat = findingDuplicate ? 328 : 448
        if let selection = navigation.selection {
            detail = try edits.detail(exerciseID: selection.exerciseID)
            let current = detail!
            if findingDuplicate {
                let selected = movingAliasID.flatMap { id in current.names.first { $0.id == id }?.text } ?? current.preferredName.text
                label(movingAliasID == nil ? "Merge with duplicate of \(selected)" : "Move alias ‘\(selected)’ to exercise", x: 24, y: top, width: width, height: 32)
            }
        }
        if !findingDuplicate { label("↑↓ select · → show aliases", x: 24, y: 448, width: 592, height: 32) }
        searchField.frame = NSRect(x: 24, y: top - 48, width: width, height: 32)
        searchField.placeholderString = findingDuplicate ? "Search for a possible duplicate" : "Search exercises"
        searchField.stringValue = navigation.editQuery
        editingWindow.contentView?.addSubview(searchField)
        chooser.scrollView.frame = NSRect(x: 24, y: findingDuplicate ? 76 : 150, width: width, height: findingDuplicate ? 188 : 236)
        chooser.tableView.tableColumns.first?.width = width - 16
        editingWindow.contentView?.addSubview(chooser.scrollView)
        if findingDuplicate {
            button(movingAliasID == nil ? "Combine…  ↩" : "Move alias…  ↩", selector: #selector(chooseExercise), x: 24, y: 28, width: 220, key: "\r", command: false)
            button("Cancel  Esc", selector: #selector(back), x: 356, y: 28, width: 180)
        } else {
            splitButton = button("Promote to exercise…  ⌘S", selector: #selector(splitSelected), x: 24, y: 100, width: 246, key: "s")
            splitButton?.toolTip = "Expand an exercise and select an alias to give it its own exercise."
            duplicateButton = button("Merge with duplicate…  ⌘F", selector: #selector(findDuplicate), x: 270, y: 100, width: 346, key: "f")
            duplicateButton?.toolTip = "An exercise row combines all names; an alias row moves only that alias."
        }
        try updateEditSearch()
    }

    private func selectSearchResult() {
        guard navigation.route == .edit, !findingDuplicate else { return }
        guard let item = chooser.selectedItem, let nameID = chooser.selectedNameID else {
            detail = nil
            navigation.selection = nil
            splitButton?.isEnabled = false
            duplicateButton?.isEnabled = false
            return
        }
        do {
            let selection = LibraryMaintenanceSelection(exerciseID: item.exerciseID, nameID: nameID)
            if !refreshingSearchResults, navigation.selection != selection { clearFeedback() }
            detail = try edits.detail(exerciseID: item.exerciseID)
            navigation.selection = selection
            let actions = LibraryMaintenanceRowActions(isAlias: chooser.isAliasSelected, confirmedNameCount: detail?.names.count ?? 0)
            splitButton?.isEnabled = actions.canPromote
            duplicateButton?.isEnabled = actions.canCombine
        } catch { showError(error) }
    }

    private func renderImport() throws {
        window.title = "Gym Assistant — Import"
        let count = try imports.pendingReviewCount()
        label("CSV import\nRequired columns:\nobserved_name_verbatim, source_note, source_line_verbatim, occurrence_count, extraction_status, extraction_note\n\nextraction_status must be plausible_exercise.", x: 24, y: 276, width: 592, height: 160)
        button("Choose CSV…", selector: #selector(chooseCSV), x: 24, y: 234, width: 180, key: "o")
        if let preview = importPreview {
            label("\(importURL?.lastPathComponent ?? "CSV")\n\(preview.source.recordCount) records · \(preview.source.observations.count) observations · \(preview.source.occurrenceCount) occurrences\n\(preview.exactReuseCount) observations already match confirmed names", x: 24, y: 145, width: 592, height: 80)
            button("Import  ⌘I", selector: #selector(applyImport), x: 24, y: 105, width: 130, key: "i")
        }
        button("Review candidates  (\(count) to review)  ⌘J", selector: #selector(showReview), x: 220, y: 105, width: 396, key: "j")
        button("← Add Exercises  Esc", selector: #selector(back), x: 24, y: 70, width: 210)
    }

    private func updateEditSearch() throws {
        refreshingSearchResults = true
        defer { refreshingSearchResults = false }
        let matches = try (retainedDuplicateMatches ?? search.search(searchField.stringValue, limit: 20))
            .filter { !findingDuplicate || $0.exerciseID != detail?.exercise.id }
        visibleEditMatches = matches
        chooser.setItems(matches.map { match in
            RankedCandidateItem(exerciseID: match.exerciseID, preferredName: match.preferredName, aliases: match.aliases,
                                matchedName: match.matchedName, detail: "", selectable: true,
                                nameIDs: Dictionary(uniqueKeysWithValues: match.confirmedNames.map { ($0.text, $0.id) }))
        })
        selectSearchResult()
    }

    func controlTextDidChange(_ notification: Notification) {
        clearFeedback()
        retainedDuplicateMatches = nil
        saveDrafts()
        if navigation.route == .edit { do { try updateEditSearch() } catch { showError(error) } }
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        if selector == #selector(NSResponder.insertNewline(_:)) {
            if navigation.route == .add { createExercise() } else { chooseExercise() }
            return true
        }
        if selector == #selector(NSResponder.moveDown(_:)), control === searchField { chooser.moveSelection(1); return true }
        if selector == #selector(NSResponder.moveUp(_:)), control === searchField { chooser.moveSelection(-1); return true }
        if selector == #selector(NSResponder.cancelOperation(_:)) { back(); return true }
        return false
    }

    @objc private func showImport() { navigate(.importSource) }
    @objc private func showReview() { navigate(.reviewCandidates) }

    @objc private func back() {
        if navigation.route == .importSource {
            navigate(.add)
            window.makeFirstResponder(window.contentView?.subviews.compactMap { $0 as? NSButton }.first { $0.title.hasPrefix("Import") })
        }
        else if navigation.route == .reviewCandidates { navigate(.importSource) }
        else if navigation.route == .edit, findingDuplicate {
            dismissDuplicateSheet()
            focusRoute()
        } else { window.performClose(nil) }
    }

    @objc private func createExercise() {
        saveDrafts()
        do {
            let created = try library.createExercise(preferredName: navigation.creationDraft)
            navigation.selection = .init(exerciseID: created.exercise.id, nameID: created.preferredName.id)
            feedback = "Saved ‘\(created.preferredName.text)’. Invoke autocomplete again to insert."
            render()
            focusRoute()
        } catch ExerciseLibraryError.nameOwnershipConflict(_, let owner) {
            do {
                let existing = try edits.detail(exerciseID: owner)
                let name = try library.exactName(for: navigation.creationDraft) ?? existing.preferredName
                navigation.selection = .init(exerciseID: owner, nameID: name.id)
                findingDuplicate = false
                feedback = "That name already exists. No identity was changed."
                render()
                focusRoute()
            } catch { showError(error) }
        } catch { showError(error) }
    }

    @objc private func chooseExercise() {
        guard let item = chooser.selectedItem, let nameID = chooser.selectedNameID else { return }
        do {
            if findingDuplicate {
                clearFeedback()
                guard let detail else { return }
                let duplicate = try edits.detail(exerciseID: item.exerciseID)
                let preview: LibraryEditPreview
                if let alias = movingAliasID {
                    preview = try edits.previewMoveName(nameID: alias, from: detail.exercise.id, to: duplicate.exercise.id)
                    guard preview.before == [detail, duplicate] else { refreshStaleDetail(); return }
                } else {
                    preview = try edits.previewCombine(retaining: detail.exercise.id, duplicate: duplicate.exercise.id)
                    guard preview.before == [duplicate, detail] else { refreshStaleDetail(); return }
                }
                confirm(preview)
            } else {
                navigation.selection = .init(exerciseID: item.exerciseID, nameID: nameID)
            }
        } catch { showError(error) }
    }

    @objc private func findDuplicate() {
        guard let detail else { return }
        clearFeedback()
        if !findingDuplicate {
            parentEditQuery = navigation.editQuery
            movingAliasID = chooser.isAliasSelected ? chooser.selectedNameID : nil
            let start = LibraryDuplicateSearchStart(selectedName: chooser.selectedName ?? detail.preferredName.text,
                                                    source: detail.exercise.id, visibleMatches: visibleEditMatches)
            retainedDuplicateMatches = start.retainedCandidates
            navigation.editQuery = start.query
        }
        findingDuplicate = true
        render()
        window.beginSheet(duplicateWindow)
        focusRoute()
    }

    private func dismissDuplicateSheet() {
        guard findingDuplicate else { return }
        window.endSheet(duplicateWindow)
        duplicateWindow.orderOut(nil)
        findingDuplicate = false
        retainedDuplicateMatches = nil
        navigation.editQuery = parentEditQuery
    }

    @objc private func splitSelected() {
        guard chooser.isAliasSelected, let detail, let selection = navigation.selection else { return }
        do {
            let preview = try edits.previewSplit(nameID: selection.nameID, from: detail.exercise.id)
            guard preview.before == [detail] else { refreshStaleDetail(); return }
            confirm(preview)
        }
        catch { showError(error) }
    }

    private func refreshStaleDetail() {
        dismissDuplicateSheet()
        retainedDuplicateMatches = nil
        findingDuplicate = false
        render()
        showError(LibraryEditError.stalePreview)
        focusRoute()
    }

    private func confirm(_ preview: LibraryEditPreview) {
        let alert = NSAlert()
        alert.messageText = preview.confirmationPrompt
        alert.informativeText = preview.confirmationDetails
        switch preview.action {
        case .moveName: alert.addButton(withTitle: "Move alias")
        case .merge: alert.addButton(withTitle: "Combine")
        case .split: alert.addButton(withTitle: "Promote")
        }
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: editingWindow) { [weak self] response in
            guard let self else { return }
            guard response == .alertFirstButtonReturn else { self.focusRoute(); return }
            do {
                let receipt = try self.edits.apply(preview, confirmation: .init(confirming: preview))
                self.dismissDuplicateSheet()
                let survivor = receipt.after[0]
                self.navigation.selection = .init(exerciseID: survivor.exercise.id, nameID: survivor.preferredName.id)
                self.findingDuplicate = false
                self.retainedDuplicateMatches = nil
                self.feedback = "Library updated. Invoke autocomplete again to insert."
                self.render(); self.focusRoute()
            } catch {
                self.dismissDuplicateSheet()
                self.findingDuplicate = false
                self.render()
                self.showError(error)
            }
        }
    }

    @objc private func chooseCSV() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.beginSheetModal(for: window) { [weak self] response in
            guard let self, response == .OK, let url = panel.url else { return }
            do {
                let preview = try self.imports.preview(data: Data(contentsOf: url), sourceReference: url.lastPathComponent)
                self.importURL = url; self.importPreview = preview
                self.feedback = "Preview only — confirm Import to stage candidates."
                self.render()
                self.window.makeFirstResponder(self.window.contentView?.subviews.compactMap { $0 as? NSButton }.first { $0.title == "Import  ⌘I" })
                self.window.recalculateKeyViewLoop()
            } catch {
                self.importURL = nil; self.importPreview = nil
                self.render(); self.showError(error)
            }
        }
    }

    @objc private func applyImport() {
        guard let preview = importPreview, let url = importURL else { return }
        do {
            let result = try imports.apply(preview, currentData: Data(contentsOf: url))
            feedback = result.alreadyIngested ? "Already imported — no duplicate candidates staged." : "Imported \(result.observationCount) observations with \(result.occurrenceCount) occurrences."
            render()
        } catch {
            importPreview = nil
            render()
            showError(error)
        }
    }

    private func showError(_ error: Error) {
        feedback = "Could not complete safely: \(error). Refresh and confirm again."
        statusField.stringValue = feedback
        NSSound.beep()
    }

    private func clearFeedback() {
        feedback = ""
        statusField.stringValue = ""
    }

    private func installShortcutMonitor() {
        guard shortcutMonitor == nil else { return }
        shortcutMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.editingWindow.isKeyWindow, self.editingWindow.attachedSheet == nil,
                  self.navigation.route != .reviewCandidates else { return event }
            if event.keyCode == 53 { self.back(); return nil }
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask).subtracting([.capsLock, .numericPad, .function])
            if modifiers == [.command], event.charactersIgnoringModifiers == "a",
               let editor = self.editingWindow.firstResponder as? NSTextView {
                editor.selectAll(nil)
                return nil
            }
            if self.navigation.route == .edit {
                if modifiers.isEmpty, self.searchField.currentEditor() === self.editingWindow.firstResponder {
                    switch event.keyCode {
                    case 125: self.chooser.moveSelection(1)
                    case 126: self.chooser.moveSelection(-1)
                    case 124: self.chooser.expandSelection()
                    case 123: self.chooser.collapseSelection()
                    default: return event
                    }
                    return nil
                }
            }
            return event
        }
    }

    @discardableResult private func button(_ title: String, selector: Selector, x: CGFloat, y: CGFloat, width: CGFloat, key: String = "", command: Bool = true) -> NSButton {
        let button = NSButton(title: title, target: self, action: selector)
        button.frame = NSRect(x: x, y: y, width: width, height: 32)
        button.keyEquivalent = key
        button.keyEquivalentModifierMask = command ? [.command] : []
        editingWindow.contentView?.addSubview(button)
        return button
    }

    private func label(_ text: String, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        let field = NSTextField(wrappingLabelWithString: text)
        field.frame = NSRect(x: x, y: y, width: width, height: height)
        field.isSelectable = true
        editingWindow.contentView?.addSubview(field)
    }

    private func scrollText(_ text: String, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        let scroll = NSScrollView(frame: NSRect(x: x, y: y, width: width, height: height))
        let view = NSTextView(frame: NSRect(x: 0, y: 0, width: width - 18, height: height))
        view.isEditable = false
        view.isSelectable = true
        view.font = .systemFont(ofSize: 14)
        view.string = text
        view.isVerticallyResizable = true
        view.isHorizontallyResizable = false
        view.textContainer?.widthTracksTextView = true
        view.autoresizingMask = [.width]
        scroll.hasVerticalScroller = true
        scroll.documentView = view
        window.contentView?.addSubview(scroll)
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
    private let library: ExerciseLibrary
    private var libraryEditWindow: LibraryEditWindowController?

    func reopenLibraryMaintenance() -> Bool {
        libraryEditWindow?.bringToFront() ?? false
    }

    override init() {
        do {
            let databaseURL: URL
            if let explicitPath = ProcessInfo.processInfo.environment["GYM_ASSISTANT_DATABASE_PATH"] {
                guard explicitPath.hasPrefix("/") else {
                    throw ExerciseLibraryError.database(message: "Experimental database path must be absolute")
                }
                databaseURL = URL(fileURLWithPath: explicitPath)
            } else {
                let baseURL = try FileManager.default.url(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                ).appendingPathComponent("Gym Assistant", isDirectory: true)
                try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
                databaseURL = baseURL.appendingPathComponent("exercise-library.sqlite")
            }
            let library = try ExerciseLibrary(databaseURL: databaseURL)
            self.library = library
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
        case .maintenance(let navigation):
            DispatchQueue.main.async { [weak self] in
                self?.showLibraryMaintenance(navigation: navigation, returnFocusTo: invokingApplication)
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

    private func showLibraryMaintenance(navigation: LibraryMaintenanceNavigation, returnFocusTo application: NSRunningApplication?) {
        let controller: LibraryEditWindowController
        if let libraryEditWindow {
            controller = libraryEditWindow
        } else {
            controller = LibraryEditWindowController(library: library, reviewService: identityReview)
            libraryEditWindow = controller
        }
        controller.show(navigation: navigation, returnFocusTo: application)
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
        if let iconURL = Bundle.main.url(forResource: "GymAssistant", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            NSApp.applicationIconImage = icon
        }
        NSApp.servicesProvider = serviceProvider
        NSUpdateDynamicServices()
        WorkflowEventLog.write("application_launched")
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        !serviceProvider.reopenLibraryMaintenance()
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
