import AppKit
import Testing
import GymAssistantWorkspace
@testable import GymAssistantMacOS

@Suite("Notes semantic document import") @MainActor struct ProgramDocumentReaderTests {
    @Test func importsNativeHeadingWrappersListsAndBold() throws {
        let html = """
        <div><b><h1>Synthetic note</h1></b></div>
        <div><b><h2>Session A</h2></b></div>
        <div><b><h3>Week 1</h3></b></div>
        <ul>
        <li>Light preparation</li>
        <li>Balance</li>
        </ul>
        <div><b>A1</b> Row &amp; carry</div>
        <div><br></div>
        <div><h3>Week 2</h3></div>
        <div>Progression</div>
        <div><h2>Parking Lot</h2></div>
        <div>Try a press</div>
        """
        let (document, rich) = try ProgramDocumentReader.read(NoteSnapshot(id: NoteID("fixture"), text: "", html: html))
        #expect(document.candidates().count == 1)
        #expect(document.paragraphs[1].headingLevel == 2)
        #expect(document.paragraphs[2].headingLevel == 3)
        #expect(document.snapshot.text.contains("Row & carry\n\nWeek 2"))
        #expect(document.snapshot.text.contains("\t•\tBalance\n"))
        let markdown = try ScratchpadRichTextExporter.markdown(rich)
        #expect(markdown.contains("* Balance"))
    }

    @Test func refusesUnrepresentedFormattingAndExternalResources() {
        for html in ["<div><img src=\"https://example.test/image\"/></div>",
                     "<div style=\"color:red\">Warning</div>", "<div><i>Italic</i></div>",
                     "<ul><li>Outer<ul><li>Inner</li></ul></li></ul>",
                     "<!DOCTYPE x><div>Text</div>", "<div>Unclosed"] {
            #expect(throws: ProgramDocumentReadError.self) {
                try ProgramDocumentReader.read(NoteSnapshot(id: NoteID("fixture"), text: "", html: html))
            }
        }
    }
}
