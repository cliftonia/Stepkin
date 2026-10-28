import SwiftUI

// MARK: - Scene Backdrop

extension LCDDisplay {

    /// Draws the backdrop's faint grid, with a line every fourth column and
    /// row and a dimmer wash on a dark screen.
    func drawGrid(
        in context: GraphicsContext,
        size: CGSize,
        pixelWidth: CGFloat,
        pixelHeight: CGFloat
    ) {
        let gridColor = basePixelColor.opacity(isDarkScreen ? 0.24 : 0.06)

        for col in stride(from: 0, through: LCDGeometry.columns, by: LCDGeometry.gridStride) {
            let x = Double(col) * pixelWidth
            let line = Path(
                CGRect(
                    x: x, y: 0,
                    width: 0.5, height: size.height
                )
            )
            context.fill(line, with: .color(gridColor))
        }
        for row in stride(from: 0, through: LCDGeometry.rows, by: LCDGeometry.gridStride) {
            let y = Double(row) * pixelHeight
            let line = Path(
                CGRect(
                    x: 0, y: y,
                    width: size.width, height: 0.5
                )
            )
            context.fill(line, with: .color(gridColor))
        }
    }

    /// Draws the ground line on the ground row and a tuft of grass one row above it
    /// at seven fixed columns, dimmer on a dark screen.
    func drawGround(
        in context: GraphicsContext,
        size: CGSize,
        pixelWidth: CGFloat,
        pixelHeight: CGFloat
    ) {
        let groundColor = basePixelColor.opacity(isDarkScreen ? 0.34 : 0.12)

        let groundY = Double(LCDGeometry.groundRow) * pixelHeight
        let groundLine = Path(
            CGRect(
                x: 0, y: groundY,
                width: size.width, height: pixelHeight
            )
        )
        context.fill(groundLine, with: .color(groundColor))

        let tuftColor = basePixelColor.opacity(isDarkScreen ? 0.28 : 0.10)
        for col in LCDGeometry.tuftColumns {
            let rect = CGRect(
                x: Double(col) * pixelWidth,
                y: Double(LCDGeometry.groundRow - 1) * pixelHeight,
                width: pixelWidth,
                height: pixelHeight
            )
            context.fill(Path(rect), with: .color(tuftColor))
        }
    }
}
