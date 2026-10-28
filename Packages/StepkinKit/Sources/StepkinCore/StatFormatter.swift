import Foundation

/// Display formatting for numeric stats — grouped thousands and a win-rate
/// percent. A stateless enum helper in the style of `WeatherTemperatureFormatter`,
/// reusable by the Stats screen and the complication.
public enum StatFormatter {

    /// Formats the value with locale-grouped thousands, e.g. 12_340 -> "12,340".
    public static func grouped(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// Returns the win rate as a whole-number percent (0...100), or nil when
    /// there are no battles to divide by. Clamps in `Double` before converting,
    /// so extreme ratios can never trap the `Int` conversion.
    public static func percent(_ part: Int, of whole: Int) -> String? {
        guard whole > 0 else { return nil }
        let ratio = Double(part) / Double(whole) * 100
        return "\(Int(min(100, max(0, ratio.rounded()))))%"
    }
}
