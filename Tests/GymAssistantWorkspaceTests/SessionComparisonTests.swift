import Testing
@testable import GymAssistantWorkspace

@Suite("Handoff comparison exceptions") struct SessionComparisonTests {
    @Test func onlyTerminalEmptyBodyParagraphsAreIgnoredWithoutMutation() {
        let row = ProgramParagraph(text: "A1 Row\n")
        let blank = ProgramParagraph(text: "\n")
        let before = SessionSourceEvidence(paragraphs: [row, blank, blank])
        let after = SessionSourceEvidence(paragraphs: [row])
        #expect(SessionComparison.handoffEquivalent(before, after))
        #expect(SessionComparison.handoffText(before: before, after: after) == "No text differences.")
        #expect(before.text == "A1 Row\n\n\n")
        #expect(before.paragraphs.count == 3)
        for retained in [ProgramParagraph(text: "\n", headingLevel: 3),
                         ProgramParagraph(text: "\n", listStyle: "disc"),
                         ProgramParagraph(text: " \n"), ProgramParagraph(text: "\t\n")] {
            #expect(!SessionComparison.handoffEquivalent(SessionSourceEvidence(paragraphs: [row, retained]), after))
        }
        #expect(!SessionComparison.handoffEquivalent(SessionSourceEvidence(paragraphs: [row, blank, row]),
                                                     SessionSourceEvidence(paragraphs: [row, row])))
    }
    @Test func contentAndFormattingDifferencesRemainVisible() {
        let plain = SessionSourceEvidence(paragraphs: [ProgramParagraph(text: "A1 Row\n")])
        let heading = SessionSourceEvidence(paragraphs: [ProgramParagraph(text: "A1 Row\n", headingLevel: 2)])
        let changed = SessionSourceEvidence(paragraphs: [ProgramParagraph(text: "A1 Press\n")])
        #expect(!SessionComparison.handoffEquivalent(plain, heading))
        #expect(!SessionComparison.handoffEquivalent(plain, changed))
        #expect(SessionComparison.handoffText(before: plain, after: changed).contains("+ A1 Press"))
    }
}
