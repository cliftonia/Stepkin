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

    /// Counts complication reloads, running `onReload` at each so a test can
    /// look at the pet the hand-off saw.
    private final class ReloadCount: @unchecked Sendable {
        var count = 0
        var onReload: (() -> Void)?
    }

    /// Counts evolution announcements and records the species they named.
    private final class AnnounceCapture: @unchecked Sendable {
        var count = 0
        var species: PetSpecies?
    }

    private func makeStore(_ box: StoreBox) -> PetStateStore {
        PetStateStore(
            save: { box.state = $0; box.saveCount += 1 },
            load: { box.state },
            delete: { box.state = nil }
        )
    }

    /// An app presenter over `store` whose settings live in a suite of their
    /// own, so the host's real toggles never reach a test.
    private func makeApp(store: PetStateStore) throws -> AppPresenter {
        AppPresenter(
            store: store,
            weatherStore: WeatherStore(provider: WeatherProvider(fetchCurrent: { throw TestError() })),
            stepActivityStore: StepActivityStore(provider: StepCountProvider(fetchTodaySteps: { 0 })),
            settings: SettingsStore(defaults: try makeIsolatedDefaults("PetActionRouterTests")),
            permissions: PermissionRequester(requestAll: {})
        )
    }

    private func makeOffline(
        store: PetStateStore,
        refresh: RefreshCapture? = nil,
        reloads: ReloadCount = ReloadCount(),
        announce: AnnounceCapture = AnnounceCapture(),
        notificationsEnabled: Bool = false
    ) -> OfflineSession.Dependencies {
        OfflineSession.Dependencies(
            store: store,
            finalSteps: { _ in nil },
            witnesses: CareHandoff.Witnesses(
                notifications: NotificationScheduler(
                    schedule: { _ in },
                    notify: { _, _, species in announce.count += 1; announce.species = species },
                    cancelAll: {}, requestAuthorization: { true }
                ),
                complications: ComplicationReloader(reload: { reloads.count += 1; reloads.onReload?() })
            ),
            refresh: refresh.map { capture in BackgroundRefreshScheduler(schedule: { capture.date = $0 }) },
            notificationsEnabled: notificationsEnabled
        )
    }

    @Test
    func `with no live presenter the action runs offline against the save`() async throws {
        let offlineBox = StoreBox()
        offlineBox.state = makeTestState(species: .emberkin, hunger: 1)
        let app = try makeApp(store: makeStore(StoreBox()))

        let outcome = await PetActionRouter.perform(
            .feed(.meat), app: app, offline: makeOffline(store: makeStore(offlineBox)), now: .now
        )

        #expect(outcome == .done)
        #expect(offlineBox.saveCount == 1)
        #expect(offlineBox.state?.hungerHearts.value == 2)
    }

    @Test
    func `with a live presenter the action goes through it and the save is not written offline`() async throws {
        let appBox = StoreBox()
        appBox.state = makeTestState(species: .emberkin, hunger: 1)
        let app = try makeApp(store: makeStore(appBox))
        app.onAppear()
        await app.permissionTask?.value
        let savesBefore = appBox.saveCount
        let offlineBox = StoreBox()

        let outcome = await PetActionRouter.perform(
            .feed(.meat), app: app, offline: makeOffline(store: makeStore(offlineBox)), now: .now
        )

        // "Fed." is only true once the ceremony has applied the feed and saved.
        #expect(outcome == .done)
        #expect(appBox.saveCount == savesBefore + 1)
        #expect(appBox.state?.hungerHearts.value == 2)
        #expect(offlineBox.saveCount == 0)
        app.petPresenter?.stopGameLoop()
    }

    @Test
    func `a live tick saves through the presenter and still re-arms the next wake`() async throws {
        let appBox = StoreBox()
        appBox.state = makeTestState()
        let app = try makeApp(store: makeStore(appBox))
        app.onAppear()
        await app.permissionTask?.value
        let savesBefore = appBox.saveCount
        let offlineBox = StoreBox()
        let refresh = RefreshCapture()
        let reloads = ReloadCount()
        let now = Date.now

        let outcome = await PetActionRouter.perform(
            .tick, app: app, offline: makeOffline(store: makeStore(offlineBox), refresh: refresh, reloads: reloads), now: now
        )

        #expect(outcome == .done)
        // The live tick still hands care off: the complication is reloaded once.
        #expect(reloads.count == 1)
        #expect(appBox.saveCount == savesBefore + 1)
        #expect(offlineBox.saveCount == 0)
        #expect(refresh.date == now.addingTimeInterval(TimeConstants.backgroundRefreshInterval))
        app.petPresenter?.stopGameLoop()
    }

    @Test
    func `a live feed of a sated pet is refused with the shared reason`() async throws {
        let full = makeTestState(species: .emberkin, hunger: PetSpecies.emberkin.maxHunger)
        let appBox = StoreBox()
        appBox.state = full
        let app = try makeApp(store: makeStore(appBox))
        app.onAppear()
        await app.permissionTask?.value

        let outcome = await PetActionRouter.perform(
            .feed(.meat), app: app, offline: makeOffline(store: makeStore(StoreBox())), now: .now
        )

        #expect(outcome == .refused(reason: FeedRefusal.full))
        app.petPresenter?.stopGameLoop()
    }

    /// A presenter that appears while the session is mid-flight (the UI opened
    /// during a cold background wake) takes the action; the session never saves.
    @Test
    func `a presenter that appears mid-session takes the action and the session does not save`() async throws {
        let appBox = StoreBox()
        appBox.state = makeTestState(species: .emberkin, hunger: 1)
        let app = try makeApp(store: makeStore(appBox))
        let offlineBox = StoreBox()
        offlineBox.state = makeTestState(species: .emberkin, hunger: 1)
        let offlineStore = PetStateStore(
            save: { offlineBox.state = $0; offlineBox.saveCount += 1 },
            load: {
                // The UI comes up between the session's first check and its save.
                MainActor.assumeIsolated { app.onAppear() }
                return offlineBox.state
            },
            delete: {}
        )

        let outcome = await PetActionRouter.perform(.feed(.meat), app: app, offline: makeOffline(store: offlineStore), now: .now)

        #expect(outcome == .done)
        #expect(offlineBox.saveCount == 0)
        #expect(app.petPresenter != nil)
        #expect(app.petPresenter?.state.hungerHearts.value == 2)
        #expect(appBox.state?.hungerHearts.value == 2)
        await app.permissionTask?.value
        app.petPresenter?.stopGameLoop()
    }

    /// A tick that wakes a suspended app cannot play the flash nobody sees: the
    /// pet evolves at once, is announced once, and the hand-off bakes the
    /// evolved creature into the complication.
    @Test
    func `a live tick while the scene is inactive evolves at once, announces once and hands off the evolved pet`() async throws {
        let appBox = StoreBox()
        var ready = makeTestState(species: .dotkin)
        ready.lifetimeActiveSteps = EvolutionStage.fresh.stepsToEvolve
        appBox.state = ready
        let app = try makeApp(store: makeStore(appBox))
        app.onAppear()
        await app.permissionTask?.value
        app.petPresenter?.isSceneActive = false
        let announce = AnnounceCapture()
        let handedOff = AnnounceCapture()
        let reloads = ReloadCount()
        reloads.onReload = { MainActor.assumeIsolated { handedOff.species = app.petPresenter?.state.species } }
        let offline = makeOffline(store: makeStore(StoreBox()), reloads: reloads, announce: announce, notificationsEnabled: true)

        let outcome = await PetActionRouter.perform(.tick, app: app, offline: offline, now: .now)

        #expect(outcome == .done)
        #expect(announce.count == 1)
        #expect(announce.species == .hopkin)
        #expect(handedOff.species == .hopkin)
        #expect(appBox.state?.species == .hopkin)
        #expect(app.petPresenter?.viewModel.activity == .idle)
        app.petPresenter?.stopGameLoop()
    }
}
