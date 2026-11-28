import Testing
import Foundation
import StepkinCore
@testable import StepkinEngine
import StepkinTestSupport

@Suite("CareMistakeTracker")
struct CareMistakeTrackerTests {

    // MARK: - Hunger / strength neglect

    @Test
    func `neglect starts the countdown without an immediate mistake`() {
        let now = Date.now
        var state = makeTestState(hunger: 0, at: now)
        state.timestamps.pendingCareMistakeAt = nil

        state = CareMistakeTracker.apply(to: state, at: now, bedtime: false)
        #expect(state.careMistakes == 0)
        #expect(state.timestamps.pendingCareMistakeAt == now)
    }

    /// The app may first see an empty heart hours after it emptied; the
    /// neglect is billed from the emptying, so looking less never costs less.
    @Test
    func `a heart that emptied unseen is billed from when it emptied`() {
        let now = Date.now
        var state = makeTestState(hunger: 0, at: now)
        state.timestamps.hungerEmptiedAt = now.addingTimeInterval(-3 * TimeConstants.careMistakeWindow)

        state = CareMistakeTracker.apply(to: state, at: now, bedtime: false)
        #expect(state.careMistakes == 3)
        #expect(state.timestamps.pendingCareMistakeAt == now)
    }

    /// Sleep pauses neglect, so a pet that went to bed hungry is billed from
    /// the moment it wakes, never for the night.
    @Test
    func `a pet that wakes hungry is billed from the wake`() {
        let dawn = Date.now
        var state = makeTestState(hunger: 0, at: dawn)
        state.timestamps.hungerEmptiedAt = dawn.addingTimeInterval(-36_000)
        state.isSleeping = true

        state.wake(at: dawn)
        state = CareMistakeTracker.apply(
            to: state, at: dawn.addingTimeInterval(2 * TimeConstants.careMistakeWindow), bedtime: false
        )
        #expect(state.careMistakes == 2)
    }

    @Test
    func `neglect past the window counts a mistake`() {
        let now = Date.now
        var state = makeTestState(hunger: 0, at: now)
        state.timestamps.pendingCareMistakeAt =
            now.addingTimeInterval(-TimeConstants.careMistakeWindow)

        state = CareMistakeTracker.apply(to: state, at: now, bedtime: false)
        #expect(state.careMistakes == 1)
    }

    @Test
    func `empty strength alone past the window counts a mistake`() {
        // Hunger is full — this exercises the strength operand of needsAttention,
        // which the hunger-empty cases never reach.
        let now = Date.now
        var state = makeTestState(hunger: 4, strength: 0, at: now)
        state.timestamps.pendingCareMistakeAt =
            now.addingTimeInterval(-TimeConstants.careMistakeWindow)

        state = CareMistakeTracker.apply(to: state, at: now, bedtime: false)
        #expect(state.careMistakes == 1)
    }

    @Test
    func `recovery clears the pending countdown`() {
        let now = Date.now
        var state = makeTestState(hunger: 4, strength: 4, at: now)
        state.timestamps.pendingCareMistakeAt =
            now.addingTimeInterval(-TimeConstants.careMistakeWindow)

        state = CareMistakeTracker.apply(to: state, at: now, bedtime: false)
        #expect(state.careMistakes == 0)
        #expect(state.timestamps.pendingCareMistakeAt == nil)
    }

    @Test
    func `sleeping accrues no neglect and holds the pending clock at now`() {
        // Held at now, the clock cannot back-fill the night on any path out of
        // sleep, and cannot re-bill what was counted before it.
        let now = Date.now
        var state = makeTestState(hunger: 0, at: now)
        state.isSleeping = true
        state.timestamps.hungerEmptiedAt = now.addingTimeInterval(-TimeConstants.careMistakeWindow * 4)
        state.timestamps.pendingCareMistakeAt =
            now.addingTimeInterval(-TimeConstants.careMistakeWindow * 2)

        state = CareMistakeTracker.apply(to: state, at: now, bedtime: false)
        #expect(state.careMistakes == 0)
        #expect(state.timestamps.pendingCareMistakeAt == now)

        // Roused without `wake` (the app keeps a busy pet up): nothing is billed twice.
        state.isSleeping = false
        state = CareMistakeTracker.apply(to: state, at: now.addingTimeInterval(30), bedtime: false)
        #expect(state.careMistakes == 0)
    }

    // MARK: - Lights-at-night penalty (independent accumulator)

    @Test
    func `light on past the window at night counts a mistake`() {
        let now = Date.now
        var state = makeTestState(hunger: 4, strength: 4, at: now)
        state.lightsOn = true
        state.timestamps.pendingLightsMistakeAt =
            now.addingTimeInterval(-TimeConstants.lightsMistakeWindow)

        state = CareMistakeTracker.apply(to: state, at: now, bedtime: true)
        #expect(state.careMistakes == 1)
    }

    @Test
    func `light off at night clears the lights countdown`() {
        let now = Date.now
        var state = makeTestState(hunger: 4, strength: 4, at: now)
        state.lightsOn = false
        state.timestamps.pendingLightsMistakeAt =
            now.addingTimeInterval(-TimeConstants.careMistakeWindow)

        state = CareMistakeTracker.apply(to: state, at: now, bedtime: true)
        #expect(state.careMistakes == 0)
        #expect(state.timestamps.pendingLightsMistakeAt == nil)
    }

    // Both penalties can fire in a single tick (asleep blocks only neglect).
    @Test
    func `neglect and lights penalties both count in one tick`() {
        let now = Date.now
        var state = makeTestState(hunger: 0, strength: 4, at: now)
        state.lightsOn = true
        state.timestamps.pendingCareMistakeAt =
            now.addingTimeInterval(-TimeConstants.careMistakeWindow)
        state.timestamps.pendingLightsMistakeAt =
            now.addingTimeInterval(-TimeConstants.lightsMistakeWindow)

        state = CareMistakeTracker.apply(to: state, at: now, bedtime: true)
        #expect(state.careMistakes == 2)
    }
}
