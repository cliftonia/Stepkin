import Foundation

// MARK: - External Actions

/// The presenter's share of the one-writer rule: actions routed in from
/// outside the home screen, and adopting a save written while it was away.
extension PetPresenter {

    /// Performs an action routed by `PetActionRouter` while this presenter is
    /// the save's writer. A tick runs one game-loop tick; a feed refuses with
    /// the shared `FeedRefusal` reason when the pet cannot eat or is sated,
    /// else starts the same feeding ceremony the home screen's menu does.
    func perform(_ action: PetAction) -> PetActionOutcome {
        switch action {
        case .tick:
            tick()
            return .done
        case .feed(let food):
            if let reason = FeedRefusal.reason(for: state, food: food) {
                return .refused(reason: reason)
            }
            viewModel.selectedFood = food
            startActivity { await $0.runFeedingSequence() }
            return .done
        }
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
