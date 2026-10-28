import Foundation

/// Accumulates each day's real-world steps into the lifetime steps that drive
/// evolution.
///
/// Fresh steps are credited to the lifetime total, which only ever grows, and
/// finishing a lazy day — under `lazyThreshold` steps — raises the evolution
/// goal by a stage-scaled penalty, so progression rewards staying active
/// rather than a single burst. The accumulator is a plain value so a catch-up
/// can replay each missed day through the same `advance` call, as
/// `PetPresenter.settleAndRollOver` does. All tuning lives here and in
/// `EvolutionStage`.
nonisolated enum StepProgress {

    /// Steps under which a finished day counts as a lazy day; kept in line with
    /// `ActivityModel.sedentaryFactor`, whose sedentary floor is the same count.
    static let lazyThreshold = 2_000

    /// The lifetime steps accumulator, advanced as a unit.
    nonisolated struct Progress: Sendable, Equatable {
        /// The lifetime steps total; credited only, never decremented.
        var lifetime: Int
        /// Steps credited on `trackedDay`; compared with `lazyThreshold` when
        /// the day rolls over.
        var creditedToday: Int
        /// The calendar day `creditedToday` belongs to; `nil` until first credit.
        var trackedDay: Date?
        /// Extra steps the lazy-day penalties have added to the evolution goal.
        var goalPenalty: Int
    }

    /// Folds `todaySteps` into the accumulator, charging `stagePenalty` to the
    /// evolution goal when a calendar-day rollover finishes a lazy day.
    ///
    /// `todaySteps` is HealthKit's running total for the current day, so within
    /// a day only the delta since `creditedToday` is credited, and a downward
    /// reading is ignored rather than subtracted; a negative count clamps to
    /// zero. Callers pass the current stage's `EvolutionStage.lazyDayPenalty`
    /// as `stagePenalty`.
    static func advance(
        _ progress: Progress,
        todaySteps: Int,
        now: Date,
        stagePenalty: Int,
        calendar: Calendar
    ) -> Progress {
        let today = max(0, todaySteps)

        // Baseline only — a fresh pet must not inherit steps taken before it existed.
        guard let trackedDay = progress.trackedDay else {
            return Progress(
                lifetime: max(0, progress.lifetime),
                creditedToday: today,
                trackedDay: now,
                goalPenalty: progress.goalPenalty
            )
        }

        if calendar.isDate(now, inSameDayAs: trackedDay) {
            let delta = max(0, today - progress.creditedToday)
            return Progress(
                lifetime: progress.lifetime + delta,
                creditedToday: max(progress.creditedToday, today),
                trackedDay: trackedDay,
                goalPenalty: progress.goalPenalty
            )
        }

        // One rollover charges at most one lazy day: a multi-day absence is
        // settled by `PetPresenter.settleAndRollOver` replaying each missed day
        // through here, so every day gets its own verdict rather than one
        // approximate charge.
        let penalty = progress.creditedToday < lazyThreshold ? stagePenalty : 0
        return Progress(
            lifetime: progress.lifetime + today,
            creditedToday: today,
            trackedDay: now,
            goalPenalty: progress.goalPenalty + penalty
        )
    }
}

// MARK: - PetState Mapping

nonisolated extension StepProgress.Progress {

    /// Creates an accumulator from `PetState`'s four persisted fields; the
    /// field-for-field inverse of `write(to:)`.
    init(of state: PetState) {
        self.init(
            lifetime: state.lifetimeActiveSteps,
            creditedToday: state.stepsCreditedToday,
            trackedDay: state.stepTrackedDay,
            goalPenalty: state.evolutionGoalPenalty
        )
    }

    /// Writes the accumulator back into the same four `PetState` fields that
    /// `init(of:)` reads.
    func write(to state: inout PetState) {
        state.lifetimeActiveSteps = lifetime
        state.stepsCreditedToday = creditedToday
        state.stepTrackedDay = trackedDay
        state.evolutionGoalPenalty = goalPenalty
    }
}
