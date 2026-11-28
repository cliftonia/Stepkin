import Foundation
import StepkinCore

/// The result of one arena round, resolved from the `AttackHeight` triangle
/// and, on matched heights, from power: a hit on either side, or a `.clash`
/// when neither the heights nor the powers separate them.
public enum RoundOutcome: Equatable, Sendable {
    case playerHit
    case opponentHit
    case clash
}

/// The arena rules as pure, stateless functions: each round is an
/// attack-height duel resolved by the `AttackHeight` triangle, with power
/// deciding matched heights, and applying
/// the result mutates a caller-owned `PetState` — the win/loss record and
/// conditioning the evolution gates read.
public enum BattleEngine {

    /// The most rounds one battle lasts; a battle still undecided then is
    /// judged on remaining HP by `judge`.
    public static let maxRounds = 20

    // MARK: - Query

    /// Reports whether the pet may battle, which requires it to be awake and alive.
    public static func canBattle(_ state: PetState) -> Bool {
        state.isAwakeAndAlive
    }

    /// The pet's battle power: its species' base plus
    /// `TimeConstants.powerPerTrainedPoint` for each trained point.
    public static func power(of state: PetState) -> Double {
        Double(state.species.basePower) + Double(state.trainedPower) * TimeConstants.powerPerTrainedPoint
    }

    /// Resolves one round by the height triangle. Matching heights go to a
    /// side stronger by more than `TimeConstants.clashPowerMargin`; between
    /// closer powers they are a `.clash` and nobody is hit. A level session
    /// ends on `judge` instead.
    public static func resolveRound(
        playerHeight: AttackHeight,
        opponentHeight: AttackHeight,
        playerPower: Double,
        opponentPower: Double
    ) -> RoundOutcome {
        if playerHeight.beats(opponentHeight) {
            return .playerHit
        }
        if opponentHeight.beats(playerHeight) {
            return .opponentHit
        }
        if playerPower > opponentPower * TimeConstants.clashPowerMargin {
            return .playerHit
        }
        if opponentPower > playerPower * TimeConstants.clashPowerMargin {
            return .opponentHit
        }
        return .clash
    }

    /// Judges an undecided battle on remaining HP: more HP wins, less loses,
    /// and equal HP is a draw.
    public static func judge(petHP: Int, opponentHP: Int) -> BattleResult {
        if petHP > opponentHP { return .win }
        if opponentHP > petHP { return .lose }
        return .draw
    }

    /// Applies the battle result: every result stamps `lastBattledAt`, even a
    /// draw. A win adds +1 `trainedPower` while `canCondition` holds (never for
    /// Dotkin), clamped to `TimeConstants.maxConditioning`; a loss with strength
    /// or hunger at one heart or fewer also injures the pet.
    public static func applyResult(
        _ result: BattleResult,
        to state: PetState,
        at now: Date
    ) -> PetState {
        var state = state
        state.timestamps.lastBattledAt = now
        switch result {
        case .win:
            state.battleWins += 1
            if state.canCondition {
                state.trainedPower = min(
                    TimeConstants.maxConditioning, state.trainedPower + 1
                )
            }
        case .lose:
            state.battleLosses += 1
            let weak = state.strengthHearts.value <= 1 || state.hungerHearts.value <= 1
            if weak {
                state.injure(at: now)
            }
        case .draw:
            break
        }
        return state
    }
}
