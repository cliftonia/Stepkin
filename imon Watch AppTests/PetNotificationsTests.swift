import Testing
import Foundation
@testable import imon_Watch_App

@Suite("Care notifications wiring")
@MainActor
struct PetNotificationsTests {

    /// Synchronous capture box — the scheduler closures fire on the main actor
    /// within the call, so plain reference storage is safe.
    private final class Capture: @unchecked Sendable {
        var scheduled: [CareNotification]?
    }

    private func makePresenter(
        _ state: PetState,
        _ capture: Capture,
        reloader: ComplicationReloader = ComplicationReloader(reload: {})
    ) -> PetPresenter {
        makePetPresenter(
            state: state,
            scheduler: NotificationScheduler(
                schedule: { capture.scheduled = $0 },
                notify: { _, _, _ in },
                cancelAll: {},
                requestAuthorization: { true }
            ),
            reloader: reloader
        )
    }

    @Test
    func `scheduling feeds the planned reminders to the scheduler`() {
        let now = today(at: 8)
        let state = makeTestState(species: .emberkin, hunger: 2, at: now)
        let capture = Capture()
        let presenter = makePresenter(state, capture)

        presenter.scheduleCareNotifications(now: now)

        let expected = CareNotificationPlanner.plan(for: state, now: now, steps: nil)
        #expect(capture.scheduled == expected)
        #expect(expected.isEmpty == false)
    }

    @Test
    func `scheduling also refreshes the complication`() {
        let reloads = ReloadBox()
        let presenter = makePresenter(
            makeTestState(), Capture(),
            reloader: ComplicationReloader(reload: { reloads.count += 1 })
        )

        presenter.scheduleCareNotifications(now: .now)

        #expect(reloads.count == 1)
    }

    private final class ReloadBox: @unchecked Sendable {
        var count = 0
    }
}
