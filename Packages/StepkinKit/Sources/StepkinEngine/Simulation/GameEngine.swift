import Foundation
import StepkinCore
import os

/// Runs a tick: advances pet state from `lastAdvancedAt` to a given date.
///
/// A caseless enum because the engine is a pure state-to-state function with
/// no stored state, so a tick runs from any isolation. Called
/// on app wake, on the foreground and background schedules, and after user
/// actions.
public enum GameEngine {

    /// Advances the full game state to the supplied date, running every
    /// simulator in order and evaluating death.
    ///
    /// A call spanning a long gap is a catch-up: the clock's sleep boundaries
    /// inside the span are replayed before landing on `now`, so a missed
    /// night is slept through rather than charged as waking hours. `isNight`
    /// is the weather's daylight reading; `nil` resolves night from the
    /// 18:00–06:00 clock window in `SleepSchedule.isNight`. `steps` is
    /// today's reading; `.off` and `.unavailable` (no count) disable activity
    /// scaling, leaving every simulator at its base interval.
    /// `calendar` supplies the age, night and bedtime hours. For a dead or
    /// egg pet only `lastAdvancedAt` moves; no simulator runs.
    public static func advance(
        _ state: PetState,
        to now: Date,
        isNight: Bool?,
        steps: StepReading,
        calendar: Calendar
    ) -> PetState {
        var state = state

        guard !state.isDead, !state.isEgg else {
            state.timestamps.lastAdvancedAt = now
            return state
        }

        // Replayed boundaries predate the weather reading, so they resolve
        // night from the clock (isNight: nil); only the final step sees the
        // live signal.
        let boundaries = SleepSchedule.replayBoundaries(
            from: state.timestamps.lastAdvancedAt, to: now, calendar: calendar
        )
        for boundary in boundaries {
            state = step(state, to: boundary, isNight: nil, steps: steps, calendar: calendar)
            if state.isDead { return state }
        }
        return step(state, to: now, isNight: isNight, steps: steps, calendar: calendar)
    }

    /// Runs one step from `lastAdvancedAt` to `now`: every simulator, then
    /// the death check.
    ///
    /// The simulator order is load-bearing — the trackers read the hearts and
    /// flags the earlier simulators wrote — so do not reorder it.
    private static func step(
        _ state: PetState,
        to now: Date,
        isNight: Bool?,
        steps: StepReading,
        calendar: Calendar
    ) -> PetState {
        var state = state

        // Clamped so a backward clock can't produce a negative age.
        let days = calendar.dateComponents(
            [.day], from: state.timestamps.bornAt, to: now
        ).day ?? state.age
        state.age = max(0, days)

        // Resolve night and bedtime once so every simulator in the step sees
        // the same signal.
        let night = SleepSchedule.isNight(weatherNight: isNight, at: now, calendar: calendar)
        let bedtime = SleepSchedule.isBedtime(at: now, calendar: calendar)

        state = SleepSchedule.apply(to: state, at: now, night: night, calendar: calendar)
        state = HungerSimulator.apply(to: state, at: now, steps: steps.count)
        state = StrengthSimulator.apply(to: state, at: now, steps: steps.count)
        state = ConditioningSimulator.apply(to: state, at: now)
        state = PoopSimulator.apply(to: state, at: now)
        state = InjurySimulator.apply(to: state, at: now, steps: steps.count)
        state = CareMistakeTracker.apply(to: state, at: now, bedtime: bedtime)
        state = CollapseTracker.apply(to: state, at: now)

        if let cause = DeathEvaluator.evaluate(state, at: now) {
            Log.engine.info("Pet died from \(String(describing: cause))")
            state = DeathEvaluator.applyDeath(to: state)
        }

        state.timestamps.lastAdvancedAt = now
        return state
    }
}
