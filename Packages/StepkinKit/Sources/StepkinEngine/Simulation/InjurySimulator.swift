import Foundation
import StepkinCore

/// Injures the pet when poop piles reach `TimeConstants.maxPoopPiles` — one
/// pile sooner when the wearer is sedentary. Injury is how an untended mess
/// escalates: it bumps the lifetime count and starts the untreated-injury
/// countdown `DeathEvaluator` turns into a death. Where the other simulators
/// count whole intervals from their anchors, this trigger is a pile count,
/// so activity scaling only shifts the threshold.
enum InjurySimulator {

    /// Injures at the threshold and returns the state unchanged otherwise —
    /// asleep, dead, egg and already-injured pets all pass through. `steps`
    /// is today's running count: `nil` counts as not sedentary, and a
    /// sedentary reading (`ActivityModel.isSedentary`) selects the lowered
    /// threshold.
    static func apply(to state: PetState, at now: Date, steps: Int? = nil) -> PetState {
        var state = state
        guard state.isAwakeAndAlive, !state.isInjured else { return state }

        let sedentary = steps.map { ActivityModel.isSedentary(steps: $0) } ?? false
        let threshold = sedentary
            ? TimeConstants.maxPoopPiles - 1
            : TimeConstants.maxPoopPiles

        if state.poopCount >= threshold {
            state.injure(at: now)
        }

        return state
    }
}
