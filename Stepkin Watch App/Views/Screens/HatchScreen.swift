import SwiftUI

/// The egg-hatching screen; shows the hatch sequence from egg to newborn.
///
/// Renders the sprite inside `AnimatedSpriteBezel` with a caption tracking
/// the `HatchPresenter`'s phase, and starts the sequence from `.task`.
struct HatchScreen: View {

    /// The presenter driving the hatch: supplies the sprite animator and
    /// phase, and starts the sequence from `.task`.
    let presenter: HatchPresenter

    var body: some View {
        VStack(spacing: 12) {
            AnimatedSpriteBezel(
                animator: presenter.spriteAnimator,
                pixelSize: 4
            )

            phaseLabel
        }
        .task {
            presenter.startHatching()
        }
        .accessibilityLabel("Egg hatching screen")
    }

    private var phaseLabel: some View {
        let phase = presenter.viewModel.phase
        return ZStack {
            Text("An egg!")
                .font(.lcd(12))
                .opacity(phase == .egg ? 1 : 0)
                .accessibilityHidden(phase != .egg)
            Text("It's hatching...")
                .font(.lcd(12))
                .opacity(phase == .cracking ? 1 : 0)
                .accessibilityHidden(phase != .cracking)
            Text("Dotkin is born!")
                .font(.lcd(12, weight: .bold))
                .opacity(phase == .hatched ? 1 : 0)
                .accessibilityHidden(phase != .hatched)
        }
    }
}
