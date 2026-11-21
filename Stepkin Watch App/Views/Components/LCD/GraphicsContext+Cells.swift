import SwiftUI

// MARK: - LCD Cell Fills
//
// Every LCD layer draws by filling grid cells. The +0.5 bleed keeps adjacent
// cells seamless when the pixel size is non-integer.

extension GraphicsContext {

    /// Fills one grid cell, bleeding 0.5 past its width and height so adjacent
    /// cells stay seamless when the pixel size is non-integer.
    func fillCell(
        x: Int,
        y: Int,
        pixelWidth: CGFloat,
        pixelHeight: CGFloat,
        color: Color
    ) {
        let rect = CGRect(
            x: Double(x) * pixelWidth,
            y: Double(y) * pixelHeight,
            width: pixelWidth + 0.5,
            height: pixelHeight + 0.5
        )
        fill(Path(rect), with: .color(color))
    }

    /// Fills a list of cells, skipping any outside the 32×20 LCD grid.
    func fillLCDCells(
        _ cells: [(x: Int, y: Int)],
        pixelWidth: CGFloat,
        pixelHeight: CGFloat,
        color: Color
    ) {
        for cell in cells where cell.x >= 0 && cell.x < 32 && cell.y >= 0 && cell.y < 20 {
            fillCell(
                x: cell.x, y: cell.y,
                pixelWidth: pixelWidth, pixelHeight: pixelHeight,
                color: color
            )
        }
    }
}
