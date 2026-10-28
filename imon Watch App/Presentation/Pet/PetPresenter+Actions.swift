import Foundation

// MARK: - External Actions

/// The presenter's share of the one-writer rule: actions routed in from
/// outside the home screen, and adopting a save written while it was away.
extension PetPresenter {

    /// Performs an action routed by `PetActionRouter` while this presenter is
    /// the save's writer. A tick runs one game-loop tick; a feed refuses with
    /// the shared `FeedRefusal` reason when the pet is busy, cannot eat or is sated,
    /// else runs the same feeding ceremony the home screen's menu does and
    /// returns once it has finished, so `.done` means the feed was applied and
    /// saved. A ceremony cancelled before it fed (the screen went away) is
    /// reported as busy; awaiting it cannot hang, since cancellation ends it.
    func perform(_ action: PetAction) async -> PetActionOutcome {
        switch action {
        case .tick:
            tick()
            return .done
        case .feed(let food):
            // A running ceremony is never cancelled by a routed feed.
            if viewModel.isBusy { return .refused(reason: FeedRefusal.busy) }
            if let reason = FeedRefusal.reason(for: state, food: food) {
                return .refused(reason: reason)
            }
            viewModel.selectedFood = food
            var fed = false
            startActivity { fed = await $0.runFeedingSequence() }
            await activityTask?.value
            return fed ? .done : .refused(reason: FeedRefusal.busy)
        }
    }

    /// Evolves the pet at once, without the flash, when its gate is met and it
    /// is idle: the path a wake takes while the scene is not active, where a
    /// strobe would play to nobody. Announces through `notifications` when
    /// `enabled`, as the offline session does, then saves.
    func evolveUnseen(now: Date, notifications: NotificationScheduler, enabled: Bool) {
        guard !viewModel.isBusy else { return }
        let evolved = EvolutionAnnouncer.evolveIfReady(state, now: now, notifications: notifications, enabled: enabled)
        guard evolved.species != state.species else { return }
        state = evolved
        updateViewModel()
        updateAnimation()
        save()
    }

    /// Replaces the in-memory pet with the save when the save has advanced
    /// further: something wrote it while this presenter was suspended, so it
    /// is the single truth. An older or equal save is this presenter's own.
    func adoptNewerSave() {
        guard let saved = try? store.load(),
              saved.timestamps.lastAdvancedAt > state.timestamps.lastAdvancedAt
        else { return }
        state = saved
        updateViewModel()
    }
}
