import Testing
@testable import GymAssistantWorkspace

@Suite("Session text diff") struct SessionTextDiffTests {
    @Test func matchingInteriorHeadingsAreContextNotFalseChanges() {
        let diff = SessionComparison.text(before: "Session 18\nWarmup\nBalance preparation\nStrength\nA1 Row\n",
            after: "Session 19\nWarmup\nStrength\n")
        #expect(diff.contains("− Session 18") && diff.contains("+ Session 19"))
        #expect(diff.contains("  Warmup") && diff.contains("  Strength"))
        #expect(!diff.contains("− Warmup") && !diff.contains("+ Strength"))
        #expect(diff.contains("− Balance preparation") && diff.contains("− A1 Row"))
    }
    @Test func repeatedLinesAndSeparatedChangesRetainBoundedContext() {
        let same = (1...12).map { "Context \($0)" }.joined(separator: "\n")
        let diff = SessionComparison.text(before: "Old\nWarmup\nWarmup\n" + same + "\nEnd",
            after: "New\nWarmup\n" + same + "\nChanged end")
        #expect(diff.components(separatedBy: "\n").filter { $0 == "− Warmup" }.count == 1)
        #expect(diff.contains("…") && !diff.contains("Context 6"))
        #expect(SessionComparison.text(before: "same", after: "same") == "No text differences.")
        #expect(SessionComparison.text(before: "", after: "Added").contains("+ Added"))
    }
}
