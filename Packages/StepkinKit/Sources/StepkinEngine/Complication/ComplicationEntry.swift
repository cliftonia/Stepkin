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
        statusText: String
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
    }

    /// Creates an entry from a state snapshot and the sprite rows to bake,
    /// deriving the display values and the mood word from the pet's status.
    public init(date: Date, state: PetState, spriteRows: [UInt16]) {
        let status = PetStatus(from: state)
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
            statusText: Self.mood(for: status)
        )
    }

    /// Status word for the complication face. The check order is the
    /// precedence: first match wins, so `asleep` and `happy` appear only when
    /// every earlier state is false.
    private static func mood(for status: PetStatus) -> String {
        if status.isDead { return "gone" }
        if status.isEgg { return "egg" }
        if status.isInjured { return "hurt" }
        if status.hungerHearts.isEmpty { return "hungry" }
        if status.strengthHearts.isEmpty { return "weak" }
        if status.poopCount > 0 { return "messy" }
        if status.isSleeping { return "asleep" }
        return "happy"
    }
}
