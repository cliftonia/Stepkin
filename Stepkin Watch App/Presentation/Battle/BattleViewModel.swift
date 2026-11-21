import Foundation
import Observation

/// Display state for the battle screen: the active `BattlePhase`, both
/// species, both health pools, and the last round's outcome. Held as one
/// `@Observable` class so each mutation republishes to the view.
@Observable
final class BattleViewModel {

    /// The stage of the battle currently on screen.
    var phase: BattlePhase = .introPet
    /// The species shown for the pet's side of the battle.
    var petSpecies: PetSpecies = .emberkin
    /// The species shown for the opponent's side of the battle.
    var opponentSpecies: PetSpecies = .marshkin
    /// The pet's remaining health, out of `petMaxHP`.
    var petHP: Int = 3
    /// The pet's full health; `petHP` starts at this value.
    var petMaxHP: Int = 3
    /// The opponent's remaining health, out of `opponentMaxHP`.
    var opponentHP: Int = 3
    /// The opponent's full health; `opponentHP` starts at this value.
    var opponentMaxHP: Int = 3
    /// The result once the battle ends; `nil` while it is undecided.
    var result: BattleResult?
    /// The most recent round's outcome; `nil` before any round has resolved.
    var lastRoundOutcome: RoundOutcome?

    /// The stages of a battle: intros, the move choice, each side's attack and
    /// projectile, then `victory` or `defeat`. `phase` is non-optional — a
    /// battle is always in exactly one stage.
    enum BattlePhase: Sendable {
        case introPet
        case introVS
        case introEnemy
        case choosing
        case attacking
        case projectile
        case opponentAttacking
        case opponentProjectile
        case impact
        case victory
        case defeat
    }
}
