import AppKit
import GymAssistantWorkspace

@MainActor public final class ProgrammingPreferencesWindow: NSWindowController {
    public init(profile: CoachingProfile) {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 700, height: 600),
                              styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        super.init(window: window)
        window.title = "Programming preferences"
        window.isReleasedWhenClosed = false
        let scroll = NSScrollView(frame: window.contentView!.bounds)
        scroll.autoresizingMask = [.width, .height]; scroll.hasVerticalScroller = true
        let text = NSTextView(frame: scroll.bounds)
        text.isEditable = false; text.isSelectable = true
        text.isVerticallyResizable = true; text.isHorizontallyResizable = false
        text.textContainer?.widthTracksTextView = true; text.autoresizingMask = [.width]
        text.textContainerInset = NSSize(width: 20, height: 18)
        text.font = .systemFont(ofSize: 15)
        text.setAccessibilityLabel("Read-only programming preferences and sources")
        text.string = Self.inspectionText(profile)
        scroll.documentView = text; window.contentView?.addSubview(scroll)
    }
    public required init?(coder: NSCoder) { nil }
    public static func inspectionText(_ profile: CoachingProfile) -> String {
        let introduction = "Read-only profile · \(profile.version)\n\nThese are coaching sources and tendencies, not blanket rules or scientific validation. Current explicit constraints take precedence; conflicting sources should be surfaced. Chat does not change this profile.\n\n"
        guard !profile.entries.isEmpty else { return introduction + "No coaching preferences are loaded in this workspace." }
        return introduction + profile.entries.map { entry in
            let kind: String
            switch entry.kind {
            case .authored: kind = "Authored philosophy"
            case .confirmedTendency: kind = "Coaching tendency"
            case .inferred: kind = "Inference"
            case .constraint: kind = "Contextual constraint"
            case .scientificClaim: kind = "Scientific claim — retain its evidence status"
            }
            return "\(kind) · \(entry.confirmed ? "coach-confirmed" : "not coach-confirmed")\n\(entry.wording)\nSource: \(entry.source)\nScope: \(entry.scope ?? "Not stated in the source")"
                + (entry.exceptions.isEmpty ? "" : "\nExceptions or uncertainty: " + entry.exceptions.joined(separator: "; "))
        }.joined(separator: "\n\n────────\n\n")
    }
    public func show() { showWindow(nil); window?.makeKeyAndOrderFront(nil) }
}
