import Testing
import Foundation
@testable import StepkinCore

@Suite("TickMath")
struct TickMathTests {

    private static let base = Date(timeIntervalSinceReferenceDate: 0)

    @Test(arguments: [
        (span: 0.0, interval: 60.0, expected: 0),         // zero span
        (span: -10.0, interval: 60.0, expected: 0),       // backward clock
        (span: 59.9, interval: 60.0, expected: 0),        // just under one interval
        (span: 60.0, interval: 60.0, expected: 1),        // exact boundary
        (span: 120.5, interval: 60.0, expected: 2),       // rounds down, not to nearest
        (span: 10.0, interval: 0.0, expected: 0),         // zero interval guard
        (span: 10.0, interval: -1.0, expected: 0),        // negative interval guard
    ])
    func `whole intervals with span and interval guards`(
        span: TimeInterval, interval: TimeInterval, expected: Int
    ) {
        let ticks = TickMath.ticks(
            from: Self.base,
            to: Self.base.addingTimeInterval(span),
            interval: interval
        )
        #expect(ticks == expected)
    }

    @Test
    func `non-finite elapsed span yields zero ticks`() {
        let ticks = TickMath.ticks(
            from: Self.base,
            to: Date(timeIntervalSinceReferenceDate: .infinity),
            interval: 60
        )
        #expect(ticks == 0)
    }

    @Test
    func `astronomical tick counts clamp to Int max without trapping`() {
        // 1e15 s / 1e-9 s = 1e24 whole intervals — above Int.max on both the
        // 64-bit simulator and 32-bit watch hardware, so the clamp must fire
        // instead of the bare Int(largeDouble) trap the guard exists to prevent.
        let ticks = TickMath.ticks(
            from: Self.base,
            to: Date(timeIntervalSinceReferenceDate: 1e15),
            interval: 1e-9
        )
        #expect(ticks == Int.max)
    }
}
