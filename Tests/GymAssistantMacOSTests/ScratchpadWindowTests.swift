import AppKit
import Testing
import GymAssistantWorkspace
@testable import GymAssistantMacOS

private actor WindowNotesReader: NotesContextReading {
    var body = "<div><h2>Session 1</h2></div><div>B2 Row</div>"
    var reads = 0
    func captureSelectedNote() async throws -> NoteSnapshot { try await read(id: NoteID("fixture")) }
    func read(id: NoteID) async throws -> NoteSnapshot {
        reads += 1
        return NoteSnapshot(id: id, text: "", html: body, modifiedAt: Date(timeIntervalSince1970: 1))
    }
    func metadata(id: NoteID) async throws -> NoteMetadata { NoteMetadata(id: id, modifiedAt: Date(timeIntervalSince1970: 1)) }
    func change() { body = "<div><h2>Session 1</h2></div><div>B2 Changed externally</div>" }
}

@Suite("Native scratchpad controller", .serialized) @MainActor struct ScratchpadWindowTests {
    private func descendants(_ view: NSView) -> [NSView] {
        [view] + view.subviews.flatMap(descendants)
    }
    private func eventually(_ condition: () -> Bool) async throws {
        for _ in 0..<100 {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(condition())
    }
    @Test func unrecordedWindowHasNoInventedBoundaryAndPreservesAdditionThroughChatDiffAndCopy() async throws {
        let reader = WindowNotesReader()
        let context = try SessionNoteContext(noteID: NoteID("fixture"), anchors: [], reader: reader)
        let document = try await context.refresh(for: .resume)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("unrecorded-window-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let board = NSPasteboard.withUniqueName()
        defer { board.releaseGlobally() }
        let rich = NSAttributedString(string: "Session 2\nWarmup\n")
        var snapshot = WorkspaceSnapshot(anchor: .init(noteID: document.snapshot.id, recordedHeading: "Session 2",
            baselineText: "", recordingState: .unrecorded), text: rich.string, richTextArchive: try RichTextArchive.encode(rich))
        snapshot.anchor.unrecordedOrigin = SessionSourceEvidence(paragraphs: document.paragraphs)
        let store = WorkspaceSnapshotStore(directory: root)
        let invented = SessionAssociation(sessionID: snapshot.anchor.sessionID, noteID: document.snapshot.id,
            observationID: document.snapshot.observationID, range: document.candidates()[0].range)
        #expect(throws: WorkspaceError.staleAssociation) {
            _ = try SessionScratchpadWindowController(snapshot: snapshot, store: store, note: document.snapshot,
                association: invented, profile: .init(version: "empty", entries: []), noteContext: context, pasteboard: board)
        }
        let controller = try SessionScratchpadWindowController(snapshot: snapshot, store: store, note: document.snapshot,
            association: nil, profile: .init(version: "empty", entries: []),
            assistant: FakeProgrammingAssistant(delay: .milliseconds(1)), noteContext: context, pasteboard: board)
        let views = descendants(try #require(controller.window?.contentView))
        let status = try #require(views.first { $0.identifier?.rawValue == "workspace-status" } as? NSTextField)
        let composer = try #require(views.first { $0.identifier?.rawValue == "chat-composer" } as? NSTextView)
        let comparison = try #require(views.first { $0.identifier?.rawValue == "notes-comparison" } as? NSTextView)
        let send = try #require(views.compactMap { $0 as? NSButton }.first { $0.title == "Send" })
        let toggle = try #require(views.compactMap { $0 as? NSButton }.first { $0.title == "Compare with source" })
        #expect(controller.snapshot.boundaryProtection == nil)
        controller.adjustBoundary()
        #expect(status.stringValue.contains("no Notes boundary"))
        composer.string = "What should A1 be?"
        controller.textDidChange(Notification(name: NSText.didChangeNotification, object: composer))
        let reads = await reader.reads
        send.performClick(nil)
        try await eventually { controller.snapshot.messages.last?.status == .complete }
        #expect(await reader.reads > reads)
        #expect(controller.snapshot.messages.last?.text.contains("unrecorded session added separately") == true)
        toggle.performClick(nil)
        try await eventually { comparison.string.contains("proposed addition") }
        #expect(!comparison.string.contains("B2 Row"))
        controller.copyForNotes()
        try await eventually { status.stringValue.contains("Notes not verified") }
        #expect(board.string(forType: .string)?.contains("Session 2") == true)
        #expect(controller.flushAndStop())
        let saved = try #require(store.load(id: snapshot.workspaceID)?.snapshot)
        #expect(saved.anchor.isUnrecorded && saved.boundaryProtection == nil)
        #expect(saved.text == snapshot.text && context.registry.mappings.isEmpty)
        controller.window?.close()
    }
    @Test func formattingRoutesToEditorProtectsBoundaryAndPersistsUndoRedo() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("scratchpad-format-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let body = "Session 1\nWarmup\nA1 Row\n"
        let note = NoteSnapshot(id: NoteID("format-fixture"), text: body)
        let rich = NSAttributedString(string: body, attributes: [.font: NSFont.systemFont(ofSize: 16)])
        let snapshot = WorkspaceSnapshot(anchor: SessionAnchor(noteID: note.id, recordedHeading: "Session 1", baselineText: body), text: body, richTextArchive: try RichTextArchive.encode(rich))
        let store = WorkspaceSnapshotStore(directory: root)
        let controller = try SessionScratchpadWindowController(snapshot: snapshot, store: store, note: note,
            association: SessionAssociation(sessionID: snapshot.anchor.sessionID, noteID: note.id, observationID: note.observationID,
                range: SourceRange(location: 0, length: rich.length)), profile: CoachingProfile(version: "empty", entries: []))
        let views = descendants(try #require(controller.window?.contentView))
        let editor = try #require(views.first { $0.identifier?.rawValue == "scratchpad-editor" } as? NSTextView)
        let composer = try #require(views.first { $0.identifier?.rawValue == "chat-composer" } as? NSTextView)
        let item = try #require(controller.formattingMenu().items.first { $0.tag == ScratchpadFormat.heading.rawValue })
        controller.window?.makeFirstResponder(composer)
        #expect(!controller.validateMenuItem(item))
        controller.formatScratchpad(item)
        #expect(controller.snapshot.revision == 0)
        controller.window?.makeFirstResponder(editor)
        editor.setSelectedRange(NSRange(location: 0, length: 0))
        let undo = try #require(editor.undoManager)
        undo.beginUndoGrouping(); controller.formatScratchpad(item); undo.endUndoGrouping()
        #expect(controller.snapshot.revision == 1)
        #expect((editor.attributedString().attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)?.headerLevel == 2)
        #expect(throws: BoundaryChangeError.editedRegion) {
            try controller.snapshot.boundaryProtection?.preview(SourceRange(location: 10, length: rich.length - 10), in: body)
        }
        undo.undo()
        #expect(editor.attributedString().isEqual(to: rich))
        #expect(controller.snapshot.revision == 2)
        undo.redo()
        #expect(controller.snapshot.revision == 3)
        #expect(controller.flushAndStop())
        let saved = try #require(store.load(id: snapshot.workspaceID)?.snapshot)
        #expect((try RichTextArchive.decode(saved.richTextArchive).attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)?.headerLevel == 2)
        #expect(saved.boundaryProtection == controller.snapshot.boundaryProtection)
        controller.window?.close()
    }
    @Test func checkedCopyAndDiffReadNotesWithoutReplacingScratchpad() async throws {
        let reader = WindowNotesReader()
        let initial = try ProgramDocumentReader.read(await reader.read(id: NoteID("fixture")))
        let candidate = try #require(initial.0.candidates().first)
        let anchor = SessionAnchor(noteID: initial.0.snapshot.id, recordedHeading: candidate.label,
            baselineText: candidate.evidence.text, sourceEvidence: candidate.evidence)
        let context = try SessionNoteContext(noteID: anchor.noteID, anchors: [anchor], reader: reader)
        let document = try await context.refresh(for: .resume)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("scratchpad-live-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let board = NSPasteboard.withUniqueName()
        defer { board.releaseGlobally() }
        let snapshot = WorkspaceSnapshot(anchor: anchor, text: initial.1.string, richTextArchive: try RichTextArchive.encode(initial.1))
        let controller = try SessionScratchpadWindowController(snapshot: snapshot, store: WorkspaceSnapshotStore(directory: root),
            note: document.snapshot, association: context.association(for: anchor.sessionID),
            profile: CoachingProfile(version: "empty", entries: []), noteContext: context, pasteboard: board)
        let views = descendants(try #require(controller.window?.contentView))
        let status = try #require(views.first { $0.identifier?.rawValue == "workspace-status" } as? NSTextField)
        let comparison = try #require(views.first { $0.identifier?.rawValue == "notes-comparison" } as? NSTextView)
        let toggle = try #require(views.compactMap { $0 as? NSButton }.first { $0.title == "Compare with source" })
        let before = await reader.reads
        controller.copyForNotes()
        try await eventually { status.stringValue.contains("Notes checked") }
        #expect(await reader.reads > before)
        #expect(board.string(forType: .string)?.contains("B2 Row") == true)
        let copied = board.changeCount
        await reader.change()
        toggle.performClick(nil)
        try await eventually { comparison.string.contains("association is unresolved") }
        #expect(controller.snapshot.text == snapshot.text)
        #expect(board.changeCount == copied)
        #expect(controller.flushAndStop())
        controller.window?.close()
    }
    @Test func boundaryUndoRestoresIndependentTextFormattingAndRange() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("scratchpad-boundary-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let body = "Session 1\nB2 Row\n"
        let note = NoteSnapshot(id: NoteID("synthetic-boundary"), text: body + "Ideas\n")
        let rich = NSMutableAttributedString(string: body, attributes: [.font: NSFont.systemFont(ofSize: 15)])
        rich.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 20), range: NSRange(location: 0, length: 9))
        let snapshot = WorkspaceSnapshot(anchor: SessionAnchor(noteID: note.id, recordedHeading: "Session 1", baselineText: body),
            text: body, richTextArchive: try RichTextArchive.encode(rich))
        let store = WorkspaceSnapshotStore(directory: root)
        let controller = try SessionScratchpadWindowController(snapshot: snapshot, store: store, note: note,
            association: SessionAssociation(sessionID: snapshot.anchor.sessionID, noteID: note.id,
                observationID: note.observationID, range: SourceRange(location: 0, length: rich.length)),
            profile: CoachingProfile(version: "empty", entries: []))
        let content = try #require(controller.window?.contentView)
        let editor = try #require(descendants(content).first {
            $0.identifier?.rawValue == "scratchpad-editor"
        } as? NSTextView)
        let undo = try #require(editor.undoManager)
        let source = NSAttributedString(string: note.text)
        let document = try ProgramDocumentReader.document(snapshot: note, richText: source)
        undo.beginUndoGrouping()
        try controller.applyBoundary(SourceRange(location: 0, length: source.length), document: document, source: source)
        undo.endUndoGrouping()
        #expect(controller.snapshot.text == note.text)
        undo.undo()
        #expect(controller.snapshot.text == body)
        #expect(editor.attributedString().isEqual(to: rich))
        #expect(controller.snapshot.boundaryProtection?.sourceRange == SourceRange(location: 0, length: rich.length))
        #expect(controller.flushAndStop())
        #expect(try store.load(id: snapshot.workspaceID)?.snapshot.text == body)
        undo.redo()
        #expect(controller.snapshot.text == note.text)
        #expect(controller.flushAndStop())
        controller.window?.close()
    }
    @Test func composingFollowupDoesNotFalselyMarkScratchpadChanged() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("scratchpad-window-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let note = NoteSnapshot(id: NoteID("synthetic-window-test"), text: "Session 1\nB2\n")
        let rich = NSAttributedString(string: note.text)
        let snapshot = WorkspaceSnapshot(anchor: SessionAnchor(noteID: note.id, recordedHeading: "Session 1", baselineText: note.text),
            text: note.text, richTextArchive: try RichTextArchive.encode(rich))
        let controller = try SessionScratchpadWindowController(snapshot: snapshot, store: WorkspaceSnapshotStore(directory: root),
            note: note, association: SessionAssociation(sessionID: snapshot.anchor.sessionID, noteID: note.id,
                observationID: note.observationID, range: SourceRange(location: 0, length: (note.text as NSString).length)),
            profile: CoachingProfile(version: "empty-test", entries: []), assistant: FakeProgrammingAssistant(delay: .seconds(60)))
        let content = try #require(controller.window?.contentView)
        let views = descendants(content)
        let composer = try #require(views.first { $0.identifier?.rawValue == "chat-composer" } as? NSTextView)
        let editor = try #require(views.first { $0.identifier?.rawValue == "scratchpad-editor" } as? NSTextView)
        let status = try #require(views.first { $0.identifier?.rawValue == "workspace-status" } as? NSTextField)
        let send = try #require(views.compactMap { $0 as? NSButton }.first { $0.title == "Send" })
        let stop = try #require(views.compactMap { $0 as? NSButton }.first { $0.title == "Stop" })
        composer.string = "B2?"
        controller.textDidChange(Notification(name: NSText.didChangeNotification, object: composer))
        send.performClick(nil)
        #expect(!send.isEnabled && stop.isEnabled)
        composer.string = "Keep it unloaded"
        controller.textDidChange(Notification(name: NSText.didChangeNotification, object: composer))
        #expect(controller.snapshot.revision == 0)
        #expect(!status.stringValue.contains("Scratchpad changed"))
        #expect(controller.snapshot.messages.filter { $0.role == .coach }.count == 1)
        editor.string += "Coach edit\n"
        controller.textDidChange(Notification(name: NSText.didChangeNotification, object: editor))
        #expect(controller.snapshot.revision == 1)
        #expect(status.stringValue.contains("Scratchpad changed"))
        stop.performClick(nil)
        #expect(composer.string == "Keep it unloaded")
        #expect(send.isEnabled && !stop.isEnabled)
        #expect(controller.snapshot.messages.last?.status == .cancelled)
        #expect(controller.flushAndStop())
        controller.window?.close()
    }
}
