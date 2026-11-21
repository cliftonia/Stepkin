import Testing
import Foundation
@testable import Stepkin_Watch_App

@Suite("WeatherTemperatureFormatter")
struct WeatherTemperatureFormatterTests {

    @Test(arguments: [
        (celsius: 18.0, localeID: "en_GB", expected: "18°"),   // UK stays Celsius
        (celsius: 18.0, localeID: "en_US", expected: "64°"),   // converts to Fahrenheit
        (celsius: 17.6, localeID: "de_DE", expected: "18°"),   // rounds up
        (celsius: -5.4, localeID: "de_DE", expected: "-5°"),   // negative rounds toward zero
        (celsius: -0.4, localeID: "de_DE", expected: "0°"),    // never renders "-0°"
    ])
    func `renders a whole-degree value in the locale's unit`(
        celsius: Double, localeID: String, expected: String
    ) {
        let temperature = Measurement(value: celsius, unit: UnitTemperature.celsius)
        let rendered = WeatherTemperatureFormatter.string(
            for: temperature,
            locale: Locale(identifier: localeID)
        )
        #expect(rendered == expected)
    }

    @Test
    func `only US-system locales use Fahrenheit`() {
        #expect(WeatherTemperatureFormatter.usesFahrenheit(Locale(identifier: "en_US")))
        #expect(!WeatherTemperatureFormatter.usesFahrenheit(Locale(identifier: "de_DE")))
        // en_GB is .uk — non-metric but still not .us, so Celsius.
        #expect(!WeatherTemperatureFormatter.usesFahrenheit(Locale(identifier: "en_GB")))
    }
}
