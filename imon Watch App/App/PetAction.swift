import Foundation

/// One action an external caller (a background wake or an intent) can ask of
/// the pet, routed by `PetActionRouter` to whichever writer owns the save.
nonisolated enum PetAction: Sendable {
    /// Advances the pet to now, settles its steps and checks evolution.
    case tick
    /// Feeds the pet the given food, as the home screen's feed menu does.
    case feed(FeedAction.FoodKind)
}

/// The outcome an action reports back to its caller, phrased so an intent can
/// speak it.
nonisolated enum PetActionOutcome: Sendable, Equatable {
    /// The action ran (or, live, its ceremony started).
    case done
    /// The pet declined the action; `reason` is the sentence to show or speak.
    case refused(reason: String)
    /// There is no living pet to act on (no save, an unreadable save, or an egg).
    case noPet
}

/// The single source of the words a refused feed is explained with, shared by
/// the live presenter and the offline session so both refuse identically.
nonisolated enum FeedRefusal {

    /// The reason given when `FeedAction.canFeed` fails: the pet is asleep or gone.
    static var cannotEat: String { String(localized: "Your pet can't eat right now.", comment: "Feed refusal: the pet is asleep or gone.") }

    /// The reason given when the food's heart is already full.
    static var full: String { String(localized: "Your pet is full.", comment: "Feed refusal: the food's heart is already full.") }

    /// The reason given when a ceremony or mode is running on the home screen.
    static var busy: String { String(localized: "Your pet is busy right now.", comment: "Feed refusal: a ceremony is running.") }

    /// The refusal reason for feeding `food` to `state`, or nil when the feed
    /// may go ahead; checks `canFeed` before `isSated`, as the home screen does.
    static func reason(for state: PetState, food: FeedAction.FoodKind) -> String? {
        guard FeedAction.canFeed(state) else { return cannotEat }
        guard !FeedAction.isSated(state, food: food) else { return full }
        return nil
    }
}
