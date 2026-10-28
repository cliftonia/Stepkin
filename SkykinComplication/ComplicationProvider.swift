import WidgetKit
import AppIntents
import Foundation

/// The complication's timeline provider. Reads the baked timeline the app
/// writes to the App Group — no engine here: the app does all the simulation
/// and bakes the result, including the sprite.
struct ComplicationProvider: TimelineProvider {

    // Must match `AppGroup.identifier` and `ComplicationStore.key` in the app.
    private static let appGroup = "group.cliftonia.stepkin"
    private static let timelineKey = "com.cliftonia.imon.complicationTimeline"

    /// Returns `WidgetEntry.placeholder`, the newborn pose shown before the app
    /// has baked any timeline.
    func placeholder(in context: Context) -> WidgetEntry { .placeholder }

    /// Answers with the first baked entry, or the placeholder when the App
    /// Group holds nothing readable.
    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        completion(loadEntries().first ?? .placeholder)
    }

    /// Answers with the baked entries and asks WidgetKit to reload one hour
    /// after the last entry's date; an unreadable App Group yields a one-entry
    /// timeline of the placeholder.
    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let entries = loadEntries()
        let last = entries.last ?? .placeholder
        let next = last.date.addingTimeInterval(3_600)
        completion(Timeline(entries: entries, policy: .after(next)))
    }

    /// Tells the Smart Stack when to raise the widget: while the baked timeline shows the
    /// pet calling for care.
    func relevance() async -> WidgetRelevance<Void> {
        let attributes = RelevanceWindows.windows(in: loadEntries()).map {
            WidgetRelevanceAttribute(context: RelevantContext.date(interval: $0, kind: .scheduled))
        }
        return WidgetRelevance(attributes)
    }

    private func loadEntries() -> [WidgetEntry] {
        guard let defaults = UserDefaults(suiteName: Self.appGroup),
              let data = defaults.data(forKey: Self.timelineKey),
              let entries = try? JSONDecoder().decode([WidgetEntry].self, from: data),
              !entries.isEmpty
        else {
            return [.placeholder]
        }
        return entries
    }
}
