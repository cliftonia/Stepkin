import SwiftUI

/// The menu's icon strip: one symbol per action, with the icon at
/// `selectedIndex` tinted and backed and the rest muted. Renders selection
/// only; it carries no interaction, and an index outside the list highlights
/// nothing.
struct MenuIconRow: View {

    /// The index of the icon shown as selected.
    let selectedIndex: Int
    @Environment(\.lcdTheme) private var theme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(PetViewModel.MenuAction.allCases) { action in
                let index = action.rawValue
                Image(systemName: action.systemImage)
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity)
                    .frame(height: 22)
                    .foregroundStyle(
                        index == selectedIndex
                            ? theme.chromeTint
                            : theme.chromeMutedTint
                    )
                    .background(
                        index == selectedIndex
                            ? RoundedRectangle(cornerRadius: 2)
                                .fill(theme.chromeTint.opacity(0.2))
                            : nil
                    )
                    .accessibilityLabel(action.accessibilityName)
            }
        }
    }
}
