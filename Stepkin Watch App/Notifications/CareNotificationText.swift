import Foundation

/// The words of every notification the app sends, resolved through the string
/// catalog. The engine names the reason (`CareNotification.Kind`, an evolution's
/// two species); this type owns the sentence, so the package stays free of
/// user-facing English. Species names are proper nouns and pass through as-is.
nonisolated enum CareNotificationText {

    /// The title of a care reminder: the pet's species name.
    static func title(speciesName: String) -> String {
        speciesName
    }

    /// The body of a care reminder: the care need in a short sentence addressed by name.
    static func body(for kind: CareNotification.Kind, speciesName name: String) -> String {
        switch kind {
        case .hunger:
            String(localized: "\(name) is hungry!", comment: "Care reminder body; the argument is the pet's species name.")
        case .strength:
            String(
                localized: "\(name) is weak \u{2014} give it vitamins!",
                comment: "Care reminder body; the argument is the pet's species name."
            )
        case .mess:
            String(localized: "\(name) made a mess!", comment: "Care reminder body; the argument is the pet's species name.")
        case .injury:
            String(localized: "\(name) is hurt \u{2014} heal it!", comment: "Care reminder body; the argument is the pet's species name.")
        case .exercise:
            String(localized: "\(name) needs some exercise!", comment: "Care reminder body; the argument is the pet's species name.")
        case .fading:
            String(
                localized: "\(name) is fading \u{2014} care for it now!",
                comment: "Care reminder body; the argument is the pet's species name."
            )
        }
    }

    /// The title of the one-off evolution announcement.
    static var evolutionTitle: String {
        String(localized: "Evolution!", comment: "Notification title announcing that the pet evolved.")
    }

    /// The body of the evolution announcement, naming the species before and after.
    static func evolutionBody(from previous: String, to next: String) -> String {
        String(
            localized: "\(previous) evolved into \(next)!",
            comment: "Evolution notification body; the arguments are the old and the new species names."
        )
    }
}
