import AppIntents

/// Feeds the pet from Siri or a Shortcut, through the same router the home screen's writer uses.
struct FeedPetIntent: AppIntent {

    /// The name Shortcuts shows for the action.
    static let title: LocalizedStringResource = "Feed Stepkin"

    /// Runs in the background; the spoken dialog is the whole answer.
    static let openAppWhenRun = false

    /// Which food to feed.
    @Parameter(title: "Food")
    var food: FoodChoice

    /// Feeds the pet and speaks what happened.
    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: IntentDialog(stringLiteral: await Self.speak(food: food)))
    }

    /// The sentence spoken for feeding `food`: confirmation, refusal, or no-pet.
    @MainActor
    static func speak(food: FoodChoice) async -> String {
        switch await IntentGateway.route(.feed(food.kind)) {
        case .done: String(localized: "Fed.", comment: "Siri answer after feeding the pet.")
        case .refused(let reason): reason
        case .noPet: String(localized: "There is no pet to feed yet.", comment: "Siri answer when no pet has hatched.")
        }
    }
}
