import AppKit
import CoreGraphics
import Foundation

func drawIcon(size: Int) -> Data {
    let pixels = size
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 32
    ) else {
        return Data()
    }

    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    let cg = ctx.cgContext

    let s = CGFloat(size)
    let rect = CGRect(x: 0, y: 0, width: s, height: s)

    // Rounded background clip (macOS squircle approximation)
    let corner = s * 0.225
    let bgPath = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)
    cg.addPath(bgPath)
    cg.clip()

    // Diagonal gradient: indigo -> violet
    let colors = [
        CGColor(red: 0.23, green: 0.33, blue: 0.95, alpha: 1.0),
        CGColor(red: 0.55, green: 0.23, blue: 0.88, alpha: 1.0),
    ]
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors as CFArray,
        locations: [0.0, 1.0]
    )!
    cg.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: s),
        end: CGPoint(x: s, y: 0),
        options: []
    )

    // Corner brackets (crop marks)
    let inset = s * 0.16
    let bracketLen = s * 0.14
    let bracketThickness = max(1.5, s * 0.045)
    cg.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
    cg.setLineWidth(bracketThickness)
    cg.setLineCap(.round)
    cg.setLineJoin(.round)

    let brackets: [(CGPoint, CGPoint, CGPoint)] = [
        (CGPoint(x: inset, y: s - inset - bracketLen),
         CGPoint(x: inset, y: s - inset),
         CGPoint(x: inset + bracketLen, y: s - inset)),
        (CGPoint(x: s - inset - bracketLen, y: s - inset),
         CGPoint(x: s - inset, y: s - inset),
         CGPoint(x: s - inset, y: s - inset - bracketLen)),
        (CGPoint(x: inset + bracketLen, y: inset),
         CGPoint(x: inset, y: inset),
         CGPoint(x: inset, y: inset + bracketLen)),
        (CGPoint(x: s - inset, y: inset + bracketLen),
         CGPoint(x: s - inset, y: inset),
         CGPoint(x: s - inset - bracketLen, y: inset)),
    ]
    for (a, b, c) in brackets {
        cg.move(to: a)
        cg.addLine(to: b)
        cg.addLine(to: c)
    }
    cg.strokePath()

    // Text-line pills (representing captured text)
    let lineHeight = s * 0.055
    let radius = lineHeight / 2
    let widths: [CGFloat] = [s * 0.42, s * 0.5, s * 0.36]
    let spacing = lineHeight * 2.2
    let centerY = s / 2
    let centerX = s / 2
    let totalHeight = CGFloat(widths.count - 1) * spacing
    let topY = centerY + totalHeight / 2

    cg.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
    for (i, w) in widths.enumerated() {
        let y = topY - CGFloat(i) * spacing - lineHeight / 2
        let x = centerX - w / 2
        let r = CGRect(x: x, y: y, width: w, height: lineHeight)
        let p = CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil)
        cg.addPath(p)
    }
    cg.fillPath()

    NSGraphicsContext.restoreGraphicsState()

    return rep.representation(using: .png, properties: [:]) ?? Data()
}

let args = CommandLine.arguments
let outputDir = args.count > 1 ? args[1] : "build/AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

let sizes: [(Int, String)] = [
    (16,   "icon_16x16.png"),
    (32,   "icon_16x16@2x.png"),
    (32,   "icon_32x32.png"),
    (64,   "icon_32x32@2x.png"),
    (128,  "icon_128x128.png"),
    (256,  "icon_128x128@2x.png"),
    (256,  "icon_256x256.png"),
    (512,  "icon_256x256@2x.png"),
    (512,  "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

for (size, filename) in sizes {
    let data = drawIcon(size: size)
    let url = URL(fileURLWithPath: "\(outputDir)/\(filename)")
    try? data.write(to: url)
}
print("Wrote \(sizes.count) icon sizes to \(outputDir)")
