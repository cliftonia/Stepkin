import SwiftUI

/// The bezel's palette. A file-scope enum because `LCDBezel` is generic, and
/// Swift disallows stored static properties on generic types.
private enum BezelPalette {
    /// The daylight ring: the signature LCD green, matching the lit screen.
    static let dayRing = Color("LCDBackground")
    /// The night ring: a pale cool silver, legible against the dark screen.
    static let nightRing = Color(red: 0.86, green: 0.89, blue: 0.95)

    /// The classic green frame: a faint panel fill and a soft grey edge.
    static let classicFill = Color("LCDBackground").opacity(0.3)
    /// The soft grey edge of the classic frame.
    static let classicStroke = Color.gray.opacity(0.6)

    /// Battery-saver is strictly red on black — no green panel, no grey edge, so
    /// the whole bezel (frame, edge and ring) is drawn in one red.
    static let batterySaver = Color(red: 1, green: 0.12, blue: 0.08)
    /// The battery-saver panel fill: a faint red wash behind the content.
    static let batterySaverFill = batterySaver.opacity(0.18)
    /// The battery-saver frame edge: a red stroke around the panel.
    static let batterySaverStroke = batterySaver.opacity(0.6)
}

/// The watch-case frame drawn around the LCD screen's content: a panel fill and
/// edge in the active palette, plus a ring showing evolution progress.
struct LCDBezel<Content: View>: View {

    /// The screen content the bezel frames, captured from the `@ViewBuilder` closure.
    let content: Content
    /// Evolution progress (0...1) drawn as a ring around the bezel; `nil` hides it.
    let evolutionProgress: Double?
    /// The real time of day (not the resolved scene's), so the progress ring
    /// turns to the night colour at night and holds it through the ceremonies,
    /// whose clean scene always reports day.
    let dayPhase: DayPhase
    /// The active LCD palette, so the ring matches the red battery-saver screen.
    @Environment(\.lcdTheme) private var theme

    init(
        evolutionProgress: Double? = nil,
        dayPhase: DayPhase = .day,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.evolutionProgress = evolutionProgress
        self.dayPhase = dayPhase
    }

    /// Battery-saver recolours the whole screen red, so the ring uses the same
    /// red. Otherwise only the lights-off night screen is dark; day and the lit
    /// indoor room both keep the green screen, so the ring stays green there.
    private var ringColor: Color {
        switch theme {
        case .nightRed:
            BezelPalette.batterySaver
        case .classic:
            dayPhase == .night ? BezelPalette.nightRing : BezelPalette.dayRing
        }
    }

    private var frameFill: Color {
        theme == .nightRed ? BezelPalette.batterySaverFill : BezelPalette.classicFill
    }

    private var frameStroke: Color {
        theme == .nightRed ? BezelPalette.batterySaverStroke : BezelPalette.classicStroke
    }

    var body: some View {
        content
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(frameFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(frameStroke, lineWidth: 1.5)
            )
            .overlay(evolutionRing)
    }

    /// The progress arc, filling clockwise as the pet nears evolution. Always
    /// present so changes animate smoothly; hidden via opacity when unset.
    private var evolutionRing: some View {
        RoundedRectangle(cornerRadius: 6)
            .trim(from: 0, to: max(0, min(1, evolutionProgress ?? 0)))
            .stroke(
                ringColor,
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            .opacity(evolutionProgress == nil ? 0 : 1)
            .accessibilityHidden(true)
    }
}
