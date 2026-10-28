import Foundation

// MARK: - VoiceOver

extension PetViewModel {

    /// One spoken sentence for the whole home screen — the LCD itself is a
    /// Canvas, so this is the only way the pet's condition reaches VoiceOver.
    var accessibilityDescription: String {
        guard let status else { return String(localized: "Virtual pet", comment: "VoiceOver label for the home screen before a pet exists.") }
        return PetStatusSentence.describe(status, includeMenu: menuSelection.accessibilityName)
    }
}

extension PetViewModel.MenuAction: Identifiable {

    /// The entry itself identifies its icon in the menu strip.
    var id: Self { self }

    /// The SF Symbol shown for this entry in the menu icon row.
    var systemImage: String {
        switch self {
        case .stats: "heart.text.square"
        case .feed: "fork.knife"
        case .train: "figure.run"
        case .battle: "burst"
        case .clean: "shower"
        case .lights: "lightbulb"
        case .heal: "cross.case"
        case .settings: "gearshape"
        }
    }

    /// The spoken name of this entry, used for VoiceOver labels.
    var accessibilityName: String {
        switch self {
        case .stats: String(localized: "stats", comment: "Spoken menu entry name.")
        case .feed: String(localized: "feed", comment: "Spoken menu entry name.")
        case .train: String(localized: "train", comment: "Spoken menu entry name.")
        case .battle: String(localized: "battle", comment: "Spoken menu entry name.")
        case .clean: String(localized: "clean", comment: "Spoken menu entry name.")
        case .lights: String(localized: "lights", comment: "Spoken menu entry name.")
        case .heal: String(localized: "heal", comment: "Spoken menu entry name.")
        case .settings: String(localized: "settings", comment: "Spoken menu entry name.")
        }
    }
}
