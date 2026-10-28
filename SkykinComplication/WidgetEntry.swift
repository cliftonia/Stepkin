import WidgetKit
import Foundation

/// The complication's view of one timeline snapshot. A deliberate mirror of the
/// app's `ComplicationEntry`, kept here so the extension shares no source with
/// the app — the contract is the JSON the app writes to the App Group. Decodes
/// only the subset of `ComplicationEntry`'s keys the views render; `JSONDecoder`
/// ignores the extra keys the app writes.
struct WidgetEntry: TimelineEntry, Codable, Sendable {
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
