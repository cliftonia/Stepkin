import Foundation

/// The app-side words for the engine's growth stages; the package names the
/// stage, the string catalog names it to the player.
nonisolated extension EvolutionStage {

    /// The stage name shown on the stats screen and spoken by VoiceOver and Siri.
    var displayName: String {
        switch self {
        case .fresh: String(localized: "Fresh", comment: "Growth stage name.")
        case .inTraining: String(localized: "In-Training", comment: "Growth stage name.")
        case .rookie: String(localized: "Rookie", comment: "Growth stage name.")
        case .champion: String(localized: "Champion", comment: "Growth stage name.")
        case .ultimate: String(localized: "Ultimate", comment: "Growth stage name.")
        }
    }
}
