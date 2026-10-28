import Foundation
import StepkinCore

/// Adds poop piles for elapsed time, counting whole intervals from the
/// `lastPoopAt` anchor.
///
/// Stateless like the other simulators: all progress lives in the anchor, so
/// catch-up and `wake` re-anchoring need no simulator-local state.
enum PoopSimulator {

    /// Adds one pile per whole `poopInterval` elapsed since the anchor, capped
    /// at `TimeConstants.maxPoopPiles`. A no-op while the pet sleeps or is
    /// dead: `wake` re-anchors poop so sleep reads as a pause. The anchor
    /// advances only by the counted intervals, so a partial remainder carries
    /// into the next tick.
    static func apply(to state: PetState, at now: Date) -> PetState {
        var state = state
        guard state.isAwakeAndAlive else { return state }

        let newPoops = TickMath.ticks(
            from: state.timestamps.lastPoopAt,
            to: now,
            interval: TimeConstants.poopInterval
        )
        guard newPoops > 0 else { return state }

        // Clamp the addend first — `newPoops` may be the overflow sentinel.
        let added = min(newPoops, TimeConstants.maxPoopPiles)
        state.poopCount = min(TimeConstants.maxPoopPiles, state.poopCount + added)
        state.timestamps.lastPoopAt = state.timestamps.lastPoopAt.addingTimeInterval(
            Double(newPoops) * TimeConstants.poopInterval
        )
        return state
    }
}
