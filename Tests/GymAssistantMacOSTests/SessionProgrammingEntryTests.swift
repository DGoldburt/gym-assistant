import AppKit
import Testing
import GymAssistantWorkspace
@testable import GymAssistantMacOS

private actor PermissionEntryReader: NotesContextReading {
    var permitted = false
    var captures = 0
    var reads = 0
    func grant() { permitted = true }
    func captureSelectedNote() async throws -> NoteSnapshot {
        captures += 1
        guard permitted else { throw NotesReadError.permission }
        return NoteSnapshot(id: NoteID("fixture"), text: "Fixture")
    }
    func read(id: NoteID) async throws -> NoteSnapshot {
        reads += 1
        return NoteSnapshot(id: id, text: "Session 1\nA1 Row\n", html: "<div><h2>Session 1</h2></div><div>A1 Row</div>")
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
