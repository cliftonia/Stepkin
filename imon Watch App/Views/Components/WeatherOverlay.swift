import SwiftUI

/// Current temperature, humidity and condition, shown above the LCD. (The
/// weather *icon* lives in the debug row by the pet's name.)
struct WeatherOverlay: View {

    /// The reading rendered in the row: temperature, humidity and condition.
    let snapshot: WeatherSnapshot
    @Environment(\.lcdTheme) private var theme

    var body: some View {
        // Longest row that fits wins; humidity drops before condition (the only
        // release-build weather cue), so the temperature never truncates.
        ViewThatFits(in: .horizontal) {
            row(showHumidity: true, showCondition: true)
            row(showHumidity: false, showCondition: true)
            row(showHumidity: false, showCondition: false)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(snapshot.condition.displayName), "
                + WeatherTemperatureFormatter.string(for: snapshot.temperature)
                + ", humidity \(humidityText)"
        )
    }

    private func row(showHumidity: Bool, showCondition: Bool) -> some View {
        HStack(spacing: 3) {
            field(WeatherTemperatureFormatter.string(for: snapshot.temperature), opacity: 1)
            if showHumidity {
                separator
                field(humidityText, opacity: 0.65)
            }
            if showCondition {
                separator
                field(snapshot.condition.displayName, opacity: 1)
            }
        }
    }

    private func field(_ text: String, opacity: Double) -> some View {
        Text(text)
            .font(.lcd(11, weight: .bold))
            .foregroundStyle(theme.chromeTint.opacity(opacity))
    }

    private var separator: some View {
        Text("|")
            .font(.lcd(11, weight: .bold))
            .foregroundStyle(theme.chromeTint.opacity(0.35))
    }

    private var humidityText: String {
        "\(Int((snapshot.humidity * 100).rounded()))%"
    }
}

#if DEBUG
#Preview {
    WeatherOverlay(snapshot: .sample)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
}
#endif
