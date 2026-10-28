import Foundation
import StepkinCore

/// Depletes hunger hearts while the pet is awake: one heart per
/// `hungerDepletionInterval` (70 min), counted in whole intervals from the
/// `lastHungerDecayAt` anchor and activity-scaled by today's steps via
/// `ActivityModel`. Sleep skips depletion without moving the anchor —
/// `PetState.wake` re-anchors so sleep is a pause.
enum HungerSimulator {

    /// Advances hunger decay to `now` and maintains the `hungerEmptiedAt`
    /// stamp. Returns the state unchanged while the pet is asleep, dead, or
    /// unhatched.
    ///
    /// `steps` is today's running count; `nil` disables activity scaling, so
    /// the base interval stands. `CareNotificationPlanner` mirrors the same
    /// scaling — change both together.
    ///
    /// While hunger is empty, `hungerEmptiedAt` holds the moment the last
    /// heart was spent, or `now` for a state already empty without a stamp;
    /// the `HeartDecay` anchor keeps advancing past empty, so the moment
    /// cannot be reconstructed later. `CollapseTracker` reads it as the true
    /// start of the collapse countdown. Any heart present clears the stamp.
    static func apply(to state: PetState, at now: Date, steps: Int? = nil) -> PetState {
        var state = state
        guard state.isAwakeAndAlive else { return state }

        let multiplier = steps.map { ActivityModel.hungerRateMultiplier(steps: $0) } ?? 1.0
        let emptiedAt = HeartDecay.deplete(
            &state.hungerHearts,
            anchor: &state.timestamps.lastHungerDecayAt,
            baseInterval: TimeConstants.hungerDepletionInterval,
            multiplier: multiplier,
            at: now
        )
        state.timestamps.hungerEmptiedAt = state.hungerHearts.isEmpty
            ? (state.timestamps.hungerEmptiedAt ?? emptiedAt ?? now)
            : nil
        return state
    }
}
