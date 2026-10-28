import WidgetKit
import AppIntents
import Foundation

/// The complication's view of one timeline snapshot. A deliberate mirror of the
/// app's `ComplicationEntry`, kept here so the extension shares no source with
/// the app — the contract is the JSON the app writes to the App Group. Decodes
/// only the subset of `ComplicationEntry`'s keys the views render; `JSONDecoder`
/// ignores the extra keys the app writes.
struct WidgetEntry: TimelineEntry, Codable {
    /// When the snapshot becomes current on the watch face; the entry dates also drive the
    /// timeline reload.
    let date: Date
    /// The species the views name for this snapshot.
    let speciesName: String
    /// The baked sprite, one 16-bit row per element, rendered by the views.
    let spriteRows: [UInt16]
    /// Hunger hearts remaining, rendered against `hungerMax`.
    let hungerValue: Int
    /// Hunger hearts at full; the denominator of `hungerValue`.
    let hungerMax: Int
    /// Whether the pet is making a care call; the views flag the snapshot when true.
    let needsAttention: Bool
    /// A short state word the views show as text, e.g. `"happy"`.
    let statusText: String
    /// Whether the pet is injured; absent in a timeline baked by an older app.
    let isInjured: Bool?
    /// Whether the pet is dead; absent in a timeline baked by an older app.
    let isDead: Bool?
    /// Whether the pet is still an egg; absent in a timeline baked by an older app.
    let isEgg: Bool?
}

extension WidgetEntry {
    /// The newborn's idle pose (a copy of the app's Dotkin frame — the extension
    /// shares no source with the app), so the gallery preview and a fresh install
    /// show a creature rather than an empty box.
    static let placeholder = WidgetEntry(
        date: Date(),
        speciesName: "Dotkin",
        spriteRows: [
            0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
            0x03C0, 0x0FF0, 0x1FF8, 0x37B8, 0x3FF8, 0x3C78, 0x1FF8, 0x0FF0, 0x03C0,
            0x0000
        ],
        hungerValue: 2,
        hungerMax: 4,
        needsAttention: false,
        statusText: "happy",
        isInjured: nil,
        isDead: nil,
        isEgg: nil
    )
}

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
