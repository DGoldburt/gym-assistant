import Foundation
import Testing
@testable import GymAssistantWorkspace

@Suite("Unrecorded session context") struct UnrecordedSessionTests {
    private func workspace() -> WorkspaceSnapshot {
        WorkspaceSnapshot(anchor: SessionAnchor(noteID: NoteID("fixture"), recordedHeading: "Session 2", baselineText: "",
            recordingState: .unrecorded), text: "Session 2\nWarmup\n", richTextArchive: Data([1]))
    }

    @Test func additionPreservesAllRecordedNotesAndStableLocalIDs() throws {
        let draft = workspace()
        let note = NoteSnapshot(id: draft.anchor.noteID, text: "Session 1\nA1 Row\n")
        let request = try ProgramContextAssembler.assembleUnrecorded(note: note, workspace: draft,
            profile: CoachingProfile(version: "test", entries: []), question: "What should A1 be?", maximumContextBytes: 10000)
        #expect(request.noteContext.hasPrefix(note.text + "\n\n"))
        #expect(request.noteContext.contains("Unrecorded scratchpad session — addition, not yet in Notes"))
        #expect(request.noteContext.hasSuffix(draft.text))
        #expect(request.sessionRecordingState == .unrecorded)
        #expect(request.workspaceID == draft.workspaceID && request.sessionID == draft.anchor.sessionID)
        #expect(request.observationID == note.observationID)
        let falseAssociation = SessionAssociation(sessionID: draft.anchor.sessionID, noteID: note.id,
            observationID: note.observationID, range: SourceRange(location: 0, length: (note.text as NSString).length))
        #expect(throws: WorkspaceError.staleAssociation) {
            try ProgramContextAssembler.assemble(note: note, association: falseAssociation, workspace: draft,
                profile: .init(version: "test", entries: []), question: "A1?", maximumContextBytes: 10000)
        }
    }

    @Test func unrecordedStateCannotClaimBaselineRangeOrLegacySchema() throws {
        let original = workspace()
        try original.validate()
        var invalid = original; invalid.schemaVersion = 1
        #expect(throws: WorkspaceError.invalidSnapshot) { try invalid.validate() }
        invalid = original; invalid.anchor.baselineText = "Recorded already"
        #expect(throws: WorkspaceError.invalidSnapshot) { try invalid.validate() }
        invalid = original; invalid.anchor.sourceEvidence = .init(paragraphs: [])
        #expect(throws: WorkspaceError.invalidSnapshot) { try invalid.validate() }
        invalid = original; invalid.boundaryProtection = .init(sourceRange: .init(location: 0, length: (original.text as NSString).length))
        #expect(throws: WorkspaceError.invalidSnapshot) { try invalid.validate() }
        #expect(throws: SessionAssociationError.duplicateIdentity) {
            try SessionAssociationRegistry(noteID: original.anchor.noteID, anchors: [original.anchor])
        }
    }

    @Test func additionStillChecksIdentityAndBudgetWithoutTruncation() throws {
        let draft = workspace(), profile = CoachingProfile(version: "test", entries: [])
        #expect(throws: WorkspaceError.staleAssociation) {
            try ProgramContextAssembler.assembleUnrecorded(note: NoteSnapshot(id: NoteID("other"), text: ""),
                workspace: draft, profile: profile, question: "A1?", maximumContextBytes: 10000)
        }
        #expect(throws: WorkspaceError.oversizedContext) {
            try ProgramContextAssembler.assembleUnrecorded(note: NoteSnapshot(id: draft.anchor.noteID, text: "Recorded note"),
                workspace: draft, profile: profile, question: "A1?", maximumContextBytes: 1)
        }
    }
}
