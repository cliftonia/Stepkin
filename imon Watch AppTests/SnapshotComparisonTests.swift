import Testing
@testable import imon_Watch_App

/// Pins the pixel comparison the snapshot assertions rely on.
struct SnapshotComparisonTests {

    private func bitmap(width: Int, height: Int, fill: UInt8 = 0) -> SnapshotBitmap {
        SnapshotBitmap(width: width, height: height, bytes: [UInt8](repeating: fill, count: width * height * 4))
    }

    @Test func `bitmaps differing in one pixel report exactly one`() {
        let base = bitmap(width: 2, height: 2)
        var bytes = base.bytes
        bytes[5] = 255
        let changed = SnapshotBitmap(width: 2, height: 2, bytes: bytes)
        #expect(base.differingPixels(from: changed) == 1)
        #expect(base.differingPixels(from: base) == 0)
    }

    @Test func `a size mismatch counts every pixel`() {
        let small = bitmap(width: 2, height: 2)
        let large = bitmap(width: 3, height: 2)
        #expect(small.differingPixels(from: large) == 4)
    }
}
