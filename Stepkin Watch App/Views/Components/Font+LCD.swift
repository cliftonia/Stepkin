import SwiftUI

/// The monospaced font the LCD-styled labels share.
extension Font {
    /// A monospaced system font at the given size and weight, used by every LCD-styled label.
    ///
    /// - Parameters:
    ///   - size: The point size of the font.
    ///   - weight: The weight of the font; defaults to regular.
    /// - Returns: A monospaced system font.
    static func lcd(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
