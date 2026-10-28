import SwiftUI

/// The onboarding tutorial screen.
/// Shows the animated LCD, a scrolling speech bubble with the current tip, and
/// progress dots; tapping the content advances to the next tip.
struct OnboardingScreen: View {

    /// The presenter whose tutorial state the view renders and whose actions it delegates to.
    let presenter: OnboardingPresenter

    var body: some View {
        VStack(spacing: 6) {
            content
            footer
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 8)
        .padding(.bottom, 20)
        .ignoresSafeArea(.container, edges: .bottom)
    }

    // MARK: - Content (LCD pinned top + scrolling tip), tappable to advance

    private var content: some View {
        VStack(spacing: 6) {
            lcd
                .frame(maxWidth: .infinity)

            // The greedy ScrollView pins the LCD and footer; long tips scroll.
            ScrollView {
                speechBubble
            }
            .frame(maxHeight: .infinity)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: presenter.advanceAction)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(spokenLabel)
    }

    private var spokenLabel: String {
        let message = presenter.viewModel.currentTip.message
        return presenter.viewModel.isLastStep
            ? String(
                localized: "\(message). Tap to start.",
                comment: "VoiceOver: the tip text, then the instruction on the last onboarding step."
            )
            : String(
                localized: "\(message). Tap to continue.",
                comment: "VoiceOver: the tip text, then the instruction on an onboarding step."
            )
    }

    private var footerHint: String {
        presenter.viewModel.isLastStep
            ? String(localized: "tap to start ›", comment: "Hint under the last onboarding tip; the arrow points forward.")
            : String(localized: "tap ›", comment: "Hint under an onboarding tip; the arrow points forward.")
    }

    private var lcd: some View {
        AnimatedSpriteBezel(
            animator: presenter.spriteAnimator,
            pixelSize: 3
        )
    }

    private var speechBubble: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(presenter.viewModel.currentTip.message)
                .font(.lcd(13))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(footerHint)
                .font(.lcd(9))
                .foregroundStyle(Color.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(white: 0.13))
        )
    }

    // MARK: - Footer (progress dots + skip), pinned at the bottom

    private var footer: some View {
        HStack(spacing: 6) {
            pageDots
                .frame(maxWidth: .infinity, alignment: .leading)

            #if DEBUG
            Button("SKIP", action: presenter.skipAction)
                .font(.lcd(11, weight: .medium))
                .buttonStyle(.plain)
                .foregroundStyle(Color.gray)
                .accessibilityLabel("Skip tutorial")
            #endif
        }
    }

    private var pageDots: some View {
        HStack(spacing: 4) {
            ForEach(OnboardingTip.walkthrough) { tip in
                Circle()
                    .fill(
                        tip.id == presenter.viewModel.index
                            ? Color.accentColor
                            : Color.gray.opacity(0.4)
                    )
                    .frame(width: 5, height: 5)
            }
        }
        .accessibilityHidden(true)
    }
}
