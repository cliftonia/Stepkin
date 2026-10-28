import Testing
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
}
