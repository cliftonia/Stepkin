import Testing
import Foundation
import StepkinCore
@testable import StepkinEngine
import StepkinTestSupport

/// What one long catch-up owes the pet: the same outcome watching it would
/// have given. Each test is a span the app can really leave unwatched.
@Suite("GameEngine catch-up")
struct GameEngineCatchUpTests {

    private func clock(hour: Int, minute: Int = 0, daysFromNow days: Int = 0) -> Date {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: days, to: .now) ?? .now
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    // MARK: - Refilled hearts

    /// A feed between two ticks refills a heart that then empties again
    /// unseen; the neglect before the feed must not be billed a second time.
    @Test
    func `a heart fed and emptied again between ticks is billed from the second emptying`() {
        let eight = clock(hour: 8)
        var state = makeTestState(hunger: 0, at: eight)
        state = GameEngine.advance(state, to: eight.addingTimeInterval(60), isNight: false, steps: .unavailable, calendar: .current)
        state = FeedAction.apply(to: state, food: .meat, at: eight.addingTimeInterval(60))

        state = GameEngine.advance(
            state, to: eight.addingTimeInterval(60 + 7_200), isNight: false, steps: .unavailable, calendar: .current
        )

        // The meat lasts until 09:10; 51 minutes of neglect follow by 10:01.
        #expect(state.careMistakes == 2)
    }

    @Test
    func `a heart won back in training and emptied again is billed from the second emptying`() {
        let eight = clock(hour: 8)
        var state = makeTestState(strength: 0, at: eight)
        state = GameEngine.advance(state, to: eight.addingTimeInterval(60), isNight: false, steps: .unavailable, calendar: .current)
        state = TrainAction.applyResult(to: state, won: true, at: eight.addingTimeInterval(60))
        let before = state.careMistakes

        state = GameEngine.advance(
            state, to: eight.addingTimeInterval(60 + 7_200), isNight: false, steps: .unavailable, calendar: .current
        )

        // The heart lasts until 09:00; 61 minutes of neglect follow by 10:01.
        #expect(state.careMistakes - before == 3)
    }

    @Test
    func `a feed resets the collapse countdown even when no tick sees the fed pet`() {
        let eight = clock(hour: 8)
        var state = makeTestState(hunger: 0, strength: 0, at: eight)
        state = GameEngine.advance(state, to: eight.addingTimeInterval(3 * 3_600), isNight: false, steps: .unavailable, calendar: .current)
        #expect(state.timestamps.collapsingAt != nil)
        state = FeedAction.apply(to: state, food: .meat, at: eight.addingTimeInterval(3 * 3_600))

        state = GameEngine.advance(state, to: eight.addingTimeInterval(5 * 3_600), isNight: false, steps: .unavailable, calendar: .current)

        // Fed at 11:00 with the hunger anchor at 10:20, the meat is gone at 11:30.
        #expect(state.timestamps.collapsingAt == eight.addingTimeInterval(3 * TimeConstants.hungerDepletionInterval))
    }

    // MARK: - Bedtime catch-up

    private func nightAway(lastSeen: Date, weatherNight: Bool?, prepare: (inout PetState) -> Void) -> PetState {
        var state = makeTestState(at: lastSeen)
        prepare(&state)
        state = GameEngine.advance(
            state, to: lastSeen.addingTimeInterval(20), isNight: weatherNight, steps: .unavailable, calendar: .current
        )
        return GameEngine.advance(
            state, to: clock(hour: 7, minute: 30), isNight: nil, steps: .unavailable, calendar: .current
        )
    }

    /// The settle needs a tick two minutes after the light goes out; a wrist
    /// dropped sooner must not leave the pet awake and draining all night.
    @Test
    func `a light put out late, then no tick till morning, is still a night slept`() {
        let lateEvening = clock(hour: 22, minute: 30, daysFromNow: -1)
        let state = nightAway(lastSeen: lateEvening, weatherNight: nil) { pet in
            pet = LightsAction.apply(to: pet, night: true, at: lateEvening).state
        }

        #expect(state.hungerHearts.value == 3)
        #expect(state.poopCount == 0)
        #expect(state.careMistakes == 0)
    }

    @Test
    func `a pet last seen in bedtime daylight, then no tick till morning, is still a night slept`() {
        let state = nightAway(lastSeen: clock(hour: 21, minute: 10, daysFromNow: -1), weatherNight: false) { _ in }

        #expect(state.hungerHearts.value == 3)
        #expect(state.poopCount == 0)
        #expect(state.careMistakes == 0)
    }

    /// A sky still light after nine keeps the pet up; looks during that time
    /// must not put it to bed by the clock and wake it again, which would
    /// restart its hunger clock at every look.
    @Test
    func `looks in bedtime daylight do not restart the hunger clock`() {
        let eight = clock(hour: 20)
        var state = makeTestState(hunger: 4, at: eight)
        for minutes in [85.0, 105, 125] {
            state = GameEngine.advance(
                state, to: eight.addingTimeInterval(minutes * 60), isNight: false, steps: .unavailable, calendar: .current
            )
        }

        // 70 minutes a heart from 20:00: one gone by 22:05.
        #expect(state.hungerHearts.value == 3)
        #expect(!state.isSleeping)
    }

    /// A light the player leaves on through the night costs lights mistakes;
    /// the count must not depend on whether a tick happened to land before dawn.
    @Test
    func `one catch-up over a lit night bills what hourly ticks bill`() {
        let lateEvening = clock(hour: 23, minute: 30, daysFromNow: -1)
        var lit = makeTestState(at: lateEvening)
        lit = GameEngine.advance(lit, to: lateEvening.addingTimeInterval(1), isNight: nil, steps: .unavailable, calendar: .current)
        lit = LightsAction.apply(to: lit, night: true, at: lateEvening.addingTimeInterval(1)).state
        #expect(lit.lightsOn)

        let morning = clock(hour: 6, minute: 30)
        let once = GameEngine.advance(lit, to: morning, isNight: nil, steps: .unavailable, calendar: .current)
        var hourly = lit
        for hour in 1...7 {
            hourly = GameEngine.advance(
                hourly, to: lateEvening.addingTimeInterval(Double(hour) * 3_600), isNight: nil, steps: .unavailable, calendar: .current
            )
        }

        #expect(once.careMistakes == hourly.careMistakes)
        #expect(once.careMistakes >= 2)
    }

    /// Up before six under a sky already light, the pet is in its day; the
    /// catch-up that crosses six must not put it back to bed for the clock's
    /// last hour of night and restart its clocks at dawn.
    @Test(arguments: [Optional(false), nil])
    func `a pet up in early daylight is not put back to bed by the catch-up over dawn`(signalAfterDawn: Bool?) {
        let early = clock(hour: 4, minute: 30)
        var state = makeTestState(hunger: 4, at: early)
        state = GameEngine.advance(state, to: early.addingTimeInterval(40 * 60), isNight: false, steps: .unavailable, calendar: .current)

        state = GameEngine.advance(
            state, to: clock(hour: 6, minute: 30), isNight: signalAfterDawn, steps: .unavailable, calendar: .current
        )

        // Two hours awake from 04:30 at 70 minutes a heart.
        #expect(state.hungerHearts.value == 3)
    }

    /// A light sky seen before the clock's dawn says the night is over, not
    /// that it never happened: the evening behind it was still slept.
    @Test
    func `a daylight reading before six still counts the night behind it as slept`() {
        let evening = clock(hour: 20, daysFromNow: -1)
        var state = makeTestState(hunger: 4, at: evening)
        state = GameEngine.advance(state, to: evening.addingTimeInterval(10), isNight: nil, steps: .unavailable, calendar: .current)

        state = GameEngine.advance(state, to: clock(hour: 5, minute: 30), isNight: false, steps: .unavailable, calendar: .current)

        #expect(state.hungerHearts.value == 4)
        #expect(state.poopCount == 0)
        #expect(!state.isSleeping)
    }

    /// The six hours an injury may go untreated run from the injury, which a
    /// long catch-up must date to the pile that caused it, not to its own end.
    @Test
    func `a catch-up dates a mess injury to the pile that caused it`() {
        let dawn = clock(hour: 6)
        let state = makeTestState(at: dawn)

        let advanced = GameEngine.advance(
            state, to: dawn.addingTimeInterval(11 * 3_600), isNight: false, steps: .unavailable, calendar: .current
        )

        #expect(advanced.isInjured)
        #expect(advanced.timestamps.injuredAt == dawn.addingTimeInterval(Double(TimeConstants.maxPoopPiles) * TimeConstants.poopInterval))
    }

    /// Today's step count says nothing of yesterday: a morning catch-up must
    /// not replay an active evening as a sedentary one and injure the pet a
    /// pile early.
    @Test
    func `this morning's step count does not judge yesterday evening`() {
        let evening = clock(hour: 19, daysFromNow: -1)
        var state = makeTestState(at: evening)
        state = GameEngine.advance(state, to: evening.addingTimeInterval(1), isNight: nil, steps: .count(9_000), calendar: .current)
        state.poopCount = TimeConstants.maxPoopPiles - 2
        state.timestamps.lastPoopAt = evening.addingTimeInterval(-3_600)

        let morning = GameEngine.advance(state, to: clock(hour: 7), isNight: nil, steps: .count(300), calendar: .current)

        // The third pile lands at 20:00; only a sedentary day makes three an injury.
        #expect(!morning.isDead)
        #expect((morning.timestamps.injuredAt ?? .distantFuture) >= clock(hour: 6))
    }

    /// A light the owner puts on in a dark morning belongs to that night. A
    /// day with no tick must still end it, or dusk finds nothing to put out.
    @Test
    func `a light put on in a dark morning is out by the next evening`() {
        let darkMorning = clock(hour: 6, minute: 30, daysFromNow: -1)
        var state = makeTestState(at: darkMorning.addingTimeInterval(-60))
        state = GameEngine.advance(state, to: darkMorning, isNight: true, steps: .unavailable, calendar: .current)
        state = LightsAction.apply(to: state, night: true, at: darkMorning).state
        #expect(state.lightsOn)

        let evening = GameEngine.advance(
            state, to: clock(hour: 19, daysFromNow: -1), isNight: nil, steps: .unavailable, calendar: .current
        )

        #expect(!evening.lightsOn)
    }
}
