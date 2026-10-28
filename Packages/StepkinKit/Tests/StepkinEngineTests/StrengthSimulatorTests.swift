import Testing
import Foundation
import StepkinCore
@testable import StepkinEngine
import StepkinTestSupport

@Suite("StrengthSimulator")
struct StrengthSimulatorTests {

    @Test
    func `depletes one heart per interval`() {
        let start = Date.now
        var state = makeTestState(strength: 4, at: start)
        state.timestamps.lastStrengthDecayAt = start

        let later = start.addingTimeInterval(
            TimeConstants.strengthDepletionInterval
        )
        state = StrengthSimulator.apply(to: state, at: later)
        #expect(state.strengthHearts.value == 3)
    }

    @Test
    func `multiple intervals deplete multiple hearts`() {
        let start = Date.now
        var state = makeTestState(strength: 4, at: start)
        state.timestamps.lastStrengthDecayAt = start

        let later = start.addingTimeInterval(
            TimeConstants.strengthDepletionInterval * 3
        )
        state = StrengthSimulator.apply(to: state, at: later)
        #expect(state.strengthHearts.value == 1)
    }

    @Test
    func `does not deplete while sleeping`() {
        let start = Date.now
        var state = makeTestState(strength: 4, at: start)
        state.isSleeping = true
        state.timestamps.lastStrengthDecayAt = start

        let later = start.addingTimeInterval(
            TimeConstants.strengthDepletionInterval * 5
        )
        state = StrengthSimulator.apply(to: state, at: later)
        #expect(state.strengthHearts.value == 4)
    }

    // A backward clock yields a negative span — must not decay or trap.
    @Test
    func `ignores a backward clock`() {
        let start = Date.now
        var state = makeTestState(strength: 4, at: start)
        state.timestamps.lastStrengthDecayAt = start

        let earlier = start.addingTimeInterval(-TimeConstants.strengthDepletionInterval * 2)
        state = StrengthSimulator.apply(to: state, at: earlier)
        #expect(state.strengthHearts.value == 4)
    }
}
