import Foundation

/// A sparring partner drawn for a single battle: a `PetSpecies` plus a
/// power roll jittered around the species' `basePower` so repeat fights
/// are not identical.
public struct BattleOpponent: Sendable {

    /// The drawn species, chosen by `generate(matching:)` to differ from the player's when
    /// possible.
    public let species: PetSpecies
    /// The species' `basePower` jittered by ±10, clamped to at least 1.
    let power: Double

    /// Generates an opponent matched to the player's current stage.
    /// Prefers a different species of the same evolution stage, falling
    /// back to any other species, and to the pet's own species as a last
    /// resort.
    public static func generate(matching state: PetState) -> BattleOpponent {
        let sameStage = PetSpecies.allCases.filter {
            $0.stage == state.species.stage && $0 != state.species
        }
        let others = PetSpecies.allCases.filter {
            $0 != state.species
        }
        let opponent = sameStage.randomElement()
            ?? others.randomElement()
            ?? state.species
        let power = Double(opponent.basePower) + Double.random(in: -10...10)
        return BattleOpponent(
            species: opponent,
            power: max(1, power)
        )
    }
}
