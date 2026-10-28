import Foundation
import StepkinCore

/// Applies the night signal to the pet's light and sleep, bundled with the
/// bedtime window and the boundaries a catch-up replays, as pure functions
/// over `PetState`. A caseless enum because the schedule keeps no state of
/// its own.
///
/// - **Day:** the light is on and the pet is awake.
/// - **Night:** the light is the player's switch; the pet settles to sleep
///   only inside bedtime with the light off.
/// - **Transitions:** dusk turns the light off and dawn turns it on;
///   `PetState.wasNight` records the previous signal so the flip happens only
///   on a change.
public enum SleepSchedule {

    /// Resolves whether it is night: the weather's daylight flag when a
    /// reading exists, else the 18:00–06:00 clock window.
    public static func isNight(
        weatherNight: Bool?,
        at now: Date,
        calendar: Calendar
    ) -> Bool {
        if let weatherNight { return weatherNight }
        let hour = calendar.component(.hour, from: now)
        return hour < TimeConstants.nightEndHour || hour >= TimeConstants.nightStartHour
    }

    /// Reports whether `now` is inside bedtime, the 21:00–06:00 window in
    /// which the pet can settle to sleep; outside it the pet stays awake even
    /// at night.
    static func isBedtime(at now: Date, calendar: Calendar) -> Bool {
        let hour = calendar.component(.hour, from: now)
        return hour >= TimeConstants.sleepHour || hour < TimeConstants.nightEndHour
    }

    /// How many days of clock boundaries one catch-up replays. A pet neglected
    /// longer has long since collapsed, so later nights change nothing.
    static let maxReplayDays = 14

    /// Returns the scheduled state-change moments strictly between `start` and
    /// `end`, ascending, over at most `maxReplayDays` days: dusk (light off),
    /// bedtime (the settle begins), the settle completing (the pet sleeps) and
    /// dawn (wake). A catch-up steps through them so a night the app never saw
    /// is slept through, not charged as waking hours. Dawn without a preceding
    /// settle still matters: it is where a pet asleep at `start` wakes.
    static func replayBoundaries(
        from start: Date,
        to end: Date,
        calendar: Calendar
    ) -> [Date] {
        guard end > start else { return [] }
        let hours = [TimeConstants.nightEndHour, TimeConstants.nightStartHour, TimeConstants.sleepHour]
        var boundaries: [Date] = []
        var day = calendar.startOfDay(for: start)

        for _ in 0..<maxReplayDays {
            for hour in hours {
                guard let moment = calendar.date(
                    bySettingHour: hour, minute: 0, second: 0, of: day
                ) else { continue }
                boundaries.append(moment)
                if hour == TimeConstants.sleepHour {
                    boundaries.append(moment.addingTimeInterval(TimeConstants.sleepDelay))
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day), next < end else { break }
            day = next
        }
        return boundaries.filter { $0 > start && $0 < end }.sorted()
    }

    /// Applies the resolved night signal: flips the light when the signal
    /// changes, then settles or wakes the pet. A dead pet or egg is returned
    /// unchanged. The pet falls asleep only inside bedtime, once the light has
    /// been out for `sleepDelay`; waking goes through `PetState.wake(at:)` so
    /// sleep is a pause.
    public static func apply(
        to state: PetState,
        at now: Date,
        night: Bool,
        calendar: Calendar
    ) -> PetState {
        var state = state
        guard !state.isDead, !state.isEgg else { return state }

        if night != state.wasNight {
            state.lightsOn = !night
            state.wasNight = night
        }

        guard night else {
            state.lightsOn = true
            state.wake(at: now)
            return state
        }

        let bedtime = isBedtime(at: now, calendar: calendar)

        if state.lightsOn || !bedtime {
            state.wake(at: now)
        } else if state.isSleeping {
            state.timestamps.lightsOffAt = nil
        } else if let offAt = state.timestamps.lightsOffAt {
            if now.timeIntervalSince(offAt) >= TimeConstants.sleepDelay {
                state.isSleeping = true
                state.timestamps.lightsOffAt = nil
            }
        } else {
            state.timestamps.lightsOffAt = now
        }

        return state
    }
}
