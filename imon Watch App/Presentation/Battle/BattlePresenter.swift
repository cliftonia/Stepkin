import Foundation
import WatchKit

/// Runs one battle ceremony from intro to outcome: owns the phase state, both
/// sprite animators, and the async round loop. Spawned fresh per battle by
/// `PetPresenter.startBattleMode` and reports the result once via `onComplete`;
/// `cancelBattle` must run on dismissal so a pending pick continuation is
/// resumed rather than leaked.
final class BattlePresenter {

    /// Battle screen state — species, HP and phase — seeded in `startBattle`.
    private(set) var viewModel = BattleViewModel()
    /// Plays our monster's sprite animations, starting on idle in `startBattle`.
    let petAnimator = SpriteAnimator()
    /// Plays the opponent's sprite animations, starting on idle at the intro's reveal.
    let opponentAnimator = SpriteAnimator()

    // Read by the `+Frames` and `+Rounds` extensions.
    /// What the battle is built from — opponent matching, shown species and starting HP.
    let petState: PetState
    /// Forwarded to `BattleHP.calculate` when HP is seeded.
    let steps: Int?
    /// Fired exactly once with the `BattleResult`.
    let onComplete: (BattleResult) -> Void
    /// The generated rival; `nil` until `startBattle` creates it from `petState`.
    var opponent: BattleOpponent?
    /// The suspended height pick, resumed by `pickAction` — or as `.medium` on teardown.
    var pickContinuation: CheckedContinuation<AttackHeight, Never>?

    private var battleTask: Task<Void, Never>?

    // MARK: - Init

    /// Creates the presenter for a single battle; the result is reported once
    /// through `onComplete`.
    init(
        petState: PetState,
        steps: Int?,
        onComplete: @escaping (BattleResult) -> Void
    ) {
        self.petState = petState
        self.steps = steps
        self.onComplete = onComplete
    }

    // MARK: - Actions

    /// Generates the opponent, seeds the view model's species and HP, and
    /// launches the round loop. Returns immediately — the loop runs in a
    /// background task and the outcome arrives via `onComplete`.
    func startBattle() {
        let opp = BattleOpponent.generate(matching: petState)
        self.opponent = opp

        viewModel.petSpecies = petState.species
        viewModel.opponentSpecies = opp.species

        let petHP = BattleHP.calculate(for: petState, steps: steps)
        viewModel.petHP = petHP
        viewModel.petMaxHP = petHP

        let oppHP = opp.species.stage.battleHP
        viewModel.opponentHP = oppHP
        viewModel.opponentMaxHP = oppHP
        viewModel.phase = .introPet
        petAnimator.play(.idle, for: petState.species)

        battleTask = Task { [weak self] in
            await self?.runBattle()
        }
    }

    /// Resolves the pending pick with the player's choice; ignored unless the
    /// phase is `.choosing`, so stray taps cannot resume a continuation twice.
    func pickAction(_ height: AttackHeight) {
        guard viewModel.phase == .choosing else { return }
        pickContinuation?.resume(returning: height)
        pickContinuation = nil
    }

    /// Tears down an abandoned battle: cancels the loop and resumes any pending
    /// pick continuation (a `CheckedContinuation` must be resumed exactly once,
    /// or it leaks the suspended task forever).
    func cancelBattle() {
        battleTask?.cancel()
        battleTask = nil
        pickContinuation?.resume(returning: .medium)
        pickContinuation = nil
    }

    // MARK: - Battle Loop

    private func runBattle() async {
        await runIntro()
        guard !Task.isCancelled else { return }

        await runRoundLoop()
    }

    /// Opening beats: our monster, a "VS" flash, then the opponent.
    private func runIntro() async {
        // Our monster is already on screen from `startBattle` — just hold the beat.
        guard await pause(ms: Self.introSceneMs), let opp = opponent else { return }

        // The LCD flash layer draws the strobing "VS" — nothing to animate here.
        viewModel.phase = .introVS
        WKInterfaceDevice.battleHaptic()
        guard await pause(ms: Self.introVSMs) else { return }

        viewModel.phase = .introEnemy
        opponentAnimator.play(.idle, for: opp.species)
        _ = await pause(ms: Self.introSceneMs)
    }

    private static let introSceneMs = 1_300
    private static let introVSMs = 1_300

    private func runRoundLoop() async {
        for _ in 0..<20 {
            guard !Task.isCancelled else { return }

            let completed = await runSingleRound()
            guard completed, !Task.isCancelled else { return }

            if viewModel.opponentHP <= 0 {
                showVictory()
                return
            }
            if viewModel.petHP <= 0 {
                showDefeat()
                return
            }
        }
        resolveTiebreaker()
    }
}
