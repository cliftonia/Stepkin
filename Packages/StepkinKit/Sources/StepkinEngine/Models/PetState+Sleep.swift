import Foundation

extension PetState {

    /// Wakes the pet, making the sleep it just had a true pause. The waking
    /// simulators (hunger, strength, poop) skip sleeping ticks without moving
    /// their anchors, so without re-anchoring here the first awake tick would
    /// charge the whole night in one go — a pet starved, weak and injured at
    /// every dawn. The time credit's anchor moves too, so a night slept with
    /// Steps off is never paid as waking time. Any partial interval carried
    /// into sleep is forgiven.
    mutating func wake(at now: Date) {
        if isSleeping {
            timestamps.lastHungerDecayAt = now
            timestamps.lastStrengthDecayAt = now
            timestamps.lastPoopAt = now
            timestamps.lastTimeCreditAt = now
        }
        isSleeping = false
        timestamps.lightsOffAt = nil
    }
}
