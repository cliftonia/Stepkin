import Foundation

/// A single care reminder derived from the pet's state. The `id` is stable per
/// kind, so rescheduling replaces the pending request rather than stacking
/// duplicates.
public struct CareNotification: Sendable, Equatable, Identifiable {

    /// The reason the reminder fires. Keys both the message text (worded by the
    /// app, which owns every user-facing string) and the stable identifier: `id`
    /// is the raw value, so one pending request per kind.
    public enum Kind: String, Sendable {
        case hunger
        case strength
        case mess
        case injury
        case exercise
        case fading
    }

    /// Which care need this reminder is for; the app chooses the message from it.
    public let kind: Kind
    /// When the reminder is due — the fire time of the pending request.
    public let fireDate: Date
    /// The pet's species — supplies the personal name and the notification sprite.
    public let species: PetSpecies

    /// The stable request identifier, one per kind.
    public var id: String { kind.rawValue }
}
