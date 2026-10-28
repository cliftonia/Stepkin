import Foundation

/// The full V1 evolution tree as an ordered rule table. Row order is
/// load-bearing: `EvolutionEngine` takes the first satisfied row, so a more
/// specific gate must sit above any broader one that would shadow it.
public enum EvolutionChart {

    // MARK: - Complete Evolution Tree

    /// All chart rows in match order, assembled once by `buildRequirements()`.
    static let requirements: [EvolutionRequirement] = buildRequirements()

    /// Returns the rows leaving a species, preserving chart order so the
    /// first-satisfied-row rule still applies to the filtered slice.
    static func evolutions(
        for species: PetSpecies
    ) -> [EvolutionRequirement] {
        requirements.filter { $0.from == species }
    }

    /// The battle gate a species must clear, or `nil` unless every row leaving it
    /// carries a battle requirement. A species with any ungated row keeps its
    /// hidden branches hidden. Otherwise the gate is the row with the fewest wins.
    public static func battleGate(for species: PetSpecies) -> BattleGate? {
        let rows = evolutions(for: species)
        guard !rows.isEmpty, rows.allSatisfy({ $0.minBattleWins != nil }) else {
            return nil
        }
        let gated = rows.compactMap { row in row.minBattleWins.map { (wins: $0, rate: row.minWinRate) } }
        guard let nearest = gated.min(by: { $0.wins < $1.wins }) else { return nil }
        return BattleGate(minWins: nearest.wins, minWinRate: nearest.rate)
    }

    // MARK: - Private

    private static func buildRequirements() -> [EvolutionRequirement] {
        var chart: [EvolutionRequirement] = []

        chart.append(
            EvolutionRequirement(from: .dotkin, to: .hopkin, isDefault: true)
        )

        chart.append(contentsOf: hopkinPaths())

        chart.append(contentsOf: emberkinPaths())
        chart.append(contentsOf: marshkinPaths())

        chart.append(contentsOf: championPaths())

        return chart
    }

    // MARK: - In-Training Paths

    private static func hopkinPaths() -> [EvolutionRequirement] {
        [
            EvolutionRequirement(
                from: .hopkin, to: .emberkin, maxCareMistakes: 1
            ),
            EvolutionRequirement(
                from: .hopkin, to: .marshkin,
                minCareMistakes: 2, isDefault: true
            ),
        ]
    }

    // MARK: - Emberkin Paths

    private static func emberkinPaths() -> [EvolutionRequirement] {
        [
            EvolutionRequirement(
                from: .emberkin, to: .rexkin,
                maxCareMistakes: 2, minBattleWins: 5
            ),
            EvolutionRequirement(
                from: .emberkin, to: .blazekin,
                minCareMistakes: 4, minWeight: 40
            ),
            EvolutionRequirement(
                from: .emberkin, to: .dreadkin, maxCareMistakes: 3
            ),
            EvolutionRequirement(
                from: .emberkin, to: .pyrekin,
                minCareMistakes: 4, minTrainingCount: 16
            ),
            EvolutionRequirement(
                from: .emberkin, to: .sludgekin, isDefault: true
            ),
        ]
    }

    // MARK: - Marshkin Paths

    private static func marshkinPaths() -> [EvolutionRequirement] {
        [
            EvolutionRequirement(
                from: .marshkin, to: .dreadkin,
                maxCareMistakes: 3, minTrainingCount: 48
            ),
            // Must precede Galekin — first-match would shadow this more specific gate.
            EvolutionRequirement(
                from: .marshkin, to: .tidekin,
                minCareMistakes: 4, minWeight: 35
            ),
            EvolutionRequirement(
                from: .marshkin, to: .galekin, minCareMistakes: 4
            ),
            EvolutionRequirement(
                from: .marshkin, to: .sludgekin, isDefault: true
            ),
        ]
    }

    // MARK: - Champion Paths

    private static func championPaths() -> [EvolutionRequirement] {
        [
            EvolutionRequirement(
                from: .rexkin, to: .steelkin,
                minBattleWins: 15, minWinRate: 0.8, isDefault: true
            ),
            EvolutionRequirement(
                from: .blazekin, to: .orbkin, isDefault: true
            ),
            EvolutionRequirement(
                from: .dreadkin, to: .steelkin, isDefault: true
            ),
            EvolutionRequirement(
                from: .pyrekin, to: .orbkin, isDefault: true
            ),
            EvolutionRequirement(
                from: .galekin, to: .steelkin, isDefault: true
            ),
            EvolutionRequirement(
                from: .tidekin, to: .orbkin, isDefault: true
            ),
            EvolutionRequirement(
                from: .sludgekin, to: .plushkin, isDefault: true
            ),
        ]
    }
}
