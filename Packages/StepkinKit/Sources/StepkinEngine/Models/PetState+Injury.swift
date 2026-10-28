import Foundation

/// The injury invariant: flag, timestamp, and lifetime count must move
/// together — `DeathEvaluator` reads all three for the death/heal economy.
/// Every production injury routes through `injure(at:)` so a new trigger
/// cannot silently forget one of the fields.
extension PetState {

    /// Marks the pet injured, stamping the injury time and bumping the
    /// lifetime count. No-op when already injured.
    mutating func injure(at now: Date) {
        guard !isInjured else { return }
        isInjured = true
        timestamps.injuredAt = now
        injuryCount += 1
    }

    /// The inverse of `injure(at:)` — clears the flag and timestamp while
    /// leaving the lifetime `injuryCount` intact.
    public mutating func heal() {
        isInjured = false
        timestamps.injuredAt = nil
    }
}
