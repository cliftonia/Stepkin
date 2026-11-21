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
                label: String(
                    localized: "AGE",
                    comment: "Stats row label: the pet's age in days; keep it short and capitalised."
                ),
                value: String(
                    localized: "\(presenter.viewModel.ageDays)d",
                    comment: "Age in days on the LCD; the argument is a whole number and d is an abbreviation of days."
                )
            )
            statRow(
                label: String(
                    localized: "WEIGHT",
                    comment: "Stats row label: the pet's weight; keep it short and capitalised."
                ),
                value: String(
                    localized: "\(presenter.viewModel.weightGrams)G",
                    comment: "Weight on the LCD; the argument is a whole number and G is an abbreviation of grams."
                )
            )
            statRow(
                label: String(
                    localized: "TODAY",
                    comment: "Stats row label: today's step activity; keep it short and capitalised."
                ),
                value: presenter.viewModel.activityLabel
            )
            statRow(
                label: String(
                    localized: "EVOLVE",
                    comment: "Stats row label: progress toward the next evolution; keep it short and capitalised."
                ),
                value: presenter.viewModel.evolveProgress
            )
            if let battleGate = presenter.viewModel.battleGate {
                statRow(
                    label: String(
                        localized: "NEXT",
                        comment: "Stats row label: what the next evolution still needs from battles; keep it short and capitalised."
                    ),
                    value: battleGate
                )
            }
        }
    }

    private var heartMeters: some View {
        VStack(alignment: .leading, spacing: 4) {
            HeartMeter(
                label: String(
                    localized: "HUNGER",
                    comment: "Stats row label for the hunger hearts; keep it short and capitalised."
                ),
                filledCount: presenter.viewModel.hungerHearts,
                maxCount: presenter.viewModel.maxHunger
            )
            HeartMeter(
                label: String(
                    localized: "STR",
                    comment: "Stats row label for strength on a 16-cell LCD; an abbreviation of strength, a translator may keep it."
                ),
                filledCount: presenter.viewModel.strengthHearts,
                maxCount: presenter.viewModel.maxStrength
            )
        }
    }

    private var battleStats: some View {
        VStack(alignment: .leading, spacing: 4) {
            statRow(
                label: String(
                    localized: "HP",
                    comment: "Stats row label for hit points; a translator may keep the abbreviation."
                ),
                value: presenter.viewModel.hpDisplay
            )
            statRow(
                label: String(
                    localized: "POW",
                    comment: "Stats row label for power bonus on a 16-cell LCD; an abbreviation of power, a translator may keep it."
                ),
                value: presenter.viewModel.powerBonus
            )
            statRow(
                label: String(
                    localized: "WIN",
                    comment: "Stats row label for battles won; keep it short and capitalised."
                ),
                value: "\(presenter.viewModel.battleWins)"
            )
            statRow(
                label: String(
                    localized: "LOSE",
                    comment: "Stats row label for battles lost, and LCD caption for a lost game; keep it short and capitalised."
                ),
                value: "\(presenter.viewModel.battleLosses)"
            )
            statRow(
                label: String(
                    localized: "RATE",
                    comment: "Stats row label for the win rate; keep it short and capitalised."
                ),
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
