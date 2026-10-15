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

@Suite("Inserted session association") @MainActor struct InsertedSessionAssociationTests {
    private let original = "<div><h2>Session 1</h2></div><div>A1 Row</div><div><h3>Warmup</h3></div>"
    private let addition = "<div><h2>Session 2</h2></div><div><h3>Warmup</h3></div>"

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
