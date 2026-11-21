import Foundation

/// Immutable inputs for `LCDDisplay` — one value instead of a dozen view
/// parameters. Built per render from the resolved `LCDScene` plus the sprites.
nonisolated struct LCDDisplayConfiguration: Hashable, Sendable {
    /// The sprite frame drawn in the primary (left) slot.
    let leftSprite: SpriteFrame
    /// The second sprite frame, or nil when this render shows a single sprite.
    let rightSprite: SpriteFrame?
    /// The number of poop piles the scene draws.
    let poopCount: Int
    /// The animation phase of the poop's stink wisps.
    let stinkPhase: Int
    /// Whether the scene's light is on for this render.
    let lightsOn: Bool
    /// Horizontal placement of the left sprite on the LCD grid.
    let leftSpriteOffsetX: Int
    /// Vertical placement of the left sprite on the LCD grid.
    let leftSpriteOffsetY: Int
    /// Vertical placement of the right sprite on the LCD grid.
    let rightSpriteOffsetY: Int
    /// Which weather icon to overlay, or nil for none.
    let weatherCondition: WeatherIconCondition?
    /// Which moon the night sky shows.
    let moonPhase: MoonPhase
    /// The phase of day the sky is drawn in.
    let dayPhase: DayPhase
    /// Whether the storm strobe flashes this render.
    let stormFlash: Bool
    /// The evolution strobe — a full-screen white-out flash with no VS text.
    let evolveFlash: Bool
    /// Whether the Call sign blinks while the pet languishes — the toy's attention alert.
    let showCallSign: Bool

    /// Creates the immutable inputs for a single `LCDDisplay` render.
    init(
        leftSprite: SpriteFrame,
        rightSprite: SpriteFrame? = nil,
        poopCount: Int = 0,
        stinkPhase: Int = 0,
        lightsOn: Bool = true,
        leftSpriteOffsetX: Int = 8,
        leftSpriteOffsetY: Int = 4,
        rightSpriteOffsetY: Int = 4,
        weatherCondition: WeatherIconCondition? = nil,
        moonPhase: MoonPhase = .full,
        dayPhase: DayPhase = .day,
        stormFlash: Bool = false,
        evolveFlash: Bool = false,
        showCallSign: Bool = false
    ) {
        self.leftSprite = leftSprite
        self.rightSprite = rightSprite
        self.poopCount = poopCount
        self.stinkPhase = stinkPhase
        self.lightsOn = lightsOn
        self.leftSpriteOffsetX = leftSpriteOffsetX
        self.leftSpriteOffsetY = leftSpriteOffsetY
        self.rightSpriteOffsetY = rightSpriteOffsetY
        self.weatherCondition = weatherCondition
        self.moonPhase = moonPhase
        self.dayPhase = dayPhase
        self.stormFlash = stormFlash
        self.evolveFlash = evolveFlash
        self.showCallSign = showCallSign
    }
}
