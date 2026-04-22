import AppKit
import Carbon.HIToolbox

struct Hotkey: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    var displayString: String {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(optionKey)  != 0 { parts.append("⌥") }
        if modifiers & UInt32(shiftKey)   != 0 { parts.append("⇧") }
        if modifiers & UInt32(cmdKey)     != 0 { parts.append("⌘") }
        parts.append(KeyCodeMap.name(for: keyCode) ?? "?")
        return parts.joined()
    }

    static let `default` = Hotkey(
        keyCode: UInt32(kVK_ANSI_T),
        modifiers: UInt32(controlKey | cmdKey)
    )

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.command) { result |= UInt32(cmdKey) }
        if flags.contains(.control) { result |= UInt32(controlKey) }
        if flags.contains(.option)  { result |= UInt32(optionKey) }
        if flags.contains(.shift)   { result |= UInt32(shiftKey) }
        return result
    }
}

enum Preferences {
    private static let hotkeyKey = "typegrab.hotkey"

    static var hotkey: Hotkey {
        get {
            guard let data = UserDefaults.standard.data(forKey: hotkeyKey),
                  let stored = try? JSONDecoder().decode(Hotkey.self, from: data) else {
                return .default
            }
            return stored
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            UserDefaults.standard.set(data, forKey: hotkeyKey)
            NotificationCenter.default.post(name: .hotkeyChanged, object: nil)
        }
    }
}

extension Notification.Name {
    static let hotkeyChanged = Notification.Name("typegrab.hotkeyChanged")
}

enum KeyCodeMap {
    private static let map: [UInt32: String] = [
        UInt32(kVK_ANSI_A): "A", UInt32(kVK_ANSI_B): "B", UInt32(kVK_ANSI_C): "C",
        UInt32(kVK_ANSI_D): "D", UInt32(kVK_ANSI_E): "E", UInt32(kVK_ANSI_F): "F",
        UInt32(kVK_ANSI_G): "G", UInt32(kVK_ANSI_H): "H", UInt32(kVK_ANSI_I): "I",
        UInt32(kVK_ANSI_J): "J", UInt32(kVK_ANSI_K): "K", UInt32(kVK_ANSI_L): "L",
        UInt32(kVK_ANSI_M): "M", UInt32(kVK_ANSI_N): "N", UInt32(kVK_ANSI_O): "O",
        UInt32(kVK_ANSI_P): "P", UInt32(kVK_ANSI_Q): "Q", UInt32(kVK_ANSI_R): "R",
        UInt32(kVK_ANSI_S): "S", UInt32(kVK_ANSI_T): "T", UInt32(kVK_ANSI_U): "U",
        UInt32(kVK_ANSI_V): "V", UInt32(kVK_ANSI_W): "W", UInt32(kVK_ANSI_X): "X",
        UInt32(kVK_ANSI_Y): "Y", UInt32(kVK_ANSI_Z): "Z",
        UInt32(kVK_ANSI_0): "0", UInt32(kVK_ANSI_1): "1", UInt32(kVK_ANSI_2): "2",
        UInt32(kVK_ANSI_3): "3", UInt32(kVK_ANSI_4): "4", UInt32(kVK_ANSI_5): "5",
        UInt32(kVK_ANSI_6): "6", UInt32(kVK_ANSI_7): "7", UInt32(kVK_ANSI_8): "8",
        UInt32(kVK_ANSI_9): "9",
        UInt32(kVK_Space):      "Space",
        UInt32(kVK_Return):     "↩",
        UInt32(kVK_Tab):        "⇥",
        UInt32(kVK_Escape):     "⎋",
        UInt32(kVK_Delete):     "⌫",
        UInt32(kVK_LeftArrow):  "←",
        UInt32(kVK_RightArrow): "→",
        UInt32(kVK_UpArrow):    "↑",
        UInt32(kVK_DownArrow):  "↓",
        UInt32(kVK_F1): "F1", UInt32(kVK_F2): "F2", UInt32(kVK_F3):  "F3",
        UInt32(kVK_F4): "F4", UInt32(kVK_F5): "F5", UInt32(kVK_F6):  "F6",
        UInt32(kVK_F7): "F7", UInt32(kVK_F8): "F8", UInt32(kVK_F9):  "F9",
        UInt32(kVK_F10): "F10", UInt32(kVK_F11): "F11", UInt32(kVK_F12): "F12",
        UInt32(kVK_ANSI_Comma):        ",",
        UInt32(kVK_ANSI_Period):       ".",
        UInt32(kVK_ANSI_Slash):        "/",
        UInt32(kVK_ANSI_Semicolon):    ";",
        UInt32(kVK_ANSI_Quote):        "'",
        UInt32(kVK_ANSI_LeftBracket):  "[",
        UInt32(kVK_ANSI_RightBracket): "]",
        UInt32(kVK_ANSI_Backslash):    "\\",
        UInt32(kVK_ANSI_Minus):        "-",
        UInt32(kVK_ANSI_Equal):        "=",
        UInt32(kVK_ANSI_Grave):        "`",
    ]

    static func name(for keyCode: UInt32) -> String? { map[keyCode] }
}
