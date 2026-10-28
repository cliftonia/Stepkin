import Testing
import Foundation
import StepkinCore
@testable import StepkinEngine
import StepkinTestSupport

@Suite("PoopSimulator")
struct PoopSimulatorTests {

    @Test
    func `one pile appears per interval`() {
        let start = Date.now
        var state = makeTestState(at: start)
        state.poopCount = 0
        state.timestamps.lastPoopAt = start

        let later = start.addingTimeInterval(TimeConstants.poopInterval)
        state = PoopSimulator.apply(to: state, at: later)
        #expect(state.poopCount == 1)
    }

    @Test
    func `piles accumulate over multiple intervals`() {
        let start = Date.now
        var state = makeTestState(at: start)
        state.poopCount = 0
        state.timestamps.lastPoopAt = start

        let later = start.addingTimeInterval(TimeConstants.poopInterval * 3)
        state = PoopSimulator.apply(to: state, at: later)
        #expect(state.poopCount == 3)
    }

    // Piles are capped at the maximum, never beyond.
    @Test
    func `caps at the maximum pile count`() {
        let start = Date.now
        var state = makeTestState(at: start)
        state.poopCount = 0
        state.timestamps.lastPoopAt = start

        let later = start.addingTimeInterval(TimeConstants.poopInterval * 10)
        state = PoopSimulator.apply(to: state, at: later)
        #expect(state.poopCount == TimeConstants.maxPoopPiles)
    }

    @Test
    func `does not poop while sleeping`() {
        let start = Date.now
        var state = makeTestState(at: start)
        state.poopCount = 0
        state.isSleeping = true
        state.timestamps.lastPoopAt = start

        let later = start.addingTimeInterval(TimeConstants.poopInterval * 3)
        state = PoopSimulator.apply(to: state, at: later)
        #expect(state.poopCount == 0)
    }
}
