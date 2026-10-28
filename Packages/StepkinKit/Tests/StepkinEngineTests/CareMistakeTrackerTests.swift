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
    func `sleeping accrues no neglect and resets the pending clock`() {
        // The reset is what stops a sparse morning wake from back-filling the
        // whole night and dumping a pile of mistakes at once.
        let now = Date.now
        var state = makeTestState(hunger: 0, at: now)
        state.isSleeping = true
        state.timestamps.pendingCareMistakeAt =
            now.addingTimeInterval(-TimeConstants.careMistakeWindow * 2)

        state = CareMistakeTracker.apply(to: state, at: now, bedtime: false)
        #expect(state.careMistakes == 0)
        #expect(state.timestamps.pendingCareMistakeAt == nil)
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
