import AppKit

enum HUDWindow {
    private static var current: NSWindow?
    private static var dismissTimer: Timer?

    static func show(message: String, duration: TimeInterval = 1.6) {
        dismissTimer?.invalidate()
        current?.orderOut(nil)

        let label = NSTextField(labelWithString: message)
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .labelColor
        label.alignment = .center
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 1
        label.sizeToFit()

        let hPad: CGFloat = 18
        let vPad: CGFloat = 10
        let width = min(label.frame.width + hPad * 2, 560)
        let height = label.frame.height + vPad * 2
        let size = NSSize(width: width, height: height)

        guard let screen = NSScreen.main else { return }
        let origin = NSPoint(
            x: screen.frame.midX - size.width / 2,
            y: screen.frame.origin.y + 120
        )

        let window = NSWindow(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar
        window.ignoresMouseEvents = true
        window.hasShadow = true

        let container = NSVisualEffectView(frame: NSRect(origin: .zero, size: size))
        container.material = .hudWindow
        container.state = .active
        container.blendingMode = .behindWindow
        container.wantsLayer = true
        container.layer?.cornerRadius = 10
        container.layer?.masksToBounds = true

        label.frame = NSRect(x: hPad, y: vPad, width: size.width - hPad * 2, height: label.frame.height)
        container.addSubview(label)
        window.contentView = container

        window.orderFrontRegardless()
        current = window
        dismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            current?.orderOut(nil)
            current = nil
        }
    }
}
