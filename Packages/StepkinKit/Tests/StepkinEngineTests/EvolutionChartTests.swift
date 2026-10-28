import Testing
@testable import StepkinEngine
import StepkinTestSupport

@Suite("EvolutionChart reachability")
struct EvolutionChartTests {

    /// Every species must be reachable from the starting Dotkin by walking the
    /// chart edges (care mistakes reset on each evolution, so per-stage gates are
    /// independently satisfiable). A fixed-point graph traversal proves it.
    @Test
    func `every species is reachable from the starting egg`() {
        var reachable: Set<PetSpecies> = [.dotkin]
        var changed = true
        while changed {
            changed = false
            for requirement in EvolutionChart.requirements
            where reachable.contains(requirement.from) && !reachable.contains(requirement.to) {
                reachable.insert(requirement.to)
                changed = true
            }
        }

        let unreachable = Set(PetSpecies.allCases).subtracting(reachable)
        #expect(unreachable.isEmpty, "Unreachable species: \(unreachable)")
    }

    /// Every non-final species must offer at least one outgoing evolution, so no
    /// pre-ultimate pet is a dead end.
    @Test
    func `every pre-ultimate species has an outgoing path`() {
        for species in PetSpecies.allCases where species.stage != .ultimate {
            let hasPath = EvolutionChart.requirements.contains { $0.from == species }
            #expect(hasPath, "\(species) has no evolution")
        }
    }

    // Graph reachability proves an edge *exists*, but `checkEvolution` returns the
    // first *satisfied* requirement — a broader gate listed earlier can shadow a
    // more specific one. These guard the branches where that nearly happened.

    @Test
    func `a heavy neglected Marshkin reaches Tidekin, a light one Galekin`() {
        var heavy = makeTestState(species: .marshkin)
        heavy.lifetimeActiveSteps = EvolutionStage.rookie.stepsToEvolve
        heavy.careMistakes = 4
        heavy.weight = Weight(40)                       // >= 35
        #expect(EvolutionEngine.checkEvolution(for: heavy) == .tidekin)

        var light = heavy
        light.weight = Weight(20)                       // < 35
        #expect(EvolutionEngine.checkEvolution(for: light) == .galekin)
    }
}
