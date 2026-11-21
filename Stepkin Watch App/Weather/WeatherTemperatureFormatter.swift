import Foundation

/// Formats a temperature for the device locale: a whole-number value followed
/// by a degree sign (e.g. "18°"), in °F for US-style locales and °C otherwise.
nonisolated enum WeatherTemperatureFormatter {

    /// Rounds the temperature to a whole number in the locale's unit and
    /// appends a degree sign; the unit symbol is never shown.
    static func string(
        for temperature: Measurement<UnitTemperature>,
        locale: Locale = .current
    ) -> String {
        let unit: UnitTemperature = usesFahrenheit(locale) ? .fahrenheit : .celsius
        let value = temperature.converted(to: unit).value.rounded()
        return "\(Int(value))°"
    }

    /// Returns true only for the US measurement system; every other locale
    /// resolves to Celsius.
    static func usesFahrenheit(_ locale: Locale) -> Bool {
        locale.measurementSystem == .us
    }
}
