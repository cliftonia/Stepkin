import Foundation

/// The app's side of the complication hand-off: writes the baked timeline to the
/// App Group for the widget to read. The widget deliberately shares no source with
/// the app — it reads the JSON via its own mirror (`WidgetEntry` and hardcoded
/// constants in `StepkinComplication/ComplicationProvider.swift`), which must be
/// kept in lock-step with `ComplicationEntry` and the key here.
nonisolated enum ComplicationStore {

    private static let key = "com.cliftonia.imon.complicationTimeline"

    /// Bakes the timeline into the App Group for the widget to read. An encoding
    /// failure skips the write silently, leaving the App Group untouched.
    static func save(
        _ entries: [ComplicationEntry],
        to defaults: UserDefaults = .stepkinShared
    ) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: key)
    }

    /// Reads the baked timeline, or an empty list when nothing has been baked
    /// yet or the stored data fails to decode.
    static func load(
        from defaults: UserDefaults = .stepkinShared
    ) -> [ComplicationEntry] {
        guard let data = defaults.data(forKey: key),
              let entries = try? JSONDecoder().decode([ComplicationEntry].self, from: data)
        else {
            return []
        }
        return entries
    }
}
