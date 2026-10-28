import Foundation

/// Sends an action through the live presenter when one exists, else through
/// the offline session: the one rule that keeps a single writer for the save.
@MainActor
enum PetActionRouter {

    /// Performs `action` on the live `PetPresenter` when the app holds one;
    /// otherwise refreshes today's steps and runs `OfflineSession` against the
    /// save with the app's night and step readings. The live path still
    /// re-arms `offline.refresh` when given, and a live tick hands care off
    /// the way a background wake always has; neither writes the save.
    static func perform(
        _ action: PetAction,
        app: AppPresenter,
        offline: OfflineSession.Dependencies,
        now: Date
    ) async -> PetActionOutcome {
        guard let petPresenter = app.petPresenter else {
            let steps = await app.refreshedStepReading(now: now)
            return await OfflineSession.run(
                action, readings: (night: app.currentNightReading(), steps: steps), dependencies: offline, now: now
            )
        }

        let outcome = petPresenter.perform(action)
        offline.refresh?.scheduleNext(from: now)
        if case .tick = action {
            CareHandoff.perform(
                state: petPresenter.state, now: now, steps: petPresenter.currentSteps().count,
                notificationsEnabled: offline.notificationsEnabled, witnesses: offline.witnesses
            )
        }
        return outcome
    }
}
