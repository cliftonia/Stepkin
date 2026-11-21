import Observation
import WatchKit

/// The settings store: user toggles persisted to `UserDefaults` and shared
/// across screens. Main-actor isolated because views bind to it directly.
@MainActor
@Observable
final class SettingsStore {

    /// Forces the red battery-saver palette on. `ContentView` ORs it with
    /// system Low Power Mode, so either this switch or the system setting
    /// turns it red.
    var batterySaverEnabled: Bool {
        didSet { defaults.set(batterySaverEnabled, forKey: Key.batterySaver) }
    }

    /// The notifications toggle, persisted on every change and enabled by default.
    var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Key.notifications) }
    }

    /// The weather toggle, persisted on every change and enabled by default.
    var weatherEnabled: Bool {
        didSet { defaults.set(weatherEnabled, forKey: Key.weather) }
    }

    /// The steps toggle, persisted on every change and enabled by default.
    var stepsEnabled: Bool {
        didSet { defaults.set(stepsEnabled, forKey: Key.steps) }
    }

    /// The haptics toggle, written through to `WKInterfaceDevice.hapticsEnabled`
    /// on every change and applied once at init.
    var hapticsEnabled: Bool {
        didSet {
            defaults.set(hapticsEnabled, forKey: Key.haptics)
            WKInterfaceDevice.hapticsEnabled = hapticsEnabled
        }
    }

    private let defaults: UserDefaults

    /// The `UserDefaults` keys the toggles persist under. The strings address
    /// already-stored settings, so they must not be renamed.
    private enum Key {
        static let batterySaver = "settings.batterySaver"
        static let notifications = "settings.notifications"
        static let weather = "settings.weather"
        static let steps = "settings.steps"
        static let haptics = "settings.haptics"
    }

    /// Creates the store over the injected `UserDefaults`. Keys with no prior
    /// write fall back to per-toggle defaults, and the haptics toggle is
    /// applied to `WKInterfaceDevice.hapticsEnabled` on creation.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // Integrations default on; battery saver defaults off (it follows Low
        // Power Mode until switched on). object(forKey:) is nil before first write.
        batterySaverEnabled = defaults.object(forKey: Key.batterySaver) as? Bool ?? false
        notificationsEnabled = defaults.object(forKey: Key.notifications) as? Bool ?? true
        weatherEnabled = defaults.object(forKey: Key.weather) as? Bool ?? true
        stepsEnabled = defaults.object(forKey: Key.steps) as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: Key.haptics) as? Bool ?? true
        WKInterfaceDevice.hapticsEnabled = hapticsEnabled
    }
}
