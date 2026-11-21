import Foundation
import WatchKit

/// Drives the post-hatch walkthrough: steps Dotkin through the fixed
/// `OnboardingTip.walkthrough` list, playing each tip's animation, and hands
/// off through `onComplete` when finished or skipped. The newborn is already
/// persisted before this shows, so quitting mid-walkthrough cannot lose it.
final class OnboardingPresenter {

    /// The walkthrough's current-step state; read to know which tip to show and whether it is
    /// the last.
    private(set) var viewModel = OnboardingViewModel()
    /// Plays the current tip's animation; stopped before the hand-off to play.
    let spriteAnimator = SpriteAnimator()

    /// Called when the walkthrough is finished or skipped - hands off to play.
    private let onComplete: () -> Void

    // MARK: - Init

    /// Creates the walkthrough driver and starts playing the first tip's
    /// animation at once.
    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        playCurrentTip()
    }

    // MARK: - Actions

    /// Advances to the next tip, or finishes on the last one.
    func advanceAction() {
        guard !viewModel.isLastStep else {
            spriteAnimator.stop()
            onComplete()
            return
        }
        viewModel.index += 1
        playCurrentTip()
        WKInterfaceDevice.buttonHaptic()
    }

    /// Jumps straight to play, skipping the rest of the walkthrough.
    func skipAction() {
        spriteAnimator.stop()
        onComplete()
    }

    // MARK: - Private

    private func playCurrentTip() {
        spriteAnimator.play(viewModel.currentTip.animation, for: .dotkin)
    }
}
