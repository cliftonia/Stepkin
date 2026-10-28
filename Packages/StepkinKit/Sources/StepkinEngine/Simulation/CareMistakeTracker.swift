import Foundation
import StepkinCore

/// Tracks care mistakes from two neglect paths: hunger or strength left
/// empty for longer than `careMistakeWindow` (20 min, paused while asleep),
/// and the light left on past bedtime for longer than `lightsMistakeWindow`
/// (3 h). Pending timestamps record when each neglect period began.
enum CareMistakeTracker {

    /// Applies both neglect paths to the state. Dead and egg pets are exempt;
    /// the hunger/strength path pauses while the pet sleeps — the lights path
    /// does not.
    static func apply(to state: PetState, at now: Date, bedtime: Bool) -> PetState {
        var state = state
        guard !state.isDead, !state.isEgg else { return state }

        state.careMistakes += accrueMistakes(
            anchor: &state.timestamps.pendingLightsMistakeAt,
            active: bedtime && state.lightsOn,
            window: TimeConstants.lightsMistakeWindow,
            now: now
        )

        // Reset while asleep — a catch-up tick after wake must not bill the
        // whole night.
        guard !state.isSleeping else {
            state.timestamps.pendingCareMistakeAt = nil
            return state
        }

        let needsAttention = state.hungerHearts.isEmpty || state.strengthHearts.isEmpty
        state.careMistakes += accrueMistakes(
            anchor: &state.timestamps.pendingCareMistakeAt,
            active: needsAttention,
            window: TimeConstants.careMistakeWindow,
            now: now
        )

        return state
    }

    // MARK: - Accrual

    /// Counts one mistake per elapsed `window` since `anchor` while the condition
    /// is active, seeding the anchor on the first active tick and advancing it by
    /// the consumed span. Clears the anchor once the condition lifts.
    private static func accrueMistakes(
        anchor: inout Date?,
        active: Bool,
        window: TimeInterval,
        now: Date
    ) -> Int {
        guard active else {
            anchor = nil
            return 0
        }
        guard let pendingAt = anchor else {
            anchor = now
            return 0
        }

        let mistakes = TickMath.ticks(from: pendingAt, to: now, interval: window)
        if mistakes > 0 {
            anchor = pendingAt.addingTimeInterval(Double(mistakes) * window)
        }
        return mistakes
    }
}
