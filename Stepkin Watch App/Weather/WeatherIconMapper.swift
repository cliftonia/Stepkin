import Foundation

/// Maps a weather condition (and daylight) to its LCD sprite icon.
nonisolated enum WeatherIconMapper {

    /// Returns the sprite for a condition; only clear and cloudy split on
    /// daylight, every other condition ignores `isDaylight`.
    static func frame(
        for condition: WeatherIconCondition,
        isDaylight: Bool
    ) -> SpriteFrame {
        switch condition {
        case .clear:
            return isDaylight ? SharedSprites.weatherSun : SharedSprites.weatherMoon
        case .cloudy:
            return isDaylight ? SharedSprites.weatherCloud : SharedSprites.weatherCloudNight
        case .rain:
            return SharedSprites.weatherRain
        case .snow:
            return SharedSprites.weatherSnow
        case .storm:
            return SharedSprites.weatherStorm
        case .fog:
            return SharedSprites.weatherFog
        case .wind:
            return SharedSprites.weatherWind
        }
    }
}
