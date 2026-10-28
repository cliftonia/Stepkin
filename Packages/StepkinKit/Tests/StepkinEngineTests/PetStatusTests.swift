import Testing
import Foundation
@testable import StepkinEngine
import StepkinTestSupport

@Suite("PetStatus")
struct PetStatusTests {

    @Test
    func `a well-kept pet needs no attention`() {
        let status = PetStatus(from: makeTestState(hunger: 4, strength: 4))
        #expect(status.needsAttention == false)
    }

    @Test
    func `empty hunger needs attention`() {
        let status = PetStatus(from: makeTestState(hunger: 0, strength: 4))
        #expect(status.needsAttention)
    }

    @Test
    func `empty strength needs attention`() {
        let status = PetStatus(from: makeTestState(hunger: 4, strength: 0))
        #expect(status.needsAttention)
    }

    @Test
    func `poop on screen needs attention`() {
        var state = makeTestState(hunger: 4, strength: 4)
        state.poopCount = 1
        #expect(PetStatus(from: state).needsAttention)
    }

    @Test
    func `injury needs attention`() {
        var state = makeTestState(hunger: 4, strength: 4)
        state.isInjured = true
        #expect(PetStatus(from: state).needsAttention)
    }

    // MARK: - Care Flags

    @Test
    func `an awake languishing pet is drooping`() {
        let status = PetStatus(from: makeTestState(hunger: 0, strength: 0))
        #expect(status.isDrooping)
    }

    @Test
    func `a sleeping languishing pet is not drooping`() {
        var state = makeTestState(hunger: 0, strength: 0)
        state.isSleeping = true
        #expect(PetStatus(from: state).isDrooping == false)
    }

    @Test
    func `a pet with one full stat is not drooping`() {
        #expect(PetStatus(from: makeTestState(hunger: 0, strength: 2)).isDrooping == false)
    }

    @Test
    func `poop or injury is a care mess`() {
        var poopy = makeTestState()
        poopy.poopCount = 1
        var hurt = makeTestState()
        hurt.isInjured = true
        #expect(PetStatus(from: poopy).hasCareMess)
        #expect(PetStatus(from: hurt).hasCareMess)
        #expect(PetStatus(from: makeTestState()).hasCareMess == false)
    }
}
