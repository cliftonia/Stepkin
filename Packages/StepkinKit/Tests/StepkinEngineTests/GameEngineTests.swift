import Testing
import Foundation
import StepkinCore
@testable import StepkinEngine
import StepkinTestSupport

@Suite("GameEngine")
struct GameEngineTests {

    @Test
    func `advance updates age in days`() {
        // Born three days ago but tended an hour ago — age is measured from
        // birth, not from the last tick, and a tended pet does not collapse.
        let born = Date.now.addingTimeInterval(-86400 * 3)
        var state = makeTestState(at: .now.addingTimeInterval(-3600))
        state.timestamps.bornAt = born

        state = GameEngine.advance(state, to: .now, isNight: nil, steps: .unavailable, calendar: .current)
        #expect(state.age >= 3)
    }

    private func clock(hour: Int, minute: Int = 0, daysFromNow days: Int = 0) -> Date {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: days, to: .now) ?? .now
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    @Test
    func `a night's sleep pauses hunger, strength and poop instead of deferring them`() {
        let tonight = clock(hour: 22)
        let dawn = clock(hour: TimeConstants.nightEndHour, daysFromNow: 1)
        var state = makeTestState(hunger: 4, strength: 4, at: tonight)
        state.isSleeping = true
        state.lightsOn = false
        state.wasNight = true

        // Half an hour after the clock's dawn: the replay woke the pet at dawn.
        state = GameEngine.advance(state, to: clock(hour: 6, minute: 30, daysFromNow: 1), isNight: false, steps: .unavailable, calendar: .current)

        #expect(state.isSleeping == false)
        #expect(state.hungerHearts.value == 4)
        #expect(state.strengthHearts.value == 4)
        #expect(state.poopCount == 0)
        #expect(state.isInjured == false)
        #expect(state.timestamps.lastHungerDecayAt == dawn)
    }

    /// The bug Kimi's review named: closed at 5pm and reopened after dawn, the
    /// old single-step catch-up never saw dusk or bedtime, so the pet was
    /// charged fifteen waking hours. The replay puts it to bed at 21:02.
    @Test
    func `a night the app never saw is slept through, not charged`() {
        let afternoon = clock(hour: 17)
        var state = makeTestState(hunger: 4, strength: 4, at: afternoon)
        state.lightsOn = true
        state.wasNight = false

        state = GameEngine.advance(state, to: clock(hour: 6, minute: 30, daysFromNow: 1), isNight: nil, steps: .unavailable, calendar: .current)

        // Awake 17:00 → 21:02 only: 3 hunger ticks (70 min), 4 strength (60 min), 2 poops (2 h).
        #expect(state.hungerHearts.value == 1)
        #expect(state.strengthHearts.value == 0)
        #expect(state.poopCount == 2)
        #expect(state.isInjured == false)
        #expect(state.isSleeping == false)
        #expect(state.lightsOn == true)
    }

    @Test
    func `a pet left for days still collapses during the replay`() {
        var state = makeTestState(hunger: 1, strength: 1, at: clock(hour: 10))
        state.lightsOn = true

        state = GameEngine.advance(state, to: clock(hour: 10, daysFromNow: 4), isNight: nil, steps: .unavailable, calendar: .current)

        #expect(state.isDead == true)
    }

    @Test
    func `dead pet is not advanced`() {
        var state = makeTestState(hunger: 4)
        state.isDead = true
        let original = state
        state = GameEngine.advance(state, to: .now, isNight: nil, steps: .unavailable, calendar: .current)
        #expect(
            state.hungerHearts.value
                == original.hungerHearts.value
        )
    }

    @Test
    func `a starved and weak pet collapses to death over time`() {
        let start = Date.now
        var state = makeTestState(hunger: 0, strength: 0, at: start)
        state.timestamps.lastHungerDecayAt = start
        state.timestamps.lastStrengthDecayAt = start

        // First advance arms the collapse countdown but doesn't kill yet.
        state = GameEngine.advance(state, to: start.addingTimeInterval(60), isNight: nil, steps: .unavailable, calendar: .current)
        #expect(state.isDead == false)
        #expect(state.timestamps.collapsingAt != nil)

        // Left languishing past the window, it perishes.
        state = GameEngine.advance(
            state, to: start.addingTimeInterval(TimeConstants.collapseDeathTime + 120), isNight: nil, steps: .unavailable, calendar: .current
        )
        #expect(state.isDead)
    }

    @Test
    func `an egg stays frozen across days until it hatches`() {
        let born = Date.now.addingTimeInterval(-86400 * 5)
        var state = PetState.hatched(at: .now)
        state.isEgg = true
        state.timestamps.bornAt = born
        let original = state

        // Five days on, the engine must still short-circuit the egg: it neither
        // hatches itself nor drains the stats the simulators would touch.
        state = GameEngine.advance(state, to: .now, isNight: nil, steps: .unavailable, calendar: .current)
        #expect(state.isEgg)
        #expect(state.hungerHearts.value == original.hungerHearts.value)
        #expect(state.poopCount == original.poopCount)
    }

    // Parity: the reading's count reaches the simulators exactly as the old optional did.
    private func daytimeHunger(steps: StepReading) -> (engine: Int, direct: Int) {
        let start = clock(hour: 10)
        let end = start.addingTimeInterval(TimeConstants.hungerDepletionInterval * 3)
        var state = makeTestState(hunger: 4, at: start)
        state.timestamps.lastHungerDecayAt = start
        let advanced = GameEngine.advance(state, to: end, isNight: false, steps: steps, calendar: .current)
        let direct = HungerSimulator.apply(to: state, at: end, steps: steps.count)
        return (advanced.hungerHearts.value, direct.hungerHearts.value)
    }

    @Test
    func `a count reading drains hunger as the plain count did`() {
        let result = daytimeHunger(steps: .count(ActivityModel.stepGoal))
        #expect(result.engine == result.direct)
        #expect(result.engine < daytimeHunger(steps: .count(0)).engine)
    }

    @Test
    func `an unavailable reading drains hunger as no count did`() {
        let result = daytimeHunger(steps: .unavailable)
        #expect(result.engine == result.direct)
    }
}
