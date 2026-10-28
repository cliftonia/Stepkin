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
        reloader: ComplicationReloader = ComplicationReloader(reload: {}),
        cancelAll: @escaping @Sendable () -> Void = {}
    ) -> PetPresenter {
        makePetPresenter(
            state: state,
            scheduler: NotificationScheduler(
                schedule: { capture.scheduled = $0 },
                notify: { _, _, _ in },
                cancelAll: cancelAll,
                requestAuthorization: { true }
            ),
            reloader: reloader
        )
    }

    @Test
    func `scheduling feeds the planned reminders to the scheduler`() {
        let state = makeTestState(species: .emberkin, hunger: 2, at: .now)
        let capture = Capture()
        let presenter = makePresenter(state, capture)

        presenter.handleScenePhase(isActive: false, notificationsEnabled: true)

        #expect(capture.scheduled?.isEmpty == false)
    }

    @Test
    func `scheduling also refreshes the complication`() {
        let reloads = ReloadBox()
        let presenter = makePresenter(
            makeTestState(), Capture(),
            reloader: ComplicationReloader(reload: { reloads.count += 1 })
        )

        presenter.handleScenePhase(isActive: false, notificationsEnabled: true)

        #expect(reloads.count == 1)
    }

    @Test
    func `backgrounding with notifications off cancels reminders and still bakes the timeline`() {
        let cancels = ReloadBox()
        let reloads = ReloadBox()
        let presenter = makePresenter(
            makeTestState(), Capture(),
            reloader: ComplicationReloader(reload: { reloads.count += 1 }),
            cancelAll: { cancels.count += 1 }
        )

        presenter.handleScenePhase(isActive: false, notificationsEnabled: false)

        #expect(cancels.count == 1)
        #expect(reloads.count == 1)
    }

    private final class ReloadBox: @unchecked Sendable {
        var count = 0
    }
}
