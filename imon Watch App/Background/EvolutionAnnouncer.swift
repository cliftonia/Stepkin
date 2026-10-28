import Foundation

/// Evolves a pet that has met its gate and announces it, shared by the
/// offline session and a live presenter woken while its scene is inactive,
/// so both grow the pet and word the "Evolution!" notification identically.
nonisolated enum EvolutionAnnouncer {

    /// Returns `state` evolved at `now` when it has met its gate, else
    /// unchanged; a real evolution is announced through `notifications` when
    /// `enabled`.
    static func evolveIfReady(
        _ state: PetState,
        now: Date,
        notifications: NotificationScheduler,
        enabled: Bool
    ) -> PetState {
        guard let target = EvolutionEngine.checkEvolution(for: state) else { return state }
        let previous = state.species
        let evolved = EvolutionEngine.evolve(state, to: target, at: now)
        if enabled {
            notifications.notify(
                CareNotificationText.evolutionTitle,
                CareNotificationText.evolutionBody(from: previous.displayName, to: target.displayName),
                target
            )
        }
        return evolved
    }
}
