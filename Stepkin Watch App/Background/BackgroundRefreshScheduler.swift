import Foundation
import WatchKit
import os

/// Requests the next background wake-up, injected as a protocol witness so the
/// decision logic is testable even though the OS trigger is not.
nonisolated struct BackgroundRefreshScheduler: Sendable {
    /// Asks the system to wake the app near the given date (one pending at a time).
    let schedule: @Sendable (Date) -> Void
}

extension BackgroundRefreshScheduler {

    /// Re-arms the next wake one refresh interval from `now` — the single
    /// home for the re-arm date math. `nonisolated` so the background tick
    /// (itself nonisolated) can re-arm the chain.
    nonisolated func scheduleNext(from now: Date) {
        schedule(now.addingTimeInterval(TimeConstants.backgroundRefreshInterval))
    }

    /// Creates the witness backed by `WKApplication.scheduleBackgroundRefresh`.
    /// The `schedule` closure assumes the main actor, as its callers are.
    static func live() -> BackgroundRefreshScheduler {
        BackgroundRefreshScheduler(
            schedule: { date in
                // Callers are main-actor; a deferred Task races setTaskCompleted,
                // breaking the chain.
                MainActor.assumeIsolated {
                    WKApplication.shared().scheduleBackgroundRefresh(
                        withPreferredDate: date, userInfo: nil
                    ) { error in
                        if let error {
                            Log.background.error(
                                "Background refresh schedule failed: \(error.localizedDescription)"
                            )
                        }
                    }
                }
            }
        )
    }
}
