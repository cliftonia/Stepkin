import Testing
import Foundation
@testable import imon_Watch_App

@Suite("App lifecycle resolution")
@MainActor
struct AppPresenterTests {

    private struct TestError: Error {}

    /// Captures every store interaction the presenter makes.
    private final class StoreBox: @unchecked Sendable {
        var saved: [PetState] = []
        var deleteCount = 0
    }

    /// Counts permission rounds so the tests can pin down when they happen.
    private final class PermissionBox: @unchecked Sendable {
        var requests = 0
    }

    private func makePresenter(
        load: @escaping @Sendable () throws -> PetState?,
        box: StoreBox,
        deleteFails: Bool = false,
        permissions: PermissionBox = PermissionBox()
    ) throws -> AppPresenter {
        try AppPresenter(
            store: PetStateStore(
                save: { box.saved.append($0) },
                load: load,
                delete: {
                    box.deleteCount += 1
                    if deleteFails { throw TestError() }
                }
            ),
            weatherStore: WeatherStore(
                provider: WeatherProvider(fetchCurrent: { throw TestError() })
            ),
            stepActivityStore: StepActivityStore(
                provider: StepCountProvider(fetchTodaySteps: { 0 })
            ),
            // A suite of its own, so the host's real toggles never reach a test.
            settings: SettingsStore(defaults: makeIsolatedDefaults("AppPresenterTests")),
            permissions: PermissionRequester(requestAll: { permissions.requests += 1 })
        )
    }

    // MARK: - Load-or-Start-New Resolution

    @Test
    func `a first launch with no saved pet starts hatching`() throws {
        let presenter = try makePresenter(load: { nil }, box: StoreBox())

        presenter.onAppear()

        #expect(presenter.phase == .hatching)
        #expect(presenter.hatchPresenter != nil)
        #expect(presenter.petPresenter == nil)
    }

    @Test
    func `a saved egg re-hatches instead of simulating`() throws {
        let box = StoreBox()
        var egg = PetState.hatched(at: .now)
        egg.isEgg = true
        let presenter = try makePresenter(load: { [egg] in egg }, box: box)

        presenter.onAppear()

        #expect(presenter.phase == .hatching)
        #expect(box.saved.isEmpty)
    }

    @Test
    func `a living pet is caught up, persisted and shown`() throws {
        let hourAgo = Date.now.addingTimeInterval(-3600)
        let saved = makeTestState(at: hourAgo)
        let box = StoreBox()
        let presenter = try makePresenter(load: { saved }, box: box)

        presenter.onAppear()

        #expect(presenter.phase == .alive)
        #expect(presenter.petPresenter != nil)
        // The persisted state must be the advanced one, not the raw save.
        let persisted = try #require(box.saved.first)
        #expect(persisted.timestamps.lastAdvancedAt > saved.timestamps.lastAdvancedAt)
    }

    @Test
    func `a pet that died while away shows the grave immediately`() throws {
        var state = makeTestState()
        state.injuryCount = TimeConstants.maxInjuriesBeforeDeath
        let fatal = state
        let box = StoreBox()
        let presenter = try makePresenter(load: { fatal }, box: box)

        presenter.onAppear()

        #expect(presenter.phase == .dead)
        #expect(presenter.deathPresenter != nil)
        #expect(presenter.petPresenter == nil)
        #expect(box.saved.last?.isDead == true)
    }

    @Test
    func `a corrupted save falls back to a fresh hatch`() throws {
        let presenter = try makePresenter(load: { throw TestError() }, box: StoreBox())

        presenter.onAppear()

        #expect(presenter.phase == .hatching)
        #expect(presenter.hatchPresenter != nil)
    }

    // MARK: - Permissions

    @Test
    func `permissions are not requested while the egg is still hatching`() async throws {
        let permissions = PermissionBox()
        let presenter = try makePresenter(load: { nil }, box: StoreBox(), permissions: permissions)

        presenter.onAppear()
        await presenter.permissionTask?.value

        #expect(presenter.phase == .hatching)
        #expect(permissions.requests == 0)
    }

    @Test
    func `permissions are requested once the pet is alive`() async throws {
        let permissions = PermissionBox()
        let saved = makeTestState()
        let presenter = try makePresenter(load: { saved }, box: StoreBox(), permissions: permissions)

        presenter.onAppear()
        await presenter.permissionTask?.value

        #expect(presenter.phase == .alive)
        #expect(permissions.requests == 1)
    }

    // MARK: - Restart After Death

    @Test(arguments: [false, true])
    func `restarting after death deletes the save and hatches anew`(deleteFails: Bool) throws {
        var state = makeTestState()
        state.isDead = true
        let dead = state
        let box = StoreBox()
        let presenter = try makePresenter(load: { dead }, box: box, deleteFails: deleteFails)
        presenter.onAppear()
        #expect(presenter.phase == .dead)

        presenter.deathPresenter?.restartAction()

        #expect(box.deleteCount == 1)
        #expect(presenter.phase == .hatching)
        #expect(presenter.hatchPresenter != nil)
    }

    // MARK: - Step Reading

    /// The three readings the engine can be handed: `.off` while the switch is
    /// off (whatever the store holds), `.count` once the store has today's
    /// figure, and `.unavailable` while it has none.
    @Test(arguments: [
        (false, true, StepReading.off),
        (true, true, StepReading.count(4_200)),
        (true, false, StepReading.unavailable)
    ])
    func `the step reading follows the switch and the store`(
        stepsEnabled: Bool, refreshed: Bool, expected: StepReading
    ) async throws {
        let settings = SettingsStore(defaults: try makeIsolatedDefaults("AppPresenterTests.steps"))
        settings.stepsEnabled = stepsEnabled
        let steps = StepActivityStore(provider: StepCountProvider(fetchTodaySteps: { 4_200 }))
        let presenter = AppPresenter(
            store: PetStateStore(save: { _ in }, load: { nil }, delete: {}),
            weatherStore: WeatherStore(provider: WeatherProvider(fetchCurrent: { throw TestError() })),
            stepActivityStore: steps,
            settings: settings,
            permissions: PermissionRequester(requestAll: {})
        )
        if refreshed {
            await steps.refresh()
        }

        #expect(presenter.currentStepReading() == expected)
    }
}
