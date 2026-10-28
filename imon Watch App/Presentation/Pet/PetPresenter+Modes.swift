import Foundation

// MARK: - Training & Battle Modes

extension PetPresenter {

    // MARK: - Training Mode (Inline)

    /// Enters training inline, refusing when `TrainAction.canTrain` rejects the
    /// current state. Stops wandering and switches `screenMode` to `.training`;
    /// the outcome returns through `applyTrainingResult(won:)`.
    func startTrainingMode() {
        guard TrainAction.canTrain(state) else {
            refuse()
            return
        }
        wander.stop()
        let presenter = TrainingPresenter(
            species: state.species
        ) { [weak self] won in
            self?.applyTrainingResult(won: won)
        }
        trainingPresenter = presenter
        viewModel.screenMode = .training
        presenter.startTraining()
    }

    /// Exits training, cancelling the session and stopping both animators
    /// before releasing the presenter and returning to normal mode.
    func dismissTraining() {
        trainingPresenter?.cancel()
        trainingPresenter?.spriteAnimator.stop()
        trainingPresenter?.targetAnimator.stop()
        trainingPresenter = nil
        returnToNormalMode()
    }

    // MARK: - Battle Mode (Inline)

    /// Enters battle inline, refusing when `BattleEngine.canBattle` rejects the
    /// current state. The `BattlePresenter` receives the pet state and the
    /// current step count; the outcome returns through `applyBattleResult(_:)`.
    func startBattleMode() {
        guard BattleEngine.canBattle(state) else {
            refuse()
            return
        }
        wander.stop()
        let presenter = BattlePresenter(
            petState: state,
            steps: currentSteps()
        ) { [weak self] result in
            self?.applyBattleResult(result)
        }
        battlePresenter = presenter
        viewModel.screenMode = .battle
        presenter.startBattle()
    }

    /// Exits battle, cancelling the battle and stopping the pet and opponent
    /// animators before releasing the presenter and returning to normal mode.
    func dismissBattle() {
        battlePresenter?.cancelBattle()
        battlePresenter?.petAnimator.stop()
        battlePresenter?.opponentAnimator.stop()
        battlePresenter = nil
        returnToNormalMode()
    }

    private func returnToNormalMode() {
        viewModel.screenMode = .normal
        updateAnimation()
        wander.start()
    }
}
