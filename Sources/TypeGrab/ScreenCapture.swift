import AppKit

enum ScreenCapture {
    static func capture(rect: CGRect) -> CGImage? {
        guard let primary = NSScreen.screens.first(where: { $0.frame.origin == .zero }) else {
            return nil
        }
        let flipped = CGRect(
            x: rect.origin.x,
            y: primary.frame.height - rect.maxY,
            width: rect.width,
            height: rect.height
        )
        return CGWindowListCreateImage(
            flipped,
            .optionOnScreenBelowWindow,
            kCGNullWindowID,
            [.bestResolution, .boundsIgnoreFraming]
        )
    }
}
