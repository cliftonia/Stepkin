import Foundation

/// The verdict of a battle: win, lose, or draw.
///
/// A payload-free, `Sendable` value type, so a result crosses isolation
/// boundaries unchanged.
public enum BattleResult: Sendable {
    case win
    case lose
    case draw
}
