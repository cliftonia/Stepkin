import Foundation

/// Asks for the system permissions the game loop needs (HealthKit steps and
/// care reminders), injected as a closure witness so the app presenter can be
/// tested without touching either framework. Asked once the pet is alive —
/// after the walkthrough has explained what steps and reminders are for —
/// rather than on the first frame of a fresh install. Each framework only
/// prompts once, so calling this on every alive start is harmless.
nonisolated struct PermissionRequester: Sendable {
    /// The prompt for both authorizations: HealthKit steps and care reminders.
    let requestAll: @Sendable () async -> Void
}

nonisolated extension PermissionRequester {

    /// Creates the live witness backed by the real frameworks: HealthKit
    /// authorization through `StepCountProvider` and reminder authorization
    /// through `NotificationScheduler`, whose granted-or-denied answer is
    /// discarded.
    static func live() -> PermissionRequester {
        PermissionRequester {
            await StepCountProvider.requestAuthorization()
            _ = await NotificationScheduler.live().requestAuthorization()
        }
    }
}
