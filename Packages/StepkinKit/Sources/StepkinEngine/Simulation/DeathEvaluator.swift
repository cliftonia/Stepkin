import Foundation
import StepkinCore

/// Decides whether a death threshold in `TimeConstants` has killed the pet,
/// and applies it. Evaluation and application are split so `GameEngine.step`
/// can log the `CauseOfDeath` between deciding and flipping the flag; pure
/// value in, value out, like the simulators.
enum DeathEvaluator {

    /// Which death threshold killed the pet: the injury count, an untreated
    /// injury, or the collapse countdown. Returned separately from `evaluate`
    /// so `GameEngine.step` can log it before `applyDeath` flips the flag.
    enum CauseOfDeath: Sendable {
        case injuries
        case untreatedInjury
        case collapse
    }

    // MARK: - Evaluate

    /// Returns the cause of death once a threshold is met, or `nil` while the
    /// pet is alive. Eggs and pets already dead are ineligible. When several
    /// thresholds are met at once the first check wins: lifetime `injuryCount`,
    /// then an untreated injury older than `untreatedInjuryDeathTime`, then
    /// the collapse countdown `CollapseTracker` started.
    static func evaluate(_ state: PetState, at now: Date) -> CauseOfDeath? {
        guard !state.isDead, !state.isEgg else { return nil }

        if state.injuryCount >= TimeConstants.maxInjuriesBeforeDeath {
            return .injuries
        }

        if state.isInjured, let injuredAt = state.timestamps.injuredAt {
            let elapsed = now.timeIntervalSince(injuredAt)
            if elapsed >= TimeConstants.untreatedInjuryDeathTime {
                return .untreatedInjury
            }
        }

        if let collapsingAt = state.timestamps.collapsingAt {
            let elapsed = now.timeIntervalSince(collapsingAt)
            if elapsed >= TimeConstants.collapseDeathTime {
                return .collapse
            }
        }

        return nil
    }

    // MARK: - Apply

    /// Marks the pet dead, flipping `isDead` and nothing else. The cause is
    /// not stored: the caller logs the `CauseOfDeath` it got from `evaluate`.
    static func applyDeath(to state: PetState) -> PetState {
        var state = state
        state.isDead = true
        return state
    }
}
