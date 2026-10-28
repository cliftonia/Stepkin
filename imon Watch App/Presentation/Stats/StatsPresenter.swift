import Foundation

/// Presenter for the read-only stats screen. `update(from:steps:stepsEnabled:)`
/// formats a one-shot snapshot of the live `PetState` into display strings — the
/// screen does not tick, so its figures are frozen at the moment Stats was opened.
/// With the Steps switch off the activity row says so; the evolution row keeps
/// its normal total over goal because a time-fed pet still grows.
final class StatsPresenter {

    /// The display snapshot the stats screen renders; rewritten in full on every update.
    private(set) var viewModel = StatsViewModel()

    // MARK: - Update

    /// Writes the full snapshot from `state` into the view model. A `nil`
    /// `steps` renders the activity row as a dash; `stepsEnabled == false`
    /// overrides both step-fed rows before any step value is read.
    func update(from state: PetState, steps: Int?, stepsEnabled: Bool = true) {
        let status = PetStatus(from: state)
        viewModel.speciesName = status.species.displayName
        viewModel.stageName = status.stage.displayName
        viewModel.ageDays = status.ageDays
        viewModel.weightGrams = status.weightGrams
        viewModel.hungerHearts = status.hungerHearts.value
        viewModel.maxHunger = status.species.maxHunger
        viewModel.strengthHearts = status.strengthHearts.value
        viewModel.maxStrength = status.species.maxStrength
        let hp = BattleHP.calculate(for: state, steps: steps)
        viewModel.hpDisplay = state.trainedHP > 0 ? "\(hp) (+\(state.trainedHP))" : "\(hp)"
        viewModel.powerBonus = "+\(state.trainedPower)"
        if !stepsEnabled {
            viewModel.activityLabel = "Steps off"
        } else if let steps {
            let active = !ActivityModel.isSedentary(steps: steps)
            viewModel.activityLabel = "\(steps) \u{00b7} \(active ? "Active" : "Resting")"
        } else {
            viewModel.activityLabel = "—"
        }
        let total = StatFormatter.grouped(state.lifetimeActiveSteps)
        if status.species.stage == .ultimate {
            viewModel.evolveProgress = "MAX \u{00b7} " + total
        } else {
            viewModel.evolveProgress = total + " / " + StatFormatter.grouped(state.evolutionGoal)
        }
        viewModel.battleWins = status.battleWins
        viewModel.battleLosses = status.battleLosses

        let battles = status.battleWins + status.battleLosses
        viewModel.winRate = StatFormatter.percent(status.battleWins, of: battles) ?? "—"
        viewModel.battleGate = Self.battleGateLine(for: status)
    }

    // MARK: - Battle Gate

    /// Formats the species' battle gate as progress over target, with the win
    /// rate appended when the gate sets one; `nil` when no gate is named.
    private static func battleGateLine(for status: PetStatus) -> String? {
        guard let gate = EvolutionChart.battleGate(for: status.species) else { return nil }
        var line = "\(status.battleWins) / \(gate.minWins) wins"
        if let rate = gate.minWinRate {
            line += " \u{00b7} \(Int((rate * 100).rounded()))%"
        }
        return line
    }
}
