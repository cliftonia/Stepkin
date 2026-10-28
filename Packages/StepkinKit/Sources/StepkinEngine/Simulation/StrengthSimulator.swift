import Foundation
import StepkinCore

/// Decays strength hearts one per `strengthDepletionInterval` (60 min),
/// counting whole intervals from the `lastStrengthDecayAt` anchor.
///
/// Activity scaling runs inverse to hunger — strength depletes faster the
/// less the wearer moves (`ActivityModel.strengthRateMultiplier`). Like the
/// other simulators, the enum is stateless: all progress lives in the
/// anchor, so catch-up and `wake` re-anchoring need no simulator-local
/// state.
enum StrengthSimulator {

    /// Skips depletion while the pet sleeps or is dead: `wake` re-anchors
    /// strength along with hunger and poop, so sleep reads as a pause.
    /// `steps` is today's running count, fed to
    /// `ActivityModel.strengthRateMultiplier`; `nil` keeps the base
    /// interval. Emptying the last heart stamps `strengthEmptiedAt`, which
    /// `CollapseTracker` uses to start the languishing countdown.
    static func apply(to state: PetState, at now: Date, steps: Int? = nil) -> PetState {
        var state = state
        guard state.isAwakeAndAlive else { return state }

        let multiplier = steps.map { ActivityModel.strengthRateMultiplier(steps: $0) } ?? 1.0
        let emptiedAt = HeartDecay.deplete(
            &state.strengthHearts,
            anchor: &state.timestamps.lastStrengthDecayAt,
            baseInterval: TimeConstants.strengthDepletionInterval,
            multiplier: multiplier,
            at: now
        )
        state.timestamps.strengthEmptiedAt = state.strengthHearts.isEmpty
            ? (state.timestamps.strengthEmptiedAt ?? emptiedAt ?? now)
            : nil
        return state
    }
}
