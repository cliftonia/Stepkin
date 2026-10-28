import Foundation
import UserNotifications

/// Side-effecting wrapper around the user-notification centre, injected as
/// a closure-based witness so presenters are testable without UserNotifications.
nonisolated struct NotificationScheduler: Sendable {
    /// Replaces every pending care reminder with the supplied set.
    let schedule: @Sendable ([CareNotification]) -> Void
    /// Fires a one-off notification immediately (e.g. an evolution announcement).
    let notify: @Sendable (_ title: String, _ body: String, _ species: PetSpecies) -> Void
    /// Removes every pending care reminder.
    let cancelAll: @Sendable () -> Void
    /// Requests permission for alerts and sounds; false on denial or failure.
    let requestAuthorization: @Sendable () async -> Bool
}

nonisolated extension NotificationScheduler {

    /// Builds a reminder's content, attaching the species sprite for the `night`
    /// state at `fireDate` — the moment it appears, not when it is scheduled.
    /// Resolved without a weather reading; shared by scheduled and one-off sends.
    private static func makeContent(
        title: String, body: String, species: PetSpecies, fireDate: Date
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let isNight = SleepSchedule.isNight(weatherNight: nil, at: fireDate)
        if let sprite = NotificationSpriteRenderer.attachment(for: species, isNight: isNight) {
            content.attachments = [sprite]
        }
        return content
    }

    /// Creates the witness backed by `UNUserNotificationCenter`; scheduled
    /// delays are measured from the moment each batch is scheduled.
    static func live() -> NotificationScheduler {
        NotificationScheduler(
            schedule: { notifications in
                let center = UNUserNotificationCenter.current()
                center.removeAllPendingNotificationRequests()
                for notification in notifications {
                    let content = makeContent(
                        title: notification.title, body: notification.body,
                        species: notification.species, fireDate: notification.fireDate
                    )
                    // Floor of one second so a past fire date cannot yield a
                    // non-positive interval.
                    let interval = max(1, notification.fireDate.timeIntervalSince(Date()))
                    let trigger = UNTimeIntervalNotificationTrigger(
                        timeInterval: interval, repeats: false
                    )
                    let request = UNNotificationRequest(
                        identifier: notification.id, content: content, trigger: trigger
                    )
                    center.add(request)
                }
            },
            notify: { title, body, species in
                let content = makeContent(title: title, body: body, species: species, fireDate: Date())
                let request = UNNotificationRequest(
                    identifier: "event-\(title)", content: content, trigger: nil
                )
                UNUserNotificationCenter.current().add(request)
            },
            cancelAll: {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            },
            requestAuthorization: {
                do {
                    return try await UNUserNotificationCenter.current()
                        .requestAuthorization(options: [.alert, .sound])
                } catch {
                    return false
                }
            }
        )
    }

}
