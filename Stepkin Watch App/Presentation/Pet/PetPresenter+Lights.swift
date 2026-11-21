import Foundation

// MARK: - Lights

extension PetPresenter {

    /// Toggles the lights via `LightsAction`; by day the light is forced on
    /// and the action is refused like any other blocked action. A successful
    /// toggle saves the state and starts the settle countdown toward sleep.
    func lightsAction() {
        let (newState, result) = LightsAction.apply(
            to: state, night: currentlyNight, at: .now
        )
        guard result == .toggled else {
            // By day the light is forced on — refuse like every other blocked action.
            refuse()
            return
        }
        state = newState
        updateViewModel()
        updateAnimation()
        save()
        scheduleSleepSettle()
    }

    /// Re-runs `environmentDidChange` once the settle delay passes, so the
    /// pet falls asleep without waiting for the next tick. Calling again
    /// cancels the pending run. Does nothing while the light is on or the
    /// pet is already asleep.
    private func scheduleSleepSettle() {
        sleepSettle.cancel()
        guard state.timestamps.lightsOffAt != nil, !state.isSleeping else { return }
        sleepSettle.schedule(after: .seconds(TimeConstants.sleepDelay)) { [weak self] in
            self?.environmentDidChange()
        }
    }
}
