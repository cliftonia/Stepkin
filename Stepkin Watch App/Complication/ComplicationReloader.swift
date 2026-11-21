import Foundation
import WidgetKit

/// Witness that asks WidgetKit to refresh the complication timeline, injected so
/// callers can be tested with a capturing mock. Reloading is a no-op when no
/// complication is installed.
nonisolated struct ComplicationReloader: Sendable {
    /// Asks WidgetKit to refresh the complication timeline.
    let reload: @Sendable () -> Void
}

extension ComplicationReloader {
    /// Creates the witness backed by `WidgetCenter`, reloading every timeline
    /// rather than a single complication's.
    static func live() -> ComplicationReloader {
        ComplicationReloader(reload: { WidgetCenter.shared.reloadAllTimelines() })
    }
}
