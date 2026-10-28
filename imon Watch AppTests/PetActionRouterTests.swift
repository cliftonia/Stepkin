import Testing
import Foundation
@testable import imon_Watch_App

@Suite("PetActionRouter")
@MainActor
struct PetActionRouterTests {

    private struct TestError: Error {}

    /// A fake save the app presenter or the offline session reads and writes.
    private final class StoreBox: @unchecked Sendable {
        var state: PetState?
        var saveCount = 0
    }

    private final class RefreshCapture: @unchecked Sendable {
        var date: Date?
    }

    private func makeStore(_ box: StoreBox) -> PetStateStore {
        PetStateStore(
            save: { box.state = $0; box.saveCount += 1 },
            load: { box.state },
            delete: { box.state = nil }
        )
    }

    private func makeApp(store: PetStateStore) -> AppPresenter {
        AppPresenter(
            store: store,
            weatherStore: WeatherStore(provider: WeatherProvider(fetchCurrent: { throw TestError() })),
            stepActivityStore: StepActivityStore(provider: StepCountProvider(fetchTodaySteps: { 0 })),
            permissions: PermissionRequester(requestAll: {})
        )
    }

    private func makeOffline(store: PetStateStore, refresh: RefreshCapture? = nil) -> OfflineSession.Dependencies {
        OfflineSession.Dependencies(
            store: store,
            finalSteps: { _ in nil },
            witnesses: CareHandoff.Witnesses(
                notifications: NotificationScheduler(
                    schedule: { _ in }, notify: { _, _, _ in }, cancelAll: {}, requestAuthorization: { true }
                ),
                complications: ComplicationReloader(reload: {})
            ),
            refresh: refresh.map { capture in BackgroundRefreshScheduler(schedule: { capture.date = $0 }) },
            notificationsEnabled: false
        )
    }

    @Test
    func `with no live presenter the action runs offline against the save`() async {
        let offlineBox = StoreBox()
        offlineBox.state = makeTestState(species: .emberkin, hunger: 1)
        let app = makeApp(store: makeStore(StoreBox()))

        let outcome = await PetActionRouter.perform(
            .feed(.meat), app: app, offline: makeOffline(store: makeStore(offlineBox)), now: .now
        )

        #expect(outcome == .done)
        #expect(offlineBox.saveCount == 1)
        #expect(offlineBox.state?.hungerHearts.value == 2)
    }

    @Test
    func `with a live presenter the action goes through it and the save is not written offline`() async {
        let appBox = StoreBox()
        appBox.state = makeTestState(species: .emberkin, hunger: 1)
        let app = makeApp(store: makeStore(appBox))
        app.onAppear()
        await app.permissionTask?.value
        let offlineBox = StoreBox()

        let outcome = await PetActionRouter.perform(
            .feed(.meat), app: app, offline: makeOffline(store: makeStore(offlineBox)), now: .now
        )

        #expect(outcome == .done)
        #expect(offlineBox.saveCount == 0)
        #expect(await waitUntil { app.petPresenter?.viewModel.activity == .feeding(.serving) })
        app.petPresenter?.stopGameLoop()
    }

    @Test
    func `a live tick saves through the presenter and still re-arms the next wake`() async {
        let appBox = StoreBox()
        appBox.state = makeTestState()
        let app = makeApp(store: makeStore(appBox))
        app.onAppear()
        await app.permissionTask?.value
        let savesBefore = appBox.saveCount
        let offlineBox = StoreBox()
        let refresh = RefreshCapture()
        let now = Date.now

        let outcome = await PetActionRouter.perform(
            .tick, app: app, offline: makeOffline(store: makeStore(offlineBox), refresh: refresh), now: now
        )

        #expect(outcome == .done)
        #expect(appBox.saveCount == savesBefore + 1)
        #expect(offlineBox.saveCount == 0)
        #expect(refresh.date == now.addingTimeInterval(TimeConstants.backgroundRefreshInterval))
        app.petPresenter?.stopGameLoop()
    }

    @Test
    func `a live feed of a sated pet is refused with the shared reason`() async {
        let full = makeTestState(species: .emberkin, hunger: PetSpecies.emberkin.maxHunger)
        let appBox = StoreBox()
        appBox.state = full
        let app = makeApp(store: makeStore(appBox))
        app.onAppear()
        await app.permissionTask?.value

        let outcome = await PetActionRouter.perform(
            .feed(.meat), app: app, offline: makeOffline(store: makeStore(StoreBox())), now: .now
        )

        #expect(outcome == .refused(reason: FeedRefusal.full))
        app.petPresenter?.stopGameLoop()
    }
}
