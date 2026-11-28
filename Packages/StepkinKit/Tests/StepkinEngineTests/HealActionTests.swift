import Testing
import StepkinCore
@testable import StepkinEngine
import StepkinTestSupport

@Suite("HealAction")
struct HealActionTests {

    @Test
    func `canHeal returns true when injured`() {
        var state = makeTestState()
        state.isInjured = true
        #expect(HealAction.canHeal(state))
    }

    @Test
    func `canHeal returns false when not injured`() {
        let state = makeTestState()
        #expect(!HealAction.canHeal(state))
    }

    @Test
    func `canHeal returns false when dead`() {
        var state = makeTestState()
        state.isInjured = true
        state.isDead = true
        #expect(!HealAction.canHeal(state))
    }

    @Test
    func `heal clears injury`() {
        var state = makeTestState()
        state.isInjured = true
        state = HealAction.apply(to: state)
        #expect(!state.isInjured)
    }

    /// Mess at an injuring height would wound the pet again on the next tick,
    /// burning a lifetime injury; the mess has to go first.
    @Test
    func `canHeal returns false while the mess could injure again`() {
        var state = makeTestState()
        state.isInjured = true
        state.poopCount = TimeConstants.maxPoopPiles - 1
        #expect(!HealAction.canHeal(state))

        state.poopCount = TimeConstants.maxPoopPiles - 2
        #expect(HealAction.canHeal(state))
    }
}
