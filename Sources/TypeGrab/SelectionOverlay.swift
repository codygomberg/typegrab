import AppKit

final class SelectionOverlay {
    private var windows: [NSWindow] = []
    private var startPoint: NSPoint?
    private var currentPoint: NSPoint?
    private var activeScreen: NSScreen?
    private let completion: (CGRect?) -> Void

    init(completion: @escaping (CGRect?) -> Void) {
        self.completion = completion
    }

    func show() {
        for screen in NSScreen.screens {
            let window = OverlayWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.level = .screenSaver
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.ignoresMouseEvents = false

            let view = OverlayView(frame: NSRect(origin: .zero, size: screen.frame.size))
            view.onMouseDown = { [weak self] pt in self?.beginSelection(at: pt, screen: screen) }
            view.onMouseDragged = { [weak self] pt in self?.updateSelection(to: pt, screen: screen) }
            view.onMouseUp = { [weak self] pt in self?.endSelection(at: pt, screen: screen) }
            view.onCancel = { [weak self] in self?.cancel() }
            window.contentView = view
            window.makeFirstResponder(view)
            window.makeKeyAndOrderFront(nil)
            windows.append(window)
        }
        NSApp.activate(ignoringOtherApps: true)
        NSCursor.crosshair.set()
    }

    private func beginSelection(at point: NSPoint, screen: NSScreen) {
        startPoint = point
        currentPoint = point
        activeScreen = screen
        refreshViews()
    }

    private func updateSelection(to point: NSPoint, screen: NSScreen) {
        guard activeScreen === screen else { return }
        currentPoint = point
        refreshViews()
    }

    private func endSelection(at point: NSPoint, screen: NSScreen) {
        guard activeScreen === screen, let start = startPoint else {
            cancel()
            return
        }
        let rect = NSRect(
            x: min(start.x, point.x),
            y: min(start.y, point.y),
            width: abs(point.x - start.x),
            height: abs(point.y - start.y)
        )
        close()
        guard rect.width > 4, rect.height > 4 else {
            completion(nil)
            return
        }
        let globalRect = CGRect(
            x: screen.frame.origin.x + rect.origin.x,
            y: screen.frame.origin.y + rect.origin.y,
            width: rect.width,
            height: rect.height
        )
        completion(globalRect)
    }

    private func cancel() {
        close()
        completion(nil)
    }

    private func refreshViews() {
        for window in windows {
            guard let view = window.contentView as? OverlayView else { continue }
            if window.screen === activeScreen, let start = startPoint, let current = currentPoint {
                view.selectionRect = NSRect(
                    x: min(start.x, current.x),
                    y: min(start.y, current.y),
                    width: abs(current.x - start.x),
                    height: abs(current.y - start.y)
                )
            } else {
                view.selectionRect = nil
            }
            view.needsDisplay = true
        }
    }

    private func close() {
        for window in windows { window.orderOut(nil) }
        windows.removeAll()
        NSCursor.arrow.set()
    }
}

final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class OverlayView: NSView {
    var onMouseDown: ((NSPoint) -> Void)?
    var onMouseDragged: ((NSPoint) -> Void)?
    var onMouseUp: ((NSPoint) -> Void)?
    var onCancel: (() -> Void)?
    var selectionRect: NSRect?

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        onMouseDown?(convert(event.locationInWindow, from: nil))
    }

    override func mouseDragged(with event: NSEvent) {
        onMouseDragged?(convert(event.locationInWindow, from: nil))
    }

    override func mouseUp(with event: NSEvent) {
        onMouseUp?(convert(event.locationInWindow, from: nil))
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            onCancel?()
        } else {
            super.keyDown(with: event)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath()
        path.append(NSBezierPath(rect: bounds))
        if let r = selectionRect {
            path.append(NSBezierPath(rect: r))
            path.windingRule = .evenOdd
        }
        NSColor.black.withAlphaComponent(0.35).setFill()
        path.fill()

        if let r = selectionRect {
            NSColor.systemBlue.setStroke()
            let stroke = NSBezierPath(rect: r)
            stroke.lineWidth = 1.5
            stroke.stroke()
        }
    }
}
