import AppKit
import Testing
import GymAssistantWorkspace
@testable import GymAssistantMacOS

private actor EntryReader: NotesContextReading {
    var selection = NoteID("entry-fixture")
    var html = "<div><h2>Session 12</h2></div><div>A1 Row</div><div><h2>Session A</h2></div><div><h3>Week 1</h3></div><div>A1 Squat</div><div><h3>Week 2</h3></div><div>A1 Squat progression</div>"
    var captures = 0
    var reads: [NoteID] = []
    func captureSelectedNote() async throws -> NoteSnapshot {
        captures += 1
        return NoteSnapshot(id: selection, text: "", html: html)
    }
    func read(id: NoteID) async throws -> NoteSnapshot {
        reads.append(id); return NoteSnapshot(id: id, text: "", html: html)
    }
    func metadata(id: NoteID) async throws -> NoteMetadata { NoteMetadata(id: id, modifiedAt: .distantPast) }
    func replace(_ value: String) { html = value }
    func selectAnotherNote() { selection = NoteID("another-note") }
}

@Suite("Session workspace entry") @MainActor struct SessionWorkspaceEntryTests {
    private func temporaryStore() -> WorkspaceSnapshotStore {
        WorkspaceSnapshotStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent("entry-test-" + UUID().uuidString))
    }

    @Test func newSessionPreviewCreatesNothingAndAcceptedSkeletonResumesWithoutDuplication() async throws {
        let reader = EntryReader(), store = temporaryStore()
        defer { try? FileManager.default.removeItem(at: store.directory) }
        let entry = SessionWorkspaceEntry(store: store, reader: reader)
        let id = try await entry.captureNote()
        guard case .proposal(let proposal) = try await entry.prepareNewSession(in: id) else { Issue.record("Expected proposal"); return }
        #expect(proposal.skeleton.evidence.text == "Session B\nWeek 1\nWeek 2\n")
        #expect(try store.storedAnchors().isEmpty)
        let first = Task { try await entry.acceptNewSession(proposal) }
        let second = Task { try await entry.acceptNewSession(proposal) }
        let created = try await first.value, repeated = try await second.value
        #expect(created.snapshot.workspaceID == repeated.snapshot.workspaceID)
        #expect(created.snapshot.anchor.isUnrecorded && created.snapshot.boundaryProtection == nil)
        #expect(created.context.registry.mappings.isEmpty)
        #expect(try store.storedAnchors().count == 1)
        var edited = created.snapshot; edited.composerText = "Keep it unloaded"; edited.revision += 1
        try store.save(edited)
        let reopened = SessionWorkspaceEntry(store: store, reader: reader)
        guard case .resume(let resumed) = try await reopened.prepareNewSession(in: id) else { Issue.record("Expected resume"); return }
        #expect(resumed.snapshot == edited)
        let rich = try RichTextArchive.decode(resumed.snapshot.richTextArchive)
        #expect((rich.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)?.headerLevel == 2)
        #expect((rich.attribute(.paragraphStyle, at: 10, effectiveRange: nil) as? NSParagraphStyle)?.headerLevel == 3)
    }

    @Test func changedSkeletonSourceRefusesCreationAndUncertainHeadingsStayReviewable() async throws {
        let reader = EntryReader(), store = temporaryStore()
        defer { try? FileManager.default.removeItem(at: store.directory) }
        let entry = SessionWorkspaceEntry(store: store, reader: reader)
        let id = try await entry.captureNote()
        await reader.replace("<div><h2>Session Z</h2></div><div><h3>A1 Row</h3></div><div>3x5</div>")
        guard case .proposal(let proposal) = try await entry.prepareNewSession(in: id) else { Issue.record("Expected proposal"); return }
        #expect(proposal.skeleton.evidence.text == "Session [number or letter]\n")
        #expect(proposal.skeleton.headingsNeedingReview.map(\.paragraph.label) == ["A1 Row"])
        await reader.replace("<div><h2>Session Z</h2></div><div><h3>A1 Press</h3></div><div>3x5</div>")
        await #expect(throws: SessionEntryError.skeletonSourceChanged) { _ = try await entry.acceptNewSession(proposal) }
        #expect(try store.storedAnchors().isEmpty)
    }

    @Test func multipleUnrecordedSessionsRequireExplicitChoiceRatherThanInventingAnother() async throws {
        let reader = EntryReader(), store = temporaryStore()
        defer { try? FileManager.default.removeItem(at: store.directory) }
        let id = NoteID("entry-fixture")
        for label in ["Session B", "Session C"] {
            let rich = NSAttributedString(string: label + "\n")
            try store.save(WorkspaceSnapshot(anchor: .init(noteID: id, recordedHeading: label, baselineText: "", recordingState: .unrecorded),
                text: rich.string, richTextArchive: try RichTextArchive.encode(rich)))
        }
        let entry = SessionWorkspaceEntry(store: store, reader: reader)
        await #expect(throws: SessionEntryError.multipleUnrecordedWorkspaces) { _ = try await entry.prepareNewSession(in: id) }
        #expect(try store.storedAnchors().count == 2)
    }

    @Test func simultaneousEntriesReuseOneWindowAndClosedWindowsRetainIdentity() async throws {
        let reader = EntryReader(), store = temporaryStore()
        defer { try? FileManager.default.removeItem(at: store.directory) }
        let windows = SessionWorkspaceWindows(store: store, reader: reader,
            profile: CoachingProfile(version: "test", entries: []), assistant: FakeProgrammingAssistant())
        let id = try await windows.captureNote()
        let firstTask = Task { ObjectIdentifier(try await windows.latest(in: id)) }
        let secondTask = Task { ObjectIdentifier(try await windows.latest(in: id)) }
        let firstIdentity = try await firstTask.value, secondIdentity = try await secondTask.value
        #expect(firstIdentity == secondIdentity)
        let first = try await windows.latest(in: id)
        #expect(ObjectIdentifier(first) == firstIdentity)
        first.window?.close()
        let reopened = try await windows.latest(in: id)
        #expect(first === reopened)
        #expect(try store.storedAnchors().count == 1)
        #expect(windows.flushAndStop())
    }

    @Test func unrecordedWindowsReuseTheEditorAcrossCloseAndReentry() async throws {
        let reader = EntryReader(), store = temporaryStore()
        defer { try? FileManager.default.removeItem(at: store.directory) }
        let windows = SessionWorkspaceWindows(store: store, reader: reader,
            profile: .init(version: "test", entries: []), assistant: FakeProgrammingAssistant())
        let id = try await windows.captureNote()
        guard case .proposal(let proposal) = try await windows.prepareNewSession(in: id) else { Issue.record("Expected proposal"); return }
        let first = try await windows.acceptNewSession(proposal)
        first.window?.close()
        guard case .workspace(let reopened) = try await windows.prepareNewSession(in: id) else { Issue.record("Expected existing window"); return }
        #expect(first === reopened)
        #expect(first.snapshot.anchor.isUnrecorded && first.snapshot.boundaryProtection == nil)
        #expect(try store.storedAnchors().count == 1)
        #expect(windows.flushAndStop())
    }

    @Test func capturesOnceKeepsLetteredWeeksTogetherAndReopensSavedScratchpad() async throws {
        let reader = EntryReader(), store = temporaryStore()
        defer { try? FileManager.default.removeItem(at: store.directory) }
        let entry = SessionWorkspaceEntry(store: store, reader: reader)
        let id = try await entry.captureNote()
        await reader.selectAnotherNote()
        let first = try await entry.latest(in: id)
        #expect(first.snapshot.anchor.recordedHeading == "Session A")
        #expect(first.snapshot.text.contains("Week 1") && first.snapshot.text.contains("Week 2"))
        var edited = first.snapshot
        edited.composerText = "Keep it unloaded"; edited.revision += 1
        try store.save(edited)
        let reopened = try await SessionWorkspaceEntry(store: store, reader: reader).latest(in: id)
        #expect(reopened.snapshot == edited)
        #expect(try store.storedAnchors().count == 1)
        #expect(await reader.captures == 1)
        #expect(await reader.reads.allSatisfy { $0 == id })
    }

    @Test func renumberingRelocatesSavedOwnerWithoutReplacingScratchpad() async throws {
        let reader = EntryReader(), store = temporaryStore()
        defer { try? FileManager.default.removeItem(at: store.directory) }
        let entry = SessionWorkspaceEntry(store: store, reader: reader)
        let id = try await entry.captureNote()
        let first = try await entry.latest(in: id)
        let oldHTML = await reader.html
        await reader.replace(oldHTML.replacingOccurrences(of: "Session 12", with: "Session 1234")
            .replacingOccurrences(of: "Session A", with: "Session B"))
        let reopened = try await SessionWorkspaceEntry(store: store, reader: reader).latest(in: id)
        #expect(reopened.snapshot == first.snapshot)
        #expect(reopened.association.range.location == first.association.range.location + 2)
        let controller = try SessionScratchpadWindowController(snapshot: reopened.snapshot, store: store,
            note: reopened.note, association: reopened.association, profile: CoachingProfile(version: "test", entries: []),
            noteContext: reopened.context, pasteboard: .withUniqueName())
        #expect(controller.snapshot.text == first.snapshot.text)
        #expect(controller.snapshot.anchor.baselineText == first.snapshot.anchor.baselineText)
        #expect(controller.snapshot.boundaryProtection?.sourceRange == reopened.association.range)
        #expect(try store.storedAnchors().count == 1)
    }

    @Test func duplicateUnknownOrChangedRegionsNeverCreateReplacementWorkspace() async throws {
        let reader = EntryReader(), store = temporaryStore()
        defer { try? FileManager.default.removeItem(at: store.directory) }
        let entry = SessionWorkspaceEntry(store: store, reader: reader)
        let id = try await entry.captureNote()
        let first = try await entry.latest(in: id)
        let oldHTML = await reader.html
        await reader.replace(oldHTML.replacingOccurrences(of: "Session A", with: "Session 12"))
        await #expect(throws: SessionEntryError.duplicateHeadings(["12"])) { _ = try await entry.latest(in: id) }
        await reader.replace(oldHTML.replacingOccurrences(of: "A1 Squat progression", with: "Changed externally"))
        await #expect(throws: SessionEntryError.unresolvedSavedWorkspace) { _ = try await entry.latest(in: id) }
        await reader.replace(oldHTML + "<div><h2>Ideas</h2></div><div>Unclassified</div>")
        await #expect(throws: SessionEntryError.boundaryReviewRequired) { _ = try await entry.latest(in: id) }
        #expect(try store.storedAnchors().count == 1)
        #expect(try store.load(id: first.snapshot.workspaceID)?.snapshot == first.snapshot)
    }

    @Test func damagedSavedRichTextRequiresRecoveryInsteadOfEmptyReplacement() async throws {
        let reader = EntryReader(), store = temporaryStore()
        defer { try? FileManager.default.removeItem(at: store.directory) }
        let entry = SessionWorkspaceEntry(store: store, reader: reader)
        let id = try await entry.captureNote()
        let first = try await entry.latest(in: id)
        try store.save(first.snapshot) // Preserve a valid previous slot.
        var damaged = first.snapshot
        damaged.richTextArchive = Data([0, 1, 2])
        let bytes = try JSONEncoder().encode(damaged)
        try bytes.write(to: store.currentURL(for: damaged.workspaceID))
        await #expect(throws: SessionEntryError.recoveryRequired(damaged.workspaceID)) { _ = try await entry.latest(in: id) }
        #expect(try Data(contentsOf: store.currentURL(for: damaged.workspaceID)) == bytes)
        #expect(try store.storedAnchors().count == 1)
    }
}
