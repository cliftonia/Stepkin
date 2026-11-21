import Foundation

/// What the LCD draws behind the pet for a given moment — the scene's
/// lights, day phase and weather, decided by `SceneResolver`.
nonisolated struct LCDScene: Equatable, Sendable {
    /// Whether the scene draws lit or dark; the arena derives it from the day phase.
    let lightsOn: Bool
    /// Day or night for the environment; the arena forces day, going dark through its lights.
    let dayPhase: DayPhase
    /// The weather behind the pet; `nil` draws none — a ceremony, a care mess, or the arena.
    let weather: WeatherIconCondition?
}

/// Resolves which scene shows, so the rules live in one testable place
/// instead of scattered across the views.
nonisolated enum SceneResolver {

    /// Resolves the home (pet) screen: the full environment with real light,
    /// day phase and weather — except an action ceremony, which plays in its
    /// own clean scene (no room, no weather) with the real lighting kept,
    /// and a care mess, which hides the weather so the care cue reads clearly.
    static func home(
        dayPhase: DayPhase,
        lightsOn: Bool,
        weather: WeatherIconCondition?,
        isInActionScene: Bool,
        careMessPresent: Bool
    ) -> LCDScene {
        if isInActionScene {
            return LCDScene(lightsOn: lightsOn, dayPhase: .day, weather: nil)
        }
        return LCDScene(
            lightsOn: lightsOn,
            dayPhase: dayPhase,
            weather: careMessPresent ? nil : weather
        )
    }

    /// Resolves the battle / training arena — always outdoors: lit by day,
    /// dark at night, never the inside room, never weather.
    static func arena(dayPhase: DayPhase) -> LCDScene {
        LCDScene(lightsOn: dayPhase == .day, dayPhase: .day, weather: nil)
    }
}
