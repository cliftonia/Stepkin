import SwiftUI

/// A labelled row of hearts showing a stat as filled and hollow symbols.
///
/// Draws `maxCount` hearts with the first `filledCount` filled, and flattens
/// the row into one accessibility element reading the label and the count.
struct HeartMeter: View {

    /// Leading text of the row, also read in the accessibility label.
    let label: String
    /// Number of leading hearts drawn filled; the rest draw hollow.
    let filledCount: Int
    /// Total hearts drawn in the row.
    let maxCount: Int

    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.lcd(10, weight: .medium))
                .frame(width: 40, alignment: .leading)

            HStack(spacing: 1) {
                ForEach(Array(0..<maxCount), id: \.self) { index in
                    Image(
                        systemName: index < filledCount
                            ? "heart.fill"
                            : "heart"
                    )
                    .font(.system(size: 8))
                    .foregroundStyle(
                        index < filledCount ? Color.red : Color.gray
                    )
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(label): \(filledCount) of \(maxCount) hearts"
        )
    }
}
