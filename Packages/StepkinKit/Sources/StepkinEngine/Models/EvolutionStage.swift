import Foundation

/// The five growth stages of the V1 lifecycle, always derived from
/// `PetSpecies` (never persisted) so a pet's stage can never disagree with its
/// species. Per-stage tuning lives here in one switch per knob.
public enum EvolutionStage: Int, Codable, Sendable, CaseIterable {
    case fresh = 0
    case inTraining
    case rookie
    case champion
    case ultimate

    /// Battle HP for stage-generated opponents only; the player's pet fights
    /// on `PetSpecies.baseHP` plus its trained bonus (see `BattleHP`).
    public var battleHP: Int {
        switch self {
        case .fresh: 1
        case .inTraining: 2
        case .rookie: 3
        case .champion: 4
        case .ultimate: 5
        }
    }

    /// Lifetime active steps needed to leave this stage (a single growing
    /// counter). The final stage never evolves, so its bar is effectively
    /// unreachable.
    public var stepsToEvolve: Int {
        switch self {
        case .fresh: 10_000
        case .inTraining: 50_000
        case .rookie: 300_000
        case .champion: 1_000_000
        case .ultimate: .max
        }
    }

    /// Extra steps added to this stage's evolution goal for each lazy day (fewer
    /// than `StepProgress.lazyThreshold` active steps). Later stages are penalised
    /// harder, so neglecting an older pet costs more progress.
    public var lazyDayPenalty: Int {
        switch self {
        case .fresh: 4_000
        case .inTraining: 6_000
        case .rookie: 8_000
        case .champion: 10_000
        case .ultimate: 0
        }
    }

    /// The stage name shown on the stats screen.
    public var displayName: String {
        switch self {
        case .fresh: "Fresh"
        case .inTraining: "In-Training"
        case .rookie: "Rookie"
        case .champion: "Champion"
        case .ultimate: "Ultimate"
        }
    }
}
