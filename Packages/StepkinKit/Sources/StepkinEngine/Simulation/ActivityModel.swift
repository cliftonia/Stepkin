import Foundation

/// Maps today's step count into the activity-scaling values that stretch or
/// compress the simulators' intervals.
///
/// More movement depletes hunger faster and strength slower; less movement
/// reverses both. All activity-scaling tuning lives here, and clamping keeps
/// every multiplier between ×0.8 and ×1.5, so no step count can halt
/// depletion entirely.
public enum ActivityModel {

    /// Step count at which the activity factor saturates at 1.0; steps
    /// beyond it have no further effect.
    static let stepGoal = 8_000

    /// Activity factor below which the pet counts as sedentary — 0.25 of
    /// `stepGoal` is 2,000 steps, matching `StepProgress.lazyThreshold`.
    static let sedentaryFactor = 0.25

    /// Returns the activity factor for a step count, clamped to 0 (no steps)
    /// at the bottom and 1 (at or above `stepGoal`) at the top.
    static func factor(steps: Int) -> Double {
        min(1, max(0, Double(steps) / Double(stepGoal)))
    }

    /// Reports whether a step count is sedentary: an activity factor below
    /// `sedentaryFactor`.
    public static func isSedentary(steps: Int) -> Bool {
        factor(steps: steps) < sedentaryFactor
    }

    /// Multiplies the hunger depletion rate from ×0.8 (sedentary) up to ×1.5
    /// (fully active): more movement compresses the hunger interval.
    static func hungerRateMultiplier(steps: Int) -> Double {
        0.8 + 0.7 * factor(steps: steps)
    }

    /// Multiplies the strength depletion rate from ×1.5 (sedentary) down to
    /// ×0.8 (fully active): less movement compresses the strength interval.
    static func strengthRateMultiplier(steps: Int) -> Double {
        1.5 - 0.7 * factor(steps: steps)
    }

}
