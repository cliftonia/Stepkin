import Foundation

/// Weather conditions reduced to the small set the LCD has icons for.
nonisolated enum WeatherIconCondition: Sendable, Equatable, CaseIterable, Identifiable {
    case clear
    case cloudy
    case rain
    case snow
    case storm
    case fog
    case wind

    var id: Self { self }

    var displayName: String {
        switch self {
        case .clear: String(localized: "Clear", comment: "Weather condition name.")
        case .cloudy: String(localized: "Cloudy", comment: "Weather condition name.")
        case .rain: String(localized: "Rain", comment: "Weather condition name.")
        case .snow: String(localized: "Snow", comment: "Weather condition name.")
        case .storm: String(localized: "Storm", comment: "Weather condition name.")
        case .fog: String(localized: "Fog", comment: "Weather condition name.")
        case .wind: String(localized: "Windy", comment: "Weather condition name.")
        }
    }
}

/// Immutable current-weather reading. Temperature is kept raw so it can be
/// formatted in the device's locale at display time.
nonisolated struct WeatherSnapshot: Sendable, Equatable {
    /// The current temperature as measured, before any display formatting.
    let temperature: Measurement<UnitTemperature>
    /// The current condition, reduced to the set the LCD has icons for.
    let condition: WeatherIconCondition
    /// Whether daylight holds for the reading.
    let isDaylight: Bool
    /// Relative humidity, 0...1.
    let humidity: Double
}

/// Failures obtaining a weather reading: the location is unavailable, or the
/// weather itself is unavailable.
nonisolated enum WeatherError: Error, Sendable {
    case locationUnavailable
    case weatherUnavailable
}

#if DEBUG
nonisolated extension WeatherSnapshot {
    /// A fixed sample reading for debug builds.
    static let sample = WeatherSnapshot(
        temperature: Measurement(value: 18, unit: .celsius),
        condition: .clear,
        isDaylight: true,
        humidity: 0.6
    )
}
#endif
