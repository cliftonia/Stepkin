import Foundation

/// A 16x16 1-bit monochrome bitmap. Each UInt16 is one row, MSB = leftmost
/// pixel — the same encoding the Tools/ pipeline round-trips, so frames stay
/// diffable against their ASCII-art comments. Shifts discard pixels pushed
/// past an edge, and shift amounts outside 1..<16 are a no-op.
public struct SpriteFrame: Sendable, Hashable {

    /// The bitmap's 16 rows, topmost first.
    public let rows: [UInt16]

    /// Creates a frame; traps unless `rows` contains exactly 16 rows.
    public init(rows: [UInt16]) {
        precondition(rows.count == 16, "SpriteFrame must have exactly 16 rows")
        self.rows = rows
    }

    /// Whether the pixel at (x, y) is lit. x=0 is leftmost, y=0 is topmost;
    /// out-of-bounds coordinates read as off rather than trapping, so callers
    /// can probe neighbours without bounds checks.
    public func pixel(x: Int, y: Int) -> Bool {
        guard x >= 0, x < Self.size, y >= 0, y < Self.size else { return false }
        return (rows[y] >> (15 - x)) & 1 == 1
    }

    /// Flips the frame left-for-right; column x moves to column 15 - x.
    func mirrored() -> SpriteFrame {
        let mirroredRows = rows.map { row -> UInt16 in
            var result: UInt16 = 0
            for i in 0..<16 where (row >> i) & 1 == 1 {
                result |= 1 << (15 - i)
            }
            return result
        }
        return SpriteFrame(rows: mirroredRows)
    }

    /// Slides the frame n pixels up, discarding pixels past the top edge.
    func shiftedUp(_ n: Int) -> SpriteFrame {
        guard n > 0, n < Self.size else { return self }
        let shifted = Array(rows.suffix(Self.size - n))
            + [UInt16](repeating: 0, count: n)
        return SpriteFrame(rows: shifted)
    }

    /// Slides the frame n pixels down, discarding pixels past the bottom edge.
    func shiftedDown(_ n: Int) -> SpriteFrame {
        guard n > 0, n < Self.size else { return self }
        let shifted = [UInt16](repeating: 0, count: n)
            + Array(rows.prefix(Self.size - n))
        return SpriteFrame(rows: shifted)
    }

    /// Slides the frame n pixels left, discarding pixels past the left edge.
    func shiftedLeft(_ n: Int) -> SpriteFrame {
        guard n > 0, n < Self.size else { return self }
        return SpriteFrame(rows: rows.map { $0 << n })
    }

    /// Slides the frame n pixels right, discarding pixels past the right edge.
    func shiftedRight(_ n: Int) -> SpriteFrame {
        guard n > 0, n < Self.size else { return self }
        return SpriteFrame(rows: rows.map { $0 >> n })
    }

    /// Overlays another frame using bitwise OR.
    public func overlaying(_ other: SpriteFrame) -> SpriteFrame {
        SpriteFrame(rows: zip(rows, other.rows).map { $0 | $1 })
    }

    /// The enclosed "holes": off pixels unreachable from the border through
    /// other off pixels (4-connected) - eyes, mouths, any gap walled in by the
    /// body. The renderer fills these with a dim, opaque colour so the animated
    /// backdrop can't show through the creature. Gaps that open to the edge
    /// (e.g. the space between two legs) stay empty and keep showing the scene.
    public func interiorHoles() -> SpriteFrame {
        let n = Self.size
        var exterior = [Bool](repeating: false, count: n * n)
        var stack: [(x: Int, y: Int)] = []

        /// Marks the off pixel at (x, y) as exterior and pushes it onto the
        /// flood-fill stack; lit, already-marked, and out-of-bounds pixels are
        /// ignored, so call sites can pass every candidate guard-free.
        func markExterior(_ x: Int, _ y: Int) {
            guard x >= 0, x < n, y >= 0, y < n else { return }
            guard !pixel(x: x, y: y), !exterior[y * n + x] else { return }
            exterior[y * n + x] = true
            stack.append((x, y))
        }

        for i in 0..<n {
            markExterior(i, 0); markExterior(i, n - 1)
            markExterior(0, i); markExterior(n - 1, i)
        }
        while let (x, y) = stack.popLast() {
            markExterior(x + 1, y); markExterior(x - 1, y)
            markExterior(x, y + 1); markExterior(x, y - 1)
        }

        var holeRows = [UInt16](repeating: 0, count: n)
        for y in 0..<n {
            for x in 0..<n where !pixel(x: x, y: y) && !exterior[y * n + x] {
                holeRows[y] |= 1 << (15 - x)
            }
        }
        return SpriteFrame(rows: holeRows)
    }

    /// A frame with every pixel off.
    public static let empty = SpriteFrame(
        rows: [UInt16](repeating: 0, count: 16)
    )

    /// The frame's width and height in pixels.
    public static let size = 16
}
