import Foundation
import Testing
@testable import Stepkin_Watch_App

@Suite("MoonPhase")
struct MoonPhaseTests {

    private let synodicMonth = 29.530588853
    private let referenceNewMoon = Date(timeIntervalSince1970: 947_182_440)

    private func date(daysAfterReference days: Double) -> Date {
        referenceNewMoon.addingTimeInterval(days * 86_400)
    }

    @Test
    func `reference instant is a new moon`() {
        #expect(MoonPhase.current(date: referenceNewMoon) == .new)
    }

    @Test
    func `quarter cycle is first quarter`() {
        #expect(MoonPhase.current(date: date(daysAfterReference: synodicMonth / 4)) == .firstQuarter)
    }

    @Test
    func `half cycle is full moon`() {
        #expect(MoonPhase.current(date: date(daysAfterReference: synodicMonth / 2)) == .full)
    }

    @Test
    func `three quarter cycle is last quarter`() {
        #expect(MoonPhase.current(date: date(daysAfterReference: synodicMonth * 3 / 4)) == .lastQuarter)
    }

    @Test
    func `phase repeats after a full synodic month`() {
        let base = MoonPhase.current(date: date(daysAfterReference: 3))
        let next = MoonPhase.current(date: date(daysAfterReference: 3 + synodicMonth))
        #expect(base == next)
    }
}
