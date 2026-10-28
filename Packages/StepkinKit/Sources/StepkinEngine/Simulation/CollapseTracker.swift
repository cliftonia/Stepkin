import Foundation

/// Tracks the collapse countdown: a pet with no hunger *and* no strength is
/// languishing. `collapsingAt` marks when that began; left untended past
/// `collapseDeathTime`, `DeathEvaluator` ends it. Recovering either stat clears
/// the countdown.
enum CollapseTracker {

    /// Starts or clears the countdown; dead and egg pets are exempt.
    static func apply(to state: PetState, at now: Date) -> PetState {
        var state = state
        guard !state.isDead, !state.isEgg else { return state }

        guard state.isLanguishing else {
            state.timestamps.collapsingAt = nil
            return state
        }
        if state.timestamps.collapsingAt == nil {
            // The countdown starts when the later stat actually ran out, not
            // when the app next looked — a pet that emptied while the app was
            // closed must not be granted those hours back.
            state.timestamps.collapsingAt = max(
                state.timestamps.hungerEmptiedAt ?? now,
                state.timestamps.strengthEmptiedAt ?? now
            )
        }
        return state
    }
}
