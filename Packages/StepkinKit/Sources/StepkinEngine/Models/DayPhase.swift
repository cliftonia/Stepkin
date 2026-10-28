import Foundation

/// The three environment states that drive sleep, the light, and the LCD scene.
public enum DayPhase: Sendable {
    /// Daylight hours — the light is forced on and the pet is awake.
    case day
    /// Dark hours with the light off — the pet sleeps; the night sky shows.
    case night
    /// Dark hours with the light on — the pet is awake indoors (lit room).
    case inside

    /// Resolves the phase from the night signal and the light; daylight forces
    /// `day`, so the light is consulted only in dark hours.
    public static func resolve(isNight: Bool, lightsOn: Bool) -> DayPhase {
        guard isNight else { return .day }
        return lightsOn ? .inside : .night
    }
}
