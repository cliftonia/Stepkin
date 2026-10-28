import Foundation

// MARK: - Step Crediting

extension PetPresenter {

    /// Folds today's live steps into the evolution accumulator through
    /// `StepCrediting`. Within the tracked day the delta is credited at once;
    /// a day that ended while the app was closed settles asynchronously in
    /// `dayRecoveryTask`, since HealthKit keeps counting unwatched and the
    /// last figure seen would lose steps and misjudge the day's laziness.
    func creditSteps() {
        guard let steps = currentSteps().count else { return }

        guard StepCrediting.isCatchUpPending(state, now: .now, calendar: .current) else {
            state = StepCrediting.creditLive(state, todaySteps: steps, now: .now, calendar: .current)
            return
        }

        guard dayRecoveryTask == nil else { return }
        let snapshot = state
        dayRecoveryTask = Task { [weak self] in
            guard let finalSteps = self?.finalSteps else { return }
            let settled = await StepCrediting.settle(
                snapshot, todaySteps: steps, now: .now, finalSteps: finalSteps, calendar: .current
            )
            self?.adoptSettledSteps(settled, from: snapshot)
        }
    }

    /// Writes a finished settle's step accumulator back and saves. The state
    /// is re-read after the fetch rather than replaced by the settled copy, so
    /// an evolution or feed accepted meanwhile is not overwritten: only the
    /// four step fields are taken, and only while the accumulator still
    /// tracks the day the settle started from. Today's latest live count then
    /// tops the credit up.
    func adoptSettledSteps(_ settled: PetState, from snapshot: PetState) {
        defer { dayRecoveryTask = nil }
        guard !Task.isCancelled else { return }
        guard let trackedDay = snapshot.stepTrackedDay,
              state.stepTrackedDay?.isSameDay(as: trackedDay) == true
        else { return }

        StepProgress.Progress(of: settled).write(to: &state)
        if let latest = currentSteps().count {
            state = StepCrediting.creditLive(state, todaySteps: latest, now: .now, calendar: .current)
        }
        save()
    }
}
