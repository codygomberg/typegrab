import AppKit

final class SelectionOverlay {
    private var window: OverlayWindow?
    private var startPoint: NSPoint?
    private let completion: (CGRect?) -> Void

    init(completion: @escaping (CGRect?) -> Void) {
        self.completion = completion
    }

    func show() {
        // Only cover the screen the cursor is on — avoids cross-display coord issues.
        let cursorPos = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(cursorPos) })
                     ?? NSScreen.main
                     ?? NSScreen.screens[0]

        let win = OverlayWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        // setFrame uses unambiguous global screen coordinates (origin = main screen
        // bottom-left), bypassing the per-screen-relative offset in the initializer.
        win.setFrame(screen.frame, display: false)
        win.level = .screenSaver
        win.backgroundColor = .clear
        win.isOpaque = false
        win.hasShadow = false
        win.ignoresMouseEvents = false

        let view = OverlayView(frame: NSRect(origin: .zero, size: screen.frame.size))
        view.onMouseDown   = { [weak self] pt in self?.beginSelection(at: pt) }
        view.onMouseDragged = { [weak self] pt in self?.updateSelection(to: pt) }
        view.onMouseUp     = { [weak self] pt in self?.endSelection(at: pt, screen: screen) }
        view.onCancel      = { [weak self] in self?.cancel() }
        win.contentView = view
        win.makeFirstResponder(view)
        win.makeKeyAndOrderFront(nil)
        window = win

        NSApp.activate(ignoringOtherApps: true)
        NSCursor.crosshair.set()
    }

    private func beginSelection(at point: NSPoint) {
        startPoint = point
        updateOverlay(to: point)
    }

    private func updateSelection(to point: NSPoint) {
        updateOverlay(to: point)
    }

    private func updateOverlay(to current: NSPoint) {
        guard let view = window?.contentView as? OverlayView,
              let start = startPoint else { return }
        view.selectionRect = NSRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
        view.needsDisplay = true
    }

    private func endSelection(at point: NSPoint, screen: NSScreen) {
        guard let start = startPoint else { cancel(); return }
        let rect = NSRect(
            x: min(start.x, point.x),
            y: min(start.y, point.y),
            width: abs(point.x - start.x),
            height: abs(point.y - start.y)
        )
        close()
        guard rect.width > 4, rect.height > 4 else { completion(nil); return }
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

    private func close() {
        window?.orderOut(nil)
        window = nil
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
