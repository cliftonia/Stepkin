import Testing
@testable import imon_Watch_App

/// Checks that the LCD's shared cell layout stays on the screen it describes.
struct LCDGeometryTests {

    @Test func `the moon disc has 37 cells all inside the screen`() {
        let cells = LCDGeometry.moonDisc.map {
            (x: LCDGeometry.moonCenter.x + $0.dx, y: LCDGeometry.moonCenter.y + $0.dy)
        }
        #expect(cells.count == 37)
        #expect(cells.allSatisfy { (0..<LCDGeometry.columns).contains($0.x) && (0..<LCDGeometry.rows).contains($0.y) })
    }

    @Test func `every star is inside the screen`() {
        #expect(LCDGeometry.starSpots.count == 6)
        #expect(LCDGeometry.starSpots.allSatisfy {
            (0..<LCDGeometry.columns).contains($0.x) && (0..<LCDGeometry.rows).contains($0.y)
        })
    }
}
