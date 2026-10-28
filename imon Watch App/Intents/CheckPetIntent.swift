import AppIntents

/// Reads the pet's condition aloud from Siri or a Shortcut.
struct CheckPetIntent: AppIntent {

    /// The name Shortcuts shows for the action.
    static let title: LocalizedStringResource = "Check on Stepkin"

    /// Runs in the background; the spoken dialog is the whole answer.
    static let openAppWhenRun = false

    /// Speaks the pet's condition.
    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: IntentDialog(stringLiteral: await Self.speak()))
    }

    /// The sentence spoken for a check: the pet's condition, or the no-pet notice.
    @MainActor
    static func speak() async -> String {
        await IntentGateway.describe() ?? "There is no pet yet."
    }
}
