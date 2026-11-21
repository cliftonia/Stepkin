import Foundation
import Observation

/// Display state for the Stats screen. Values are pre-formatted for display
/// (strings default to placeholders such as "—"), so the view binds directly
/// with no formatting logic of its own.
@Observable
final class StatsViewModel {
    /// The pet's species name; the empty string is the no-data placeholder.
    var speciesName: String = ""
    /// The pet's evolution stage name; the empty string is the no-data placeholder.
    var stageName: String = ""
    /// The pet's age in whole days.
    var ageDays: Int = 0
    /// The pet's weight in whole grams.
    var weightGrams: Int = 0
    /// Filled hunger hearts, counted against `maxHunger`.
    var hungerHearts: Int = 0
    /// Total hunger hearts the gauge can show; `hungerHearts` is the filled count.
    var maxHunger: Int = 4
    /// Filled strength hearts, counted against `maxStrength`.
    var strengthHearts: Int = 0
    /// Total strength hearts the gauge can show; `strengthHearts` is the filled count.
    var maxStrength: Int = 4
    /// HP value, pre-formatted as a display string.
    var hpDisplay: String = "0"
    /// Power bonus, pre-formatted with its leading sign (e.g. "+0").
    var powerBonus: String = "+0"
    /// Battles the pet has won.
    var battleWins: Int = 0
    /// Battles the pet has lost.
    var battleLosses: Int = 0
    /// Win rate, pre-formatted; "—" is the no-data placeholder.
    var winRate: String = "—"
    /// Label for the current activity; "—" is the no-data placeholder.
    var activityLabel: String = "—"
    /// Progress toward evolution, pre-formatted; "—" is the no-data placeholder.
    var evolveProgress: String = "—"
    /// The battle gate line, e.g. "12 / 15 wins"; `nil` hides the row.
    var battleGate: String?
}
