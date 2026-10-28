import Foundation

/// The battle requirement standing between a species and every one of its next forms.
public struct BattleGate: Equatable, Sendable {

    /// The fewest battle wins that unlock the nearest gated form.
    public let minWins: Int
    /// The minimum win rate, a 0–1 fraction, or `nil` when the row sets none.
    public let minWinRate: Double?

    /// Creates a gate from its win count and optional win rate.
    public init(minWins: Int, minWinRate: Double?) {
        self.minWins = minWins
        self.minWinRate = minWinRate
    }
}
