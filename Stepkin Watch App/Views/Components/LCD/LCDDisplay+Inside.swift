import SwiftUI

// MARK: - Inside (Room)
//
// Cozy-corner layout: a window on the back wall (top-right) showing the sky,
// a small light hanging from the ceiling (centre), and a potted plant in the
// bottom-left corner. The window and plant are dim (background); the hanging
// light is solid (foreground). The pet stands in front of it all.

extension LCDDisplay {

    /// Ambient room lighting: a bright pool under the lamp fading to a dim room.
    func drawRoomGlow(
        in context: GraphicsContext,
        size: CGSize,
        pixelWidth: CGFloat,
        pixelHeight: CGFloat
    ) {
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: roomGlowShading(pixelWidth: pixelWidth, pixelHeight: pixelHeight)
        )
    }

    /// The lamp-lit room gradient — bright pool under the lamp fading to the
    /// ambient shade. Shared by `drawRoomGlow` and the indoor eye-hole backing
    /// so the eyes match the wall behind them exactly, wherever the pet stands.
    func roomGlowShading(
        pixelWidth: CGFloat,
        pixelHeight: CGFloat
    ) -> GraphicsContext.Shading {
        let center = CGPoint(x: 10.5 * pixelWidth, y: 2.5 * pixelHeight)
        let bright = Color(red: 150 / 255, green: 184 / 255, blue: 118 / 255)
        return .radialGradient(
            Gradient(colors: [bright, Self.roomAmbientColor]),
            center: center,
            startRadius: 0,
            endRadius: 32 * pixelWidth * 0.72
        )
    }

    /// The dark night pane behind the window content.
    func drawWindowPane(
        in context: GraphicsContext,
        pixelWidth: CGFloat,
        pixelHeight: CGFloat
    ) {
        let pane = CGRect(
            x: Double(Self.windowCols.lowerBound) * pixelWidth,
            y: Double(Self.windowRows.lowerBound) * pixelHeight,
            width: Double(Self.windowCols.count) * pixelWidth,
            height: Double(Self.windowRows.count) * pixelHeight
        )
        context.fill(Path(pane), with: .color(Color(white: 0.07)))
    }

    /// The room dressing: dim plant and window frame (background) and the solid
    /// hanging light with its gleam (foreground).
    func drawRoomChrome(
        phase: Int,
        in context: GraphicsContext,
        pixelWidth: CGFloat,
        pixelHeight: CGFloat
    ) {
        /// Fills one cell list using the enclosing draw's context and pixel size.
        func fill(_ cells: [(x: Int, y: Int)], _ color: Color) {
            context.fillLCDCells(
                cells,
                pixelWidth: pixelWidth, pixelHeight: pixelHeight,
                color: color
            )
        }
        fill(Self.furnitureCells(), basePixelColor.opacity(0.35))
        fill(Self.windowFrameCells(), basePixelColor.opacity(0.45))
        fill(Self.lampCells(), basePixelColor)
        fill(Self.lampGleamCells(phase: phase), basePixelColor.opacity(0.5))
    }

    /// The window opening (inside the frame) where the sky/weather shows.
    static let windowCols = 21...28
    /// Row span of the same opening; stays one cell inside the border from `windowFrameCells`.
    static let windowRows = 2...9

    /// The window frame on the back wall - a clean border, no mullion bars.
    static func windowFrameCells() -> [(x: Int, y: Int)] {
        let x0 = 20, x1 = 29, y0 = 1, y1 = 10
        var cells: [(x: Int, y: Int)] = []
        for x in x0...x1 { cells.append((x: x, y: y0)); cells.append((x: x, y: y1)) }
        for y in y0...y1 { cells.append((x: x0, y: y)); cells.append((x: x1, y: y)) }
        return cells
    }

    /// A small light tucked up against the ceiling - tiny cord and bulb.
    static func lampCells() -> [(x: Int, y: Int)] {
        let cx = 10
        return [
            (x: cx, y: 0),                                      // ceiling mount
            (x: cx - 1, y: 1), (x: cx, y: 1), (x: cx + 1, y: 1),// bulb
            (x: cx - 1, y: 2), (x: cx, y: 2), (x: cx + 1, y: 2),
            (x: cx, y: 3)                                       // tip
        ]
    }

    /// Pulsing gleam around the hanging bulb - drawn dimmer, like a glow.
    static func lampGleamCells(phase: Int) -> [(x: Int, y: Int)] {
        guard (phase / 3) % 2 == 0 else { return [] }
        let cx = 10
        return [(x: cx - 3, y: 2), (x: cx + 3, y: 2), (x: cx, y: 5)]
    }

    /// Dim background dressing: a potted plant on the floor (bottom-left) and a
    /// wall shelf with books (top-left).
    static func furnitureCells() -> [(x: Int, y: Int)] {
        var cells: [(x: Int, y: Int)] = [
            // Potted plant, sitting on the floor.
            (x: 2, y: 13),                               // sprout
            (x: 1, y: 14), (x: 2, y: 14), (x: 3, y: 14), // leaves
            (x: 2, y: 15),                               // stem
            (x: 1, y: 16), (x: 3, y: 16),                // pot rim
            (x: 1, y: 17), (x: 2, y: 17), (x: 3, y: 17), // pot
            (x: 1, y: 18), (x: 2, y: 18), (x: 3, y: 18)  // on the floor
        ]
        // Wall shelf with a few books, top-left.
        let shelfY = 6
        for x in 1...6 { cells.append((x: x, y: shelfY)) }   // ledge
        cells += [
            (x: 2, y: shelfY - 1), (x: 2, y: shelfY - 2),    // tall book
            (x: 3, y: shelfY - 1),                           // short book
            (x: 5, y: shelfY - 1), (x: 5, y: shelfY - 2)     // tall book
        ]
        return cells
    }
}
