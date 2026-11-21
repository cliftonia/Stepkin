import Foundation

// MARK: - Battle "VS" Flash

extension LCDDisplay {

    /// True on every third `phase`, strobing the short battle "VS" beat.
    static func isVSFlash(_ phase: Int) -> Bool {
        phase % 3 == 0
    }

    /// Returns the "VS" glyph's set pixels, unpacked from `vsTextRows`.
    static func vsTextCells() -> [(x: Int, y: Int)] { cells(from: vsTextRows) }

    /// Returns the drop shadow's set pixels, unpacked from `vsShadowRows`.
    static func vsShadowCells() -> [(x: Int, y: Int)] { cells(from: vsShadowRows) }

    /// Bold italic "VS" spanning the LCD, centred, one bit per pixel
    /// (bit 31 = col 0).
    private static let vsTextRows: [UInt32] = [
        0x00000000, 0x00000000, 0x00000000,
        0x381C7FF0, 0x381C7FF0, 0x1C387FF0, 0x1C387000,
        0x1CE0E000, 0x1CE0FFF0, 0x1CE0FFF0, 0x0FC0FFF0,
        0x1F8000E0, 0x1F8000E0, 0x0F0000E0, 0x1E03FFC0,
        0x1E03FFC0, 0x1E03FFC0, 0x00000000, 0x00000000, 0x00000000
    ]

    /// The matching drop shadow, offset down-right by one pixel.
    private static let vsShadowRows: [UInt32] = [
        0x00000000, 0x00000000, 0x00000000, 0x00000000,
        0x04020008, 0x00060008, 0x02040FF8, 0x021C1800,
        0x02100000, 0x02100008, 0x00300008, 0x00607F18,
        0x00400010, 0x00C00010, 0x01800030, 0x01000020,
        0x01000020, 0x0F01FFE0, 0x00000000, 0x00000000
    ]

    private static func cells(from rows: [UInt32]) -> [(x: Int, y: Int)] {
        var cells: [(x: Int, y: Int)] = []
        for (y, row) in rows.enumerated() {
            for x in 0..<32 where (row >> (31 - x)) & 1 == 1 {
                cells.append((x: x, y: y))
            }
        }
        return cells
    }
}
