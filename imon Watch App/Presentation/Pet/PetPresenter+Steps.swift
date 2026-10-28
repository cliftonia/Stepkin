import Foundation

// MARK: - Step Crediting

extension PetPresenter {

    /// How many missed days a single catch-up will settle with HealthKit.
    static let maxCatchUpDays = 7

    /// Folds today's live steps into the evolution accumulator, applying the
    /// lazy-day penalty on rollover. A day that ends while the app is closed
    /// settles asynchronously first: HealthKit keeps counting unwatched, so
    /// the last figure seen would lose steps and misjudge the day's laziness.
    func creditSteps() {
        guard let steps = currentSteps().count else { return }
        let progress = StepProgress.Progress(of: state)

        guard let trackedDay = progress.trackedDay,
              !trackedDay.isSameDay(as: .now)
        else {
            rollOver(progress, todaySteps: steps)
            return
        }

        guard dayRecoveryTask == nil else { return }
        dayRecoveryTask = Task { [weak self] in
            await self?.settleAndRollOver(trackedDay: trackedDay, fallbackSteps: steps)
        }
    }

    /// Credits the closed day's true total, then rolls the accumulator over.
    /// Every missed day is fetched before any state is touched, so an
    /// evolution accepted mid-fetch is not overwritten; the rollover proceeds
    /// even when fetches fail, with `fallbackSteps` covering a lost live count.
    func settleAndRollOver(trackedDay: Date, fallbackSteps: Int) async {
        let totals = await missedDayTotals(from: trackedDay)
        defer { dayRecoveryTask = nil }
        guard !Task.isCancelled else { return }

        var progress = StepProgress.Progress(of: state)
        guard progress.trackedDay?.isSameDay(as: trackedDay) == true else { return }

        // Each entry settles its own day: the first credits the tracked day's
        // uncounted tail, and every later one rolls the previous day over with
        // that day's true total deciding the lazy-day verdict.
        for entry in totals {
            progress = StepProgress.advance(
                progress,
                todaySteps: entry.total,
                now: entry.day,
                stagePenalty: state.species.stage.lazyDayPenalty,
                calendar: .current
            )
        }
        rollOver(progress, todaySteps: currentSteps().count ?? fallbackSteps)
        save()
    }

    /// Settled totals for the tracked day and each whole day missed since,
    /// oldest first. Capped at `maxCatchUpDays` days walked, so a failing
    /// HealthKit leaves gaps instead of fanning out queries; days beyond go
    /// uncredited and unpenalised, and a future tracked day returns empty.
    func missedDayTotals(from trackedDay: Date) async -> [(day: Date, total: Int)] {
        let calendar = Calendar.current
        var totals: [(day: Date, total: Int)] = []
        var cursor = trackedDay

        for _ in 0..<Self.maxCatchUpDays where cursor < .now && !calendar.isDateInToday(cursor) {
            if let total = await finalSteps(cursor) {
                totals.append((cursor, total))
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return totals
    }

    /// Rolls the finished day over at the current moment, crediting the live
    /// count `todaySteps` carries. Writes the advanced progress into `state`
    /// but never saves; each caller decides persistence.
    func rollOver(_ progress: StepProgress.Progress, todaySteps: Int) {
        StepProgress.advance(
            progress,
            todaySteps: todaySteps,
            now: .now,
            stagePenalty: state.species.stage.lazyDayPenalty,
            calendar: .current
        )
        .write(to: &state)
    }
}
