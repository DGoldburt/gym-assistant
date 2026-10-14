import Foundation
import Testing
import GymAssistantWorkspace
@testable import GymAssistantMacOS

private actor ContextReader: NotesContextReading {
    var html = "<div><h2>Session 12</h2></div><div>A1 Row</div><div><h2>Session 13</h2></div><div>A1 Squat</div>"
    func captureSelectedNote() async throws -> NoteSnapshot { try await read(id: NoteID("fixture")) }
    func read(id: NoteID) async throws -> NoteSnapshot { NoteSnapshot(id: id, text: "", html: html) }
    func metadata(id: NoteID) async throws -> NoteMetadata { NoteMetadata(id: id, modifiedAt: Date(timeIntervalSince1970: 1)) }
    func replace(_ value: String) { html = value }
}

@Suite("Shared Notes session context") @MainActor struct SessionNoteContextTests {
    @Test func poolSharesMonitorAndLoadsClosedWorkspaceOwners() async throws {
        let reader = ContextReader()
        let document = try ProgramDocumentReader.read(await reader.read(id: NoteID("fixture"))).0
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("session-pool-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = WorkspaceSnapshotStore(directory: root)
        for candidate in document.candidates() {
            let anchor = SessionAnchor(noteID: document.snapshot.id, recordedHeading: candidate.label,
                baselineText: candidate.evidence.text, sourceEvidence: candidate.evidence)
            let rich = NSAttributedString(string: candidate.evidence.text)
            try store.save(WorkspaceSnapshot(anchor: anchor, text: rich.string, richTextArchive: RichTextArchive.encode(rich)))
        }
        let pool = SessionNoteContextPool(store: store, reader: reader)
        let first = try pool.context(for: document.snapshot.id)
        let second = try pool.context(for: document.snapshot.id)
        #expect(first === second)
        _ = try await first.refresh(for: .resume)
        #expect(first.registry.mappings.count == 2)
        #expect(try store.storedAnchors().count == 2)
    }

    @Test func revalidatesClosedAnchorsAndRetainsManualConfirmationAcrossIdenticalReads() async throws {
        let reader = ContextReader()
        let original = try ProgramDocumentReader.read(await reader.read(id: NoteID("fixture"))).0
        let anchors = original.candidates().map {
            SessionAnchor(noteID: original.snapshot.id, recordedHeading: $0.label,
                          baselineText: $0.evidence.text, sourceEvidence: $0.evidence)
        }
        let context = try SessionNoteContext(noteID: original.snapshot.id, anchors: anchors, reader: reader)
        _ = try await context.refresh(for: .resume)
        #expect(context.registry.mappings.count == 2)
        await reader.replace("<div><h2>Session 13</h2></div><div>A1 Row</div><div><h2>Session 14</h2></div><div>A1 Squat</div>")
        let renumbered = try await context.refresh(for: .chat)
        #expect(try context.association(for: anchors[0].sessionID).range == renumbered.candidates()[0].range)
        #expect(try context.association(for: anchors[1].sessionID).range == renumbered.candidates()[1].range)
        await reader.replace("<div><h2>Session 13</h2></div><div>Edited row</div><div><h2>Session 14</h2></div><div>A1 Squat</div>")
        let changed = try await context.refresh(for: .comparison)
        #expect(throws: WorkspaceError.staleAssociation) { try context.association(for: anchors[0].sessionID) }
        let confirmed = try context.confirm(session: anchors[0].sessionID, range: changed.candidates()[0].range,
                                            observation: changed.snapshot.observationID)
        #expect(confirmed.baselineText == anchors[0].baselineText)
        let reread = try await context.refresh(for: .checkedCopy)
        #expect(try context.association(for: anchors[0].sessionID).observationID == reread.snapshot.observationID)
    }
}
