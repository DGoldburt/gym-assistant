import AppKit
import Testing
import GymAssistantWorkspace
@testable import GymAssistantMacOS

private actor BoundaryReader: NotesContextReading {
    func captureSelectedNote() async throws -> NoteSnapshot { try await read(id: NoteID("boundary-fixture")) }
    func read(id: NoteID) async throws -> NoteSnapshot {
        NoteSnapshot(id: id, text: "", html: "<div><h2>Session 1</h2></div><div>A1 Row</div><div>Ideas</div><div><h2>Session 2</h2></div><div>A1 Squat</div>")
    }
    func metadata(id: NoteID) async throws -> NoteMetadata { NoteMetadata(id: id, modifiedAt: .distantPast) }
}

@Suite("Atomic session boundary commits") @MainActor struct SessionBoundaryCommitTests {
    private func descendants(_ view: NSView) -> [NSView] { [view] + view.subviews.flatMap(descendants) }

    @Test func browserPreviewsProtectedShrinkAndNeighborOwnershipWithoutApplying() async throws {
        let (document, rich) = try ProgramDocumentReader.read(await BoundaryReader().captureSelectedNote())
        let selected = document.candidates()[0].range
        var protection = BoundaryEditProtection(sourceRange: selected)
        try protection.formattingChanged(range: document.ranges[0].nsRange)
        var applied = false
        let browser = SessionBoundaryBrowser(document: document, richText: rich, selected: selected,
            owners: [.init(label: "Session 2", range: document.candidates()[1].range)],
            preview: { _ = try protection.preview($0, in: document.snapshot.text) }, apply: { _ in applied = true })
        let views = descendants(try #require(browser.window?.contentView))
        let source = try #require(views.first { $0.identifier?.rawValue == "boundary-source" } as? NSTextView)
        let status = try #require(views.first { $0.identifier?.rawValue == "boundary-status" } as? NSTextField)
        let apply = try #require(views.first { $0.identifier?.rawValue == "boundary-apply" } as? NSButton)
        #expect(apply.isEnabled)
        #expect(status.stringValue.contains("Adjacent: Session 2"))
        source.setSelectedRange(NSRange(location: document.ranges[1].location,
            length: selected.length - document.ranges[1].location))
        browser.textViewDidChangeSelection(Notification(name: NSTextView.didChangeSelectionNotification, object: source))
        #expect(!apply.isEnabled)
        #expect(status.stringValue.contains("Cannot shrink"))
        source.setSelectedRange(NSRange(location: 0, length: rich.length))
        browser.textViewDidChangeSelection(Notification(name: NSTextView.didChangeSelectionNotification, object: source))
        #expect(!apply.isEnabled)
        #expect(status.stringValue.contains("Overlaps the scratchpad for Session 2"))
        source.setSelectedRange(selected.nsRange)
        browser.textViewDidChangeSelection(Notification(name: NSTextView.didChangeSelectionNotification, object: source))
        #expect(apply.isEnabled)
        #expect(!applied)
    }

    private func proposed(_ snapshot: WorkspaceSnapshot, range: SourceRange,
                          document: ProgramDocument, rich: NSAttributedString) throws -> WorkspaceSnapshot {
        var result = snapshot
        let contents = rich.attributedSubstring(from: range.nsRange)
        result.text = contents.string; result.richTextArchive = try RichTextArchive.encode(contents)
        result.anchor.sourceEvidence = try document.evidence(in: range)
        result.boundaryProtection = BoundaryEditProtection(sourceRange: range)
        result.revision += 1
        return result
    }

    @Test func commitsOwnershipAndSavedTextTogetherWithoutAcceptingNotesBaseline() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("boundary-commit-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = WorkspaceSnapshotStore(directory: root)
        let context = try SessionNoteContext(noteID: NoteID("boundary-fixture"), anchors: [], reader: BoundaryReader())
        let document = try await context.refresh(for: .resume)
        let initialRange = SourceRange(location: 0, length: document.ranges[2].location)
        let original = try context.createWorkspace(range: initialRange, observation: document.snapshot.observationID, store: store)
        let expanded = document.candidates()[0].range
        let changed = try proposed(original, range: expanded, document: document, rich: #require(context.richText))
        var acceptedExternalText = changed
        acceptedExternalText.anchor.baselineText = changed.text
        #expect(throws: WorkspaceError.invalidSnapshot) {
            try context.commitBoundary(acceptedExternalText, range: expanded, observation: document.snapshot.observationID, store: store)
        }
        var staleRevision = changed
        staleRevision.revision = original.revision
        #expect(throws: WorkspaceError.invalidSnapshot) {
            try context.commitBoundary(staleRevision, range: expanded, observation: document.snapshot.observationID, store: store)
        }
        try context.commitBoundary(changed, range: expanded, observation: document.snapshot.observationID, store: store)
        #expect(try store.load(id: original.workspaceID)?.snapshot == changed)
        #expect(try context.association(for: original.anchor.sessionID).range == expanded)
        #expect(context.registry.anchor(for: original.anchor.sessionID)?.baselineText == original.anchor.baselineText)
        #expect(changed.text.hasSuffix("Ideas\n"))
        let fresh = try await context.refresh(for: .comparison)
        #expect(try context.association(for: original.anchor.sessionID).range == expanded)
        #expect(throws: WorkspaceError.staleAssociation) {
            try context.commitBoundary(changed, range: expanded, observation: document.snapshot.observationID, store: store)
        }
        let neighbor = try context.createWorkspace(range: fresh.candidates()[1].range, observation: fresh.snapshot.observationID, store: store)
        let all = SourceRange(location: 0, length: (fresh.snapshot.text as NSString).length)
        let overlap = try proposed(changed, range: all, document: fresh, rich: #require(context.richText))
        #expect(throws: SessionAssociationError.occupied) {
            try context.commitBoundary(overlap, range: all, observation: fresh.snapshot.observationID, store: store)
        }
        #expect(try store.load(id: original.workspaceID)?.snapshot == changed)
        #expect(try context.association(for: neighbor.anchor.sessionID).range == fresh.candidates()[1].range)
    }

    @Test func failureAfterDiskPromotionBlocksOwnershipUntilDurableOwnersReload() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("boundary-failure-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = WorkspaceSnapshotStore(directory: root)
        let reader = BoundaryReader()
        let context = try SessionNoteContext(noteID: NoteID("boundary-fixture"), anchors: [], reader: reader)
        let document = try await context.refresh(for: .resume)
        let initialRange = SourceRange(location: 0, length: document.ranges[2].location)
        let original = try context.createWorkspace(range: initialRange, observation: document.snapshot.observationID, store: store)
        let expanded = document.candidates()[0].range
        let changed = try proposed(original, range: expanded, document: document, rich: #require(context.richText))
        let failing = WorkspaceSnapshotStore(directory: root, fault: { phase in
            if case .promoted = phase { throw CocoaError(.fileWriteUnknown) }
        })
        #expect(throws: (any Error).self) {
            try context.commitBoundary(changed, range: expanded, observation: document.snapshot.observationID, store: failing)
        }
        #expect(context.failure != nil)
        #expect(throws: WorkspaceError.staleAssociation) { try context.association(for: original.anchor.sessionID) }
        await #expect(throws: WorkspaceError.staleAssociation) { _ = try await context.refresh(for: .comparison) }
        #expect(try store.load(id: original.workspaceID)?.snapshot == changed)
        #expect(try store.load(id: original.workspaceID)?.snapshot.anchor.baselineText == original.anchor.baselineText)
        let reopened = try SessionNoteContextPool(store: store, reader: reader).context(for: document.snapshot.id)
        _ = try await reopened.refresh(for: .resume)
        #expect(try reopened.association(for: original.anchor.sessionID).range == expanded)
    }
}
