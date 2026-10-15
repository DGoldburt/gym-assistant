import Foundation
import Testing
@testable import GymAssistantWorkspace

@Suite("Heading-only session skeleton") struct SessionSkeletonTests {
    @Test func incrementsNumberOrLetterWithoutPromptingOrCarryingDate() throws {
        for (previous, expected) in [("Session 18 — 14 Oct", "Session 19"), ("Session 009", "Session 010"),
                                     ("Session A", "Session B"), ("session b: three weeks", "Session C"),
                                     ("Session Y", "Session Z")] {
            let source = SessionSourceEvidence(paragraphs: [.init(text: previous + "\n", headingLevel: 2),
                                                           .init(text: "Warmup\n", headingLevel: 3)])
            let skeleton = try SessionSkeleton(previous: source)
            #expect(skeleton.evidence.text == expected + "\nWarmup\n")
        }
    }

    @Test func ambiguityUsesEditableNonIdentityPlaceholder() throws {
        for previous in ["Session Z", "Session AA", "Session A1", "Session 1/2", "Session", "Other heading",
                         "Session " + String(Int.max), "Session 999999999999999999999999999999999"] {
            #expect(SessionSkeleton.nextHeading(after: previous) == SessionSkeleton.placeholderHeading)
        }
        #expect(SessionSkeleton.nextHeading(after: "Session 18", existingHeadings: ["Session 18", "Session 19 — old"])
                == SessionSkeleton.placeholderHeading)
        #expect(SessionSkeleton.nextHeading(after: "Session A", existingHeadings: ["Session A", "Session A"])
                == SessionSkeleton.placeholderHeading)
        #expect(SessionSkeleton.nextHeading(after: "Session 009", existingHeadings: ["Session 10"])
                == SessionSkeleton.placeholderHeading)
        let source = SessionSourceEvidence(paragraphs: [.init(text: "Session Z\n", headingLevel: 2)])
        let skeleton = try SessionSkeleton(previous: source)
        #expect(skeleton.evidence.text == "Session [number or letter]\n")
        // A temporary label is editable text, not a new authoritative Notes identity.
        #expect(ProgramDocument.sessionLabel(skeleton.evidence.paragraphs[0].label) == nil)
    }

    @Test func excludesExerciseDoseDateAndParkingLotContent() throws {
        let previous = SessionSourceEvidence(paragraphs: [
            .init(text: "Session 18 — 14 Oct\n", headingLevel: 2),
            .init(text: "Warmup\n", headingLevel: 3),
            .init(text: "Band pull-apart 2 x 12\n"),
            .init(text: "A1\n", headingLevel: 3),
            .init(text: "Deadlift 3 x 5 at 50kg\n"),
            .init(text: "B1 Overhead press\n", headingLevel: 3),
            .init(text: "14 Oct results\n", headingLevel: 3),
            .init(text: "Neck felt tight\n"),
            .init(text: "Parking Lot\n", headingLevel: 2),
            .init(text: "Conditioning\n", headingLevel: 3),
            .init(text: "Bike intervals next time\n")
        ])
        let skeleton = try SessionSkeleton(previous: previous, newHeading: "Session 19")
        #expect(skeleton.evidence.text == "Session 19\nWarmup\nA1\n")
        #expect(skeleton.headingsNeedingReview.map(\.paragraph.label) == ["B1 Overhead press", "14 Oct results"])
        #expect(skeleton.headingsNeedingReview.map(\.sourceParagraphIndex) == [5, 6])
        #expect(skeleton.evidence.paragraphs.map(\.headingLevel) == [2, 3, 3])
    }

    @Test func retainsAllWeeksAsOneLetteredStructureWithoutPrescriptionsOrMarks() throws {
        let previous = SessionSourceEvidence(paragraphs: [
            .init(text: "Session A\n", headingLevel: 2),
            .init(text: "Week 1\n", headingLevel: 3),
            .init(text: "Warmup\n", headingLevel: 4, marks: [.init(range: .init(location: 0, length: 6), kind: .link, value: "https://example.com")]),
            .init(text: "A1 Row 3 x 8\n"),
            .init(text: "Week 2\n", headingLevel: 3),
            .init(text: "Warmup\n", headingLevel: 4),
            .init(text: "A1 Row 3 x 10\n"),
            .init(text: "Week 3\n", headingLevel: 3),
            .init(text: "A1 Row 3 x 12\n")
        ])
        let skeleton = try SessionSkeleton(previous: previous, newHeading: "Session B")
        #expect(skeleton.evidence.text == "Session B\nWeek 1\nWarmup\nWeek 2\nWarmup\nWeek 3\n")
        #expect(skeleton.evidence.paragraphs.allSatisfy { $0.marks.isEmpty && $0.listStyle == nil })
        #expect(skeleton.headingsNeedingReview.isEmpty)
    }

    @Test func unknownOrPeerHeadingsNeedReviewAndPlainBodyNeverBecomesStructure() throws {
        let previous = SessionSourceEvidence(paragraphs: [
            .init(text: "Session 1\n", headingLevel: 2),
            .init(text: "Warmup\n"),
            .init(text: "Week 1 — heavier\n", headingLevel: 3),
            .init(text: "Strength\n", headingLevel: 2),
            .init(text: "A\n", headingLevel: 3),
            .init(text: "Block B\n", headingLevel: 3)
        ])
        let skeleton = try SessionSkeleton(previous: previous, newHeading: "Session 2")
        // A and Block B are children of the unclassified peer heading; do not
        // silently promote them after omitting their parent.
        #expect(skeleton.evidence.text == "Session 2\n")
        #expect(skeleton.headingsNeedingReview.count == 4)
        for invalid in ["", "New session", "Session 2\nA1 Row"] {
            #expect(throws: WorkspaceError.invalidSnapshot) { try SessionSkeleton(previous: previous, newHeading: invalid) }
        }
        #expect(throws: WorkspaceError.invalidSnapshot) {
            try SessionSkeleton(previous: .init(paragraphs: []), newHeading: "Session 2")
        }
    }
}
