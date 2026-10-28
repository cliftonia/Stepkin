import Foundation
import StepkinCore

/// Feeding: meat refills one hunger heart, a vitamin one strength heart, and
/// either adds weight — the gain is what makes overfeeding a real evolution
/// path (the chart's `minWeight` gates) rather than a free top-up.
public enum FeedAction {

    /// The two foods. The case selects which heart a feed refills and which
    /// weight gain applies, per the switch in `FeedAction.apply`.
    public enum FoodKind: Sendable {
        case meat
        case vitamin
    }

    // MARK: - Query

    /// Reports whether the pet can eat — the gate `apply` checks first; only
    /// an awake, living pet can be fed, regardless of heart levels.
    public static func canFeed(_ state: PetState) -> Bool {
        state.isAwakeAndAlive
    }

    /// Reports whether the stat this food refills is already at capacity, so
    /// eating it would only add weight — a cue for the pet to refuse as "full".
    public static func isSated(_ state: PetState, food: FoodKind) -> Bool {
        switch food {
        case .meat:
            return state.hungerHearts.value >= state.species.maxHunger
        case .vitamin:
            return state.strengthHearts.value >= state.species.maxStrength
        }
    }

    // MARK: - Apply

    /// Feeds the pet, refilling the food's heart up to the species maximum
    /// and adding weight even when that stat is already full. Returns `state`
    /// unchanged when `canFeed` is false.
    public static func apply(to state: PetState, food: FoodKind, at now: Date) -> PetState {
        guard canFeed(state) else { return state }

        var state = state

        switch food {
        case .meat:
            state.hungerHearts.increment(upTo: state.species.maxHunger)
            state.weight.add(TimeConstants.meatWeightGain)
        case .vitamin:
            state.strengthHearts.increment(upTo: state.species.maxStrength)
            state.weight.add(TimeConstants.vitaminWeightGain)
        }

        state.timestamps.lastFedAt = now
        return state
    }
}
