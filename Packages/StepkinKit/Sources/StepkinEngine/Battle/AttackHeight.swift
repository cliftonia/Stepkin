import Foundation

/// The three heights an attack strikes at: high, medium, or low. The
/// matchups form a rock-paper-scissors cycle — each height beats exactly one
/// other and is beaten by exactly one — so a closed enum keeps that cycle in
/// `prey` instead of a lookup table that could drift out of sync.
public enum AttackHeight: CaseIterable, Sendable {
    case high, medium, low

    /// The height this one beats — high over medium, medium over low, low
    /// over high. The switch is exhaustive with no `default:` (banned), so
    /// adding a case fails to compile here instead of falling through.
    var prey: AttackHeight {
        switch self {
        case .high: .medium
        case .medium: .low
        case .low: .high
        }
    }

    /// Returns whether `other` is this height's `prey`; equal heights draw,
    /// since each height beats only its single prey in the cycle.
    func beats(_ other: AttackHeight) -> Bool {
        prey == other
    }
}
