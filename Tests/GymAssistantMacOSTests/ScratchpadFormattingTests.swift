import AppKit
import Testing
@testable import GymAssistantMacOS

@Suite("Scratchpad semantic formatting") @MainActor struct ScratchpadFormattingTests {
    @Test func returnContinuesVisibleBulletAndEmptyItemRequestsBody() {
        let editor = ScratchpadTextView()
        let rich = ScratchpadFormatting.apply(.bulletedList, to: NSAttributedString(string: "Balance\n"), selection: NSRange(location: 0, length: 0))
        editor.textStorage?.setAttributedString(rich)
        editor.setSelectedRange(NSRange(location: rich.length - 1, length: 0))
        editor.typingAttributes = rich.attributes(at: 0, effectiveRange: nil)
        editor.insertNewline(nil)
        #expect(editor.string == "\t•\tBalance\n\t•\t\n")
        var requestedBody = false
        editor.returnToBody = { requestedBody = true }
        editor.insertNewline(nil)
        #expect(requestedBody)
        #expect(editor.string == "\t•\tBalance\n\t•\t\n")
    }
    @Test func paragraphCommandsDoNotChangeOtherParagraphsAndBodyRemovesListMarkers() throws {
        let original = NSAttributedString(string: "Session 1\nWarmup\nBalance\nA1 Row\n")
        let heading = ScratchpadFormatting.apply(.heading, to: original, selection: NSRange(location: 2, length: 0))
        #expect((heading.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)?.headerLevel == 2)
        #expect(heading.attributedSubstring(from: NSRange(location: 10, length: original.length - 10)).isEqual(to: original.attributedSubstring(from: NSRange(location: 10, length: original.length - 10))))
        let warmup = (original.string as NSString).range(of: "Warmup")
        let subheading = ScratchpadFormatting.apply(.subheading, to: heading, selection: warmup)
        #expect((subheading.attribute(.paragraphStyle, at: warmup.location, effectiveRange: nil) as? NSParagraphStyle)?.headerLevel == 3)
        let balance = (original.string as NSString).range(of: "Balance")
        let list = ScratchpadFormatting.apply(.bulletedList, to: subheading, selection: balance)
        #expect(list.string.contains("\t•\tBalance\n"))
        #expect((list.attribute(.paragraphStyle, at: balance.location, effectiveRange: nil) as? NSParagraphStyle)?.textLists.count == 1)
        let body = ScratchpadFormatting.apply(.body, to: list, selection: NSRange(location: balance.location, length: 0))
        #expect(body.string == original.string)
        #expect((body.attribute(.paragraphStyle, at: balance.location, effectiveRange: nil) as? NSParagraphStyle)?.textLists.isEmpty == true)
        let plainHeading = ScratchpadFormatting.apply(.body, to: body, selection: NSRange(location: 0, length: 0))
        #expect((plainHeading.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)?.headerLevel == 0)
    }
    @Test func boldChangesOnlySelectionAndTogglesOff() {
        let rich = NSAttributedString(string: "A1 Row\n", attributes: [.font: NSFont.systemFont(ofSize: 16)])
        let selected = NSRange(location: 0, length: 2)
        let bold = ScratchpadFormatting.apply(.bold, to: rich, selection: selected)
        #expect(NSFontManager.shared.traits(of: bold.attribute(.font, at: 0, effectiveRange: nil) as! NSFont).contains(.boldFontMask))
        #expect(!NSFontManager.shared.traits(of: bold.attribute(.font, at: 3, effectiveRange: nil) as! NSFont).contains(.boldFontMask))
        #expect(ScratchpadFormatting.apply(.bold, to: bold, selection: selected).isEqual(to: rich))
    }
}
