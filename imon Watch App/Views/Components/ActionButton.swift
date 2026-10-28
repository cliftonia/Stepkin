import SwiftUI
import WatchKit

/// A hardware-style button whose printed face is only "A", "B" or "C".
/// The letter cannot describe what the press does, so the action's meaning
/// is carried separately: `accessibilityLabel` for VoiceOver and an optional
/// debug action fired by a long press.
struct ActionButton: View {

    /// The letter printed on the face; it identifies the hardware position and cannot describe
    /// the press.
    let label: String
    /// What the press does right now, for VoiceOver — the printed label is
    /// only "A", "B" or "C".
    var accessibilityLabel: String?
    /// Debug action fired on a long press (e.g. cycle weather / evolve).
    var longPressAction: (() -> Void)?
    /// The press handler, fired after the button haptic.
    let action: () -> Void
    @Environment(\.lcdTheme) private var theme

    var body: some View {
        Button {
            WKInterfaceDevice.buttonHaptic()
            action()
        } label: {
            Text(label)
                .font(.lcd(12, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 28)
                .foregroundStyle(theme.chromeTint)
        }
        .buttonStyle(.bordered)
        // Only override the fill under battery-saver; classic keeps the default.
        .tint(theme == .nightRed ? theme.chromeTint : nil)
        .accessibilityLabel(accessibilityLabel ?? "\(label) button")
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                guard let longPressAction else { return }
                WKInterfaceDevice.buttonHaptic()
                longPressAction()
            }
        )
    }
}
