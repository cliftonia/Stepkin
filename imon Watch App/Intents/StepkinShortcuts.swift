import AppIntents

/// The phrases Siri recognises for the app; watchOS matches them literally.
struct StepkinShortcuts: AppShortcutsProvider {

    /// Feed and check, each spoken with the app's name.
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: FeedPetIntent(),
            phrases: ["Feed \(.applicationName)"],
            shortTitle: "Feed",
            systemImageName: "fork.knife"
        )
        AppShortcut(
            intent: CheckPetIntent(),
            phrases: ["Check on \(.applicationName)"],
            shortTitle: "Check on",
            systemImageName: "heart.text.square"
        )
    }
}
