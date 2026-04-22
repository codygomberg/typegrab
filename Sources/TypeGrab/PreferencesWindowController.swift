import AppKit

final class PreferencesWindowController: NSWindowController {
    private let recorder: HotkeyRecorderView
    private let launchCheckbox: NSButton

    init() {
        let size = NSSize(width: 440, height: 220)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "TypeGrab Preferences"
        window.isReleasedWhenClosed = false
        window.center()

        recorder = HotkeyRecorderView(
            frame: NSRect(x: 160, y: 140, width: 240, height: 34),
            hotkey: Preferences.hotkey
        )

        launchCheckbox = NSButton(checkboxWithTitle: "Launch TypeGrab at login", target: nil, action: nil)
        launchCheckbox.frame = NSRect(x: 160, y: 90, width: 260, height: 20)
        launchCheckbox.state = LaunchAtLogin.isEnabled ? .on : .off

        super.init(window: window)

        launchCheckbox.target = self
        launchCheckbox.action = #selector(toggleLaunchAtLogin(_:))

        let hotkeyLabel = NSTextField(labelWithString: "Capture hotkey:")
        hotkeyLabel.frame = NSRect(x: 20, y: 146, width: 130, height: 20)
        hotkeyLabel.alignment = .right

        let hint = NSTextField(labelWithString: "Click the field and press any key combination with at least one modifier (⌘ ⌃ ⌥ ⇧). Press ⎋ to cancel.")
        hint.font = .systemFont(ofSize: 11)
        hint.textColor = .secondaryLabelColor
        hint.frame = NSRect(x: 20, y: 26, width: size.width - 40, height: 48)
        hint.usesSingleLineMode = false
        hint.maximumNumberOfLines = 3
        hint.cell?.wraps = true
        hint.cell?.isScrollable = false

        let content = window.contentView!
        content.addSubview(hotkeyLabel)
        content.addSubview(recorder)
        content.addSubview(launchCheckbox)
        content.addSubview(hint)

        recorder.onHotkeyChanged = { newHotkey in
            Preferences.hotkey = newHotkey
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func toggleLaunchAtLogin(_ sender: NSButton) {
        LaunchAtLogin.set(sender.state == .on)
        sender.state = LaunchAtLogin.isEnabled ? .on : .off
    }

    func present() {
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
}
