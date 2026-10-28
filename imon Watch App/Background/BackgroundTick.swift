import Foundation
import os

/// Runs one background tick: advances the saved pet to `now`, persists it,
/// re-arms the next wake-up, and re-evaluates care reminders and complications.
/// Self-contained: reads and writes `PetStateStore` directly, so a bare
/// background launch runs it. `steps` is today's HealthKit total, or `nil` when
/// the Steps toggle is off or the read failed — activity scaling is skipped.
nonisolated enum BackgroundTick {

    // swiftlint:disable function_parameter_count
    /// Performs the whole tick end to end; a load failure still re-arms the next
    /// wake-up so the refresh chain survives, while a missing pet is a no-op.
    /// No defaulted witnesses — a new call site must decide notifications
    /// explicitly.
    static func perform(
        store: PetStateStore,
        notifications: NotificationScheduler,
        refresh: BackgroundRefreshScheduler,
        complications: ComplicationReloader,
        notificationsEnabled: Bool,
        steps: Int?,
        now: Date = .now
    ) {
        // swiftlint:enable function_parameter_count
        // A load failure re-arms and bails (keep the chain); a missing pet is a true no-op.
        let loaded: PetState?
        do {
            loaded = try store.load()
        } catch {
            Log.background.error("Background load failed: \(error, privacy: .public)")
            refresh.scheduleNext(from: now)
            return
        }
        guard let state = loaded else { return }

        var advanced = GameEngine.advance(state, to: now, isNight: nil, steps: steps, calendar: .current)

        // Evolution otherwise runs only foregrounded — evaluate so pets grow while away.
        if let target = EvolutionEngine.checkEvolution(for: advanced) {
            let previous = advanced.species
            advanced = EvolutionEngine.evolve(advanced, to: target, at: now)
            if notificationsEnabled {
                notifications.notify(
                    "Evolution!", "\(previous.displayName) evolved into \(target.displayName)!", target
                )
            }
        }

        store.save(advanced, loggingTo: Log.background)

        // Re-arm before the task completes — the chain survives if work below is cut short.
        refresh.scheduleNext(from: now)

        // The foreground path also hands off through `CareHandoff`, sharing the toggle handling.
        CareHandoff.perform(
            state: advanced, now: now, steps: steps, notificationsEnabled: notificationsEnabled,
            witnesses: CareHandoff.Witnesses(notifications: notifications, complications: complications)
        )
    }
}
