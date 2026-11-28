import Foundation
import StepkinCore

/// Tracks care mistakes from two neglect paths: hunger or strength left
/// empty for longer than `careMistakeWindow` (20 min, paused while asleep),
/// and the light left on past bedtime for longer than `lightsMistakeWindow`
/// (3 h). Pending timestamps record when each neglect period began; a heart
/// that emptied while nothing was watching is billed from when it emptied.
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
            start: now,
            window: TimeConstants.lightsMistakeWindow,
            now: now
        )

        // Held at now while asleep — whichever way the pet comes out of sleep,
        // the night is not billed and nothing counted before it is billed again.
        guard !state.isSleeping else {
            state.timestamps.pendingCareMistakeAt = now
            return state
        }

        // The emptied stamps exist only while their heart is empty, so the
        // earliest one is when this neglect began.
        let emptiedAt = [state.timestamps.hungerEmptiedAt, state.timestamps.strengthEmptiedAt].compactMap(\.self).min()
        let needsAttention = state.hungerHearts.isEmpty || state.strengthHearts.isEmpty
        state.careMistakes += accrueMistakes(
            anchor: &state.timestamps.pendingCareMistakeAt,
            active: needsAttention,
            start: emptiedAt ?? now,
            window: TimeConstants.careMistakeWindow,
            now: now
        )

        return state
    }

    // MARK: - Accrual

    /// Counts one mistake per elapsed `window` since `anchor` while the condition
    /// is active, seeding the anchor with `start` on the first active tick and
    /// advancing it by the consumed span. Clears the anchor once the condition lifts.
    private static func accrueMistakes(
        anchor: inout Date?,
        active: Bool,
        start: Date,
        window: TimeInterval,
        now: Date
    ) -> Int {
        guard active else {
            anchor = nil
            return 0
        }
        let pendingAt = anchor ?? start
        anchor = pendingAt
        let mistakes = TickMath.ticks(from: pendingAt, to: now, interval: window)
        if mistakes > 0 {
            anchor = pendingAt.addingTimeInterval(Double(mistakes) * window)
        }
        return mistakes
    }
}
