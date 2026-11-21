import Foundation
import WatchKit

extension PetPresenter {

    // MARK: - Healing (Inline LCD Ceremony)

    /// Starts the healing ceremony, refusing instead when `HealAction.canHeal`
    /// rejects the state; a tap arriving while an activity runs is ignored.
    func healAction() {
        guard !viewModel.isBusy else { return }
        guard HealAction.canHeal(state) else {
            refuse()
            return
        }
        startActivity { await $0.runHealingSequence() }
    }

    /// Plays the refuse ceremony: refusal animation and haptic, held 800 ms.
    func runRefuseSequence() async {
        viewModel.activity = .refusing

        spriteAnimator.play(
            SpriteCatalog.animation(
                for: state.species, kind: .refuse
            )
        )
        WKInterfaceDevice.rejectHaptic()

        guard await pause(ms: 800) else { return }

        endActivity()
    }

    /// Plays the healing ceremony: needle injection with haptic for 1,200 ms,
    /// then `HealAction.apply` updates and saves the state, and the
    /// satisfaction heart holds for 1,000 ms before the activity ends.
    func runHealingSequence() async {
        viewModel.activity = .healing

        feedingAnimator.play(SharedSprites.needleInjection)
        WKInterfaceDevice.healHaptic()

        guard await pause(ms: 1200) else { return }

        state = HealAction.apply(to: state)
        updateViewModel()
        save()

        feedingAnimator.play(
            .still(SharedSprites.satisfactionHeart)
        )
        spriteAnimator.play(
            SpriteCatalog.animation(
                for: state.species, kind: .happy
            )
        )

        guard await pause(ms: 1000) else { return }

        endActivity()
    }
}
