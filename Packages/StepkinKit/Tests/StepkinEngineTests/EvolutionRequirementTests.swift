import Testing
import Foundation
@testable import StepkinEngine
import StepkinTestSupport

@Suite("EvolutionRequirement")
struct EvolutionRequirementTests {

    private func makeReady() -> PetState {
        var state = makeTestState(species: .emberkin)
        // Plenty of lifetime steps so only the field under test gates the result.
        state.lifetimeActiveSteps = 1_000_000
        return state
    }

    @Test
    func `step gate blocks evolution below the stage threshold`() {
        var state = makeTestState(species: .emberkin)
        state.lifetimeActiveSteps = EvolutionStage.rookie.stepsToEvolve - 1
        let req = EvolutionRequirement(from: .emberkin, to: .galekin)
        #expect(req.isSatisfied(by: state) == false)
    }

    @Test
    func `step gate allows evolution at the stage threshold`() {
        var state = makeTestState(species: .emberkin)
        state.lifetimeActiveSteps = EvolutionStage.rookie.stepsToEvolve
        let req = EvolutionRequirement(from: .emberkin, to: .galekin)
        #expect(req.isSatisfied(by: state))
    }

    // The zero-battle edge: a win-rate gate must fail when no battles happened.
    @Test
    func `win rate is unmet with no battles`() {
        var state = makeReady()
        state.battleWins = 0
        state.battleLosses = 0
        let req = EvolutionRequirement(
            from: .emberkin, to: .galekin, minWinRate: 0.8
        )
        #expect(req.isSatisfied(by: state) == false)
    }

    @Test
    func `win rate is met when high enough`() {
        var state = makeReady()
        state.battleWins = 9
        state.battleLosses = 1
        let req = EvolutionRequirement(
            from: .emberkin, to: .galekin, minWinRate: 0.8
        )
        #expect(req.isSatisfied(by: state))
    }

    @Test
    func `win rate is unmet when too low`() {
        var state = makeReady()
        state.battleWins = 5
        state.battleLosses = 5
        let req = EvolutionRequirement(
            from: .emberkin, to: .galekin, minWinRate: 0.8
        )
        #expect(req.isSatisfied(by: state) == false)
    }

    @Test
    func `the lazy-day penalty raises the step goal`() {
        var state = makeTestState(species: .emberkin)
        state.lifetimeActiveSteps = EvolutionStage.rookie.stepsToEvolve
        let req = EvolutionRequirement(from: .emberkin, to: .galekin)

        // At exactly the base goal but carrying a penalty — the bar moved up.
        state.evolutionGoalPenalty = 5_000
        #expect(req.isSatisfied(by: state) == false)

        // Cover the raised goal and it passes again.
        state.lifetimeActiveSteps = EvolutionStage.rookie.stepsToEvolve + 5_000
        #expect(req.isSatisfied(by: state))
    }

    @Test
    func `weight and care-mistake bounds gate evolution`() {
        var state = makeReady()
        state.weight = Weight(50)
        state.careMistakes = 3
        let needsLight = EvolutionRequirement(
            from: .emberkin, to: .galekin, maxCareMistakes: 1
        )
        let needsHeavy = EvolutionRequirement(
            from: .emberkin, to: .galekin, minWeight: 40
        )
        #expect(needsLight.isSatisfied(by: state) == false)  // 3 > 1
        #expect(needsHeavy.isSatisfied(by: state))           // 50 >= 40
    }
}
