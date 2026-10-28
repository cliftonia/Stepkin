import Testing
import Foundation
import StepkinCore
@testable import StepkinEngine
import StepkinTestSupport

@Suite("InjurySimulator")
struct InjurySimulatorTests {

    @Test
    func `injures when poop reaches the maximum`() {
        let now = Date.now
        var state = makeTestState(at: now)
        state.poopCount = TimeConstants.maxPoopPiles

        state = InjurySimulator.apply(to: state, at: now)
        #expect(state.isInjured)
        #expect(state.injuryCount == 1)
        #expect(state.timestamps.injuredAt == now)
    }

    @Test
    func `does not injure below the maximum`() {
        let now = Date.now
        var state = makeTestState(at: now)
        state.poopCount = TimeConstants.maxPoopPiles - 1

        state = InjurySimulator.apply(to: state, at: now)
        #expect(state.isInjured == false)
        #expect(state.injuryCount == 0)
    }

    // An already-injured pet must not be counted again on the next tick.
    @Test
    func `does not double-count an existing injury`() {
        let now = Date.now
        var state = makeTestState(at: now)
        state.poopCount = TimeConstants.maxPoopPiles
        state.isInjured = true
        state.injuryCount = 1

        state = InjurySimulator.apply(to: state, at: now)
        #expect(state.injuryCount == 1)
    }

    @Test
    func `does not injure while sleeping`() {
        let now = Date.now
        var state = makeTestState(at: now)
        state.poopCount = TimeConstants.maxPoopPiles
        state.isSleeping = true

        state = InjurySimulator.apply(to: state, at: now)
        #expect(state.isInjured == false)
    }
}
