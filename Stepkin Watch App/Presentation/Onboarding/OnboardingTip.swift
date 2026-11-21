import Foundation

/// One step of the post-hatch walkthrough: a line Dotkin "speaks" and the
/// animation it plays while saying it. Kept as data so the flow is a simple
/// list the presenter steps through.
nonisolated struct OnboardingTip: Sendable, Identifiable {
    /// The tip's index in `walkthrough`, doubling as its `Identifiable` identity.
    let id: Int
    /// The animation Dotkin acts out while the message is shown.
    let animation: SpriteCatalog.AnimationKind
    /// The line Dotkin speaks for this step.
    let message: String
}

extension OnboardingTip {

    /// The full first-run walkthrough, in order. Dotkin narrates each tip and
    /// acts it out (eating, walking, attacking…) so the lesson is shown, not
    /// just told. Covers the core loops: care, activity, growth, environment.
    static let walkthrough: [OnboardingTip] = [
        OnboardingTip(
            id: 0, animation: .happy,
            message: String(localized: "Hi! I'm Dotkin. Look after me and I'll grow!", comment: "Onboarding tip spoken by Dotkin.")
        ),
        OnboardingTip(
            id: 1, animation: .eat,
            message: String(localized: "Feed me meat to fill up, vitamins for strength.", comment: "Onboarding tip spoken by Dotkin.")
        ),
        OnboardingTip(
            id: 2, animation: .idle,
            message: String(localized: "Clean my mess, and heal me when I'm sick.", comment: "Onboarding tip spoken by Dotkin.")
        ),
        OnboardingTip(
            id: 3, animation: .sideWalk,
            message: String(localized: "Your real steps grow me. Walk daily!", comment: "Onboarding tip spoken by Dotkin.")
        ),
        OnboardingTip(
            id: 4, animation: .attack,
            message: String(localized: "Train and battle to grow stronger.", comment: "Onboarding tip spoken by Dotkin.")
        ),
        OnboardingTip(
            id: 5, animation: .happy,
            message: String(localized: "Care well and stay active to evolve me!", comment: "Onboarding tip spoken by Dotkin.")
        ),
        OnboardingTip(
            id: 6, animation: .sleep,
            message: String(localized: "I follow real weather. Lights off to sleep.", comment: "Onboarding tip spoken by Dotkin.")
        ),
        OnboardingTip(
            id: 7, animation: .happy,
            message: String(localized: "That's it. Let's begin!", comment: "Onboarding tip spoken by Dotkin.")
        )
    ]
}
