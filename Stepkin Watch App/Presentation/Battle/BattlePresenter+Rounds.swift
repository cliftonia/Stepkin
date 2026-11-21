import Foundation
import WatchKit

// MARK: - Round Loop & Outcomes

extension BattlePresenter {

    /// Plays one full round: pick, both attack ceremonies, then the impact.
    /// Returns false when the battle task is cancelled mid-round so
    /// `runRoundLoop` bails out without judging HP.
    func runSingleRound() async -> Bool {
        enterChoosing()
        let playerHeight = await waitForPick()
        guard !Task.isCancelled else { return false }

        let opponentHeight = AttackHeight.allCases
            .randomElement() ?? .medium
        let outcome = BattleEngine.resolveRound(
            playerHeight: playerHeight,
            opponentHeight: opponentHeight
        )
        viewModel.lastRoundOutcome = outcome

        await runAttacking()
        guard !Task.isCancelled else { return false }

        await runProjectile(height: playerHeight)
        guard !Task.isCancelled else { return false }

        await runOpponentAttacking()
        guard !Task.isCancelled else { return false }

        await runOpponentProjectile(height: opponentHeight)
        guard !Task.isCancelled else { return false }

        await runImpact(outcome: outcome)
        return !Task.isCancelled
    }

    private func enterChoosing() {
        viewModel.phase = .choosing
        viewModel.lastRoundOutcome = nil
        petAnimator.play(.idle, for: petState.species)
    }

    private func waitForPick() async -> AttackHeight {
        await withCheckedContinuation { continuation in
            self.pickContinuation = continuation
        }
    }

    private func runAttacking() async {
        viewModel.phase = .attacking
        petAnimator.play(
            SpriteCatalog.sideAttack(for: petState.species)
        )
        WKInterfaceDevice.battleHaptic()
        _ = await pause(ms: 800)
    }

    private func runProjectile(height: AttackHeight) async {
        viewModel.phase = .projectile
        petAnimator.play(
            SpriteCatalog.projectile(for: petState.species, height: height)
        )
        _ = await pause(ms: 600)
    }

    private func runOpponentAttacking() async {
        guard let opp = opponent else { return }
        viewModel.phase = .opponentAttacking
        opponentAnimator.play(
            SpriteCatalog.sideAttack(for: opp.species)
        )
        _ = await pause(ms: 800)
    }

    private func runOpponentProjectile(height: AttackHeight) async {
        guard let opp = opponent else { return }
        viewModel.phase = .opponentProjectile
        opponentAnimator.play(
            SpriteCatalog.projectileReversed(for: opp.species, height: height)
        )
        WKInterfaceDevice.battleHaptic()
        _ = await pause(ms: 600)
    }

    private func runImpact(outcome: RoundOutcome) async {
        guard let opp = opponent else { return }
        viewModel.phase = .impact

        switch outcome {
        case .playerHit:
            viewModel.opponentHP -= 1
            let base = SpriteCatalog.frames(for: opp.species, kind: .idle)[0]
            let hit = SpriteAnimation(
                frames: [
                    base.overlaying(SharedSprites.explosion1),
                    SharedSprites.explosion2,
                    SharedSprites.explosion3,
                    .empty,
                    base
                ],
                frameDuration: 0.25,
                loops: false
            )
            opponentAnimator.play(hit)
            WKInterfaceDevice.battleWinHaptic()

        case .opponentHit:
            viewModel.petHP -= 1
            petAnimator.play(SharedSprites.missStreaks)
            WKInterfaceDevice.battleLoseHaptic()

        case .clash:
            petAnimator.play(SharedSprites.explosion)
            WKInterfaceDevice.buttonHaptic()
        }

        _ = await pause(ms: 1_500)
    }

    /// Judges the battle on remaining HP: the pet wins on more HP, loses on
    /// less, and equal HP is a draw.
    func resolveTiebreaker() {
        switch BattleEngine.judge(petHP: viewModel.petHP, opponentHP: viewModel.opponentHP) {
        case .win: showVictory()
        case .lose: showDefeat()
        case .draw: showDraw()
        }
    }

    /// Ends the battle as a win: the pet celebrates, the opponent stops, the
    /// win haptic fires, then `.win` is reported through `onComplete`.
    func showVictory() {
        viewModel.result = .win
        viewModel.phase = .victory
        petAnimator.play(.happy, for: petState.species)
        opponentAnimator.stop()
        WKInterfaceDevice.battleWinHaptic()
        onComplete(.win)
    }

    /// Ends the battle as a loss: the pet's defeat animation against a
    /// celebrating opponent, the lose haptic, then `.lose` reported through
    /// `onComplete`. Does nothing when `opponent` is nil.
    func showDefeat() {
        guard let opp = opponent else { return }
        viewModel.result = .lose
        viewModel.phase = .defeat
        petAnimator.play(
            SpriteCatalog.defeatAnimation(for: petState.species)
        )
        opponentAnimator.play(.happy, for: opp.species)
        WKInterfaceDevice.battleLoseHaptic()
        onComplete(.lose)
    }

    /// A draw reuses the `victory` phase: both pets idle, no winner animation.
    func showDraw() {
        guard let opp = opponent else { return }
        viewModel.result = .draw
        viewModel.phase = .victory
        petAnimator.play(.idle, for: petState.species)
        opponentAnimator.play(.idle, for: opp.species)
        WKInterfaceDevice.buttonHaptic()
        onComplete(.draw)
    }
}
