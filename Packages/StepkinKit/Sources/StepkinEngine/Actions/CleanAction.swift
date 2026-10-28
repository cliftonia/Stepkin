import Foundation

/// Flushes every poop pile in one go; there is deliberately no per-pile scoop.
///
/// A caseless enum because the action is pure behaviour over `PetState` — no
/// instance state exists to carry between the `canClean` gate and `apply`.
public enum CleanAction {

    // MARK: - Query

    /// Reports whether cleaning can proceed: the pet is alive, hatched, and
    /// has at least one pile to remove.
    public static func canClean(_ state: PetState) -> Bool {
        !state.isDead && !state.isEgg && state.poopCount > 0
    }

    // MARK: - Apply

    /// Removes every pile and re-anchors `lastPoopAt` to `now`, so a pile
    /// nearly due does not reappear right after cleaning. Returns the state
    /// unchanged when `canClean` says there is nothing to do.
    public static func apply(to state: PetState, at now: Date) -> PetState {
        guard canClean(state) else { return state }

        var state = state
        state.poopCount = 0
        state.timestamps.lastPoopAt = now
        return state
    }
}
