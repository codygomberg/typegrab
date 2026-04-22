import AppKit

final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private let captureItem: NSMenuItem
    private let captureAction: () -> Void
    private let preferencesAction: () -> Void
    private let quitAction: () -> Void

    init(captureAction: @escaping () -> Void,
         preferencesAction: @escaping () -> Void,
         quitAction: @escaping () -> Void) {
        self.captureAction = captureAction
        self.preferencesAction = preferencesAction
        self.quitAction = quitAction
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        captureItem = NSMenuItem(title: "Capture Text", action: nil, keyEquivalent: "")
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "text.viewfinder", accessibilityDescription: "TypeGrab")
        }

        let menu = NSMenu()
        captureItem.target = self
        captureItem.action = #selector(handleCapture)
        menu.addItem(captureItem)

        menu.addItem(.separator())

        let prefs = NSMenuItem(title: "Preferences…", action: #selector(handlePreferences), keyEquivalent: ",")
        prefs.target = self
        menu.addItem(prefs)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit TypeGrab", action: #selector(handleQuit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    func updateHotkeyDisplay(_ shortcut: String) {
        captureItem.title = "Capture Text   \(shortcut)"
    }

    @objc private func handleCapture() { captureAction() }
    @objc private func handlePreferences() { preferencesAction() }
    @objc private func handleQuit() { quitAction() }
}
