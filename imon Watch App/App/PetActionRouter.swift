import Foundation

/// Sends an action through the live presenter when one exists, else through
/// the offline session: the one rule that keeps a single writer for the save.
@MainActor
enum PetActionRouter {

    /// Refreshes today's steps, then performs `action` on the live
    /// `PetPresenter` when the app holds one, or runs `OfflineSession` against
    /// the save with the app's night and step readings. The session is given a
    /// hand-off back to this router's live path, so a presenter that appears
    /// across one of its awaits takes the action instead of the session saving.
    static func perform(
        _ action: PetAction,
        app: AppPresenter,
        offline: OfflineSession.Dependencies,
        now: Date
    ) async -> PetActionOutcome {
        let steps = await app.refreshedStepReading(now: now)

        // Checked after the refresh's await: the UI may have created a presenter meanwhile.
        if let petPresenter = app.petPresenter {
            return performLive(action, on: petPresenter, offline: offline, now: now)
        }

        var session = offline
        session.liveHandOff = { [weak app] action in
            app?.petPresenter.map { performLive(action, on: $0, offline: offline, now: now) }
        }
        return await OfflineSession.run(
            action, readings: (night: app.currentNightReading(), steps: steps), dependencies: session, now: now
        )
    }

    /// The live path: the presenter performs the action, the refresh is
    /// re-armed when given, and a tick hands care off the way a background
    /// wake always has. Neither of the last two writes the save.
    private static func performLive(
        _ action: PetAction,
        on petPresenter: PetPresenter,
        offline: OfflineSession.Dependencies,
        now: Date
    ) -> PetActionOutcome {
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
