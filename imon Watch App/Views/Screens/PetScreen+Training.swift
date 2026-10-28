import SwiftUI

extension PetScreen {

    // MARK: - Training LCD

    @ViewBuilder
    var trainingLCD: some View {
        if let training = presenter.trainingPresenter {
            let phase = training.viewModel.phase
            let isMiss = phase == .miss
            let resultOnly = phase == .hit || isMiss
            let showTarget = phase == .hit || phase == .victory

            LCDDisplay(configuration: LCDDisplayConfiguration(
                leftSprite: isMiss
                    ? training.targetFrame
                    : resultOnly ? .empty : training.petFrame,
                rightSprite: showTarget
                    ? training.targetFrame : nil,
                lightsOn: arenaScene.lightsOn,
                leftSpriteOffsetY: isMiss ? 2 : 4,
                rightSpriteOffsetY: 0
            ))
        }
    }

    // MARK: - Training Info Row

    @ViewBuilder
    var trainingInfoRow: some View {
        if let training = presenter.trainingPresenter {
            HStack(spacing: 6) {
                Text(trainingRoundText(training))
                    .font(.lcd(10))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                trainingNumberBadge(training)

                trainingScoreDots(training)

                Text(trainingPhaseLabelText(training))
                    .font(.lcd(11, weight: .bold))
                    .foregroundStyle(
                        trainingPhaseLabelColor(training)
                    )
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .frame(width: 36)
                    .fixedSize()
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Training Buttons

    @ViewBuilder
    var trainingButtons: some View {
        if let training = presenter.trainingPresenter {
            let phase = training.viewModel.phase
            let showsGuessButtons = phase == .challenge
            let showsDoneButton = phase == .victory || phase == .defeat

            ZStack {
                HStack(spacing: 4) {
                    ActionButton(label: "HIGH", accessibilityLabel: "Guess high") {
                        training.guessAction(.high)
                    }
                    ActionButton(label: "LOW", accessibilityLabel: "Guess low") {
                        training.guessAction(.low)
                    }
                }
                .opacity(showsGuessButtons ? 1 : 0)
                .allowsHitTesting(showsGuessButtons)
                .accessibilityHidden(!showsGuessButtons)

                HStack(spacing: 4) {
                    ActionButton(label: "DONE", accessibilityLabel: "Finish training") {
                        presenter.dismissTraining()
                    }
                }
                .opacity(showsDoneButton ? 1 : 0)
                .allowsHitTesting(showsDoneButton)
                .accessibilityHidden(!showsDoneButton)
            }
        }
    }

    // MARK: - Private Helpers

    private func trainingRoundText(
        _ training: TrainingPresenter
    ) -> String {
        "R\(training.viewModel.currentRound + 1)"
            + "/\(TimeConstants.trainRounds)"
    }

    private func trainingNumberBadge(
        _ training: TrainingPresenter
    ) -> some View {
        let text = training.viewModel.showingNumber
            ? "\(training.viewModel.currentNumber)"
            : "?"
        return Text(text)
            .font(.lcd(14, weight: .bold))
            .minimumScaleFactor(0.7)
            .lineLimit(1)
            .frame(width: 24, height: 18)
            .background(Color("LCDBackground"))
            .foregroundStyle(Color("LCDPixelOn"))
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .fixedSize()
            .accessibilityLabel("Number: \(text)")
    }

    private func trainingScoreDots(
        _ training: TrainingPresenter
    ) -> some View {
        HStack(spacing: 3) {
            ForEach(training.viewModel.roundResults) { result in
                Circle()
                    .fill(result.won ? Color.green : Color.red)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(width: 50, alignment: .leading)
        .fixedSize(horizontal: true, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(trainingScoreLabel(training))
    }

    private func trainingScoreLabel(
        _ training: TrainingPresenter
    ) -> String {
        let wins = training.viewModel.roundResults
            .filter(\.won).count
        let total = training.viewModel.roundResults.count
        return "Score: \(wins) of \(total) correct"
    }

    private func trainingPhaseLabelText(
        _ training: TrainingPresenter
    ) -> String {
        switch training.viewModel.phase {
        case .hit: "HIT!"
        case .miss: "MISS"
        case .victory: "WIN!"
        case .defeat: "LOSE"
        case .attacking, .projectile: "..."
        case .ready, .challenge: ""
        }
    }

    private func trainingPhaseLabelColor(
        _ training: TrainingPresenter
    ) -> Color {
        switch training.viewModel.phase {
        case .hit, .victory: .green
        case .miss, .defeat: .red
        case .ready, .challenge, .attacking, .projectile: .white
        }
    }
}
