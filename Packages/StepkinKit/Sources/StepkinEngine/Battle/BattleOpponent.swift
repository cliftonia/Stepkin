import Foundation

/// A sparring partner drawn for a single battle: a `PetSpecies` plus a
/// power roll jittered around the species' `basePower` so repeat fights
/// are not identical.
public struct BattleOpponent: Sendable {

    /// The drawn species, chosen by `generate(matching:)` to differ from the player's when
    /// possible.
    public let species: PetSpecies
    /// The species' `basePower` jittered by ±10, clamped to at least 1; set
    /// against `BattleEngine.power(of:)` when a round's heights match.
    public let power: Double

    /// Generates an opponent matched to the player's current stage: another
    /// species of the same stage, or of the nearest stage when the pet's
    /// species is alone in its own, so power stays a fair contest. The pet's
    /// own species is the last resort.
    public static func generate(matching state: PetState) -> BattleOpponent {
        let stage = state.species.stage.rawValue
        let others = PetSpecies.allCases.filter { $0 != state.species }
        let nearest = others.map { abs($0.stage.rawValue - stage) }.min()
        let opponent = others.filter { abs($0.stage.rawValue - stage) == nearest }.randomElement()
            ?? state.species
        let power = Double(opponent.basePower) + Double.random(in: -10...10)
        return BattleOpponent(
            species: opponent,
            power: max(1, power)
        )
    }
}
