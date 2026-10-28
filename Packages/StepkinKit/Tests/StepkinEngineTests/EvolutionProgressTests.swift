import Testing
import Foundation
@testable import StepkinEngine
import StepkinTestSupport

@Suite("Evolution progress fraction")
struct EvolutionProgressTests {

    @Test
    func `a fresh pet with no steps reads as zero progress`() {
        let state = makeTestState(species: .dotkin)
        #expect(state.evolutionProgressFraction == 0)
    }

    @Test
    func `halfway to the goal reads as one half`() {
        var state = makeTestState(species: .dotkin)
        state.lifetimeActiveSteps = EvolutionStage.fresh.stepsToEvolve / 2
        #expect(abs(state.evolutionProgressFraction - 0.5) < 0.001)
    }

    @Test
    func `progress clamps to one at and beyond the goal`() {
        var state = makeTestState(species: .dotkin)
        state.lifetimeActiveSteps = EvolutionStage.fresh.stepsToEvolve * 3
        #expect(state.evolutionProgressFraction == 1)
    }

    @Test
    func `the lazy-day penalty lowers the fraction`() {
        var state = makeTestState(species: .dotkin)
        state.lifetimeActiveSteps = EvolutionStage.fresh.stepsToEvolve
        let unpenalised = state.evolutionProgressFraction
        state.evolutionGoalPenalty = EvolutionStage.fresh.stepsToEvolve
        #expect(state.evolutionProgressFraction < unpenalised)
    }

    @Test
    func `the ultimate stage reads as a full ring`() {
        let state = makeTestState(species: .steelkin)
        #expect(state.evolutionProgressFraction == 1)
    }
}
