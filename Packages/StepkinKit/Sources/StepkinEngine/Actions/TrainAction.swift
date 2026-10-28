import Foundation
import StepkinCore

/// The training mini-game: guess whether a hidden number (1–9, never 5, so a
/// guess always has a true answer) lands high or low. A winning session builds
/// strength, sheds weight and adds trained HP; win or lose, the exertion risks
/// a poop (60%) or an injury (10%).
public enum TrainAction {

    /// A guess that the hidden number lands above or below 5. No "equal"
    /// case exists because `generateNumber` excludes 5, so every round has
    /// a true answer.
    public enum Guess: Sendable {
        case high
        case low
    }

    /// The outcome of one round, produced by `evaluateRound`: `won` records
    /// whether the guess matched the hidden number.
    public struct RoundResult: Sendable {
        /// Whether the guess matched the hidden number; `applyResult` grants
        /// its strength, weight and conditioning gains only when this is true.
        public let won: Bool
    }

    // MARK: - Query

    /// Reports whether a training session may start. `applyResult` enforces
    /// the same gate and returns the state unchanged when this is false.
    public static func canTrain(_ state: PetState) -> Bool {
        state.isAwakeAndAlive
    }

    // MARK: - Round Logic

    /// Draws the round's hidden number uniformly from 1...9 but never 5, so
    /// every guess has a true answer.
    public static func generateNumber() -> Int {
        var number = Int.random(in: 1...9)
        while number == 5 {
            number = Int.random(in: 1...9)
        }
        return number
    }

    /// Scores one round: `.high` wins when `number` is above 5, `.low` when
    /// it is below. A 5 loses either way, which `generateNumber` rules out.
    public static func evaluateRound(number: Int, guess: Guess) -> RoundResult {
        let won: Bool = {
            switch guess {
            case .high: number > 5
            case .low: number < 5
            }
        }()
        return RoundResult(won: won)
    }

    /// Judges a session from its round results so far: `true` once wins reach
    /// `TimeConstants.trainWinsNeeded`, `false` once losses exceed the allowance
    /// (`trainRounds - trainWinsNeeded`), `nil` while the session plays on.
    public static func sessionOutcome(results: [Bool]) -> Bool? {
        let wins = results.filter { $0 }.count
        let losses = results.count - wins
        if wins >= TimeConstants.trainWinsNeeded { return true }
        if losses > TimeConstants.trainRounds - TimeConstants.trainWinsNeeded { return false }
        return nil
    }

    // MARK: - Apply

    /// Applies a training session's result, or nothing when `canTrain` fails.
    /// A win increments strength (cap `species.maxStrength`), subtracts
    /// `TimeConstants.trainWeightLoss`, and adds one trained HP when
    /// `canCondition` holds; the poop-or-injury roll runs win or lose.
    public static func applyResult(
        to state: PetState,
        won: Bool,
        at now: Date
    ) -> PetState {
        guard canTrain(state) else { return state }

        var state = state

        if won {
            state.strengthHearts.increment(upTo: state.species.maxStrength)
            state.weight.subtract(TimeConstants.trainWeightLoss)
            if state.canCondition {
                state.trainedHP = min(
                    TimeConstants.maxConditioning, state.trainedHP + 1
                )
            }
        }

        state.trainingCount += 1
        state.timestamps.lastTrainedAt = now
        let roll = Int.random(in: 1...10)
        if (1...6).contains(roll) {
            state.poopCount = min(TimeConstants.maxPoopPiles, state.poopCount + 1)
            state.timestamps.lastPoopAt = now
        } else if roll == 10 {
            state.injure(at: now)
        }

        return state
    }
}
