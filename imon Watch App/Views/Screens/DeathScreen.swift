import SwiftUI

/// The screen shown after the pet dies. Shows the pet's sprite, species name,
/// and age in days above a "New Egg" button; restarting routes through
/// `DeathPresenter`.
struct DeathScreen: View {

    /// The source of the sprite, species name, and age shown and of the restart action.
    let presenter: DeathPresenter

    var body: some View {
        // Scroll-bounded so content can't collide with the clock on 40/41mm.
        ScrollView {
            VStack(spacing: 10) {
                AnimatedSpriteBezel(
                    animator: presenter.spriteAnimator,
                    pixelSize: 3
                )

                Text("R.I.P.")
                    .font(.lcd(16, weight: .bold))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text(presenter.configuration.speciesName)
                    .font(.lcd(11))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text("Age: \(presenter.configuration.ageDays) days")
                    .font(.lcd(10))
                    .foregroundStyle(Color.gray)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Button("New Egg") {
                    presenter.restartAction()
                }
                .accessibilityLabel("Start new egg")
            }
            .padding(.vertical, 4)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "Death screen. Your Creature has passed away."
        )
    }
}
