import SwiftUI

/// The game-mode screen shell: the LCD content in an `LCDBezel` on top, a
/// one-line info strip, and buttons pinned to the bottom.
/// Generic over the slots so callers supply the views while this type owns
/// their vertical arrangement and spacing. An optional header sits above the
/// bezel, and the bezel can show the evolution ring and the moonlit rim.
struct GameModeLayout<
    Header: View,
    LCD: View,
    Info: View,
    Buttons: View
>: View {

    /// The view shown above the bezel; `EmptyView` when the screen has none.
    let header: Header

    /// Evolution progress (0...1) for the bezel's ring; `nil` hides the ring.
    let evolutionProgress: Double?

    /// The real time of day for the bezel's rim; `nil` uses the bezel's default.
    let dayPhase: DayPhase?

    /// The view drawn inside the `LCDBezel` at the top.
    let lcd: LCD

    /// The one-line strip shown between the LCD and the buttons.
    let info: Info

    /// The controls pinned to the bottom of the screen.
    let buttons: Buttons

    /// Creates the layout with a header above the bezel and the bezel's ring
    /// and rim parameters, evaluating each view builder immediately and
    /// storing the built views.
    init(
        header: Header,
        evolutionProgress: Double? = nil,
        dayPhase: DayPhase? = nil,
        @ViewBuilder lcd: () -> LCD,
        @ViewBuilder info: () -> Info,
        @ViewBuilder buttons: () -> Buttons
    ) {
        self.header = header
        self.evolutionProgress = evolutionProgress
        self.dayPhase = dayPhase
        self.lcd = lcd()
        self.info = info()
        self.buttons = buttons()
    }

    var body: some View {
        VStack(spacing: 4) {
            header

            LCDBezel(
                evolutionProgress: evolutionProgress,
                dayPhase: dayPhase ?? .day
            ) { lcd }
                .fixedSize(horizontal: false, vertical: true)

            info
                .frame(height: 20)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            buttons
                .padding(.horizontal, 4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(
                    maxHeight: .infinity,
                    alignment: .bottom
                )
        }
    }
}

extension GameModeLayout where Header == EmptyView {

    /// Creates the layout without a header, the shape training and battle use.
    init(
        @ViewBuilder lcd: () -> LCD,
        @ViewBuilder info: () -> Info,
        @ViewBuilder buttons: () -> Buttons
    ) {
        self.init(header: EmptyView(), lcd: lcd, info: info, buttons: buttons)
    }
}
