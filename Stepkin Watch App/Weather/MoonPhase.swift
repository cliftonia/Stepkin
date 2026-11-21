import Foundation

/// The eight phases of the lunar cycle, ordered new → waning crescent.
nonisolated enum MoonPhase: Sendable, CaseIterable {
    case new
    case waxingCrescent
    case firstQuarter
    case waxingGibbous
    case full
    case waningGibbous
    case lastQuarter
    case waningCrescent

    /// Derives the phase for a given date from the synodic month (~29.53 days),
    /// counting from a known new moon (2000-01-06 18:14 UTC).
    static func current(date: Date = Date()) -> MoonPhase {
        let synodicMonth = 29.530588853
        let referenceNewMoon = Date(timeIntervalSince1970: 947_182_440)
        let days = date.timeIntervalSince(referenceNewMoon) / 86_400
        let fraction = (days / synodicMonth).truncatingRemainder(dividingBy: 1)
        let position = fraction < 0 ? fraction + 1 : fraction
        let index = Int((position * 8).rounded()) % 8
        return allCases[index]
    }
}
