import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
import UserNotifications

/// Renders the pet in its home LCD scene — grid, ground and a day or night sky —
/// to a PNG and wraps it as a notification attachment, so a reminder's long-look
/// shows the pet where it actually lives rather than a bare green swatch or the
/// app icon. Uses CoreGraphics + ImageIO (watchOS lacks UIKit's renderer).
nonisolated enum NotificationSpriteRenderer {

    // The LCD's cell grid comes from `LCDGeometry`; each cell renders at `pixelScale` points.
    private static let columns = LCDGeometry.columns
    private static let rows = LCDGeometry.rows
    private static let pixelScale = 12

    /// Where the pet rests on the grid — matching the on-screen idle offset.
    private static let petOffsetX = 8

    /// A screen colour in device RGB — a named type so the palette constants and
    /// draw helpers stay readable (and clear of the tuple-size lint).
    private struct RGB {
        /// The red channel, passed straight to `CGContext.setFillColor`.
        let r: CGFloat
        /// The green channel, passed straight to `CGContext.setFillColor`.
        let g: CGFloat
        /// The blue channel, passed straight to `CGContext.setFillColor`.
        let b: CGFloat
    }

    // Day: black on signature green; night: white on near-black — the classic LCD palette.
    private static let dayBackground = RGB(r: CGFloat(0x8B) / 255, g: CGFloat(0xAC) / 255, b: CGFloat(0x6E) / 255)
    private static let dayPixel = RGB(r: 0, g: 0, b: 0)
    private static let nightBackground = RGB(r: 0.07, g: 0.07, b: 0.07)
    private static let nightPixel = RGB(r: 1, g: 1, b: 1)

    /// Renders the home scene and wraps it as the reminder's attachment for the
    /// long-look; nil when rendering or attachment creation fails, leaving the
    /// app icon.
    static func attachment(for species: PetSpecies, isNight: Bool) -> UNNotificationAttachment? {
        guard let url = renderPNG(for: species, isNight: isNight) else { return nil }
        return try? UNNotificationAttachment(
            identifier: "sprite-\(species.rawValue)-\(isNight ? "night" : "day")", url: url
        )
    }

    private static func renderPNG(for species: PetSpecies, isNight: Bool) -> URL? {
        let width = columns * pixelScale
        let height = rows * pixelScale

        guard let context = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        // Flip the bottom-left origin so cell (x, y) maps top-down with no per-cell flip.
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)

        drawScene(for: species, isNight: isNight, in: context)
        return finalize(context)
    }

    private static func finalize(_ context: CGContext) -> URL? {
        guard let image = context.makeImage() else { return nil }
        // Unique file per render — the system moves attachments; a reused path strands later ones.
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("skykin-\(UUID().uuidString).png")
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.png.identifier as CFString, 1, nil
        ) else { return nil }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return url
    }

    // MARK: - Scene

    private static func drawScene(for species: PetSpecies, isNight: Bool, in context: CGContext) {
        let background = isNight ? nightBackground : dayBackground
        let pixel = isNight ? nightPixel : dayPixel

        fill(background, alpha: 1, in: context)
        context.fill(CGRect(x: 0, y: 0, width: columns * pixelScale, height: rows * pixelScale))

        drawGrid(pixel: pixel, in: context)
        drawGround(pixel: pixel, in: context)
        if isNight { drawNightSky(pixel: pixel, in: context) }
        drawPet(species, pixel: pixel, in: context)
    }

    /// Draws the faint 4-cell backdrop grid, matching the on-screen LCD.
    private static func drawGrid(pixel: RGB, in context: CGContext) {
        fill(pixel, alpha: 0.06, in: context)
        let thickness: CGFloat = 1
        for col in stride(from: 0, through: columns, by: LCDGeometry.gridStride) {
            context.fill(CGRect(
                x: CGFloat(col * pixelScale), y: 0, width: thickness, height: CGFloat(rows * pixelScale)
            ))
        }
        for row in stride(from: 0, through: rows, by: LCDGeometry.gridStride) {
            context.fill(CGRect(
                x: 0, y: CGFloat(row * pixelScale), width: CGFloat(columns * pixelScale), height: thickness
            ))
        }
    }

    /// Draws the ground band and the scattered grass tufts sitting just above it.
    private static func drawGround(pixel: RGB, in context: CGContext) {
        fill(pixel, alpha: 0.12, in: context)
        context.fill(CGRect(
            x: 0, y: LCDGeometry.groundRow * pixelScale, width: columns * pixelScale, height: pixelScale
        ))
        fill(pixel, alpha: 0.10, in: context)
        for col in LCDGeometry.tuftColumns {
            fillCell(x: col, y: LCDGeometry.groundRow - 1, in: context)
        }
    }

    /// Draws a full moon in the top-right with a few stars kept clear of the pet.
    private static func drawNightSky(pixel: RGB, in context: CGContext) {
        fill(pixel, alpha: 1, in: context)
        for disc in LCDGeometry.moonDisc {
            fillCell(x: LCDGeometry.moonCenter.x + disc.dx, y: LCDGeometry.moonCenter.y + disc.dy, in: context)
        }
        for star in LCDGeometry.starSpots {
            fillCell(x: star.x, y: star.y, in: context)
        }
    }

    private static func drawPet(_ species: PetSpecies, pixel: RGB, in context: CGContext) {
        let frame = SpriteCatalog.frames(for: species, kind: .idle).first ?? .empty
        fill(pixel, alpha: 1, in: context)
        for y in 0..<SpriteFrame.size {
            for x in 0..<SpriteFrame.size where frame.pixel(x: x, y: y) {
                fillCell(x: x + petOffsetX, y: y, in: context)
            }
        }
    }

    // MARK: - Primitives

    private static func fill(_ color: RGB, alpha: CGFloat, in context: CGContext) {
        context.setFillColor(red: color.r, green: color.g, blue: color.b, alpha: alpha)
    }

    private static func fillCell(x: Int, y: Int, in context: CGContext) {
        context.fill(CGRect(
            x: x * pixelScale, y: y * pixelScale, width: pixelScale, height: pixelScale
        ))
    }
}
