import AppKit
import Testing
import GymAssistantWorkspace
@testable import GymAssistantMacOS

private actor PermissionEntryReader: NotesContextReading {
    var permitted = false
    var captures = 0
    var reads = 0
    var html = "<div><h2>Session 1</h2></div><div>A1 Row</div>"
    func replace(_ value: String) { html = value }
    func grant() { permitted = true }
    func captureSelectedNote() async throws -> NoteSnapshot {
        captures += 1
        guard permitted else { throw NotesReadError.permission }
        return NoteSnapshot(id: NoteID("fixture"), text: "Fixture")
    }
    func read(id: NoteID) async throws -> NoteSnapshot {
        reads += 1
        return NoteSnapshot(id: id, text: "", html: html)
    }
    func metadata(id: NoteID) async throws -> NoteMetadata { NoteMetadata(id: id, modifiedAt: .distantPast) }
}

@Suite("Programming entry onboarding") @MainActor struct SessionProgrammingEntryTests {
    private func descendants(_ view: NSView) -> [NSView] { [view] + view.subviews.flatMap(descendants) }
    private func eventually(_ test: () -> Bool) async throws {
        for _ in 0..<100 {
            if test() { return }
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(test())
    }
    @Test func newSessionPreviewCancelCreateAndResumeReuseOneWorkspace() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("entry-skeleton-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = WorkspaceSnapshotStore(directory: root), reader = PermissionEntryReader()
        await reader.grant()
        let workspaces = SessionWorkspaceWindows(store: store, reader: reader,
            profile: .init(version: "test", entries: []), assistant: FakeProgrammingAssistant())
        var presented: [SessionScratchpadWindowController] = []
        let entry = SessionProgrammingEntryWindow(workspaces: workspaces, modeDescription: "Test",
            presentWorkspace: { presented.append($0) }, requestAccess: {})
        func view(_ id: String) -> NSView? { entry.window?.contentView.flatMap { descendants($0).first { $0.identifier?.rawValue == id } } }
        func button(_ id: String) throws -> NSButton { try #require(view(id) as? NSButton) }
        try button("program-entry-capture").performClick(nil)
        try await eventually { (view("program-entry-new") as? NSButton)?.isEnabled == true }
        #expect(try button("program-entry-new").keyEquivalent == "n")
        try button("program-entry-new").performClick(nil)
        try await eventually { view("session-skeleton-preview") != nil }
        let preview = try #require(view("session-skeleton-preview") as? NSTextView)
        #expect(preview.string == "Session 2\n" && !preview.isEditable)
        #expect(try store.storedAnchors().isEmpty)
        try button("session-skeleton-cancel").performClick(nil)
        #expect(view("program-entry-new") != nil && presented.isEmpty)
        #expect(try store.storedAnchors().isEmpty)
        try button("program-entry-new").performClick(nil)
        try await eventually { view("session-skeleton-create") != nil }
        try button("session-skeleton-create").performClick(nil)
        try await eventually { presented.count == 1 }
        #expect(presented[0].snapshot.anchor.isUnrecorded)
        #expect(presented[0].snapshot.text == "Session 2\n")
        try button("program-entry-new").performClick(nil)
        try await eventually { presented.count == 2 }
        #expect(presented[0] === presented[1])
        #expect(try store.storedAnchors().count == 1)
        #expect(workspaces.flushAndStop())
        presented[0].window?.close(); entry.cancel()
    }

    @Test func placeholderAndOmissionsAreVisibleAndChangedNotesRejectPreview() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("entry-stale-skeleton-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = WorkspaceSnapshotStore(directory: root), reader = PermissionEntryReader()
        await reader.grant()
        await reader.replace("<div><h2>Session Z</h2></div><div><h3>A1 Row</h3></div><div>3x5</div>")
        let workspaces = SessionWorkspaceWindows(store: store, reader: reader,
            profile: .init(version: "test", entries: []), assistant: FakeProgrammingAssistant())
        var presentations = 0
        let entry = SessionProgrammingEntryWindow(workspaces: workspaces, modeDescription: "Test",
            presentWorkspace: { _ in presentations += 1 }, requestAccess: {})
        func view(_ id: String) -> NSView? { entry.window?.contentView.flatMap { descendants($0).first { $0.identifier?.rawValue == id } } }
        func button(_ id: String) throws -> NSButton { try #require(view(id) as? NSButton) }
        try button("program-entry-capture").performClick(nil)
        try await eventually { (view("program-entry-new") as? NSButton)?.isEnabled == true }
        try button("program-entry-new").performClick(nil)
        try await eventually { view("session-skeleton-preview") != nil }
        let preview = try #require(view("session-skeleton-preview") as? NSTextView)
        #expect(preview.string.hasPrefix("Session [number or letter]\n"))
        #expect(preview.string.contains("Not copied") && preview.string.contains("A1 Row"))
        #expect(!preview.string.contains("3x5"))
        await reader.replace("<div><h2>Session Z</h2></div><div>Changed externally</div>")
        try button("session-skeleton-create").performClick(nil)
        try await eventually { (view("session-skeleton-status") as? NSTextField)?.stringValue.contains("Notes changed") == true }
        #expect(try store.storedAnchors().isEmpty && presentations == 0)
        #expect(try !button("session-skeleton-create").isEnabled)
        entry.cancel()
    }
    @Test func permissionRequiresExplicitRetryAndCaptureDoesNotCreateWorkspace() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("entry-onboarding-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = WorkspaceSnapshotStore(directory: root), reader = PermissionEntryReader()
        let workspaces = SessionWorkspaceWindows(store: store, reader: reader,
            profile: CoachingProfile(version: "test", entries: []), assistant: FakeProgrammingAssistant())
        var grants = 0
        let entry = SessionProgrammingEntryWindow(workspaces: workspaces, modeDescription: "Local test assistant", requestAccess: {
            grants += 1; await reader.grant()
        })
        let views = descendants(try #require(entry.window?.contentView))
        func button(_ id: String) throws -> NSButton { try #require(views.first { $0.identifier?.rawValue == id } as? NSButton) }
        let retry = try button("program-entry-capture"), access = try button("program-entry-access"), latest = try button("program-entry-latest")
        #expect(grants == 0)
        #expect(await reader.captures == 0)
        retry.performClick(nil)
        try await eventually { !access.isHidden && retry.isEnabled }
        #expect(grants == 0)
        #expect(!latest.isEnabled)
        access.performClick(nil)
        try await eventually { access.isHidden && access.isEnabled }
        #expect(grants == 1)
        #expect(await reader.captures == 1) // Grant did not silently recapture.
        #expect(!latest.isEnabled)
        retry.performClick(nil)
        try await eventually { latest.isEnabled && retry.isEnabled }
        #expect(await reader.captures == 2)
        #expect(await reader.reads == 0) // No session opened merely by capture.
        #expect(try store.storedAnchors().isEmpty)
        #expect(latest.keyEquivalent == "\r")
        entry.cancel()
    }
}
