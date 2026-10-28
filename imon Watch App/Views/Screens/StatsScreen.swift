import SwiftUI

/// The Stats screen, showing the pet's species and stage, core stats, hunger
/// and strength meters, and battle record as read from `StatsPresenter`.
struct StatsScreen: View {

    /// The presenter owning this screen's state; every section reads its
    /// view model.
    let presenter: StatsPresenter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                speciesHeader
                Divider()
                coreStats
                heartMeters
                Divider()
                battleStats
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle("Stats")
    }

    private var speciesHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(presenter.viewModel.speciesName)
                .font(.lcd(14, weight: .bold))

            Text(presenter.viewModel.stageName)
                .font(.lcd(11))
                .foregroundStyle(Color.gray)
        }
    }

    private var coreStats: some View {
        VStack(alignment: .leading, spacing: 4) {
            statRow(
                label: "AGE",
                value: "\(presenter.viewModel.ageDays)d"
            )
            statRow(
                label: "WEIGHT",
                value: "\(presenter.viewModel.weightGrams)G"
            )
            statRow(
                label: "TODAY",
                value: presenter.viewModel.activityLabel
            )
            statRow(
                label: "EVOLVE",
                value: presenter.viewModel.evolveProgress
            )
            if let battleGate = presenter.viewModel.battleGate {
                statRow(label: "NEXT", value: battleGate)
            }
        }
    }

    private var heartMeters: some View {
        VStack(alignment: .leading, spacing: 4) {
            HeartMeter(
                label: "HUNGER",
                filledCount: presenter.viewModel.hungerHearts,
                maxCount: presenter.viewModel.maxHunger
            )
            HeartMeter(
                label: "STR",
                filledCount: presenter.viewModel.strengthHearts,
                maxCount: presenter.viewModel.maxStrength
            )
        }
    }

    private var battleStats: some View {
        VStack(alignment: .leading, spacing: 4) {
            statRow(
                label: "HP",
                value: presenter.viewModel.hpDisplay
            )
            statRow(
                label: "POW",
                value: presenter.viewModel.powerBonus
            )
            statRow(
                label: "WIN",
                value: "\(presenter.viewModel.battleWins)"
            )
            statRow(
                label: "LOSE",
                value: "\(presenter.viewModel.battleLosses)"
            )
            statRow(
                label: "RATE",
                value: presenter.viewModel.winRate
            )
        }
    }

    // MARK: - Helpers

    private func statRow(label: String, value: String) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.lcd(10, weight: .medium))
                .frame(width: 50, alignment: .leading)

            Text(value)
                .font(.lcd(10))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }
}
