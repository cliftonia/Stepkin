import Testing
import Foundation
@testable import StepkinEngine
import StepkinTestSupport

@Suite("EvolutionEngine")
struct EvolutionEngineTests {

    @Test
    func `dotkin evolves to hopkin once the step gate is met`() {
        var state = makeTestState(species: .dotkin)
        state.lifetimeActiveSteps = EvolutionStage.fresh.stepsToEvolve
        #expect(EvolutionEngine.checkEvolution(for: state) == .hopkin)
    }

    @Test
    func `a dead pet never evolves, however many steps it has`() {
        var state = makeTestState(species: .dotkin)
        state.lifetimeActiveSteps = EvolutionStage.fresh.stepsToEvolve
        state.isDead = true
        #expect(EvolutionEngine.checkEvolution(for: state) == nil)
    }

    @Test
    func `dotkin does not evolve below the step gate`() {
        var state = makeTestState(species: .dotkin)
        state.lifetimeActiveSteps = EvolutionStage.fresh.stepsToEvolve - 1
        #expect(EvolutionEngine.checkEvolution(for: state) == nil)
    }

    @Test
    func `hopkin evolves to emberkin with 0-1 care mistakes`() {
        var state = makeTestState(species: .hopkin)
        state.lifetimeActiveSteps = EvolutionStage.inTraining.stepsToEvolve
        state.careMistakes = 0
        #expect(EvolutionEngine.checkEvolution(for: state) == .emberkin)
    }

    @Test
    func `hopkin evolves to marshkin with 2+ care mistakes`() {
        var state = makeTestState(species: .hopkin)
        state.lifetimeActiveSteps = EvolutionStage.inTraining.stepsToEvolve
        state.careMistakes = 3
        #expect(EvolutionEngine.checkEvolution(for: state) == .marshkin)
    }

    @Test
    func `the same care state still picks the branch independent of steps`() {
        var lazyEnough = makeTestState(species: .hopkin)
        lazyEnough.lifetimeActiveSteps = EvolutionStage.inTraining.stepsToEvolve * 4
        lazyEnough.careMistakes = 0
        // Far past the gate, but care (not steps) still decides Emberkin.
        #expect(EvolutionEngine.checkEvolution(for: lazyEnough) == .emberkin)
    }

    @Test
    func `evolving clears the lazy-day goal penalty`() {
        var state = makeTestState(species: .dotkin)
        state.lifetimeActiveSteps = EvolutionStage.fresh.stepsToEvolve
        state.evolutionGoalPenalty = 8_000
        let evolved = EvolutionEngine.evolve(state, to: .hopkin, at: .now)
        #expect(evolved.evolutionGoalPenalty == 0)
    }

    @Test
    func `evolving heals any standing injury so no death carries over`() {
        var state = makeTestState(species: .dotkin)
        state.isInjured = true
        state.timestamps.injuredAt = .now
        let evolved = EvolutionEngine.evolve(state, to: .hopkin, at: .now)
        #expect(evolved.isInjured == false)
        #expect(evolved.timestamps.injuredAt == nil)
    }

    @Test
    func `evolving resets the lifetime injury count and clears poop`() {
        // Otherwise a well-cared pet accruing training injuries would hit the
        // 20-injury death cap in ~40 days despite the rebalance.
        var state = makeTestState(species: .dotkin)
        state.injuryCount = 18
        state.poopCount = 3
        let evolved = EvolutionEngine.evolve(state, to: .hopkin, at: .now)
        #expect(evolved.injuryCount == 0)
        #expect(evolved.poopCount == 0)
    }

    @Test
    func `ultimate stage cannot evolve further`() {
        var state = makeTestState(species: .steelkin)
        state.lifetimeActiveSteps = 5_000_000
        #expect(EvolutionEngine.checkEvolution(for: state) == nil)
    }
}
