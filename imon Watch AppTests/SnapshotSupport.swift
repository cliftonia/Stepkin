import CoreGraphics
import Foundation
import ImageIO
import SwiftUI
import Testing
import UniformTypeIdentifiers
@testable import imon_Watch_App

/// An anchor class whose bundle is the test bundle, where the snapshot
/// references are copied as resources.
final class SnapshotAnchor {}

/// The point size every LCD snapshot is rendered at - the 32×20 grid's 8:5
/// aspect, so the canvas fills it exactly.
private let snapshotSize = CGSize(width: 160, height: 100)

/// Renders one frozen frame of the LCD under `theme` at 160×100 points and
/// scale 2, so the image is 320×200 pixels.
@MainActor
func renderLCD(_ configuration: LCDDisplayConfiguration, theme: LCDTheme, weatherPhase: Int = 0) -> CGImage? {
    let view = LCDDisplay(configuration: configuration, fixedWeatherPhase: weatherPhase)
        .environment(\.lcdTheme, theme)
        .frame(width: snapshotSize.width, height: snapshotSize.height)
    let renderer = ImageRenderer(content: view)
    renderer.proposedSize = ProposedViewSize(snapshotSize)
    renderer.scale = 2
    return renderer.cgImage
}

/// Compares `image` byte for byte (RGBA8, sRGB) against `Snapshots/<name>.png`
/// in the test bundle. In record mode it writes the reference into the source
/// tree and records an issue, so a recording run never passes silently. On a
/// mismatch it writes `<name>.actual.png` beside the reference and fails with
/// the number of differing pixels. Record from the command line with
/// `TEST_RUNNER_RECORD_SNAPSHOTS=1 xcodebuild test …` (xcodebuild strips the prefix when forwarding), or set
/// `RECORD_SNAPSHOTS=1` in the scheme's environment.
@MainActor
func assertSnapshot(
    _ image: CGImage,
    named name: String,
    record: Bool = ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] == "1",
    sourceLocation: SourceLocation = #_sourceLocation
) {
    guard let actual = SnapshotBitmap(image) else {
        Issue.record("could not read the rendered image for \(name)", sourceLocation: sourceLocation)
        return
    }
    if record {
        write(actual, to: snapshotDirectory().appendingPathComponent("\(name).png"), sourceLocation: sourceLocation)
        Issue.record("recorded \(name)", sourceLocation: sourceLocation)
        return
    }
    guard let reference = loadReference(named: name) else {
        Issue.record(
            "no reference for \(name) - record with TEST_RUNNER_RECORD_SNAPSHOTS=1 xcodebuild test (or RECORD_SNAPSHOTS=1 in the scheme)",
            sourceLocation: sourceLocation
        )
        return
    }
    let differing = actual.differingPixels(from: reference)
    guard differing > 0 else { return }
    write(actual, to: snapshotDirectory().appendingPathComponent("\(name).actual.png"), sourceLocation: sourceLocation)
    Issue.record("\(name) differs from its reference in \(differing) pixels", sourceLocation: sourceLocation)
}

/// The `Snapshots` folder in the source tree, next to this file.
private func snapshotDirectory(filePath: String = #filePath) -> URL {
    URL(fileURLWithPath: filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Snapshots", isDirectory: true)
}

/// Loads a reference from the test bundle; a synchronized folder may flatten
/// resources to the bundle root, so both locations are tried.
private func loadReference(named name: String) -> SnapshotBitmap? {
    let bundle = Bundle(for: SnapshotAnchor.self)
    let url = bundle.url(forResource: name, withExtension: "png", subdirectory: "Snapshots")
        ?? bundle.url(forResource: name, withExtension: "png")
    guard let url,
          let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
    return SnapshotBitmap(image)
}

/// Encodes `bitmap` as a PNG at `url`, recording an issue when that fails.
private func write(_ bitmap: SnapshotBitmap, to url: URL, sourceLocation: SourceLocation) {
    do {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        guard let image = bitmap.makeImage(),
              let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
        else {
            Issue.record("could not encode \(url.lastPathComponent)", sourceLocation: sourceLocation)
            return
        }
        CGImageDestinationAddImage(destination, image, nil)
        if !CGImageDestinationFinalize(destination) {
            Issue.record("could not write \(url.lastPathComponent)", sourceLocation: sourceLocation)
        }
    } catch {
        Issue.record("could not create \(url.path): \(error)", sourceLocation: sourceLocation)
    }
}

/// An image normalised to 8-bit RGBA in sRGB, so a render and a decoded PNG
/// compare on the same byte layout.
struct SnapshotBitmap: Equatable {
    /// The image width in pixels.
    let width: Int
    /// The image height in pixels.
    let height: Int
    /// The premultiplied RGBA bytes, row by row with no padding.
    let bytes: [UInt8]

    private static let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
    private static let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

    /// Wraps raw RGBA bytes, for building small fixtures.
    init(width: Int, height: Int, bytes: [UInt8]) {
        self.width = width
        self.height = height
        self.bytes = bytes
    }

    /// Redraws `image` into an sRGB RGBA8 buffer; nil if the context fails.
    init?(_ image: CGImage) {
        let width = image.width
        let height = image.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4,
                space: Self.colorSpace, bitmapInfo: Self.bitmapInfo
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }
        self.width = width
        self.height = height
        self.bytes = bytes
    }

    /// The number of pixels whose RGBA differs from `other`; every pixel
    /// counts as differing when the sizes disagree.
    func differingPixels(from other: SnapshotBitmap) -> Int {
        guard width == other.width, height == other.height else { return max(width * height, 1) }
        return stride(from: 0, to: bytes.count, by: 4).reduce(into: 0) { count, index in
            if bytes[index..<index + 4] != other.bytes[index..<index + 4] { count += 1 }
        }
    }

    /// Wraps the bytes back into a `CGImage` for PNG encoding.
    func makeImage() -> CGImage? {
        guard let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }
        return CGImage(
            width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
            bytesPerRow: width * 4, space: Self.colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: Self.bitmapInfo),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent
        )
    }
}
