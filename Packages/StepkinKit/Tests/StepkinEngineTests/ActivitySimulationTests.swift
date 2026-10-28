import Testing
import Foundation
import StepkinCore
@testable import StepkinEngine
import StepkinTestSupport

// How real-world activity (steps) reshapes the simulation.
@Suite("Activity simulation")
struct ActivitySimulationTests {

    // MARK: - Hunger: faster the more you move

    @Test func `more steps deplete hunger faster`() {
        let start = Date.now
        let elapsed = TimeConstants.hungerDepletionInterval * 3
        func remaining(steps: Int) -> Int {
            var s = makeTestState(hunger: 4, at: start)
            s.timestamps.lastHungerDecayAt = start
            s = HungerSimulator.apply(
                to: s, at: start.addingTimeInterval(elapsed), steps: steps
            )
            return s.hungerHearts.value
        }
        #expect(remaining(steps: ActivityModel.stepGoal) < remaining(steps: 0))
    }

    // MARK: - Strength: faster the LESS you move

    @Test func `fewer steps deplete strength faster`() {
        let start = Date.now
        let elapsed = TimeConstants.strengthDepletionInterval * 3
        func remaining(steps: Int) -> Int {
            var s = makeTestState(strength: 4, at: start)
            s.timestamps.lastStrengthDecayAt = start
            s = StrengthSimulator.apply(
                to: s, at: start.addingTimeInterval(elapsed), steps: steps
            )
            return s.strengthHearts.value
        }
        #expect(remaining(steps: 0) < remaining(steps: ActivityModel.stepGoal))
    }

    // MARK: - Injury: sedentary injures one pile sooner

    @Test func `sedentary injures at the lower poop threshold`() {
        let now = Date.now
        var base = makeTestState(at: now)
        base.poopCount = TimeConstants.maxPoopPiles - 1   // 3 piles

        let sedentary = InjurySimulator.apply(to: base, at: now, steps: 0)
        let active = InjurySimulator.apply(
            to: base, at: now, steps: ActivityModel.stepGoal
        )
        #expect(sedentary.isInjured)            // 3 piles + sedentary → hurt
        #expect(active.isInjured == false)      // 3 piles + active → not yet
    }

    // MARK: - Battle: fitter fighter

    @Test func `active pet gets a battle HP bonus`() {
        let state = makeTestState(hunger: 4, strength: 4)
        let resting = BattleHP.calculate(for: state, steps: 0)
        let active = BattleHP.calculate(for: state, steps: ActivityModel.stepGoal)
        #expect(active > resting)
    }

    // MARK: - Defeat injures only when weak

    @Test func `losing while weak injures the pet`() {
        let weak = makeTestState(hunger: 4, strength: 1)
        let result = BattleEngine.applyResult(.lose, to: weak, at: .now)
        #expect(result.isInjured)
        #expect(result.battleLosses == 1)
    }

    @Test func `losing while healthy does not injure`() {
        let healthy = makeTestState(hunger: 4, strength: 4)
        let result = BattleEngine.applyResult(.lose, to: healthy, at: .now)
        #expect(result.isInjured == false)
        #expect(result.battleLosses == 1)
    }
}
