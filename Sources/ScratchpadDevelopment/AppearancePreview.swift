import AppKit
import GymAssistantWorkspace
import GymAssistantMacOS

/// Deterministic native-view renders: fresh synthetic data, no Notes or model calls.
@MainActor final class AppearancePreview {
    let controller: SessionScratchpadWindowController
    private let root: URL

    init() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("gym-assistant-appearance-" + UUID().uuidString)
        let body = "Session 18\nWarmup\nBalance preparation\n\nStrength\nA1 Single-leg RDL\nB1 Press\nB2 Dowel squat — light\n\nKeep the focus on control and coordination.\n"
        let note = NoteSnapshot(id: NoteID("synthetic-appearance-preview"), text: "Coordination & strength program\n\n" + body)
        let rich = NSMutableAttributedString(string: body, attributes: [.font: NSFont.systemFont(ofSize: 16)])
        for (title, size, level) in [("Session 18", 24.0, 2), ("Warmup", 18.0, 3), ("Strength", 18.0, 3)] {
            let style = NSMutableParagraphStyle(); style.headerLevel = level
            rich.addAttributes([.font: NSFont.systemFont(ofSize: size, weight: .semibold), .paragraphStyle: style],
                               range: (body as NSString).range(of: title))
        }
        var snapshot = WorkspaceSnapshot(anchor: .init(noteID: note.id, recordedHeading: "Session 18", baselineText: body),
            text: body, richTextArchive: try RichTextArchive.encode(rich), composerText: "Keep B2 unloaded and leave the rest as written.")
        let examples: [(MessageRole, String)] = [
            (.coach, "For this synthetic layout example, keep the session light. Can B2 focus on coordination?"),
            (.assistant, "Synthetic preview response\n\nB2 is shown as a light dowel squat. This sample demonstrates the conversation layout; it is not exercise advice.\n\nThe scratchpad on the left stays available while you write your next question."),
            (.coach, "Keep the rest of the session as written. I only want to refine B2."),
            (.assistant, "Understood for this preview. The other items remain as written in the synthetic scratchpad.\n\nA1  Single-leg RDL\nB1  Press\nB2  Dowel squat — light\n\nYou can continue refining the note alongside this conversation."),
            (.coach, "What changed in this draft?"),
            (.assistant, "This is a saved example message for checking scrolling. Your questions sit on the right; responses start on the left. The down arrow returns to the latest message when you are reading earlier content.")]
        for (role, text) in examples {
            snapshot.messages.append(.init(requestID: UUID(), conversationID: snapshot.conversationID, role: role,
                text: text, status: .complete, scratchpadRevision: 0, observationID: note.observationID))
        }
        let range = (note.text as NSString).range(of: body)
        controller = try SessionScratchpadWindowController(snapshot: snapshot, store: .init(directory: root), note: note,
            association: .init(sessionID: snapshot.anchor.sessionID, noteID: note.id, observationID: note.observationID,
                               range: .init(location: range.location, length: range.length)),
            profile: .init(version: "appearance-preview", entries: []))
    }

    func export(to directory: URL) async throws {
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        controller.show()
        guard let window = controller.window, let view = window.contentView else { throw CocoaError(.fileWriteUnknown) }
        func descendants(_ view: NSView) -> [NSView] { [view] + view.subviews.flatMap(descendants) }
        let chat = descendants(view).first { $0.identifier?.rawValue == "conversation-scroll" } as? NSScrollView
        for (name, appearance) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
            window.appearance = NSAppearance(named: appearance)
            window.makeFirstResponder(nil)
            view.layoutSubtreeIfNeeded()
            // Let AppKit apply appearance changes and calculate text heights.
            try await Task.sleep(for: .milliseconds(200))
            chat?.contentView.scroll(to: .zero)
            if let chat { chat.reflectScrolledClipView(chat.contentView) }
            guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { throw CocoaError(.fileWriteUnknown) }
            window.effectiveAppearance.performAsCurrentDrawingAppearance {
                for child in descendants(view) { child.needsDisplay = true }
                view.display()
                view.cacheDisplay(in: view.bounds, to: bitmap)
            }
            guard let data = bitmap.representation(using: .png, properties: [:]) else { throw CocoaError(.fileWriteUnknown) }
            let url = directory.appendingPathComponent("scratchpad-conversation-\(name).png")
            try data.write(to: url, options: .atomic)
            print(url.path)
        }
        _ = controller.flushAndStop()
        window.close()
    }
}
