import Foundation
import Observation

/// The Settings screen's presenter. Toggles bind straight to the shared
/// `SettingsStore` (itself observable); the debug actions (DEBUG only) are
/// injected closures onto the app's presenters, so this stays free of
/// navigation and game knowledge. Holds no ViewModel — everything it exposes
/// is immutable or already observable.
final class SettingsPresenter {

    /// The shared store the Settings screen's toggles bind to directly.
    let settings: SettingsStore

    /// "1.0 (1)" from the bundle, "—" for missing values; shown on the About row.
    var versionLabel: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return String(localized: "\(version) (\(build))", comment: "Settings About row: app version and build number.")
    }

    #if DEBUG
    /// The developer actions shown in the screen's Debug section.
    let debug: SettingsDebugActions

    /// Creates the presenter for the Settings screen, with the developer
    /// actions shown in its Debug section.
    init(settings: SettingsStore, debug: SettingsDebugActions) {
        self.settings = settings
        self.debug = debug
    }
    #else
    /// Creates the presenter for the Settings screen.
    init(settings: SettingsStore) {
        self.settings = settings
    }
    #endif
}

#if DEBUG
/// The developer-only actions under the Settings screen's Debug section,
/// injected as a witness so `SettingsPresenter` holds no game knowledge.
@MainActor
struct SettingsDebugActions {
    /// Debug action forcing a weather condition.
    let setWeather: (WeatherIconCondition?) -> Void
    /// Debug action forcing an evolution.
    let forceEvolve: () -> Void
    /// Debug action running the care test.
    let careTest: () -> Void
    /// Debug action killing the pet.
    let killPet: () -> Void
    /// Debug action morphing the pet into the given species.
    let morph: (PetSpecies) -> Void
}
#endif
