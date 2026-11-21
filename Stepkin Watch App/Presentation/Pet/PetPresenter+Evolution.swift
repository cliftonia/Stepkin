import Foundation
import WatchKit

// MARK: - Evolution

/// The presenter's share of the evolution ceremony: the threshold check, the
/// reveal strobe, and applying the new stage.
extension PetPresenter {

    /// Duration of the reveal strobe before the evolved creature appears, in milliseconds.
    static let evolveFlashMilliseconds = 1_600

    /// Starts the evolution flash when the lifetime steps have crossed the
    /// stage threshold, the pet is idle and the scene is active. The ceremony
    /// is automatic — there is nothing to tap — matching the original toy.
    /// While the scene is inactive a routed tick evolves through
    /// `evolveUnseen` instead, so no strobe plays to nobody.
    func checkEvolution() {
        guard isSceneActive, !viewModel.isBusy else { return }
        guard let target = EvolutionEngine.checkEvolution(for: state) else { return }
        beginEvolution(to: target)
    }

    /// Plays the strobe, then reveals the evolved creature. Runs through the
    /// shared activity machinery so the ceremony blocks input and is cancelled
    /// cleanly if the screen goes away mid-flash (the pet re-offers next tick).
    func beginEvolution(to target: PetSpecies) {
        viewModel.activity = .evolving
        WKInterfaceDevice.evolveHaptic()
        startActivity { await $0.runEvolutionFlash(to: target) }
    }

    private func runEvolutionFlash(to target: PetSpecies) async {
        guard await pause(ms: Self.evolveFlashMilliseconds) else { return }
        performEvolution(to: target)
    }

    /// Applies the evolution and reveals the new creature with a happy bounce.
    /// Split out from the flash so it can be exercised without the strobe delay.
    func performEvolution(to target: PetSpecies) {
        state = EvolutionEngine.evolve(state, to: target, at: .now)
        #if DEBUG
        // Debug journeys re-dirty the pet so each stage's care loop can be exercised.
        if debugStepIndex > 0 {
            state.poopCount = 1
            state.isInjured = true
        }
        #endif
        viewModel.activity = .idle
        updateViewModel()
        spriteAnimator.play(.happy, for: state.species)
        save()
        WKInterfaceDevice.evolveHaptic()
    }
}
