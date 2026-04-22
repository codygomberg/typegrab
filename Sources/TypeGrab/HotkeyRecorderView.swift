import AppKit
import Carbon.HIToolbox

final class HotkeyRecorderView: NSView {
    var onHotkeyChanged: ((Hotkey) -> Void)?
    var hotkey: Hotkey {
        didSet { updateLabel() }
    }

    private let label = NSTextField(labelWithString: "")
    private var isRecording = false {
        didSet { updateAppearance(); updateLabel() }
    }
    private var eventMonitor: Any?

    init(frame: NSRect, hotkey: Hotkey) {
        self.hotkey = hotkey
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.borderWidth = 1

        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.alignment = .center
        label.isEditable = false
        label.isSelectable = false
        label.frame = bounds
        label.autoresizingMask = [.width, .height]
        addSubview(label)

        updateAppearance()
        updateLabel()
    }

    required init?(coder: NSCoder) { fatalError() }

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    override func resignFirstResponder() -> Bool {
        if isRecording { stopRecording() }
        return super.resignFirstResponder()
    }

    private func startRecording() {
        isRecording = true
        window?.makeFirstResponder(self)

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard let self, self.isRecording else { return event }

            if event.type == .keyDown, event.keyCode == UInt16(kVK_Escape) {
                self.stopRecording()
                return nil
            }

            let modifiers = Hotkey.carbonModifiers(from: event.modifierFlags)
            if event.type == .keyDown, modifiers != 0, KeyCodeMap.name(for: UInt32(event.keyCode)) != nil {
                let newHotkey = Hotkey(keyCode: UInt32(event.keyCode), modifiers: modifiers)
                self.hotkey = newHotkey
                self.onHotkeyChanged?(newHotkey)
                self.stopRecording()
                return nil
            }

            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func updateLabel() {
        if isRecording {
            label.stringValue = "Press new hotkey…"
            label.textColor = .secondaryLabelColor
        } else {
            label.stringValue = hotkey.displayString
            label.textColor = .labelColor
        }
    }

    private func updateAppearance() {
        if isRecording {
            layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.15).cgColor
            layer?.borderColor = NSColor.controlAccentColor.cgColor
        } else {
            layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
            layer?.borderColor = NSColor.separatorColor.cgColor
        }
    }
}
