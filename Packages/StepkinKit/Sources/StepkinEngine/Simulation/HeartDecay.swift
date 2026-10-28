import Foundation
import StepkinCore

/// Spends hunger and strength hearts for whole intervals elapsed since an
/// anchor — shared arithmetic for `HungerSimulator` and `StrengthSimulator`.
/// One heart is spent per whole `baseInterval / multiplier`; `multiplier` is
/// each caller's activity scaling, so the interval stretches or compresses
/// with today's steps. The anchor advances by the full elapsed span even when
/// the hearts are already empty, so spent time is never replayed on a later
/// call. Contrast `ConditioningSimulator.decay`, which advances its anchor
/// only by points consumed.
enum HeartDecay {

    /// Spends one heart per whole interval elapsed since `anchor` and advances
    /// `anchor` by every elapsed interval — even those falling after the hearts
    /// ran out. Returns the moment the last heart was spent, which can be
    /// earlier than `now`; nil when the stat did not reach empty during this
    /// call (no whole interval elapsed, hearts remain, or it was already
    /// empty). Because `anchor` moves past that moment, this return value is
    /// the only record of when empty began; the callers persist it as
    /// `hungerEmptiedAt` / `strengthEmptiedAt`.
    @discardableResult
    static func deplete(
        _ hearts: inout StatHearts,
        anchor: inout Date,
        baseInterval: TimeInterval,
        multiplier: Double,
        at now: Date
    ) -> Date? {
        let interval = baseInterval / multiplier
        let ticks = TickMath.ticks(from: anchor, to: now, interval: interval)
        guard ticks > 0 else { return nil }

        let start = anchor
        let ticksToEmpty = hearts.value
        // `min` caps iterations at the hearts held — `ticks` can be `Int.max`;
        // see the clamp in `TickMath.ticks`.
        for _ in 0..<min(ticks, ticksToEmpty) {
            hearts.decrement()
        }

        anchor = anchor.addingTimeInterval(Double(ticks) * interval)

        guard ticksToEmpty > 0, ticks >= ticksToEmpty else { return nil }
        return start.addingTimeInterval(Double(ticksToEmpty) * interval)
    }
}
