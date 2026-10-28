import Testing
import Foundation
@testable import imon_Watch_App

@Suite("Care hand-off")
struct CareHandoffTests {

    /// Records what the hand-off wrote through its witnesses; the closures fire
    /// synchronously within `perform`, so a lock keeps the box `Sendable`.
    private final class Capture: @unchecked Sendable {
        private let lock = NSLock()
        private var scheduledPlans: [[CareNotification]] = []
        private var cancelCount = 0
        private var reloadCount = 0

        var scheduled: [[CareNotification]] { lock.withLock { scheduledPlans } }
        var cancels: Int { lock.withLock { cancelCount } }
        var reloads: Int { lock.withLock { reloadCount } }

        func recordSchedule(_ plan: [CareNotification]) { lock.withLock { scheduledPlans.append(plan) } }
        func recordCancel() { lock.withLock { cancelCount += 1 } }
        func recordReload() { lock.withLock { reloadCount += 1 } }
    }

    private func witnesses(_ capture: Capture) -> CareHandoff.Witnesses {
        CareHandoff.Witnesses(
            notifications: NotificationScheduler(
                schedule: { capture.recordSchedule($0) },
                notify: { _, _, _ in },
                cancelAll: { capture.recordCancel() },
                requestAuthorization: { true }
            ),
            complications: ComplicationReloader(reload: { capture.recordReload() })
        )
    }

    @Test func `enabled hand-off schedules the planner's plan and reloads once`() {
        let now = today(at: 9)
        let state = makeTestState(hunger: 2, strength: 2, at: now)
        let capture = Capture()

        CareHandoff.perform(
            state: state, now: now, steps: nil, notificationsEnabled: true, witnesses: witnesses(capture)
        )

        #expect(capture.scheduled == [CareNotificationPlanner.plan(for: state, now: now, steps: nil)])
        #expect(capture.cancels == 0)
        #expect(capture.reloads == 1)
    }

    @Test func `disabled hand-off cancels, schedules nothing and still reloads once`() {
        let now = today(at: 9)
        let capture = Capture()

        CareHandoff.perform(
            state: makeTestState(at: now), now: now, steps: nil, notificationsEnabled: false,
            witnesses: witnesses(capture)
        )

        #expect(capture.cancels == 1)
        #expect(capture.scheduled.isEmpty)
        #expect(capture.reloads == 1)
    }
}
