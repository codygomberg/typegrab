import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBarController?
    private var hotkey: HotkeyManager?
    private var currentOverlay: SelectionOverlay?
    private var prefsController: PreferencesWindowController?

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBar = MenuBarController(
            captureAction: { [weak self] in self?.startCapture() },
            preferencesAction: { [weak self] in self?.showPreferences() },
            quitAction: { NSApp.terminate(nil) }
        )

        hotkey = HotkeyManager { [weak self] in self?.startCapture() }
        let current = Preferences.hotkey
        hotkey?.register(keyCode: current.keyCode, modifiers: current.modifiers)
        menuBar?.updateHotkeyDisplay(current.displayString)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hotkeyDidChange),
            name: .hotkeyChanged,
            object: nil
        )
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }

    @objc private func hotkeyDidChange() {
        let current = Preferences.hotkey
        hotkey?.register(keyCode: current.keyCode, modifiers: current.modifiers)
        menuBar?.updateHotkeyDisplay(current.displayString)
    }

    func showPreferences() {
        if prefsController == nil {
            prefsController = PreferencesWindowController()
        }
        prefsController?.present()
    }

    func startCapture() {
        guard currentOverlay == nil else { return }
        let overlay = SelectionOverlay { [weak self] rect in
            self?.currentOverlay = nil
            guard let rect else { return }
            // Wait for the overlay windows to leave the screen composite
            // before capturing, otherwise the dim layer ends up in the image.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.performOCR(in: rect)
            }
        }
        currentOverlay = overlay
        overlay.show()
    }

    private func performOCR(in rect: CGRect) {
        guard let image = ScreenCapture.capture(rect: rect) else {
            HUDWindow.show(message: "Capture failed — grant Screen Recording in System Settings")
            return
        }
        OCREngine.recognize(image: image) { text in
            DispatchQueue.main.async {
                guard let text, !text.isEmpty else {
                    HUDWindow.show(message: "No text found")
                    return
                }
                ClipboardManager.copy(text)
                let preview = text.replacingOccurrences(of: "\n", with: " ")
                let snippet = preview.count > 48 ? String(preview.prefix(48)) + "…" : preview
                HUDWindow.show(message: "Copied: \(snippet)")
            }
        }
    }
}
