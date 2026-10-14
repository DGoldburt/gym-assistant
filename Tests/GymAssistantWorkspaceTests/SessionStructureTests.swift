import Foundation
import Testing
@testable import GymAssistantWorkspace

private func document(_ lines: [(String, Int)]) throws -> ProgramDocument {
    let paragraphs = lines.map { ProgramParagraph(text: $0.0 + "\n", headingLevel: $0.1) }
    return try ProgramDocument(snapshot: NoteSnapshot(id: NoteID("fixture"), text: paragraphs.map(\.text).joined()), paragraphs: paragraphs)
}
private func anchor(_ candidate: SessionCandidate) -> SessionAnchor {
    SessionAnchor(noteID: NoteID("fixture"), recordedHeading: candidate.label,
                  baselineText: candidate.evidence.text, sourceEvidence: candidate.evidence)
}

@Suite("Session structure and stable association") struct SessionStructureTests {
    @Test func hierarchyPreservesTypoBoundaryWeeksAndParkingLot() throws {
        let doc = try document([("Program", 1), ("Session 12", 2), ("Warmup", 3), ("A1 Squat", 0),
                                ("Sesion 13", 2), ("A1 Row", 0), ("Session A", 2),
                                ("Week 1", 3), ("A1 Press", 0), ("Week 2", 3), ("Week 3", 3),
                                ("Parking Lot", 1), ("Try a carry", 0)])
        let candidates = doc.candidates()
        #expect(candidates.count == 3)
        #expect(candidates[1].needsClassification)
        #expect(!candidates[0].evidence.text.contains("Sesion"))
        #expect(candidates[2].evidence.text.contains("Week 3"))
        #expect(candidates[2].evidence.text.contains("Try a carry"))
        for candidate in candidates { #expect(try doc.evidence(in: candidate.range) == candidate.evidence) }
    }

    @Test func bulkRenumberAndReorderPreserveAllIdentities() throws {
        let old = try document([("Session 12", 2), ("A1 Squat 🏋️", 0), ("Session 13", 2), ("A1 Row", 0)])
        let anchors = old.candidates().map(anchor)
        var registry = try SessionAssociationRegistry(noteID: old.snapshot.id, anchors: anchors)
        let new = try document([("Session 14", 2), ("A1 Row", 0), ("Session 13", 2), ("A1 Squat 🏋️", 0)])
        try registry.observe(new)
        #expect(registry.unresolved.isEmpty)
        #expect(registry.mappings[anchors[0].sessionID]?.range == new.candidates()[1].range)
        #expect(registry.mappings[anchors[1].sessionID]?.range == new.candidates()[0].range)
        #expect(anchors[0].recordedHeading == "Session 12")
    }

    @Test func duplicateFixDoesNotBindByLabel() throws {
        let old = try document([("Session 12", 2), ("A1 Squat", 0), ("Session 13", 2), ("A1 Row", 0)])
        let anchors = old.candidates().map(anchor)
        var registry = try SessionAssociationRegistry(noteID: old.snapshot.id, anchors: anchors)
        try registry.observe(document([("Session 13", 2), ("A1 Squat", 0), ("Session 13", 2), ("A1 Row", 0)]))
        #expect(registry.duplicateLabels == ["13"])
        #expect(registry.mappings.isEmpty)
        let corrected = try document([("Session 13", 2), ("A1 Squat", 0), ("Session 14", 2), ("A1 Row", 0)])
        try registry.observe(corrected)
        #expect(registry.mappings[anchors[0].sessionID]?.range == corrected.candidates()[0].range)
    }

    @Test func identicalOrChangedBodiesNeedConfirmation() throws {
        let old = try document([("Session 1", 2), ("A1 Squat", 0), ("Session 2", 2), ("A1 Squat", 0)])
        var registry = try SessionAssociationRegistry(noteID: old.snapshot.id, anchors: old.candidates().map(anchor))
        try registry.observe(old)
        #expect(registry.mappings.isEmpty)
        let unique = try document([("Session 1", 2), ("A1 Row", 0)])
        registry = try SessionAssociationRegistry(noteID: unique.snapshot.id, anchors: unique.candidates().map(anchor))
        try registry.observe(document([("Session 1", 2), ("A1 Changed", 0)]))
        #expect(registry.mappings.isEmpty)
    }

    @Test func confirmationRejectsStaleAndOccupiedAllowsAbutment() throws {
        let old = try document([("Session 1", 2), ("A1 Squat", 0), ("Session 2", 2), ("A1 Row", 0)])
        let anchors = old.candidates().map(anchor)
        var registry = try SessionAssociationRegistry(noteID: old.snapshot.id, anchors: anchors)
        try registry.observe(old)
        let next = try document([("Session 1", 2), ("Edited", 0), ("Session 2", 2), ("A1 Row", 0)])
        #expect(throws: SessionAssociationError.stale) {
            try registry.confirm(sessionID: anchors[0].sessionID, range: next.candidates()[0].range, in: next)
        }
        try registry.observe(next)
        #expect(throws: SessionAssociationError.occupied) {
            try registry.confirm(sessionID: anchors[0].sessionID, range: SourceRange(location: 0, length: (next.snapshot.text as NSString).length), in: next)
        }
        try registry.confirm(sessionID: anchors[0].sessionID, range: next.candidates()[0].range, in: next)
        #expect(registry.unresolved.isEmpty)
        #expect(anchors[0].baselineText.contains("Squat"))
    }

    @Test func oldSnapshotsWithoutEvidenceRequireConfirmation() throws {
        let doc = try document([("Session 1", 2), ("A1 Row", 0)])
        let legacy = SessionAnchor(noteID: doc.snapshot.id, recordedHeading: "Session 1", baselineText: doc.snapshot.text)
        var registry = try SessionAssociationRegistry(noteID: doc.snapshot.id, anchors: [legacy])
        try registry.observe(doc)
        #expect(registry.unresolved == [legacy.sessionID])
        try registry.confirm(sessionID: legacy.sessionID, range: doc.candidates()[0].range, in: doc)
        #expect(registry.unresolved.isEmpty)
    }
}
