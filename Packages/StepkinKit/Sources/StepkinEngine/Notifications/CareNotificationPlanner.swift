import Foundation
import StepkinCore

/// Computes the care reminders to schedule for a backgrounded pet. Pure and
/// deterministic: a fire time is its anchor plus whole intervals of waking
/// time — future activity is unknown, so the estimate is approximate. Hunger,
/// strength and mess pause overnight exactly as the engine pauses them, so a
/// projection crossing bedtime resumes at dawn and those calls never fire
/// overnight, unless the player's light is keeping the pet up. The injury
/// and fading clocks do not stop for the night, so their warnings fire
/// whenever due. Results in the past are dropped.
public enum CareNotificationPlanner {

    /// `steps` is today's running step count and applies activity scaling to
    /// the hunger and strength projections exactly as the simulators do;
    /// `nil` (steps disabled or unavailable) estimates at the base rates and
    /// skips the exercise nudge. The nudge has one fixed moment a day, so
    /// replanning after it cannot nudge again. The result is sorted by fire date.
    public static func plan(
        for state: PetState,
        now: Date,
        steps: Int?
    ) -> [CareNotification] {
        guard !state.isDead, !state.isEgg else { return [] }

        var candidates: [CareNotification] = []
        let times = state.timestamps
        let calendar = Calendar.current
        // A light on at night is the player's doing and keeps the pet up until
        // dawn, so tonight's bedtime is no pause.
        let keptUpUntil = state.wasNight && state.lightsOn ? nextMorning(after: now, calendar: calendar) : nil

        // Match the simulators' activity scaling, or a fast-draining pet flags late.
        let hungerInterval = TimeConstants.hungerDepletionInterval
            / (steps.map { ActivityModel.hungerRateMultiplier(steps: $0) } ?? 1.0)
        let strengthInterval = TimeConstants.strengthDepletionInterval
            / (steps.map { ActivityModel.strengthRateMultiplier(steps: $0) } ?? 1.0)

        if state.hungerHearts.value > 0, let fire = wakingProjection(
            from: times.lastHungerDecayAt, ticks: state.hungerHearts.value,
            interval: hungerInterval, keptUpUntil: keptUpUntil, calendar: calendar
        ) {
            candidates.append(CareNotification(kind: .hunger, fireDate: fire, species: state.species))
        }
        if state.strengthHearts.value > 0, let fire = wakingProjection(
            from: times.lastStrengthDecayAt, ticks: state.strengthHearts.value,
            interval: strengthInterval, keptUpUntil: keptUpUntil, calendar: calendar
        ) {
            candidates.append(CareNotification(kind: .strength, fireDate: fire, species: state.species))
        }

        if state.poopCount < TimeConstants.maxPoopPiles, let fire = wakingProjection(
            from: times.lastPoopAt, ticks: 1, interval: TimeConstants.poopInterval,
            keptUpUntil: keptUpUntil, calendar: calendar
        ) {
            candidates.append(CareNotification(kind: .mess, fireDate: fire, species: state.species))
        }

        if let fire = injuryFireDate(for: state, now: now, steps: steps, keptUpUntil: keptUpUntil, calendar: calendar) {
            candidates.append(CareNotification(kind: .injury, fireDate: fire, species: state.species))
        }

        // Fading — warn before a languishing pet collapses.
        if let collapsingAt = times.collapsingAt {
            let fire = collapsingAt.addingTimeInterval(
                TimeConstants.collapseDeathTime - TimeConstants.nearingDeathLead
            )
            candidates.append(CareNotification(kind: .fading, fireDate: fire, species: state.species))
        }

        // Exercise — nudge a wearer still below the step target in mid-afternoon.
        if let steps, steps < TimeConstants.exerciseStepTarget, let afternoon = calendar.date(
            bySettingHour: TimeConstants.exerciseHour, minute: 0, second: 0, of: now
        ) {
            let fire = afternoon.addingTimeInterval(TimeConstants.exerciseNudgeLead)
            candidates.append(CareNotification(kind: .exercise, fireDate: fire, species: state.species))
        }

        return candidates
            .filter { $0.fireDate > now }
            .sorted { $0.fireDate < $1.fireDate }
    }

    /// When the injury reminder fires, or nil when no injury is present or in sight.
    ///
    /// An injured pet is reminded half-way to the untreated-injury death. A
    /// catch-up dates an injury to the pile that caused it, so it can be found
    /// with that mark behind it: then a last call before death, or at once.
    /// A pet not yet injured whose mess is heading there has the reminder laid
    /// down ahead, half-way from the pile that will injure (one sooner on a
    /// sedentary day) to the death, since with no wake in between nothing replans.
    private static func injuryFireDate(
        for state: PetState,
        now: Date,
        steps: Int?,
        keptUpUntil: Date?,
        calendar: Calendar
    ) -> Date? {
        let halfWay = TimeConstants.untreatedInjuryDeathTime / 2
        if state.isInjured {
            guard let injuredAt = state.timestamps.injuredAt else { return nil }
            let lastCall = TimeConstants.untreatedInjuryDeathTime - TimeConstants.injuryLastCallLead
            return [halfWay, lastCall].map { injuredAt.addingTimeInterval($0) }.first { $0 > now }
                ?? now.addingTimeInterval(TimeConstants.injuryCallDelay)
        }
        let sedentary = steps.map { ActivityModel.isSedentary(steps: $0) } ?? false
        let injuringPiles = TimeConstants.maxPoopPiles - (sedentary ? 1 : 0)
        guard state.poopCount < injuringPiles else { return nil }
        return wakingProjection(
            from: state.timestamps.lastPoopAt, ticks: injuringPiles - state.poopCount,
            interval: TimeConstants.poopInterval, keptUpUntil: keptUpUntil, calendar: calendar
        )?.addingTimeInterval(halfWay)
    }

    /// The instant `ticks` intervals of waking time complete, counting from
    /// `anchor`. The bedtime window is skipped, mirroring the engine — waking
    /// re-anchors at dawn, so an anchor in the window jumps to morning first.
    /// A pet kept up by the light stays awake through to `keptUpUntil` and on
    /// to the settle after it. Nil when no morning resolves within
    /// `SleepSchedule.maxReplayDays` days.
    private static func wakingProjection(
        from anchor: Date,
        ticks: Int,
        interval: TimeInterval,
        keptUpUntil: Date?,
        calendar: Calendar
    ) -> Date? {
        var moment = anchor
        var remaining = Double(ticks) * interval
        if let keptUpUntil, moment < keptUpUntil {
            guard let settle = nextSettle(after: keptUpUntil, calendar: calendar) else { return nil }
            let awake = settle.timeIntervalSince(moment)
            if remaining <= awake { return moment.addingTimeInterval(remaining) }
            remaining -= awake
            moment = settle
        }
        for _ in 0..<SleepSchedule.maxReplayDays {
            if SleepSchedule.isBedtime(at: moment, calendar: calendar) {
                guard let morning = nextMorning(after: moment, calendar: calendar) else { return nil }
                moment = morning
            }
            guard let settle = nextSettle(after: moment, calendar: calendar) else { return nil }
            let awake = settle.timeIntervalSince(moment)
            if remaining <= awake { return moment.addingTimeInterval(remaining) }
            remaining -= awake
            moment = settle
        }
        return nil
    }

    /// The next moment the pet settles to sleep (bedtime plus the settle delay)
    /// strictly after `date`.
    private static func nextSettle(after date: Date, calendar: Calendar) -> Date? {
        guard let bedtime = calendar.date(
            bySettingHour: TimeConstants.sleepHour, minute: 0, second: 0, of: date
        ) else { return nil }
        let settle = bedtime.addingTimeInterval(TimeConstants.sleepDelay)
        if settle > date { return settle }
        return calendar.date(byAdding: .day, value: 1, to: settle)
    }

    /// The next `nightEndHour` strictly after `date`, or nil when the calendar
    /// cannot resolve that instant.
    private static func nextMorning(after date: Date, calendar: Calendar) -> Date? {
        let isBeforeDawn = calendar.component(.hour, from: date) < TimeConstants.nightEndHour
        guard let day = isBeforeDawn
            ? date
            : calendar.date(byAdding: .day, value: 1, to: date)
        else { return nil }
        return calendar.date(
            bySettingHour: TimeConstants.nightEndHour, minute: 0, second: 0, of: day
        )
    }
}
