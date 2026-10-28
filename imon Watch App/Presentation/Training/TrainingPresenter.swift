import Foundation
import WatchKit

/// Owner of the higher-or-lower training mini-game: the phase machine, both
/// sprite animators, and the round tally, reporting win or lose once through
/// `onComplete`. Every phase advance goes through a single replaceable task —
/// `cancel()` must run on dismissal so a pending advance cannot fire into a
/// torn-down presenter.
final class TrainingPresenter {

    /// The phase machine's state and round tally the view renders; replaced wholesale by
    /// `startTraining`.
    private(set) var viewModel = TrainingViewModel()
    /// Plays the pet's own sprite for each phase: idle stance, attack, projectile, reaction.
    let spriteAnimator = SpriteAnimator()
    /// Plays the target-side effects — hit sequence, miss streaks, victory sparkle; stopped in
    /// calmer phases.
    let targetAnimator = SpriteAnimator()

    private let species: PetSpecies
    private let onComplete: (Bool) -> Void

    /// The single pending phase advance, so it can be cancelled on
    /// dismiss instead of firing into a torn-down presenter.
    private let phaseAdvance = DelayedTask()

    // MARK: - Computed

    var petFrame: SpriteFrame { spriteAnimator.currentFrame }
    var targetFrame: SpriteFrame { targetAnimator.currentFrame }

    // MARK: - Init

    /// Creates the presenter for one species; `onComplete` fires exactly once
    /// when the round tally decides the game — `true` on victory, `false` on
    /// defeat.
    init(
        species: PetSpecies,
        onComplete: @escaping (Bool) -> Void
    ) {
        self.species = species
        self.onComplete = onComplete
    }

    /// Cancels any pending phase advance — called when training is dismissed.
    func cancel() {
        phaseAdvance.cancel()
    }

    // MARK: - Actions

    /// Starts a fresh game, discarding any in-progress rounds, and enters the
    /// ready phase with the first number drawn.
    func startTraining() {
        viewModel = TrainingViewModel()
        viewModel.currentNumber = TrainAction.generateNumber()
        enterReady()
    }

    /// Scores the player's guess against the current number and enters the
    /// attack phase; a no-op unless the phase machine is at `.challenge`.
    func guessAction(_ guess: TrainAction.Guess) {
        guard viewModel.phase == .challenge else { return }

        let result = TrainAction.evaluateRound(
            number: viewModel.currentNumber,
            guess: guess
        )
        viewModel.showingNumber = true
        viewModel.roundResults.append(result.won)
        viewModel.lastGuessHigh = guess == .high

        enterAttacking(won: result.won)
    }

    // MARK: - Phase Machine

    private func enterReady() {
        viewModel.phase = .ready
        // Face front while waiting — only turn side-on once the player attacks.
        spriteAnimator.play(.idle, for: species)
        targetAnimator.stop()

        phaseAdvance.schedule(after: .milliseconds(600)) { [weak self] in
            guard let self, self.viewModel.phase == .ready else { return }
            self.enterChallenge()
        }
    }

    private func enterChallenge() {
        viewModel.phase = .challenge
        // Still facing front — the player hasn't chosen high or low yet.
        spriteAnimator.play(.idle, for: species)
    }

    private func enterAttacking(won: Bool) {
        viewModel.phase = .attacking
        spriteAnimator.play(
            SpriteCatalog.sideAttack(for: species).facing(.right)
        )
        WKInterfaceDevice.battleHaptic()

        phaseAdvance.schedule(after: .milliseconds(500)) { [weak self] in
            guard let self, self.viewModel.phase == .attacking else { return }
            self.enterProjectile(won: won)
        }
    }

    private func enterProjectile(won: Bool) {
        viewModel.phase = .projectile
        let height: AttackHeight = viewModel.lastGuessHigh
            ? .high : .low
        let animation = SpriteCatalog.projectile(
            for: species,
            height: height
        )
        spriteAnimator.play(animation)

        phaseAdvance.schedule(after: .milliseconds(700)) { [weak self] in
            guard let self, self.viewModel.phase == .projectile else { return }
            if won {
                self.enterHit()
            } else {
                self.enterMiss()
            }
        }
    }

    private func enterHit() {
        viewModel.phase = .hit
        spriteAnimator.play(
            SpriteCatalog.animation(for: species, kind: .happy).facing(.right)
        )
        targetAnimator.play(SharedSprites.trainingHitSequence)
        WKInterfaceDevice.trainingHitHaptic()

        phaseAdvance.schedule(after: .milliseconds(800)) { [weak self] in
            guard let self, self.viewModel.phase == .hit else { return }
            self.advanceOrComplete()
        }
    }

    private func enterMiss() {
        viewModel.phase = .miss
        spriteAnimator.play(
            SpriteCatalog.sideStance(for: species).facing(.right)
        )
        targetAnimator.play(SharedSprites.missStreaks)
        WKInterfaceDevice.trainingMissHaptic()

        phaseAdvance.schedule(after: .milliseconds(800)) { [weak self] in
            guard let self, self.viewModel.phase == .miss else { return }
            self.advanceOrComplete()
        }
    }

    private func advanceOrComplete() {
        let roundsPlayed = viewModel.roundResults.count
        let wins = viewModel.roundResults.filter { $0 }.count
        let losses = roundsPlayed - wins
        let maxLosses = TimeConstants.trainRounds
            - TimeConstants.trainWinsNeeded

        if wins >= TimeConstants.trainWinsNeeded {
            enterVictory()
            onComplete(true)
        } else if losses > maxLosses {
            enterDefeat()
            onComplete(false)
        } else {
            viewModel.currentRound = roundsPlayed
            viewModel.showingNumber = false
            viewModel.currentNumber = TrainAction.generateNumber()
            enterReady()
        }
    }

    private func enterVictory() {
        viewModel.phase = .victory
        spriteAnimator.play(
            SpriteCatalog.animation(for: species, kind: .happy).facing(.right)
        )
        targetAnimator.play(SharedSprites.trainingVictorySparkle)
        WKInterfaceDevice.trainingWinHaptic()
    }

    private func enterDefeat() {
        viewModel.phase = .defeat
        spriteAnimator.play(
            SpriteCatalog.defeatAnimation(for: species).facing(.right)
        )
        targetAnimator.stop()
        WKInterfaceDevice.trainingLoseHaptic()
    }
}
