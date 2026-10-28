import Foundation

/// A glanceable snapshot of the pet for the watch-face complication. Pure data
/// and `Codable` — the app bakes everything (including the pet's 16×16 pixel
/// rows) into this so the widget process can render without importing the
/// engine. The widget target deliberately
/// compiles none of the app's source: it decodes the JSON this type writes into
/// its own `WidgetEntry` mirror, so the serialised keys are the contract.
public struct ComplicationEntry: Codable, Sendable, Equatable {

    /// When the snapshot was baked.
    public let date: Date
    /// The pet's species display name.
    public let speciesName: String
    /// The pet's current 16×16 sprite, one `UInt16` per row (MSB = leftmost).
    public let spriteRows: [UInt16]
    /// Hunger hearts remaining; read against `hungerMax`.
    public let hungerValue: Int
    /// Total hunger hearts, the denominator for `hungerValue`.
    public let hungerMax: Int
    /// Whether the pet has an outstanding care call.
    public let needsAttention: Bool
    /// Whether the pet is injured.
    public let isInjured: Bool
    /// Whether the pet has died.
    public let isDead: Bool
    /// Whether the pet is still an egg rather than a hatched species.
    public let isEgg: Bool
    /// A one-word mood for the inline complication ("happy", "hungry", …).
    public let statusText: String
    /// The mood as a stable identifier (a `Mood` raw value) the widget localizes;
    /// `statusText` stays alongside it so a stale timeline still renders.
    public let moodKey: String

    /// Creates an entry from its baked values; the serialised keys are the
    /// widget's decoding contract.
    public init(
        date: Date,
        speciesName: String,
        spriteRows: [UInt16],
        hungerValue: Int,
        hungerMax: Int,
        needsAttention: Bool,
        isInjured: Bool,
        isDead: Bool,
        isEgg: Bool,
        statusText: String,
        moodKey: String
    ) {
        self.date = date
        self.speciesName = speciesName
        self.spriteRows = spriteRows
        self.hungerValue = hungerValue
        self.hungerMax = hungerMax
        self.needsAttention = needsAttention
        self.isInjured = isInjured
        self.isDead = isDead
        self.isEgg = isEgg
        self.statusText = statusText
        self.moodKey = moodKey
    }

    /// Creates an entry from a state snapshot and the sprite rows to bake,
    /// deriving the display values and the mood word from the pet's status.
    public init(date: Date, state: PetState, spriteRows: [UInt16]) {
        let status = PetStatus(from: state)
        let mood = Mood(for: status)
        self.init(
            date: date,
            speciesName: status.species.displayName,
            spriteRows: spriteRows,
            hungerValue: status.hungerHearts.value,
            hungerMax: status.species.maxHunger,
            needsAttention: status.needsAttention,
            isInjured: status.isInjured,
            isDead: status.isDead,
            isEgg: status.isEgg,
            statusText: mood.rawValue,
            moodKey: mood.rawValue
        )
    }

    /// The pet's mood for the complication face; the raw value is the identifier
    /// baked as `moodKey`, which the widget turns into a localized word. The widget
    /// cannot import the engine, so its `moodText` keys must match these by hand.
    public enum Mood: String, Sendable, CaseIterable {
        case gone, egg, hurt, hungry, weak, messy, asleep, happy

        /// Picks the mood for a status. The check order is the precedence: first
        /// match wins, so `asleep` and `happy` appear only when every earlier
        /// state is false.
        init(for status: PetStatus) {
            if status.isDead { self = .gone; return }
            if status.isEgg { self = .egg; return }
            if status.isInjured { self = .hurt; return }
            if status.hungerHearts.isEmpty { self = .hungry; return }
            if status.strengthHearts.isEmpty { self = .weak; return }
            if status.poopCount > 0 { self = .messy; return }
            self = status.isSleeping ? .asleep : .happy
        }
    }
}
