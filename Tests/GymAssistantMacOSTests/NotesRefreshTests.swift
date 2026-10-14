import Foundation
import Testing
import GymAssistantWorkspace
@testable import GymAssistantMacOS

private actor ControlledNotesReader: NotesContextReading {
    var value = NoteSnapshot(id: NoteID("fixture"), text: "Session A\nWeek 1\n", modifiedAt: Date(timeIntervalSince1970: 10))
    var bodies = 0
    var metadataCalls = 0
    var error: NotesReadError?
    var hold = false
    var releaseRead: CheckedContinuation<Void, Never>?
    var started: [CheckedContinuation<Void, Never>] = []
    func captureSelectedNote() async throws -> NoteSnapshot { throw NotesReadError.ambiguousSelection }
    func metadata(id: NoteID) throws -> NoteMetadata {
        metadataCalls += 1
        if let error { throw error }
        return NoteMetadata(id: value.id, modifiedAt: value.modifiedAt)
    }
    func read(id: NoteID) async throws -> NoteSnapshot {
        bodies += 1
        let captured = value
        if hold {
            await withCheckedContinuation { continuation in
                releaseRead = continuation
                for waiter in started { waiter.resume() }
                started.removeAll()
            }
        }
        if let error { throw error }
        return captured
    }
    func change(text: String, html: String = "", id: String = "fixture") {
        value = NoteSnapshot(id: NoteID(id), text: text, html: html, modifiedAt: value.modifiedAt)
    }
    func fail(_ failure: NotesReadError?) { error = failure }
    func advanceDate() {
        value = NoteSnapshot(id: value.id, text: value.text, html: value.html,
                             modifiedAt: value.modifiedAt.addingTimeInterval(1))
    }
    func pause() { hold = true }
    func waitForRead() async {
        if releaseRead != nil { return }
        await withCheckedContinuation { started.append($0) }
    }
    func release() { hold = false; releaseRead?.resume(); releaseRead = nil }
}

@Suite("Notes reading and freshness") struct NotesRefreshTests {
    @Test func changedMetadataCoalescesAndHiddenCancelsDeferredRead() async throws {
        let reader = ControlledNotesReader()
        let monitor = NotesRefreshCoordinator(noteID: NoteID("fixture"), reader: reader)
        await monitor.setVisible(true)
        _ = try await monitor.validate(for: .resume)
        await reader.advanceDate()
        for _ in 0..<5 { await monitor.idleTick(); await monitor.waitUntilIdle() }
        #expect(await reader.bodies == 1)
        await monitor.waitForScheduledRefresh()
        #expect(await reader.bodies == 2)
        await reader.advanceDate()
        await monitor.idleTick()
        await monitor.waitUntilIdle()
        await monitor.setVisible(false)
        await monitor.waitForScheduledRefresh()
        #expect(await reader.bodies == 2)
    }

    @Test func unchangedIdleReadsOnlyMetadataAndHiddenReadsNothing() async throws {
        let reader = ControlledNotesReader()
        let monitor = NotesRefreshCoordinator(noteID: NoteID("fixture"), reader: reader)
        await monitor.setVisible(true)
        _ = try await monitor.validate(for: .resume)
        let initial = await monitor.observation()
        for _ in 0..<20 { await monitor.idleTick(); await monitor.waitUntilIdle() }
        #expect(await reader.bodies == 1)
        #expect(await reader.metadataCalls == 20)
        #expect(await monitor.observation().contentID == initial.contentID)
        await monitor.setVisible(false)
        await monitor.idleTick()
        await monitor.waitUntilIdle()
        #expect(await reader.metadataCalls == 20)
    }

    @Test func safetyReadsFindSameDateEditsAndReuseUnchangedContent() async throws {
        let reader = ControlledNotesReader()
        let monitor = NotesRefreshCoordinator(noteID: NoteID("fixture"), reader: reader)
        _ = try await monitor.validate(for: .resume)
        let before = await monitor.observation()
        await reader.change(text: "Session A\nChanged\n")
        let changed = try await monitor.validate(for: .checkedCopy)
        #expect(changed.text == "Session A\nChanged\n")
        #expect(changed.modifiedAt == before.snapshot?.modifiedAt)
        let after = await monitor.observation()
        #expect(after.contentID != before.contentID)
        _ = try await monitor.validate(for: .chat)
        #expect(await monitor.observation().contentID == after.contentID)
        await reader.change(text: changed.text, html: "<b>Changed formatting</b>")
        _ = try await monitor.validate(for: .comparison)
        #expect(await monitor.observation().contentID != after.contentID)
        #expect(await reader.bodies == 4)
    }

    @Test func laterConsumerCannotUseAlreadyCapturedBody() async throws {
        let reader = ControlledNotesReader()
        let monitor = NotesRefreshCoordinator(noteID: NoteID("fixture"), reader: reader)
        await reader.pause()
        let first = Task { try await monitor.validate(for: .chat) }
        await reader.waitForRead()
        await reader.change(text: "Later edit")
        let second = Task { try await monitor.validate(for: .checkedCopy) }
        await reader.release()
        #expect(try await first.value.text == "Session A\nWeek 1\n")
        #expect(try await second.value.text == "Later edit")
        #expect(await reader.bodies == 2)
    }

    @Test func failuresPreserveCacheAndExplicitRequestRetries() async throws {
        let reader = ControlledNotesReader()
        let monitor = NotesRefreshCoordinator(noteID: NoteID("fixture"), reader: reader)
        await monitor.setVisible(true)
        let initial = try await monitor.validate(for: .resume)
        await reader.fail(.permission)
        await #expect(throws: NotesReadError.permission) { try await monitor.validate(for: .chat) }
        #expect(await monitor.observation().snapshot == initial)
        #expect(await monitor.observation().failure == .permission)
        await monitor.idleTick()
        await monitor.waitUntilIdle()
        #expect(await reader.metadataCalls == 0)
        await reader.fail(nil)
        _ = try await monitor.validate(for: .checkedCopy)
        #expect(await monitor.observation().failure == nil)
    }

    @Test func suspendedReadCannotPromoteStaleResult() async throws {
        let reader = ControlledNotesReader()
        let monitor = NotesRefreshCoordinator(noteID: NoteID("fixture"), reader: reader)
        await monitor.setVisible(true)
        await reader.pause()
        let task = Task { try await monitor.validate(for: .resume) }
        await reader.waitForRead()
        await monitor.setVisible(false)
        await reader.release()
        await #expect(throws: NotesReadError.unavailable) { try await task.value }
        #expect(await monitor.observation().snapshot == nil)
    }

    @Test func ticksQueuedDuringFailureRespectBackoff() async throws {
        let reader = ControlledNotesReader()
        let monitor = NotesRefreshCoordinator(noteID: NoteID("fixture"), reader: reader)
        await monitor.setVisible(true)
        await reader.pause()
        let task = Task { try await monitor.validate(for: .resume) }
        await reader.waitForRead()
        await monitor.idleTick()
        await reader.fail(.unavailable)
        await reader.release()
        await #expect(throws: NotesReadError.unavailable) { try await task.value }
        await monitor.waitUntilIdle()
        #expect(await reader.metadataCalls == 0)
        #expect(await reader.bodies == 1)
    }

    @Test func wrongIdentityCannotReplaceCapturedNote() async throws {
        let reader = ControlledNotesReader()
        let monitor = NotesRefreshCoordinator(noteID: NoteID("fixture"), reader: reader)
        let initial = try await monitor.validate(for: .resume)
        await reader.change(text: "Other note", id: "other")
        await #expect(throws: NotesReadError.unavailable) { try await monitor.validate(for: .comparison) }
        #expect(await monitor.observation().snapshot == initial)
    }

    @Test func scriptsKeepMetadataSmallAndIdentityQuoted() {
        let source = NotesContextReader.script(target: NotesContextReader.target(NoteID("opaque\"\\\nidentity")), metadataOnly: true)
        #expect(!source.contains("body of"))
        #expect(!source.contains("plaintext of"))
        #expect(!source.contains("selection"))
        #expect(source.contains("with timeout of 2 seconds"))
        #expect(NotesContextReader.literal("a\"\\\n\rb") == "\"a\\\"\\\\\\n\\rb\"")
    }
}
