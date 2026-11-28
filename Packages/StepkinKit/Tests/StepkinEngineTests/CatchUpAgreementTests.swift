import Testing
import Foundation
import StepkinCore
@testable import StepkinEngine
import StepkinTestSupport

/// The engine's promise is that time away costs what time watched costs: one
/// long catch-up must leave the pet where 30-second ticks over the same span
/// leave it. Background wakes are never guaranteed, so every disagreement is
/// a pet whose fate depends on luck.
@Suite("Catch-up agreement")
struct CatchUpAgreementTests {

    struct Span: Sendable, CustomTestStringConvertible {
        let startHour: Int
        let gapHours: Int
        let lightLeftOn: Bool
        var testDescription: String { "\(startHour):20 +\(gapHours)h light \(lightLeftOn ? "on" : "auto")" }
    }

    static let spans: [Span] = (0..<24).flatMap { hour in
        [1, 5, 14].flatMap { gap in
            [false, true].map { Span(startHour: hour, gapHours: gap, lightLeftOn: $0) }
        }
    }

    private func start(_ span: Span) -> (state: PetState, date: Date) {
        let calendar = Calendar.current
        let base = calendar.date(bySettingHour: span.startHour, minute: 20, second: 0, of: Date(timeIntervalSince1970: 1_700_000_000)) ?? .now
        // A pet that has lived through the hour before, so its light and sleep match the clock.
        var state = makeTestState(at: base.addingTimeInterval(-3_600))
        state = GameEngine.advance(state, to: base.addingTimeInterval(-1_800), isNight: nil, steps: .unavailable, calendar: calendar)
        if span.lightLeftOn {
            let lit = LightsAction.apply(to: state, night: true, at: base.addingTimeInterval(-1_800)).state
            if lit.lightsOn { state = lit }
        }
        state = GameEngine.advance(state, to: base, isNight: nil, steps: .unavailable, calendar: calendar)
        return (state, base)
    }

    @Test(arguments: spans)
    func `one catch-up agrees with 30 second ticks`(span: Span) {
        let (state, base) = start(span)
        let end = base.addingTimeInterval(Double(span.gapHours) * 3_600)

        let once = GameEngine.advance(state, to: end, isNight: nil, steps: .unavailable, calendar: .current)
        var ticked = state
        var moment = base
        while moment < end {
            moment = min(end, moment.addingTimeInterval(TimeConstants.gameTickInterval))
            ticked = GameEngine.advance(ticked, to: moment, isNight: nil, steps: .unavailable, calendar: .current)
        }

        // A long step can only notice a death at its end, so the dead are
        // compared no further: what a corpse's light is doing is of no account.
        #expect(once.isDead == ticked.isDead)
        guard !once.isDead, !ticked.isDead else { return }
        #expect(once.isSleeping == ticked.isSleeping)
        #expect(once.lightsOn == ticked.lightsOn)
        #expect(once.isInjured == ticked.isInjured)
        // One interval of slack: a decay due inside the two-minute settle
        // falls on one side or the other.
        #expect(abs(once.hungerHearts.value - ticked.hungerHearts.value) <= 1)
        #expect(abs(once.strengthHearts.value - ticked.strengthHearts.value) <= 1)
        #expect(abs(once.poopCount - ticked.poopCount) <= 1)
        #expect(abs(once.careMistakes - ticked.careMistakes) <= 1)
    }
}
