import Foundation

/// A single care reminder derived from the pet's state. The `id` is stable per
/// kind, so rescheduling replaces the pending request rather than stacking
/// duplicates.
public struct CareNotification: Sendable, Equatable, Identifiable {

    /// The reason the reminder fires. Keys both the message text and the stable
    /// identifier: `id` is the raw value, so one pending request per kind.
    public enum Kind: String, Sendable {
        case hunger
        case strength
        case mess
        case injury
        case exercise
        case fading
    }

    /// Which care need this reminder is for; chooses the message in `title` and `body`.
    public let kind: Kind
    /// When the reminder is due — the fire time of the pending request.
    public let fireDate: Date
    /// The pet's species — supplies the personal name and the notification sprite.
    public let species: PetSpecies

    /// The stable request identifier, one per kind.
    public var id: String { kind.rawValue }

    private var name: String { species.displayName }

    /// The notification title, the species name.
    public var title: String { name }

    /// The notification body, the care need in a short sentence.
    public var body: String {
        switch kind {
        case .hunger: "\(name) is hungry!"
        case .strength: "\(name) is weak \u{2014} give it vitamins!"
        case .mess: "\(name) made a mess!"
        case .injury: "\(name) is hurt \u{2014} heal it!"
        case .exercise: "\(name) needs some exercise!"
        case .fading: "\(name) is fading \u{2014} care for it now!"
        }
    }
}
