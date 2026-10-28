import Foundation

/// Folds a day's steps into the lifetime accumulator and settles every day
/// missed while the app was closed.
///
/// HealthKit keeps counting while nothing watches, so the last figure the app
/// saw for a finished day undercounts it and can misjudge its laziness. A
/// settle therefore asks for each missed day's final total, replays every day
/// through `StepProgress.advance` with its own verdict, and only then rolls
/// over to today's live count. Only the four step-accumulator fields change.
public enum StepCrediting {

    /// How many missed days a single catch-up will settle with HealthKit.
    public static let maxCatchUpDays = 7

    /// Settles `state`'s step accumulator at `now`.
    ///
    /// A nil `todaySteps` returns the state unchanged. Within the tracked day
    /// only the live delta is credited and nothing is fetched. A different day
    /// fetches each missed day's final total through `finalSteps`, oldest
    /// first and capped at `maxCatchUpDays`, skipping days that return nil and
    /// never reaching today, then rolls over with `todaySteps`.
    public static func settle(
        _ state: PetState,
        todaySteps: Int?,
        now: Date,
        finalSteps: (Date) async -> Int?,
        calendar: Calendar
    ) async -> PetState {
        guard let todaySteps else { return state }
        var progress = StepProgress.Progress(of: state)
        let penalty = state.species.stage.lazyDayPenalty

        if isCatchUpPending(state, now: now, calendar: calendar), let trackedDay = progress.trackedDay {
            // Each entry settles its own day: the first credits the tracked
            // day's uncounted tail, and every later one rolls the previous day
            // over with that day's true total deciding the lazy-day verdict.
            for entry in await missedDayTotals(from: trackedDay, now: now, finalSteps: finalSteps, calendar: calendar) {
                progress = StepProgress.advance(
                    progress, todaySteps: entry.total, now: entry.day, stagePenalty: penalty, calendar: calendar
                )
            }
        }

        var settled = state
        StepProgress.advance(progress, todaySteps: todaySteps, now: now, stagePenalty: penalty, calendar: calendar)
            .write(to: &settled)
        return settled
    }

    /// Credits the live `todaySteps` without any catch-up, for a caller that
    /// has checked `isCatchUpPending` is false and must stay synchronous.
    public static func creditLive(_ state: PetState, todaySteps: Int, now: Date, calendar: Calendar) -> PetState {
        var credited = state
        StepProgress.advance(
            StepProgress.Progress(of: state),
            todaySteps: todaySteps,
            now: now,
            stagePenalty: state.species.stage.lazyDayPenalty,
            calendar: calendar
        )
        .write(to: &credited)
        return credited
    }

    /// Reports whether the accumulator tracks a day other than `now`'s, so a
    /// settle would fetch final totals before rolling over.
    public static func isCatchUpPending(_ state: PetState, now: Date, calendar: Calendar) -> Bool {
        guard let trackedDay = state.stepTrackedDay else { return false }
        return !calendar.isDate(trackedDay, inSameDayAs: now)
    }

    /// Settled totals for the tracked day and each whole day missed since,
    /// oldest first. Capped at `maxCatchUpDays` days walked, so a failing
    /// HealthKit leaves gaps instead of fanning out queries; days beyond go
    /// uncredited and unpenalised, and a future tracked day returns empty.
    private static func missedDayTotals(
        from trackedDay: Date,
        now: Date,
        finalSteps: (Date) async -> Int?,
        calendar: Calendar
    ) async -> [(day: Date, total: Int)] {
        var totals: [(day: Date, total: Int)] = []
        var cursor = trackedDay

        for _ in 0..<maxCatchUpDays where cursor < now && !calendar.isDate(cursor, inSameDayAs: now) {
            if let total = await finalSteps(cursor) {
                totals.append((cursor, total))
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return totals
    }
}
