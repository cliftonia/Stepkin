import Foundation
import StepkinCore

/// Injures the pet when poop piles reach `TimeConstants.maxPoopPiles` — one
/// pile sooner when the wearer is sedentary. Injury is how an untended mess
/// escalates: it bumps the lifetime count and starts the untreated-injury
/// countdown `DeathEvaluator` turns into a death. Where the other simulators
/// count whole intervals from their anchors, this trigger is a pile count,
/// so activity scaling only shifts the threshold.
enum InjurySimulator {

    /// The mess as it stood before this step's piles were added, from which
    /// the moment a pile crossed the threshold is worked out.
    struct MessBefore {
        /// The pile count before `PoopSimulator` ran.
        let piles: Int
        /// The poop anchor before `PoopSimulator` ran.
        let lastPoopAt: Date
    }

    /// Injures at the threshold and returns the state unchanged otherwise —
    /// asleep, dead, egg and already-injured pets all pass through. `steps`
    /// is today's running count: `nil` counts as not sedentary, and a
    /// sedentary reading (`ActivityModel.isSedentary`) selects the lowered
    /// threshold.
    ///
    /// The injury is dated to the pile that crossed the threshold, worked out
    /// from `before`, so a long catch-up starts the untreated-injury countdown
    /// when the mess really became dangerous rather than when the app next
    /// looked. Without `before`, or when the mess was already at the threshold,
    /// it is dated `now`.
    static func apply(to state: PetState, at now: Date, steps: Int? = nil, before: MessBefore? = nil) -> PetState {
        var state = state
        guard state.isAwakeAndAlive, !state.isInjured else { return state }

        let sedentary = steps.map { ActivityModel.isSedentary(steps: $0) } ?? false
        let threshold = sedentary
            ? TimeConstants.maxPoopPiles - 1
            : TimeConstants.maxPoopPiles

        if state.poopCount >= threshold {
            var injuredAt = now
            if let before, before.piles < threshold {
                let crossed = before.lastPoopAt.addingTimeInterval(Double(threshold - before.piles) * TimeConstants.poopInterval)
                injuredAt = min(now, crossed)
            }
            state.injure(at: injuredAt)
        }

        return state
    }
}
