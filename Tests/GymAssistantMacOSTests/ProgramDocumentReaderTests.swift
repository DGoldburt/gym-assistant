import AppKit
import Testing
import GymAssistantWorkspace
@testable import GymAssistantMacOS

@Suite("Notes semantic document import") @MainActor struct ProgramDocumentReaderTests {
    @Test func reimportsObservedMarkdownHeadingArtifactsWithoutExtraParagraphs() throws {
        let html = """
        <div><b><h2>Session 18</h2></b><font face=".AppleSystemUIFont"><span style="font-size: 13px"><h2><br></h2></span></font></div>
        <div><b><h3>Warmup</h3></b><font face=".AppleSystemUIFont"><h3><br></h3></font></div>
        <div>Preparation A</div>
        <div>Preparation B</div>
        <ul><li>Bullet one</li><li><b>Bullet two</b><br></li></ul>
        <div><br></div>
        <div>A1 Row</div><div>B1 Press<br></div>
        """
        let (document, _) = try ProgramDocumentReader.read(NoteSnapshot(id: NoteID("fixture"), text: "", html: html))
        #expect(document.paragraphs.count == 9)
        #expect(document.paragraphs.map(\.headingLevel) == [2, 3, 0, 0, 0, 0, 0, 0, 0])
        #expect(document.snapshot.text == "Session 18\nWarmup\nPreparation A\nPreparation B\n\t•\tBullet one\n\t•\tBullet two\n\nA1 Row\nB1 Press\n")
        for changed in [html.replacingOccurrences(of: "<h2><br>", with: "<h2>Do not discard<br>"),
                        html.replacingOccurrences(of: "font-size: 13px", with: "color: red"),
                        "<div><font face=\".AppleSystemUIFont\"><h3><br></h3></font></div>"] {
            #expect(throws: ProgramDocumentReadError.self) {
                try ProgramDocumentReader.read(NoteSnapshot(id: NoteID("fixture"), text: "", html: changed))
            }
        }
    }
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
