import SwiftUI

// MARK: - Clear-Sky Bodies (Sun, Moon, Stars)
//
// The celestial cell generators for the clear condition, split out of
// LCDDisplay+Weather to keep that file under the length limit. `internal`
// (not private) so the weather dispatch can reach them across files.

extension LCDDisplay {

    /// A round corner sun — a disc with eight rays that pulse short→long,
    /// plus an occasional twinkle in the far corner.
    static func sunCells(phase: Int) -> [(x: Int, y: Int)] {
        let cx = 25, cy = 6
        let disc = [
            (-1, -2), (0, -2), (1, -2),
            (-2, -1), (-1, -1), (0, -1), (1, -1), (2, -1),
            (-2, 0), (-1, 0), (0, 0), (1, 0), (2, 0),
            (-2, 1), (-1, 1), (0, 1), (1, 1), (2, 1),
            (-1, 2), (0, 2), (1, 2)
        ]
        var cells = disc.map { (x: cx + $0.0, y: cy + $0.1) }
        let rayLength = 1 + (phase / 4) % 2
        for (ddx, ddy) in [(0, -1), (0, 1), (-1, 0), (1, 0)] {
            for r in 4..<(4 + rayLength) {
                cells.append((x: cx + ddx * r, y: cy + ddy * r))
            }
        }
        for (ddx, ddy) in [(-1, -1), (1, -1), (-1, 1), (1, 1)] {
            for r in 3..<(3 + rayLength) {
                cells.append((x: cx + ddx * r, y: cy + ddy * r))
            }
        }
        if (phase / 3) % 4 == 0 {
            let sx = 4, sy = 3
            cells += [(sx, sy), (sx - 1, sy), (sx + 1, sy), (sx, sy - 1), (sx, sy + 1)]
        }
        return cells
    }

    /// Scattered stars that twinkle, brightening to a cross at their peak.
    /// (Stars steer clear of the top-right where the moon sits.)
    static func starCells(phase: Int) -> [(x: Int, y: Int)] {
        let spots = [(4, 2), (10, 5), (16, 3), (21, 9), (7, 11), (14, 13), (3, 8)]
        var cells: [(x: Int, y: Int)] = []
        for (index, spot) in spots.enumerated() {
            guard (phase / 2 + index * 2) % 6 < 4 else { continue }
            cells.append((x: spot.0, y: spot.1))
            if (phase / 2 + index) % 6 == 0 {
                cells += [
                    (spot.0 - 1, spot.1), (spot.0 + 1, spot.1),
                    (spot.0, spot.1 - 1), (spot.0, spot.1 + 1)
                ]
            }
        }
        return cells
    }

    /// The full moon disc — always drawn (dim), so the shadowed side still shows.
    static func moonDiscCells() -> [(x: Int, y: Int)] {
        LCDGeometry.moonDisc.map { (x: LCDGeometry.moonCenter.x + $0.dx, y: LCDGeometry.moonCenter.y + $0.dy) }
    }

    /// The lit fraction of the moon for the given phase (waxing lit on the
    /// right; terminator vertical) — drawn bright over the dim disc.
    static func moonLitCells(_ moonPhase: MoonPhase) -> [(x: Int, y: Int)] {
        /// Reports whether the disc column at offset `dx` from the moon's centre is
        /// lit for this phase; offsets are positive rightward.
        func isLit(_ dx: Int) -> Bool {
            switch moonPhase {
            case .new: return false
            case .full: return true
            case .firstQuarter: return dx >= 0
            case .lastQuarter: return dx <= 0
            case .waxingCrescent: return dx >= 2
            case .waningCrescent: return dx <= -2
            case .waxingGibbous: return dx >= -1
            case .waningGibbous: return dx <= 1
            }
        }
        return LCDGeometry.moonDisc.filter { isLit($0.dx) }
            .map { (x: LCDGeometry.moonCenter.x + $0.dx, y: LCDGeometry.moonCenter.y + $0.dy) }
    }

    /// A meteor streaking down-right with a short trail, every ~44 frames.
    static func shootingStarCells(phase: Int) -> [(x: Int, y: Int)] {
        let cycle = phase % 44
        guard cycle < 6 else { return [] }
        let hx = 3 + cycle * 5
        let hy = 1 + cycle * 2
        return [
            (x: hx, y: hy), (x: hx - 1, y: hy),
            (x: hx - 2, y: hy - 1), (x: hx - 3, y: hy - 1),
            (x: hx - 4, y: hy - 2)
        ]
    }

}
