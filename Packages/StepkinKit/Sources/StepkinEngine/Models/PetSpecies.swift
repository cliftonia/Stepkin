import Foundation

/// The fourteen creatures of the V1 evolution tree. All per-species balance
/// numbers live here as one switch per knob so the whole roster can be read
/// and tuned side by side instead of being scattered across the engine.
public enum PetSpecies: String, Codable, Sendable, CaseIterable, Identifiable {
    // rawValues are the persisted tokens (also the case names). Never user-visible.
    case dotkin
    case hopkin
    case emberkin
    case marshkin
    case rexkin
    case blazekin
    case dreadkin
    case pyrekin
    case galekin
    case tidekin
    case sludgekin
    case steelkin
    case orbkin
    case plushkin

    /// The stable identity, the persisted raw value.
    public var id: String { rawValue }

    /// The creature name shown to the player.
    public var displayName: String {
        switch self {
        case .dotkin: "Dotkin"
        case .hopkin: "Hopkin"
        case .emberkin: "Emberkin"
        case .marshkin: "Marshkin"
        case .rexkin: "Rexkin"
        case .blazekin: "Blazekin"
        case .dreadkin: "Dreadkin"
        case .pyrekin: "Pyrekin"
        case .galekin: "Galekin"
        case .tidekin: "Tidekin"
        case .sludgekin: "Sludgekin"
        case .steelkin: "Steelkin"
        case .orbkin: "Orbkin"
        case .plushkin: "Plushkin"
        }
    }

    /// The growth stage this species belongs to.
    public var stage: EvolutionStage {
        switch self {
        case .dotkin: .fresh
        case .hopkin: .inTraining
        case .emberkin, .marshkin: .rookie
        case .rexkin, .blazekin, .dreadkin,
             .pyrekin, .galekin, .tidekin, .sludgekin: .champion
        case .steelkin, .orbkin, .plushkin: .ultimate
        }
    }

    var basePower: Int {
        switch self {
        case .dotkin: 5
        case .hopkin: 15
        case .emberkin: 40
        case .marshkin: 35
        case .rexkin: 90
        case .blazekin: 75
        case .dreadkin: 85
        case .pyrekin: 70
        case .galekin: 80
        case .tidekin: 78
        case .sludgekin: 30
        case .steelkin: 160
        case .orbkin: 140
        case .plushkin: 130
        }
    }

    var baseWeight: Int {
        switch self {
        case .dotkin: 5
        case .hopkin: 10
        case .emberkin, .marshkin: 20
        case .rexkin, .blazekin, .dreadkin,
             .pyrekin, .galekin, .tidekin, .sludgekin: 30
        case .steelkin, .orbkin, .plushkin: 40
        }
    }

    // MARK: - Capacity (grows per evolution; strength ↔ HP trade off per branch)

    /// The hunger-heart capacity; feeding never fills past it.
    public var maxHunger: Int {
        switch self {
        case .dotkin: 2
        case .hopkin: 3
        case .emberkin, .marshkin, .sludgekin: 4
        case .rexkin, .blazekin, .dreadkin, .pyrekin, .galekin, .tidekin: 5
        case .steelkin, .orbkin, .plushkin: 6
        }
    }

    /// The strength-heart capacity; vitamins never fill past it.
    public var maxStrength: Int {
        switch self {
        case .dotkin: 2
        case .hopkin: 3
        case .marshkin, .sludgekin: 3
        case .emberkin, .pyrekin, .tidekin: 4
        case .blazekin, .dreadkin, .galekin, .plushkin: 5
        case .rexkin, .steelkin, .orbkin: 6
        }
    }

    var baseHP: Int {
        switch self {
        case .dotkin: 2
        case .hopkin: 3
        case .emberkin: 4
        case .marshkin: 5
        case .rexkin: 4
        case .blazekin, .dreadkin, .galekin: 5
        case .pyrekin, .tidekin, .sludgekin: 6
        case .steelkin: 5
        case .orbkin: 6
        case .plushkin: 7
        }
    }
}
