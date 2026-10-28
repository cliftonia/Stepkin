import Testing
import Foundation
@testable import imon_Watch_App

@Suite("Per-species capacity")
struct PetSpeciesCapacityTests {

    @Test func `hatched Dotkin starts at its small capacity`() {
        let state = PetState.hatched(at: .now)
        #expect(state.species == .dotkin)
        #expect(state.hungerHearts.value == PetSpecies.dotkin.maxHunger)
        #expect(state.strengthHearts.value == PetSpecies.dotkin.maxStrength)
        #expect(PetSpecies.dotkin.maxHunger == 2)
    }

    @Test func `evolving fills to the new species capacity`() {
        var state = makeTestState(species: .dotkin, hunger: 0, strength: 0)
        state = EvolutionEngine.evolve(state, to: .emberkin, at: .now)
        #expect(state.hungerHearts.value == PetSpecies.emberkin.maxHunger)
        #expect(state.strengthHearts.value == PetSpecies.emberkin.maxStrength)
    }

    @Test func `feeding cannot exceed species hunger capacity`() {
        var state = makeTestState(species: .dotkin, hunger: 0)
        for _ in 0..<6 { state = FeedAction.apply(to: state, food: .meat, at: .now) }
        #expect(state.hungerHearts.value == PetSpecies.dotkin.maxHunger)
    }

    @Test func `every species has a positive capacity and HP`() {
        for species in PetSpecies.allCases {
            #expect(species.maxHunger >= 1)
            #expect(species.maxStrength >= 1)
            #expect(species.baseHP >= 1)
        }
    }
}
