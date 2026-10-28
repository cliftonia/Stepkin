import Foundation

/// Hands the pet's care to the system for the time away: care reminders planned
/// or cancelled, the complication timeline baked and the face reloaded.
nonisolated enum CareHandoff {

    /// The two system witnesses the hand-off writes through.
    nonisolated struct Witnesses: Sendable {
        /// Plans or clears the pending care reminders.
        let notifications: NotificationScheduler
        /// Signals WidgetKit to refresh the complication.
        let complications: ComplicationReloader
    }

    /// Plans the reminders when `notificationsEnabled` (else clears any pending
    /// ones), then bakes a fresh complication timeline and reloads the face.
    /// The timeline is baked in both cases: backgrounding is its last chance.
    static func perform(
        state: PetState,
        now: Date,
        steps: Int?,
        notificationsEnabled: Bool,
        witnesses: Witnesses
    ) {
        if notificationsEnabled {
            let plan = CareNotificationPlanner.plan(for: state, now: now, steps: steps)
            witnesses.notifications.schedule(plan)
        } else {
            witnesses.notifications.cancelAll()
        }
        ComplicationStore.save(
            ComplicationTimeline.entries(for: state, from: now, spriteRows: ComplicationEntry.spriteRows(for:))
        )
        witnesses.complications.reload()
    }
}
