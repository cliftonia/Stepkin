import Testing
import WeatherKit
@testable import Stepkin_Watch_App

@Suite("WeatherIconMapper")
struct WeatherIconMapperTests {

    @Test
    func `clear maps to sun by day and moon at night`() {
        #expect(
            WeatherIconMapper.frame(for: .clear, isDaylight: true)
                == SharedSprites.weatherSun
        )
        #expect(
            WeatherIconMapper.frame(for: .clear, isDaylight: false)
                == SharedSprites.weatherMoon
        )
    }

    @Test
    func `cloudy has a distinct night variant`() {
        #expect(
            WeatherIconMapper.frame(for: .cloudy, isDaylight: true)
                == SharedSprites.weatherCloud
        )
        #expect(
            WeatherIconMapper.frame(for: .cloudy, isDaylight: false)
                == SharedSprites.weatherCloudNight
        )
    }

    @Test(arguments: [
        (WeatherIconCondition.rain, SharedSprites.weatherRain),
        (.snow, SharedSprites.weatherSnow),
        (.storm, SharedSprites.weatherStorm),
        (.fog, SharedSprites.weatherFog),
        (.wind, SharedSprites.weatherWind),
    ])
    func `precipitation icons ignore daylight`(
        condition: WeatherIconCondition, expected: SpriteFrame
    ) {
        #expect(
            WeatherIconMapper.frame(for: condition, isDaylight: true) == expected
        )
        #expect(
            WeatherIconMapper.frame(for: condition, isDaylight: false) == expected
        )
    }

    @Test(arguments: [
        (WeatherCondition.clear, WeatherIconCondition.clear),
        (.mostlyClear, .clear),
        (.cloudy, .cloudy),
        (.partlyCloudy, .cloudy),
        (.windy, .wind),
        (.breezy, .wind),
        (.foggy, .fog),
        (.rain, .rain),
        (.drizzle, .rain),
        (.snow, .snow),
        (.blizzard, .snow),
        (.thunderstorms, .storm),
        (.hurricane, .storm),
    ])
    func `WeatherKit conditions bucket into the icon set`(
        condition: WeatherCondition, expected: WeatherIconCondition
    ) {
        #expect(WeatherIconCondition(condition) == expected)
    }
}
