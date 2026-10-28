import Testing
import Foundation
import StepkinCore
@testable import StepkinEngine
import StepkinTestSupport

@Suite("HungerSimulator")
struct HungerSimulatorTests {

    @Test
    func `depletes one heart per interval`() {
        let start = Date.now
        var state = makeTestState(hunger: 4, at: start)
        state.timestamps.lastHungerDecayAt = start

        let later = start.addingTimeInterval(
            TimeConstants.hungerDepletionInterval
        )
        state = HungerSimulator.apply(to: state, at: later)
        #expect(state.hungerHearts.value == 3)
    }

    @Test
    func `multiple intervals deplete multiple hearts`() {
        let start = Date.now
        var state = makeTestState(hunger: 4, at: start)
        state.timestamps.lastHungerDecayAt = start

        let later = start.addingTimeInterval(
            TimeConstants.hungerDepletionInterval * 3
        )
        state = HungerSimulator.apply(to: state, at: later)
        #expect(state.hungerHearts.value == 1)
    }

    @Test
    func `hunger floors at zero and never goes negative`() {
        let start = Date.now
        var state = makeTestState(hunger: 1, at: start)
        state.timestamps.lastHungerDecayAt = start

        // Far more elapsed intervals than there are hearts to lose.
        let later = start.addingTimeInterval(
            TimeConstants.hungerDepletionInterval * 6
        )
        state = HungerSimulator.apply(to: state, at: later)
        #expect(state.hungerHearts.value == 0)
    }

    @Test
    func `a backward clock does not refill or deplete hunger`() {
        let start = Date.now
        var state = makeTestState(hunger: 3, at: start)
        state.timestamps.lastHungerDecayAt = start

        let earlier = start.addingTimeInterval(
            -TimeConstants.hungerDepletionInterval * 2
        )
        state = HungerSimulator.apply(to: state, at: earlier)
        #expect(state.hungerHearts.value == 3)
        #expect(state.timestamps.lastHungerDecayAt == start)
    }

    @Test
    func `does not deplete while sleeping`() {
        let start = Date.now
        var state = makeTestState(hunger: 4, at: start)
        state.isSleeping = true
        state.timestamps.lastHungerDecayAt = start

        let later = start.addingTimeInterval(
            TimeConstants.hungerDepletionInterval * 5
        )
        state = HungerSimulator.apply(to: state, at: later)
        #expect(state.hungerHearts.value == 4)
    }
}
