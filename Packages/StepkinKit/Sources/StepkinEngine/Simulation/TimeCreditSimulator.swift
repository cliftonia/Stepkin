import Foundation
import StepkinCore

/// Credits step-equivalents for waking, living time while the Steps switch is off, so a pet without
/// HealthKit still grows. Whole credits only; the anchor advances by the time they cost.
///
/// `.off` also parks the step accumulator (`stepTrackedDay` cleared, `stepsCreditedToday` zeroed),
/// so when a count returns `StepProgress.advance` takes its baseline path and credits nothing: the
/// off period was already paid in time credit and is never replayed as missed days.
enum TimeCreditSimulator {

    /// The most credits one call may award, keeping the conversion to `Int` safe on a 32-bit watch.
    private static let creditCeiling: Double = 1_000_000_000

    /// Credits the waking time since `lastTimeCreditAt` when `steps` is `.off`; in every other case
    /// the anchor moves to `now`, so nothing accrues and nothing is owed later.
    static func apply(to state: PetState, at now: Date, steps: StepReading) -> PetState {
        var state = state
        let rate = Double(TimeConstants.fallbackStepsPerWakingHour)
        let elapsed = now.timeIntervalSince(state.timestamps.lastTimeCreditAt)

        if steps == .off {
            state.stepTrackedDay = nil
            state.stepsCreditedToday = 0
        }

        guard steps == .off, state.isAwakeAndAlive, elapsed >= 0 else {
            state.timestamps.lastTimeCreditAt = now
            return state
        }

        // The epsilon absorbs floating-point drift in the anchor, so exact multiples are not lost.
        let credits = Int(min(creditCeiling, floor(elapsed * rate / 3_600 + 1e-9)))
        guard credits > 0 else { return state }

        let (total, overflowed) = state.lifetimeActiveSteps.addingReportingOverflow(credits)
        state.lifetimeActiveSteps = overflowed ? Int.max : total
        state.timestamps.lastTimeCreditAt = state.timestamps.lastTimeCreditAt
            .addingTimeInterval(Double(credits) * 3_600 / rate)
        return state
    }
}
