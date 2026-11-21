import Foundation
import Observation

/// Display state for the Training screen: the state of one training run.
///
/// A run moves through `TrainingPhase`, tracking the current round, the
/// number being shown, and each round's result in `roundResults`.
@Observable
final class TrainingViewModel {

    /// The stage the run has reached; selects what the Training screen shows.
    var phase: TrainingPhase = .ready
    /// The round of the run being played.
    var currentRound: Int = 0
    /// The number shown in the current round.
    var currentNumber: Int = 5
    /// The result of each round the run has played.
    var roundResults: [RoundResult] = []
    /// Whether `currentNumber` is visible on screen.
    var showingNumber: Bool = false
    /// Whether the last guess was high; meaningless before the first guess.
    var lastGuessHigh: Bool = true

    /// The outcome of one round, identified by its position in the run.
    nonisolated struct RoundResult: Identifiable, Hashable, Sendable {
        /// The round's index within the run.
        let id: Int
        /// Whether the guess was correct.
        let won: Bool
    }

    /// The stage of a training run, from `ready` through the attack
    /// sequence to `victory` or `defeat`.
    enum TrainingPhase: Sendable {
        case ready
        case challenge
        case attacking
        case projectile
        case hit
        case miss
        case victory
        case defeat
    }
}
