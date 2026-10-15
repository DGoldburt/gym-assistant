import AppKit
import Testing
import GymAssistantWorkspace
@testable import GymAssistantMacOS

private actor InsertionReader: NotesContextReading {
    var html = "<div><h2>Session 1</h2></div><div>A1 Row</div><div><h3>Warmup</h3></div>"
    func captureSelectedNote() async throws -> NoteSnapshot { try await read(id: NoteID("insertion-fixture")) }
    func read(id: NoteID) async throws -> NoteSnapshot { NoteSnapshot(id: id, text: "", html: html) }
    func metadata(id: NoteID) async throws -> NoteMetadata { NoteMetadata(id: id, modifiedAt: .distantPast) }
    func replace(_ value: String) { html = value }
}

@Suite("Inserted session association", .serialized) @MainActor struct InsertedSessionAssociationTests {
    private let original = "<div><h2>Session 1</h2></div><div>A1 Row</div><div><h3>Warmup</h3></div>"
    private let addition = "<div><h2>Session 2</h2></div><div><h3>Warmup</h3></div>"
    private func descendants(_ view: NSView) -> [NSView] { [view] + view.subviews.flatMap(descendants) }
    private func eventually(_ condition: () -> Bool) async throws {
        for _ in 0..<100 {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(condition())
    }

    @Test func keyboardReviewCommandsKeepSelectionAndComparisonState() async throws {
        let reader = InsertionReader()
        let store = WorkspaceSnapshotStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        defer { try? FileManager.default.removeItem(at: store.directory) }
        let pending = try await create(reader, store)
        let controller = try SessionScratchpadWindowController(snapshot: pending.snapshot, store: store, note: pending.note,
            association: nil, profile: .init(version: "test", entries: []), noteContext: pending.context)
        let root = try #require(controller.window?.contentView)
        let items = controller.comparisonMenuItems()
        #expect(items.map(\.keyEquivalent) == ["f", "d", "m"])
        #expect(items.allSatisfy { $0.keyEquivalentModifierMask == [.command, .shift] })
        #expect(controller.validateMenuItem(items[0]))
        #expect(NSApp.sendAction(try #require(items[0].action), to: items[0].target, from: items[0]))
        try await eventually { descendants(root).contains { $0 is SessionAssociationPane } }
        #expect(!controller.validateMenuItem(items[0]))
        let pane = try #require(descendants(root).compactMap { $0 as? SessionAssociationPane }.first)
        let search = try #require(descendants(pane).compactMap { $0 as? NSSearchField }.first)
        let source = try #require(descendants(pane).first { $0.identifier?.rawValue == "association-source" } as? NSTextView)
        search.stringValue = "Session 1"
        pane.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: search))
        let selection = source.selectedRange()
        #expect(selection.length > 0 && search.nextKeyView === source)
        #expect(pane.control(search, textView: NSTextView(), doCommandBy: #selector(NSResponder.insertTab(_:))))
        #expect(controller.window?.firstResponder === source && source.selectedRange() == selection)
        #expect(!source.isEditable)
        let toggle = try #require(descendants(root).compactMap { $0 as? NSButton }.first { $0.title == "Compare with source" })
        #expect(NSApp.sendAction(try #require(items[1].action), to: items[1].target, from: items[1]))
        #expect(controller.validateMenuItem(items[1]) && items[1].state == .on && toggle.state == .on)
        toggle.performClick(nil)
        #expect(controller.validateMenuItem(items[1]) && items[1].state == .off && toggle.state == .off)
        #expect(controller.flushAndStop())
        controller.window?.close()
    }

    @Test func embeddedReviewComparesSelectionRefreshesAndConfirmsWithoutReplacingContent() async throws {
        let reader = InsertionReader()
        let store = WorkspaceSnapshotStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        defer { try? FileManager.default.removeItem(at: store.directory) }
        let pending = try await create(reader, store)
        let controller = try SessionScratchpadWindowController(snapshot: pending.snapshot, store: store, note: pending.note,
            association: nil, profile: .init(version: "test", entries: []), noteContext: pending.context)
        let root = try #require(controller.window?.contentView)
        let editor = try #require(descendants(root).first { $0.identifier?.rawValue == "scratchpad-editor" } as? NSTextView)
        let comparison = try #require(descendants(root).first { $0.identifier?.rawValue == "notes-comparison" } as? NSTextView)
        let toggle = try #require(descendants(root).compactMap { $0 as? NSButton }.first { $0.title == "Compare with source" })
        await reader.replace(original + addition + "<div>B2 Notes version</div>")
        _ = try await pending.context.refresh(for: .resume)
        controller.findSessionInNotes()
        try await eventually { descendants(root).contains { $0 is SessionAssociationPane } }
        var pane = try #require(descendants(root).compactMap { $0 as? SessionAssociationPane }.first)
        #expect(!editor.isEditable)
        let cancel = try #require(descendants(pane).compactMap { $0 as? NSButton }.first { $0.title == "Cancel" })
        cancel.performClick(nil)
        #expect(editor.isEditable && controller.snapshot.anchor.isUnrecorded)
        controller.findSessionInNotes()
        try await eventually { descendants(root).contains { $0 is SessionAssociationPane } }
        pane = try #require(descendants(root).compactMap { $0 as? SessionAssociationPane }.first)
        let source = try #require(descendants(pane).first { $0.identifier?.rawValue == "association-source" } as? NSTextView)
        let confirm = try #require(descendants(pane).first { $0.identifier?.rawValue == "association-confirm" } as? NSButton)
        source.setSelectedRange(pane.document.candidates().last!.range.nsRange)
        pane.textViewDidChangeSelection(Notification(name: NSTextView.didChangeSelectionNotification, object: source))
        toggle.performClick(nil)
        #expect(comparison.string.contains("Only in Notes") && comparison.string.contains("B2 Notes version"))
        await reader.replace(original + addition + "<div>B2 Revised Notes version</div>")
        _ = try await pending.context.refresh(for: .comparison)
        #expect(pane.selectedRange == nil && !confirm.isEnabled)
        #expect(controller.snapshot.anchor.isUnrecorded && !editor.isEditable)
        source.setSelectedRange(pane.document.candidates().last!.range.nsRange)
        pane.textViewDidChangeSelection(Notification(name: NSTextView.didChangeSelectionNotification, object: source))
        #expect(comparison.string.contains("B2 Revised Notes version"))
        confirm.performClick(nil)
        try await eventually { !controller.snapshot.anchor.isUnrecorded }
        #expect(editor.isEditable && descendants(root).allSatisfy { !($0 is SessionAssociationPane) })
        #expect(controller.snapshot.text == pending.snapshot.text)
        #expect(controller.snapshot.anchor.baselineText.contains("B2 Revised Notes version"))
        #expect(controller.snapshot.workspaceID == pending.snapshot.workspaceID)
        #expect(controller.flushAndStop())
        controller.window?.close()
    }

    @Test func associationPaneRejectsOccupiedSelectionAndNotPastedRetainsAddition() async throws {
        let reader = InsertionReader()
        let store = WorkspaceSnapshotStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        defer { try? FileManager.default.removeItem(at: store.directory) }
        let pending = try await create(reader, store)
        let document = try await pending.context.refresh(for: .resume)
        let rich = try #require(pending.context.richText)
        let owner = document.candidates()[0].range
        let pane = SessionAssociationPane(frame: NSRect(x: 0, y: 0, width: 425, height: 572), document: document, rich: rich,
            owners: [.init(label: "Session 1 workspace", range: owner)])
        let source = try #require(descendants(pane).first { $0.identifier?.rawValue == "association-source" } as? NSTextView)
        let confirm = try #require(descendants(pane).first { $0.identifier?.rawValue == "association-confirm" } as? NSButton)
        let status = try #require(descendants(pane).first { $0.identifier?.rawValue == "association-status" } as? NSTextField)
        source.setSelectedRange(owner.nsRange)
        pane.textViewDidChangeSelection(Notification(name: NSTextView.didChangeSelectionNotification, object: source))
        #expect(!confirm.isEnabled && status.stringValue.contains("Session 1 workspace"))
        let controller = try SessionScratchpadWindowController(snapshot: pending.snapshot, store: store, note: document.snapshot,
            association: nil, profile: .init(version: "test", entries: []), noteContext: pending.context)
        await reader.replace(original.replacingOccurrences(of: "Row", with: "Press"))
        _ = try await pending.context.refresh(for: .resume)
        controller.confirmNotPasted()
        try await eventually { controller.snapshot.anchor.unrecordedOrigin?.text.contains("Press") == true }
        #expect(controller.snapshot.anchor.isUnrecorded && controller.snapshot.text == pending.snapshot.text)
        #expect(pending.context.registry.mappings.isEmpty)
        #expect(controller.flushAndStop())
        controller.window?.close()
    }

    @Test func liveRefreshPromotesWithoutReplacingEditorAndOldUndoKeepsProtection() async throws {
        let reader = InsertionReader()
        let store = WorkspaceSnapshotStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        defer { try? FileManager.default.removeItem(at: store.directory) }
        let pending = try await create(reader, store)
        let controller = try SessionScratchpadWindowController(snapshot: pending.snapshot, store: store, note: pending.note,
            association: nil, profile: .init(version: "test", entries: []), noteContext: pending.context)
        let views = descendants(try #require(controller.window?.contentView))
        let editor = try #require(views.first { $0.identifier?.rawValue == "scratchpad-editor" } as? NSTextView)
        let composer = try #require(views.first { $0.identifier?.rawValue == "chat-composer" } as? NSTextView)
        controller.window?.makeFirstResponder(editor)
        editor.setSelectedRange(NSRange(location: 10, length: 0))
        let body = try #require(controller.formattingMenu().items.first { $0.tag == ScratchpadFormat.body.rawValue })
        let undo = try #require(editor.undoManager)
        undo.beginUndoGrouping(); controller.formatScratchpad(body); undo.endUndoGrouping()
        undo.undo()
        #expect(undo.canRedo)
        composer.string = "Keep this unloaded"
        controller.textDidChange(Notification(name: NSText.didChangeNotification, object: composer))
        let before = NSAttributedString(attributedString: editor.attributedString())
        await reader.replace(original + addition)
        let document = try await pending.context.refresh(for: .resume)
        #expect(!controller.snapshot.anchor.isUnrecorded)
        #expect(controller.snapshot.workspaceID == pending.snapshot.workspaceID)
        #expect(editor.attributedString().isEqual(to: before))
        #expect(composer.string == "Keep this unloaded")
        undo.redo()
        #expect(controller.snapshot.boundaryProtection != nil)
        #expect(controller.snapshot.boundaryProtection?.sourceRange == document.candidates().last?.range)
        #expect(controller.flushAndStop())
        #expect(try store.load(id: pending.snapshot.workspaceID)?.snapshot.anchor.isUnrecorded == false)
        controller.window?.close()
    }

    @Test func ambiguousRefreshPreservesQuestionAndLatestEntryCannotCreateCompetingOwner() async throws {
        let reader = InsertionReader()
        let store = WorkspaceSnapshotStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        defer { try? FileManager.default.removeItem(at: store.directory) }
        let pending = try await create(reader, store)
        let controller = try SessionScratchpadWindowController(snapshot: pending.snapshot, store: store, note: pending.note,
            association: nil, profile: .init(version: "test", entries: []), noteContext: pending.context)
        let views = descendants(try #require(controller.window?.contentView))
        let composer = try #require(views.first { $0.identifier?.rawValue == "chat-composer" } as? NSTextView)
        let send = try #require(views.compactMap { $0 as? NSButton }.first { $0.title == "Send" })
        await reader.replace(original.replacingOccurrences(of: "Row", with: "Press") + addition)
        _ = try await pending.context.refresh(for: .resume)
        composer.string = "What should A1 be?"
        controller.textDidChange(Notification(name: NSText.didChangeNotification, object: composer))
        send.performClick(nil)
        for _ in 0..<100 {
            if send.isEnabled { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(send.isEnabled)
        #expect(controller.snapshot.messages.isEmpty && composer.string == "What should A1 be?")
        #expect(controller.snapshot.anchor.isUnrecorded)
        let entry = SessionWorkspaceEntry(store: store, reader: reader)
        await #expect(throws: SessionEntryError.unresolvedSavedWorkspace) { _ = try await entry.latest(in: pending.note.id) }
        #expect(try store.storedAnchors().count == 1)
        #expect(controller.flushAndStop())
        controller.window?.close()
    }

    private func create(_ reader: InsertionReader, _ store: WorkspaceSnapshotStore) async throws -> SessionWorkspaceEntry.UnrecordedSession {
        let entry = SessionWorkspaceEntry(store: store, reader: reader)
        let id = try await entry.captureNote()
        guard case .proposal(let proposal) = try await entry.prepareNewSession(in: id) else {
            throw WorkspaceError.invalidSnapshot
        }
        return try await entry.acceptNewSession(proposal)
    }

    @Test func exactInsertionPreservesIdentityContentAndPreviousSnapshot() async throws {
        let reader = InsertionReader()
        let store = WorkspaceSnapshotStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        defer { try? FileManager.default.removeItem(at: store.directory) }
        let pending = try await create(reader, store)
        let priorBytes = try Data(contentsOf: store.currentURL(for: pending.snapshot.workspaceID))
        await reader.replace(original + addition)
        let document = try await pending.context.refresh(for: .resume)
        let promoted = try pending.context.associateInsertedSession(pending.snapshot,
            observation: document.snapshot.observationID, store: store)
        #expect(!promoted.anchor.isUnrecorded)
        #expect(promoted.workspaceID == pending.snapshot.workspaceID && promoted.anchor.sessionID == pending.snapshot.anchor.sessionID)
        #expect(promoted.conversationID == pending.snapshot.conversationID)
        #expect(promoted.text == pending.snapshot.text && promoted.richTextArchive == pending.snapshot.richTextArchive)
        #expect(promoted.anchor.unrecordedOrigin == nil)
        #expect(promoted.revision == pending.snapshot.revision + 1)
        #expect(try Data(contentsOf: store.previousURL(for: promoted.workspaceID)) == priorBytes)
        #expect(try store.load(id: promoted.workspaceID)?.snapshot == promoted)
        #expect(try pending.context.association(for: promoted.anchor.sessionID).range == document.candidates().last?.range)
        let reopened = try SessionNoteContextPool(store: store, reader: reader).context(for: promoted.anchor.noteID)
        _ = try await reopened.refresh(for: .resume)
        #expect(try reopened.association(for: promoted.anchor.sessionID).range == document.candidates().last?.range)
    }

    @Test func otherEditsDuplicatesAndMissingOriginNeverAutoAssociate() async throws {
        let reader = InsertionReader()
        let store = WorkspaceSnapshotStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        defer { try? FileManager.default.removeItem(at: store.directory) }
        let pending = try await create(reader, store)
        let rich = try RichTextArchive.decode(pending.snapshot.richTextArchive)
        let scratchpad = try ProgramDocumentReader.document(snapshot: NoteSnapshot(id: pending.note.id, text: rich.string), richText: rich)
        let evidence = SessionSourceEvidence(paragraphs: scratchpad.paragraphs)
        let initial = try await pending.context.refresh(for: .resume)
        #expect(UnrecordedSessionAssociation.evaluate(anchor: pending.snapshot.anchor, scratchpad: evidence, document: initial) == .notInserted)
        await reader.replace(original + addition)
        let inserted = try await pending.context.refresh(for: .resume)
        let withoutVisibleFormatting = SessionSourceEvidence(paragraphs: evidence.paragraphs.map {
            ProgramParagraph(text: $0.text, headingLevel: $0.headingLevel, listStyle: $0.listStyle)
        })
        #expect(UnrecordedSessionAssociation.evaluate(anchor: pending.snapshot.anchor,
            scratchpad: withoutVisibleFormatting, document: inserted) == .needsReview)
        for html in [original.replacingOccurrences(of: "Row", with: "Press") + addition,
                     original + addition + addition, original + "<div><h2>Session 2</h2></div><div>Different content</div>",
                     original + "<div><h3>Session 2</h3></div>"] {
            await reader.replace(html)
            let document = try await pending.context.refresh(for: .resume)
            #expect(UnrecordedSessionAssociation.evaluate(anchor: pending.snapshot.anchor, scratchpad: evidence, document: document) == .needsReview)
            #expect(throws: WorkspaceError.staleAssociation) {
                _ = try pending.context.associateInsertedSession(pending.snapshot, observation: document.snapshot.observationID, store: store)
            }
        }
        var legacy = pending.snapshot.anchor; legacy.unrecordedOrigin = nil
        #expect(UnrecordedSessionAssociation.evaluate(anchor: legacy, scratchpad: evidence, document: initial) == .needsReview)
        #expect(try store.load(id: pending.snapshot.workspaceID)?.snapshot == pending.snapshot)
        #expect(pending.context.registry.mappings.isEmpty)
    }

    @Test func staleUnsavedAndOccupiedTargetsPreservePendingSnapshot() async throws {
        let reader = InsertionReader()
        let store = WorkspaceSnapshotStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        defer { try? FileManager.default.removeItem(at: store.directory) }
        let pending = try await create(reader, store)
        await reader.replace(original + addition)
        let document = try await pending.context.refresh(for: .resume)
        #expect(throws: WorkspaceError.staleAssociation) {
            _ = try pending.context.associateInsertedSession(pending.snapshot, observation: UUID(), store: store)
        }
        var unsaved = pending.snapshot; unsaved.composerText = "Keep it light"
        #expect(throws: WorkspaceError.staleAssociation) {
            _ = try pending.context.associateInsertedSession(unsaved, observation: document.snapshot.observationID, store: store)
        }
        _ = try pending.context.createWorkspace(range: document.candidates().last!.range,
            observation: document.snapshot.observationID, store: store)
        #expect(throws: SessionAssociationError.occupied) {
            _ = try pending.context.associateInsertedSession(pending.snapshot, observation: document.snapshot.observationID, store: store)
        }
        #expect(try store.load(id: pending.snapshot.workspaceID)?.snapshot == pending.snapshot)
    }
}
