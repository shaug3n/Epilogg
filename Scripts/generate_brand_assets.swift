import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

private struct Palette {
    let backgroundTop: NSColor
    let backgroundBottom: NSColor
    let leftPage: NSColor
    let rightPage: NSColor
    let bookmark: NSColor
    let pageLine: NSColor
}

private let standard = Palette(
    backgroundTop: NSColor(calibratedRed: 47 / 255, green: 83 / 255, blue: 97 / 255, alpha: 1),
    backgroundBottom: NSColor(calibratedRed: 24 / 255, green: 47 / 255, blue: 58 / 255, alpha: 1),
    leftPage: .white,
    rightPage: NSColor(calibratedRed: 229 / 255, green: 240 / 255, blue: 236 / 255, alpha: 1),
    bookmark: NSColor(calibratedRed: 243 / 255, green: 203 / 255, blue: 181 / 255, alpha: 1),
    pageLine: NSColor(calibratedRed: 74 / 255, green: 128 / 255, blue: 119 / 255, alpha: 1)
)

private let dark = Palette(
    backgroundTop: NSColor(calibratedRed: 20 / 255, green: 42 / 255, blue: 53 / 255, alpha: 1),
    backgroundBottom: NSColor(calibratedRed: 9 / 255, green: 22 / 255, blue: 29 / 255, alpha: 1),
    leftPage: NSColor(calibratedRed: 216 / 255, green: 231 / 255, blue: 226 / 255, alpha: 1),
    rightPage: NSColor(calibratedRed: 187 / 255, green: 211 / 255, blue: 202 / 255, alpha: 1),
    bookmark: NSColor(calibratedRed: 232 / 255, green: 189 / 255, blue: 165 / 255, alpha: 1),
    pageLine: NSColor(calibratedRed: 57 / 255, green: 111 / 255, blue: 103 / 255, alpha: 1)
)

private let tinted = Palette(
    backgroundTop: NSColor(calibratedRed: 216 / 255, green: 234 / 255, blue: 228 / 255, alpha: 1),
    backgroundBottom: NSColor(calibratedRed: 191 / 255, green: 219 / 255, blue: 211 / 255, alpha: 1),
    leftPage: NSColor(calibratedRed: 53 / 255, green: 109 / 255, blue: 100 / 255, alpha: 1),
    rightPage: NSColor(calibratedRed: 79 / 255, green: 130 / 255, blue: 120 / 255, alpha: 1),
    bookmark: NSColor(calibratedRed: 33 / 255, green: 75 / 255, blue: 69 / 255, alpha: 1),
    pageLine: NSColor(calibratedRed: 183 / 255, green: 216 / 255, blue: 207 / 255, alpha: 1)
)

private let size = 1024
private let designScale = CGFloat(size) / 168

private func color(_ color: NSColor) -> CGColor {
    color.usingColorSpace(.deviceRGB)!.cgColor
}

private func leftPagePath() -> CGPath {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: 44, y: 44))
    path.addCurve(to: CGPoint(x: 84, y: 55), control1: CGPoint(x: 60, y: 40), control2: CGPoint(x: 73, y: 46))
    path.addLine(to: CGPoint(x: 84, y: 124))
    path.addCurve(to: CGPoint(x: 44, y: 115), control1: CGPoint(x: 73, y: 114), control2: CGPoint(x: 60, y: 111))
    path.closeSubpath()
    return path
}

private func rightPagePath() -> CGPath {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: 124, y: 44))
    path.addCurve(to: CGPoint(x: 84, y: 55), control1: CGPoint(x: 108, y: 40), control2: CGPoint(x: 95, y: 46))
    path.addLine(to: CGPoint(x: 84, y: 124))
    path.addCurve(to: CGPoint(x: 124, y: 115), control1: CGPoint(x: 95, y: 114), control2: CGPoint(x: 108, y: 111))
    path.closeSubpath()
    return path
}

private func bookmarkPath() -> CGPath {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: 101, y: 43))
    path.addLine(to: CGPoint(x: 101, y: 82))
    path.addLine(to: CGPoint(x: 111, y: 75))
    path.addLine(to: CGPoint(x: 121, y: 82))
    path.addLine(to: CGPoint(x: 121, y: 44))
    path.addCurve(to: CGPoint(x: 101, y: 43), control1: CGPoint(x: 114, y: 42), control2: CGPoint(x: 107, y: 42))
    path.closeSubpath()
    return path
}

private func drawIcon(palette: Palette) -> CGImage {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerRow = size * 4
    let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    )!

    let gradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [color(palette.backgroundTop), color(palette.backgroundBottom)] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: CGFloat(size)),
        end: CGPoint(x: CGFloat(size), y: 0),
        options: []
    )

    context.saveGState()
    context.translateBy(x: 0, y: CGFloat(size))
    context.scaleBy(x: designScale, y: -designScale)

    context.addPath(leftPagePath())
    context.setFillColor(color(palette.leftPage))
    context.fillPath()

    context.addPath(rightPagePath())
    context.setFillColor(color(palette.rightPage))
    context.fillPath()

    context.addPath(bookmarkPath())
    context.setFillColor(color(palette.bookmark))
    context.fillPath()

    context.setStrokeColor(color(palette.pageLine))
    context.setLineWidth(7)
    context.setLineCap(.round)
    for (start, end) in [
        (CGPoint(x: 56, y: 65), CGPoint(x: 70, y: 65)),
        (CGPoint(x: 56, y: 84), CGPoint(x: 70, y: 84)),
        (CGPoint(x: 98, y: 99), CGPoint(x: 112, y: 99)),
    ] {
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()
    }
    context.restoreGState()

    return context.makeImage()!
}

private func writePNG(_ image: CGImage, to url: URL) throws {
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        throw CocoaError(.fileWriteUnknown)
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw CocoaError(.fileWriteUnknown)
    }
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconDirectory = root.appendingPathComponent("EpiLogg/Assets.xcassets/AppIcon.appiconset")
let standardURL = iconDirectory.appendingPathComponent("AppIcon.png")

try writePNG(drawIcon(palette: standard), to: standardURL)
try writePNG(drawIcon(palette: dark), to: iconDirectory.appendingPathComponent("AppIcon-Dark.png"))
try writePNG(drawIcon(palette: tinted), to: iconDirectory.appendingPathComponent("AppIcon-Tinted.png"))

let marketingURL = root.appendingPathComponent("Distribution/Marketing/EpiLogg-AppIcon-1024.png")
try FileManager.default.createDirectory(
    at: marketingURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
if FileManager.default.fileExists(atPath: marketingURL.path) {
    try FileManager.default.removeItem(at: marketingURL)
}
try FileManager.default.copyItem(at: standardURL, to: marketingURL)
