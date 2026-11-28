import Foundation
import StepkinCore

/// Medicine: clears the current injury. The lifetime `injuryCount` stays, so
/// repeated injuries still count toward `maxInjuriesBeforeDeath` — healing
/// treats the wound, it does not erase the history.
public enum HealAction {

    // MARK: - Query

    /// Reports whether the pet can be healed: only while alive, hatched and
    /// injured, and only once the mess is below the lowest pile count that
    /// injures (`InjurySimulator`'s sedentary threshold). Healed among that
    /// much mess, the pet would be wounded again on the next tick.
    public static func canHeal(_ state: PetState) -> Bool {
        !state.isDead && !state.isEgg && state.isInjured && state.poopCount < TimeConstants.maxPoopPiles - 1
    }

    // MARK: - Apply

    /// Applies the medicine, returning the state unchanged when `canHeal` is
    /// false.
    public static func apply(to state: PetState) -> PetState {
        guard canHeal(state) else { return state }

        var state = state
        state.heal()
        return state
    }
}
