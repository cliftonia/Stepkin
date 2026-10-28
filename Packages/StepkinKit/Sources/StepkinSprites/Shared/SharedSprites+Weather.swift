import Foundation

// MARK: - Weather Icons (16x16, day/night variants)

extension SharedSprites {

    /// Clear-sky icon for day; `weatherMoon` is the night counterpart.
    public static let weatherSun = SpriteFrame(rows: [
        0x0000,
        0x0100,
        0x0100,
        0x1390,
        0x0FA0,
        0x07C0,
        0x27C8,
        0x4FE4,
        0x27C8,
        0x07C0,
        0x0BE0,
        0x1390,
        0x0100,
        0x0100,
        0x0000,
        0x0000
    ])

    /// Clear-sky icon for night; `weatherSun` is the day counterpart.
    public static let weatherMoon = SpriteFrame(rows: [
        0x0000,
        0x03C0,
        0x0600,
        0x0C00,
        0x1800,
        0x1800,
        0x1800,
        0x1800,
        0x1800,
        0x1800,
        0x0C00,
        0x0600,
        0x03C0,
        0x0000,
        0x0000,
        0x0000
    ])

    /// Cloudy icon for day; `weatherCloudNight` is the night counterpart.
    public static let weatherCloud = SpriteFrame(rows: [
        0x0000,
        0x0000,
        0x0000,
        0x0380,
        0x0C60,
        0x1010,
        0x200C,
        0x4002,
        0x4002,
        0x6006,
        0x3FFC,
        0x0000,
        0x0000,
        0x0000,
        0x0000,
        0x0000
    ])

    /// Cloudy icon for night, with a small sky glyph above the cloud;
    /// the day counterpart is `weatherCloud`.
    public static let weatherCloudNight = SpriteFrame(rows: [
        0x0E00,
        0x1000,
        0x1400,
        0x09C0,
        0x0630,
        0x0808,
        0x1006,
        0x2001,
        0x2001,
        0x3003,
        0x1FFC,
        0x0000,
        0x0000,
        0x0000,
        0x0000,
        0x0000
    ])

    /// Rain icon; no night variant exists, so it serves both day and night.
    public static let weatherRain = SpriteFrame(rows: [
        0x0000,
        0x0380,
        0x0C60,
        0x1010,
        0x200C,
        0x6004,
        0x7FF8,
        0x0000,
        0x2220,
        0x4440,
        0x2220,
        0x4440,
        0x0000,
        0x0000,
        0x0000,
        0x0000
    ])

    /// Snow icon; no night variant exists, so it serves both day and night.
    public static let weatherSnow = SpriteFrame(rows: [
        0x0000,
        0x0380,
        0x0C60,
        0x1010,
        0x200C,
        0x6004,
        0x7FF8,
        0x0000,
        0x1110,
        0x0AA0,
        0x1110,
        0x0AA0,
        0x1110,
        0x0000,
        0x0000,
        0x0000
    ])

    /// Storm icon; no night variant exists, so it serves both day and night.
    public static let weatherStorm = SpriteFrame(rows: [
        0x0000,
        0x0380,
        0x0C60,
        0x1010,
        0x200C,
        0x6004,
        0x7FF8,
        0x0180,
        0x0300,
        0x0780,
        0x0300,
        0x0600,
        0x0C00,
        0x0000,
        0x0000,
        0x0000
    ])

    /// Wind icon; no night variant exists, so it serves both day and night.
    public static let weatherWind = SpriteFrame(rows: [
        0x0000,
        0x0000,
        0x0000,
        0x1FF8,
        0x0008,
        0x0010,
        0x0FF0,
        0x0000,
        0x3FFC,
        0x0004,
        0x0008,
        0x1FE0,
        0x0000,
        0x0000,
        0x0000,
        0x0000
    ])

    /// Fog icon; no night variant exists, so it serves both day and night.
    public static let weatherFog = SpriteFrame(rows: [
        0x0000,
        0x0000,
        0x0000,
        0x0000,
        0x3FF0,
        0x0000,
        0x7FF8,
        0x0000,
        0x3FF0,
        0x0000,
        0x7FF8,
        0x0000,
        0x3FF0,
        0x0000,
        0x0000,
        0x0000
    ])
}
