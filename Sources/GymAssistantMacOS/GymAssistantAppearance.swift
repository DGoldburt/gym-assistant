import AppKit

/// A deliberately small native visual system shared by the programming windows.
/// The warm accent and deep-blue-adjacent neutrals take their cue from the app icon;
/// controls remain standard AppKit controls so keyboard behavior stays familiar.
@MainActor enum GymAssistantAppearance {
    static let accent = NSColor(srgbRed: 1.0, green: 0.34, blue: 0.12, alpha: 1)

    static func configure(_ window: NSWindow) {
        window.backgroundColor = .windowBackgroundColor
        window.titlebarAppearsTransparent = false
        window.toolbarStyle = .unified
    }

    static func headline(_ field: NSTextField) {
        field.font = .systemFont(ofSize: 22, weight: .semibold)
        field.textColor = .labelColor
    }

    static func sectionLabel(_ field: NSTextField) {
        field.font = .systemFont(ofSize: 12, weight: .semibold)
        field.textColor = .secondaryLabelColor
    }

    static func supportingText(_ field: NSTextField) {
        field.font = .systemFont(ofSize: 13)
        field.textColor = .secondaryLabelColor
    }

    static func primary(_ button: NSButton) {
        button.bezelStyle = .rounded
        button.controlSize = .large
        button.contentTintColor = accent
        button.font = .systemFont(ofSize: 13, weight: .semibold)
    }

    static func secondary(_ button: NSButton) {
        button.bezelStyle = .rounded
        button.controlSize = .regular
        button.font = .systemFont(ofSize: 13, weight: .medium)
    }

    static func quiet(_ button: NSButton) {
        button.bezelStyle = .inline
        button.contentTintColor = accent
        button.font = .systemFont(ofSize: 13, weight: .medium)
    }

    static func panel(frame: NSRect) -> NSVisualEffectView {
        let view = NSVisualEffectView(frame: frame)
        view.material = .sidebar
        view.blendingMode = .withinWindow
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = 10
        view.layer?.masksToBounds = true
        return view
    }
}
