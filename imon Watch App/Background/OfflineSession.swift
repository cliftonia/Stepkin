import Foundation
import os

/// Runs a pet action against the save when no presenter is alive: a bare
/// background wake, or an intent while the app is not on screen.
///
/// Self-contained: it reads and writes `PetStateStore` directly, so it is only
/// ever reached through `PetActionRouter`, which prefers the live presenter
/// whenever one exists. That keeps a single writer for the save at any time.
nonisolated enum OfflineSession {

    /// Everything a session reads and writes through, gathered so `run` stays
    /// within the parameter limit. No defaults: each call site decides
    /// notifications and the refresh chain explicitly.
    struct Dependencies: Sendable {
        /// The save the session loads, advances and writes back.
        let store: PetStateStore
        /// The settled step total for a finished day, or nil when unavailable.
        let finalSteps: @Sendable (Date) async -> Int?
        /// The reminder and complication witnesses the care hand-off writes through.
        let witnesses: CareHandoff.Witnesses
        /// The background refresh chain to re-arm, or nil when the caller is not a wake.
        let refresh: BackgroundRefreshScheduler?
        /// Whether evolution announcements and care reminders are switched on.
        let notificationsEnabled: Bool
    }

    /// Loads the pet, advances it to `now`, settles its steps, applies
    /// `action`, offers evolution, saves, re-arms the refresh and hands care
    /// off. A load failure re-arms the refresh so the chain survives and
    /// returns `.noPet`, as does a missing pet. A refused action still saves
    /// the advance, since the time away happened either way.
    static func run(
        _ action: PetAction,
        readings: (night: Bool?, steps: StepReading),
        dependencies: Dependencies,
        now: Date
    ) async -> PetActionOutcome {
        let loaded: PetState?
        do {
            loaded = try dependencies.store.load()
        } catch {
            Log.background.error("Offline load failed: \(error, privacy: .public)")
            dependencies.refresh?.scheduleNext(from: now)
            return .noPet
        }
        guard let saved = loaded, !saved.isEgg else { return .noPet }

        var state = GameEngine.advance(saved, to: now, isNight: readings.night, steps: readings.steps, calendar: .current)
        state = await StepCrediting.settle(
            state, todaySteps: readings.steps.count, now: now, finalSteps: dependencies.finalSteps, calendar: .current
        )

        let outcome = apply(action, to: &state, now: now)
        state = evolveIfReady(state, now: now, dependencies: dependencies)

        dependencies.store.save(state, loggingTo: Log.background)

        // Re-arm before the hand-off: the chain survives if the work below is cut short.
        dependencies.refresh?.scheduleNext(from: now)

        CareHandoff.perform(
            state: state, now: now, steps: readings.steps.count,
            notificationsEnabled: dependencies.notificationsEnabled, witnesses: dependencies.witnesses
        )
        return outcome
    }

    /// Applies `action` to `state`, returning `.refused` with the shared
    /// feeding reason when the pet cannot eat or is sated.
    private static func apply(_ action: PetAction, to state: inout PetState, now: Date) -> PetActionOutcome {
        switch action {
        case .tick:
            return .done
        case .feed(let food):
            if let reason = FeedRefusal.reason(for: state, food: food) {
                return .refused(reason: reason)
            }
            state = FeedAction.apply(to: state, food: food, at: now)
            return .done
        }
    }

    /// Evolves the pet when it has met its gate, announcing it when
    /// notifications are on; evolution otherwise runs only foregrounded, so
    /// this is what lets a pet grow while away.
    private static func evolveIfReady(_ state: PetState, now: Date, dependencies: Dependencies) -> PetState {
        guard let target = EvolutionEngine.checkEvolution(for: state) else { return state }
        let previous = state.species
        let evolved = EvolutionEngine.evolve(state, to: target, at: now)
        if dependencies.notificationsEnabled {
            dependencies.witnesses.notifications.notify(
                "Evolution!", "\(previous.displayName) evolved into \(target.displayName)!", target
            )
        }
        return evolved
    }
}
