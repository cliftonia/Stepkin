import Testing
import Foundation
import StepkinCore
@testable import StepkinEngine
import StepkinTestSupport

@Suite("LightsAction")
struct LightsActionTests {

    @Test
    func `cannot toggle during the day`() {
        var state = makeTestState(at: .now)
        state.lightsOn = true

        let (newState, result) = LightsAction.apply(
            to: state, night: false, at: .now
        )

        #expect(result == .blocked)
        #expect(newState.lightsOn == true)
    }

    @Test
    func `turning the light off at night starts the settle countdown`() {
        let now = Date()
        var state = makeTestState(at: now)
        state.lightsOn = true
        state.isSleeping = false

        let (newState, result) = LightsAction.apply(
            to: state, night: true, at: now
        )

        #expect(result == .toggled)
        #expect(newState.lightsOn == false)
        #expect(newState.isSleeping == false)            // not immediate
        #expect(newState.timestamps.lightsOffAt == now)
    }

    @Test
    func `turning the light on at night wakes the pet immediately`() {
        let now = Date()
        var state = makeTestState(at: now)
        state.lightsOn = false
        state.isSleeping = true

        let (newState, result) = LightsAction.apply(
            to: state, night: true, at: now
        )

        #expect(result == .toggled)
        #expect(newState.lightsOn == true)
        #expect(newState.isSleeping == false)
        #expect(newState.timestamps.lightsOffAt == nil)
        // The sleep was a pause — depletion restarts from the wake, not from bedtime.
        #expect(newState.timestamps.lastHungerDecayAt == now)
        #expect(newState.timestamps.lastStrengthDecayAt == now)
        #expect(newState.timestamps.lastPoopAt == now)
    }

    @Test
    func `cannot toggle dead pet`() {
        var state = makeTestState(at: .now)
        state.isDead = true

        let (_, result) = LightsAction.apply(to: state, night: true, at: .now)

        #expect(result == .blocked)
    }

    @Test
    func `cannot toggle egg`() {
        var state = PetState.hatched(at: .now)
        state.isEgg = true

        let (_, result) = LightsAction.apply(to: state, night: true, at: .now)

        #expect(result == .blocked)
    }
}
