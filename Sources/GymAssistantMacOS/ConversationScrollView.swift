import AppKit

/// A floating “latest” control follows actual document geometry, including resizing.
@MainActor final class ConversationScrollView: NSScrollView {
    let latestButton = LatestMessageButton(title: "", target: nil, action: nil)
    var hasContentBelow: Bool {
        guard let documentView else { return false }
        return documentView.bounds.maxY - contentView.documentVisibleRect.maxY > 6
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        drawsBackground = false
        hasVerticalScroller = true
        latestButton.target = self
        latestButton.action = #selector(jumpToLatest)
        latestButton.isBordered = false
        latestButton.identifier = .init("conversation-jump-to-latest")
        latestButton.toolTip = "Jump to latest message"
        latestButton.setAccessibilityLabel("Jump to latest message")
        latestButton.isHidden = true
        addSubview(latestButton)
        contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(updateLatestVisibility),
            name: NSView.boundsDidChangeNotification, object: contentView)
    }
    required init?(coder: NSCoder) { nil }
    override var documentView: NSView? {
        didSet {
            if let oldValue {
                NotificationCenter.default.removeObserver(self, name: NSView.frameDidChangeNotification, object: oldValue)
            }
            documentView?.postsFrameChangedNotifications = true
            if let documentView {
                NotificationCenter.default.addObserver(self, selector: #selector(updateLatestVisibility),
                    name: NSView.frameDidChangeNotification, object: documentView)
            }
            updateLatestVisibility()
        }
    }
    override func layout() {
        super.layout()
        latestButton.frame = NSRect(x: bounds.midX - 18, y: isFlipped ? bounds.maxY - 44 : 8, width: 36, height: 36)
        updateLatestVisibility()
    }
    @objc func updateLatestVisibility() { latestButton.isHidden = !hasContentBelow }
    @objc func jumpToLatest() {
        guard let text = documentView as? NSTextView else { return }
        text.scrollRangeToVisible(NSRange(location: (text.string as NSString).length, length: 0))
        updateLatestVisibility()
    }
}

/// Explicit drawing keeps the arrow legible on either appearance and surface.
@MainActor final class LatestMessageButton: NSButton {
    override func draw(_ dirtyRect: NSRect) {
        let circle = NSBezierPath(ovalIn: bounds.insetBy(dx: 1, dy: 1))
        (isHighlighted ? GymAssistantAppearance.promptFill : GymAssistantAppearance.paper).setFill()
        circle.fill()
        GymAssistantAppearance.paperBorder.setStroke()
        circle.lineWidth = 1; circle.stroke()
        let center = NSPoint(x: bounds.midX, y: bounds.midY)
        let tipY = center.y + (isFlipped ? 5 : -5)
        let topY = center.y + (isFlipped ? -6 : 6)
        let wingY = center.y
        let arrow = NSBezierPath()
        arrow.move(to: NSPoint(x: center.x, y: topY))
        arrow.line(to: NSPoint(x: center.x, y: tipY))
        arrow.move(to: NSPoint(x: center.x - 5, y: wingY))
        arrow.line(to: NSPoint(x: center.x, y: tipY))
        arrow.line(to: NSPoint(x: center.x + 5, y: wingY))
        arrow.lineWidth = 1.75; arrow.lineCapStyle = .round; arrow.lineJoinStyle = .round
        GymAssistantAppearance.inkAccent.setStroke(); arrow.stroke()
    }
}
