import AppKit

/// A deliberately small native visual system shared by the programming windows.
/// The warm accent and deep-blue-adjacent neutrals take their cue from the app icon;
/// controls remain standard AppKit controls so keyboard behavior stays familiar.
/// Visual rules and review checklist: docs/design/DESIGN_GUIDE.md.
@MainActor enum GymAssistantAppearance {
    static let accent = NSColor(srgbRed: 1.0, green: 0.34, blue: 0.12, alpha: 1)
    static let promptFill = adaptive(light: 0xFBE5D8, dark: 0x58392E)
    static let promptBorder = adaptive(light: 0xE9B79B, dark: 0x8B5942)
    static let canvas = adaptive(light: 0xEDF0F5, dark: 0x202733)
    static let paper = adaptive(light: 0xFFFCF7, dark: 0x292B30)
    static let paperBorder = adaptive(light: 0xBD7955, dark: 0xC58A68)
    static let inkAccent = adaptive(light: 0x9D4828, dark: 0xF3B08C)
    static let actionFill = adaptive(light: 0xCFAF96, dark: 0x936E57)
    static let actionInk = NSColor.black

    private static func adaptive(light: UInt32, dark: UInt32) -> NSColor {
        NSColor(name: nil) { appearance in
            let rgb = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
            return NSColor(srgbRed: CGFloat((rgb >> 16) & 255) / 255,
                           green: CGFloat((rgb >> 8) & 255) / 255,
                           blue: CGFloat(rgb & 255) / 255, alpha: 1)
        }
    }

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

    static func filledPrimary(_ button: NSButton) {
        primary(button)
        button.bezelColor = actionFill
        // AppKit otherwise chooses white on the light tan fill (only ~2:1).
        button.attributedTitle = NSAttributedString(string: button.title, attributes: [
            .foregroundColor: actionInk, .font: button.font ?? NSFont.systemFont(ofSize: 13, weight: .semibold)
        ])
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

/// Resolves the surface and border again when the window changes appearance.
@MainActor final class WorkspaceSurfaceScrollView: NSScrollView {
    var surfaceColor: NSColor = GymAssistantAppearance.paper { didSet { updateSurface() } }
    var outlineColor: NSColor = GymAssistantAppearance.paperBorder { didSet { updateSurface() } }
    var outlineWidth: CGFloat = 1.5 { didSet { updateSurface() } }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = 12
        layer?.masksToBounds = true
        updateSurface()
    }
    required init?(coder: NSCoder) { nil }
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateSurface()
    }
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let outline = NSBezierPath(roundedRect: bounds.insetBy(dx: outlineWidth / 2, dy: outlineWidth / 2),
                                   xRadius: 12, yRadius: 12)
        outlineColor.setStroke()
        outline.lineWidth = outlineWidth
        outline.stroke()
    }
    private func updateSurface() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            backgroundColor = surfaceColor
            layer?.backgroundColor = surfaceColor.cgColor
            layer?.borderColor = outlineColor.cgColor
            layer?.borderWidth = outlineWidth
        }
        needsDisplay = true
    }
}

@MainActor final class WorkspaceBackgroundView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        NSColor.windowBackgroundColor.setFill()
        dirtyRect.fill()
    }
}
