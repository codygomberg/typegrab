import AppKit

final class SelectionOverlay {
    private var windows: [NSWindow] = []
    private var startGlobal: NSPoint?
    private var currentGlobal: NSPoint?
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

    private func toGlobal(_ point: NSPoint, screen: NSScreen) -> NSPoint {
        NSPoint(x: screen.frame.origin.x + point.x, y: screen.frame.origin.y + point.y)
    }

    private func beginSelection(at point: NSPoint, screen: NSScreen) {
        let global = toGlobal(point, screen: screen)
        startGlobal = global
        currentGlobal = global
        activeScreen = screen
        refreshViews()
    }

    private func updateSelection(to point: NSPoint, screen: NSScreen) {
        guard activeScreen != nil else { return }
        // AppKit delivers all drag events to the window that received mouseDown,
        // so local coords can exceed screen bounds when the cursor is on another display.
        // Converting through the originating screen gives correct global coords.
        currentGlobal = toGlobal(point, screen: screen)
        refreshViews()
    }

    private func endSelection(at point: NSPoint, screen: NSScreen) {
        guard activeScreen != nil, let startG = startGlobal else {
            cancel()
            return
        }
        let endG = toGlobal(point, screen: screen)
        let globalRect = CGRect(
            x: min(startG.x, endG.x),
            y: min(startG.y, endG.y),
            width: abs(endG.x - startG.x),
            height: abs(endG.y - startG.y)
        )
        close()
        guard globalRect.width > 4, globalRect.height > 4 else {
            completion(nil)
            return
        }
        completion(globalRect)
    }

    private func cancel() {
        close()
        completion(nil)
    }

    private func refreshViews() {
        guard let startG = startGlobal, let currentG = currentGlobal else { return }
        let globalSelectionRect = NSRect(
            x: min(startG.x, currentG.x),
            y: min(startG.y, currentG.y),
            width: abs(currentG.x - startG.x),
            height: abs(currentG.y - startG.y)
        )
        for window in windows {
            guard let view = window.contentView as? OverlayView,
                  let screen = window.screen else { continue }
            let intersection = globalSelectionRect.intersection(screen.frame)
            if intersection.isNull || intersection.isEmpty {
                view.selectionRect = nil
            } else {
                view.selectionRect = NSRect(
                    x: intersection.origin.x - screen.frame.origin.x,
                    y: intersection.origin.y - screen.frame.origin.y,
                    width: intersection.width,
                    height: intersection.height
                )
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
