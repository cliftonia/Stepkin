import Foundation

/// One row of the `EvolutionChart`: a from→to edge plus the care gates that
/// select it. A `nil` gate is unconstrained; `isDefault` marks the fallback
/// row taken only when no specific row matches.
struct EvolutionRequirement: Sendable {

    /// The species at the start of the from→to edge.
    let from: PetSpecies
    /// The species at the end of the from→to edge.
    let to: PetSpecies
    /// The most care mistakes allowed; exceeding this rejects the row.
    let maxCareMistakes: Int?
    /// The fewest care mistakes required; falling short rejects the row.
    let minCareMistakes: Int?
    /// The fewest battle wins required; falling short rejects the row.
    let minBattleWins: Int?
    /// The minimum win rate, a 0–1 fraction; zero battles fought rejects the row.
    let minWinRate: Double?
    /// The fewest trainings required; falling short rejects the row.
    let minTrainingCount: Int?
    /// The minimum weight, in grams; lighter rejects the row.
    let minWeight: Int?
    /// Whether this is the fallback row, taken only when no specific row matches.
    let isDefault: Bool

    /// Creates a from→to edge with its care gates.
    init(
        from: PetSpecies,
        to: PetSpecies,
        maxCareMistakes: Int? = nil,
        minCareMistakes: Int? = nil,
        minBattleWins: Int? = nil,
        minWinRate: Double? = nil,
        minTrainingCount: Int? = nil,
        minWeight: Int? = nil,
        isDefault: Bool = false
    ) {
        self.from = from
        self.to = to
        self.maxCareMistakes = maxCareMistakes
        self.minCareMistakes = minCareMistakes
        self.minBattleWins = minBattleWins
        self.minWinRate = minWinRate
        self.minTrainingCount = minTrainingCount
        self.minWeight = minWeight
        self.isDefault = isDefault
    }

    // MARK: - Evaluation

    /// Steps gate *when* — lifetime steps must reach the stage threshold, raised
    /// by any lazy-day penalty; the care fields below decide *which* branch.
    func isSatisfied(by state: PetState) -> Bool {
        guard state.lifetimeActiveSteps >= state.evolutionGoal else {
            return false
        }

        if let max = maxCareMistakes, state.careMistakes > max { return false }
        if let min = minCareMistakes, state.careMistakes < min { return false }
        if let wins = minBattleWins, state.battleWins < wins { return false }

        if let rate = minWinRate {
            let total = state.battleWins + state.battleLosses
            guard total > 0 else { return false }
            let winRate = Double(state.battleWins) / Double(total)
            if winRate < rate { return false }
        }

        if let train = minTrainingCount, state.trainingCount < train { return false }
        if let minW = minWeight, state.weight.grams < minW { return false }

        return true
    }
}
