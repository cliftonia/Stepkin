import Foundation

/// The player's light switch. Turning it off at night starts the settle
/// countdown that `SleepSchedule` turns into sleep; turning it on wakes the
/// pet immediately. Day toggles are refused — daylight forces the light on.
public enum LightsAction {

    /// The outcome of a toggle attempt: `.toggled` when the light flipped,
    /// `.blocked` when `canToggle` refused. A blocked attempt returns the
    /// state unchanged.
    public enum ToggleResult: Sendable {
        case toggled
        case blocked
    }

    // MARK: - Query

    /// Reports whether the light can be toggled: night only, and never while
    /// the pet is dead or still an egg.
    static func canToggle(_ state: PetState, night: Bool) -> Bool {
        !state.isDead && !state.isEgg && night
    }

    // MARK: - Apply

    /// Flips the light, waking the pet when it comes on and anchoring the
    /// settle countdown when it goes out. A refused attempt returns the
    /// state unchanged with `.blocked`.
    @discardableResult
    public static func apply(
        to state: PetState,
        night: Bool,
        at now: Date
    ) -> (state: PetState, result: ToggleResult) {
        guard canToggle(state, night: night) else {
            return (state, .blocked)
        }

        var state = state
        state.lightsOn.toggle()
        if state.lightsOn {
            state.wake(at: now)
        } else {
            // Settle countdown anchor; the pet stays awake until
            // `SleepSchedule` turns it into sleep.
            state.timestamps.lightsOffAt = now
        }
        return (state, .toggled)
    }
}
