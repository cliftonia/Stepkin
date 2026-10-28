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

    /// Applies a finished settle on top of the live state read after the
    /// fetch, never the snapshot it ran against: an evolution or feed accepted
    /// meanwhile must survive, including the evolution's goal-penalty reset.
    /// So only what the settle added (the lifetime credit and the missed-day
    /// charges) is added to the live fields, and the settled day and count are
    /// taken only while the live accumulator still tracks the snapshot's day;
    /// otherwise the settle is dropped. Today's latest live count then tops
    /// the credit up, and the result is saved.
    func adoptSettledSteps(_ settled: PetState, from snapshot: PetState) {
        defer { dayRecoveryTask = nil }
        guard !Task.isCancelled else { return }
        guard let trackedDay = snapshot.stepTrackedDay,
              state.stepTrackedDay?.isSameDay(as: trackedDay) == true
        else { return }

        state.lifetimeActiveSteps += settled.lifetimeActiveSteps - snapshot.lifetimeActiveSteps
        state.evolutionGoalPenalty += settled.evolutionGoalPenalty - snapshot.evolutionGoalPenalty
        state.stepsCreditedToday = settled.stepsCreditedToday
        state.stepTrackedDay = settled.stepTrackedDay
        if let latest = currentSteps().count {
            state = StepCrediting.creditLive(state, todaySteps: latest, now: .now, calendar: .current)
        }
        save()
    }
}
