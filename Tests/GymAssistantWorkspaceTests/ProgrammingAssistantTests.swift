import Foundation
import Testing
@testable import GymAssistantWorkspace

private func fixture() -> (NoteSnapshot, WorkspaceSnapshot, SessionAssociation, CoachingProfile) {
    let note = NoteSnapshot(id: NoteID("synthetic"), text: "Before\nSession 1\nOld exercise\nAfter\n")
    let range = (note.text as NSString).range(of: "Session 1\nOld exercise\n")
    let workspace = WorkspaceSnapshot(anchor: SessionAnchor(noteID: note.id, recordedHeading: "Session 1", baselineText: "Session 1\nOld exercise\n"),
        revision: 2, text: "Session 1\nCoach choice\n", richTextArchive: Data([1]))
    let association = SessionAssociation(sessionID: workspace.anchor.sessionID, noteID: note.id,
        observationID: note.observationID, range: SourceRange(location: range.location, length: range.length))
    let profile = CoachingProfile(version: "fixture-1", entries: [
        ProfileEntry(wording: "Prefer non-machine choices", source: "Synthetic confirmed source", kind: .confirmedTendency,
                     confirmed: true, scope: "General tendency", exceptions: ["Explicit session constraints"]),
        ProfileEntry(wording: "Transfer claim not evaluated", source: "Synthetic claim", kind: .scientificClaim, confirmed: false)
    ])
    return (note, workspace, association, profile)
}
private func request() throws -> ProgrammingRequest {
    let (note, workspace, association, profile) = fixture()
    return try ProgramContextAssembler.assemble(note: note, association: association, workspace: workspace,
        profile: profile, question: "Use a leg press today", maximumContextBytes: 10_000)
}

@Suite("Scratchpad context and request lifecycle") struct ProgrammingAssistantTests {
    @Test func replacesOnlyAssociatedSession() throws {
        let value = try request()
        #expect(value.noteContext == "Before\nSession 1\nCoach choice\nAfter\n")
        #expect(value.scratchpad == "Session 1\nCoach choice\n")
        #expect(value.revision == 2)
        #expect(!value.noteContext.contains("Old exercise"))
    }
    @Test func preservesProfileEvidenceWithoutInferenceUpgrade() throws {
        let value = try request()
        #expect(value.question == "Use a leg press today")
        #expect(value.profile.entries[0].kind == .confirmedTendency)
        #expect(value.profile.entries[0].exceptions == ["Explicit session constraints"])
        #expect(value.profile.entries[1].kind == .scientificClaim)
        #expect(!value.profile.entries[1].confirmed)
    }
    @Test func associationNeedsTheSameObservationAndNote() throws {
        let (note, workspace, association, profile) = fixture()
        let stale = NoteSnapshot(id: note.id, text: note.text)
        #expect(throws: WorkspaceError.staleAssociation) {
            try ProgramContextAssembler.assemble(note: stale, association: association, workspace: workspace,
                profile: profile, question: "B2?", maximumContextBytes: 10_000)
        }
        let other = NoteSnapshot(id: NoteID("other"), observationID: note.observationID, text: note.text)
        #expect(throws: WorkspaceError.staleAssociation) {
            try ProgramContextAssembler.assemble(note: other, association: association, workspace: workspace,
                profile: profile, question: "B2?", maximumContextBytes: 10_000)
        }
    }
    @Test func refusesInvalidRangeAndEmptyQuestion() throws {
        let (note, workspace, _, profile) = fixture()
        let invalid = SessionAssociation(sessionID: workspace.anchor.sessionID, noteID: note.id,
            observationID: note.observationID, range: SourceRange(location: -1, length: 8))
        #expect(throws: WorkspaceError.invalidRange) {
            try ProgramContextAssembler.assemble(note: note, association: invalid, workspace: workspace,
                profile: profile, question: "B2?", maximumContextBytes: 10_000)
        }
        let (_, _, good, _) = fixture()
        // Empty question is rejected before association/context work.
        #expect(throws: WorkspaceError.emptyQuestion) {
            try ProgramContextAssembler.assemble(note: note, association: good, workspace: workspace,
                profile: profile, question: " \n", maximumContextBytes: 10_000)
        }
    }
    @Test func oversizedInputIsRejectedWithoutTruncation() throws {
        let (note, workspace, association, profile) = fixture()
        #expect(throws: WorkspaceError.oversizedContext) {
            try ProgramContextAssembler.assemble(note: note, association: association, workspace: workspace,
                profile: profile, question: "B2?", maximumContextBytes: 1)
        }
    }
    @Test func conversationIsScopedAndOrdered() throws {
        let (note, original, association, profile) = fixture()
        var workspace = original
        let id = UUID()
        workspace.messages = [
            ConversationMessage(requestID: id, conversationID: workspace.conversationID, role: .coach,
                text: "Earlier question", status: .complete, scratchpadRevision: 1, observationID: note.observationID),
            ConversationMessage(requestID: id, conversationID: workspace.conversationID, role: .assistant,
                text: "Earlier response", status: .complete, scratchpadRevision: 1, observationID: note.observationID),
            ConversationMessage(requestID: UUID(), conversationID: ConversationID(), role: .coach,
                text: "Another conversation", status: .complete, scratchpadRevision: 1, observationID: note.observationID)
        ]
        let value = try ProgramContextAssembler.assemble(note: note, association: association, workspace: workspace,
            profile: profile, question: "Now?", maximumContextBytes: 10_000)
        #expect(value.conversation.map(\.text) == ["Earlier question", "Earlier response"])
        #expect(value.conversation.map(\.role) == [.coach, .assistant])
    }
    @Test func gateRefusesSecondRequestAndLateCancelledResult() throws {
        var gate = RequestGate()
        let first = try request(), second = try request()
        try gate.begin(first)
        #expect(throws: WorkspaceError.requestAlreadyRunning) { try gate.begin(second) }
        #expect(gate.active == first)
        gate.stop(); try gate.begin(second)
        #expect(gate.finish(ProgrammingResponse(requestID: first.id, text: "Late")) == nil)
        #expect(gate.active == second)
        #expect(gate.finish(ProgrammingResponse(requestID: second.id, text: "Current")) == second)
        #expect(gate.active == nil)
    }
    @Test func editsCannotChangeCapturedRequest() throws {
        let (note, original, association, profile) = fixture()
        var workspace = original
        let first = try ProgramContextAssembler.assemble(note: note, association: association, workspace: workspace,
            profile: profile, question: "B2?", maximumContextBytes: 10_000)
        workspace.revision += 1; workspace.text += "B2 Dowel squat\n"
        let second = try ProgramContextAssembler.assemble(note: note, association: association, workspace: workspace,
            profile: profile, question: "Review", maximumContextBytes: 10_000)
        #expect(!first.scratchpad.contains("Dowel squat"))
        #expect(second.noteContext.contains("Dowel squat"))
        #expect(second.revision == first.revision + 1)
    }
    @Test func restartMarksPendingRequestsInterrupted() {
        let (note, original, _, _) = fixture()
        var workspace = original
        workspace.messages = [ConversationMessage(requestID: UUID(), conversationID: workspace.conversationID,
            role: .assistant, text: "", status: .pending, scratchpadRevision: 2, observationID: note.observationID)]
        workspace.markInterruptedRequests()
        #expect(workspace.messages[0].status == .interrupted)
    }
    @Test func fakeRespondsWithCapturedRevision() async throws {
        let value = try request()
        let reply = try await FakeProgrammingAssistant(delay: .milliseconds(1)).reply(to: value)
        #expect(reply.requestID == value.id)
        #expect(reply.text.contains("revision 2"))
        #expect(reply.text.contains("not exercise advice"))
    }
    @Test func comparisonShowsChangedLinesRatherThanStackedCopies() {
        #expect(SessionComparison.text(before: "A1 RDL\nB2\n", after: "A1 RDL\nB2 Dowel squat\n") == "  A1 RDL\n− B2\n+ B2 Dowel squat\n  ")
        #expect(SessionComparison.text(before: "Same", after: "Same") == "No text differences.")
    }
    @Test func paragraphRangesRespectUTF16AndRejectPartialText() {
        let value = "A1 🏋️\nB2\n"
        let first = (value as NSString).paragraphRange(for: NSRange(location: 0, length: 0))
        #expect(SourceRange(location: first.location, length: first.length).isParagraphAligned(in: value))
        #expect(!SourceRange(location: 1, length: first.length - 1).isParagraphAligned(in: value))
        #expect(!SourceRange(location: Int.max, length: 1).isValid(in: value))
    }
}
