import AppKit
import Foundation
import Testing
import GymAssistantWorkspace
@testable import GymAssistantMacOS

@MainActor private func richFixture(_ text: String) -> NSAttributedString {
    let rich = NSMutableAttributedString(string: text, attributes: [.font: NSFont.systemFont(ofSize: 15)])
    if !text.isEmpty {
        let paragraph = NSMutableParagraphStyle(); paragraph.headerLevel = 2
        rich.addAttribute(.paragraphStyle, value: paragraph, range: (text as NSString).paragraphRange(for: NSRange(location: 0, length: 0)))
    }
    return rich
}
@MainActor private func snapshotFixture() throws -> WorkspaceSnapshot {
    let text = "Session 1\nCoach choice\n"
    return WorkspaceSnapshot(anchor: SessionAnchor(noteID: NoteID("synthetic"), recordedHeading: "Session 1", baselineText: text),
        revision: 1, text: text, richTextArchive: try RichTextArchive.encode(richFixture(text)))
}
private enum Injected: Error { case failure }

@Suite("Formatted scratchpad persistence", .serialized) @MainActor struct WorkspaceSnapshotStoreTests {
    private func temporary() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("scratchpad-test-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }
    @Test func savesAndReopensExactFormattingAndIdentity() throws {
        let root = try temporary(); defer { try? FileManager.default.removeItem(at: root) }
        var snapshot = try snapshotFixture()
        snapshot.composerText = "Keep it unloaded — not sent"
        try WorkspaceSnapshotStore(directory: root).save(snapshot)
        let loaded = try #require(try WorkspaceSnapshotStore(directory: root).load(id: snapshot.workspaceID))
        #expect(loaded.snapshot == snapshot)
        #expect(!loaded.recoveredFromPrevious)
        let restored = try RichTextArchive.decode(loaded.snapshot.richTextArchive)
        #expect(restored.string == snapshot.text)
        #expect((restored.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)?.headerLevel == 2)
    }
    @Test(arguments: [SnapshotSavePhase.staged, .validated, .backedUp, .promoted, .reopened])
    func interruptedSavePreservesAcknowledgedRevision(phase: SnapshotSavePhase) throws {
        let root = try temporary(); defer { try? FileManager.default.removeItem(at: root) }
        let original = try snapshotFixture()
        let store = WorkspaceSnapshotStore(directory: root)
        try store.save(original)
        var changed = original; changed.revision += 1; changed.text += "B2 Dowel squat\n"
        changed.richTextArchive = try RichTextArchive.encode(richFixture(changed.text))
        let interrupted = WorkspaceSnapshotStore(directory: root, fault: { if $0 == phase { throw Injected.failure } })
        #expect(throws: Injected.failure) { try interrupted.save(changed) }
        // Original remains in current or previous, even if the unacknowledged candidate was promoted.
        let current = try JSONDecoder().decode(WorkspaceSnapshot.self, from: Data(contentsOf: store.currentURL(for: original.workspaceID)))
        if current != original {
            let previous = try JSONDecoder().decode(WorkspaceSnapshot.self, from: Data(contentsOf: store.previousURL(for: original.workspaceID)))
            #expect(previous == original)
        }
        #expect(try store.load(id: original.workspaceID) != nil)
    }
    @Test func corruptCurrentRecoversPreviousWithoutOverwriting() throws {
        let root = try temporary(); defer { try? FileManager.default.removeItem(at: root) }
        let original = try snapshotFixture(); let store = WorkspaceSnapshotStore(directory: root)
        try store.save(original)
        var changed = original; changed.revision += 1; try store.save(changed)
        let broken = Data("broken".utf8)
        try broken.write(to: store.currentURL(for: original.workspaceID))
        let loaded = try #require(try store.load(id: original.workspaceID))
        #expect(loaded.snapshot == original && loaded.recoveredFromPrevious)
        #expect(try Data(contentsOf: store.currentURL(for: original.workspaceID)) == broken)
        #expect(throws: (any Error).self) { try store.save(changed) }
        #expect(try Data(contentsOf: store.currentURL(for: original.workspaceID)) == broken)
    }
    @Test func unsupportedSchemaIsPreservedRatherThanDowngraded() throws {
        let root = try temporary(); defer { try? FileManager.default.removeItem(at: root) }
        var snapshot = try snapshotFixture(); let store = WorkspaceSnapshotStore(directory: root)
        try store.save(snapshot)
        snapshot.schemaVersion = 99
        let bytes = try JSONEncoder().encode(snapshot)
        try bytes.write(to: store.currentURL(for: snapshot.workspaceID))
        #expect(throws: WorkspaceError.unsupportedSchema(99)) { try store.load(id: snapshot.workspaceID) }
        #expect(try Data(contentsOf: store.currentURL(for: snapshot.workspaceID)) == bytes)
    }
    @Test func semanticallyWrongArchiveAndOlderRevisionCannotOverwrite() throws {
        let root = try temporary(); defer { try? FileManager.default.removeItem(at: root) }
        let original = try snapshotFixture(); let store = WorkspaceSnapshotStore(directory: root)
        try store.save(original)
        var invalid = original; invalid.text = "Different from archive"
        #expect(throws: WorkspaceError.invalidArchive) { try store.save(invalid) }
        invalid = original; invalid.revision = 0
        #expect(throws: SnapshotStoreError.staleRevision) { try store.save(invalid) }
        #expect(try store.load(id: original.workspaceID)?.snapshot == original)
    }
    @Test func corruptBackupCannotReplaceValidCurrent() throws {
        let root = try temporary(); defer { try? FileManager.default.removeItem(at: root) }
        let original = try snapshotFixture(); let store = WorkspaceSnapshotStore(directory: root)
        try store.save(original)
        try Data("broken backup".utf8).write(to: store.previousURL(for: original.workspaceID))
        #expect(try store.load(id: original.workspaceID)?.snapshot == original)
        #expect(throws: SnapshotStoreError.unsafeExistingFile) { try store.save(original) }
    }
    @Test func directoryFailureIsNotASuccessfulSave() throws {
        let root = try temporary(); defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("not-a-directory")
        try Data([1]).write(to: file)
        #expect(throws: (any Error).self) { try WorkspaceSnapshotStore(directory: file).save(snapshotFixture()) }
    }
}

@Suite("Scratchpad Markdown handoff", .serialized) @MainActor struct ScratchpadMarkdownTests {
    @Test func nativeHeadingsAndBoldParagraphSerialize() throws {
        let rich = NSMutableAttributedString(attributedString: richFixture("Session 1\nB2 Dowel squat\n"))
        rich.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 15), range: (rich.string as NSString).range(of: "B2"))
        let output = try ScratchpadRichTextExporter.markdown(rich)
        #expect(output == "## Session 1\n\n**B2** Dowel squat\n")
    }
    @Test func discListIsContiguousAndLiteralMarkersEscaped() throws {
        let value = "\t•\tA1 RDL\n\t•\tBalance preparation\n# literal [cue] *stars*\n"
        let rich = NSMutableAttributedString(string: value, attributes: [.font: NSFont.systemFont(ofSize: 15)])
        let list = NSMutableParagraphStyle(); list.textLists = [NSTextList(markerFormat: .disc, options: 0)]
        rich.addAttribute(.paragraphStyle, value: list, range: (value as NSString).range(of: "\t•\tA1 RDL\n\t•\tBalance preparation\n"))
        let output = try ScratchpadRichTextExporter.markdown(rich)
        #expect(output.contains("* A1 RDL\n* Balance preparation"))
        #expect(output.contains("\\# literal \\[cue\\] \\*stars\\*"))
        #expect(!output.contains("•"))
    }
    @Test func unsupportedHeadingDoesNotClaimFidelity() throws {
        let rich = NSMutableAttributedString(string: "Unsupported\n")
        let style = NSMutableParagraphStyle(); style.headerLevel = 4
        rich.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: rich.length))
        #expect(throws: WorkspaceError.invalidArchive) { try ScratchpadRichTextExporter.markdown(rich) }
    }
    @Test func unsupportedLinkCannotBeSilentlyDropped() throws {
        let rich = NSMutableAttributedString(string: "Source", attributes: [.link: URL(string: "https://example.com")!])
        #expect(throws: WorkspaceError.invalidArchive) { try ScratchpadRichTextExporter.markdown(rich) }
    }
    @Test func literalNumberDoesNotBecomeAnOrderedList() throws {
        #expect(try ScratchpadRichTextExporter.markdown(NSAttributedString(string: "1. Literal count\n")) == "1\\. Literal count\n")
    }
    @Test func unsupportedEmphasisCannotBeSilentlyDropped() throws {
        let rich = NSAttributedString(string: "Underline", attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
        #expect(throws: WorkspaceError.invalidArchive) { try ScratchpadRichTextExporter.markdown(rich) }
    }
}
