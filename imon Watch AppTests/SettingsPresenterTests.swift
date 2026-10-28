import Foundation
import Testing
import WatchKit
@testable import imon_Watch_App

@Suite("SettingsPresenter") @MainActor struct SettingsPresenterTests {
    /// Builds a presenter over a store backed by throwaway defaults, returning the defaults for reads.
    private func makeTestSubject() throws -> (presenter: SettingsPresenter, defaults: UserDefaults) {
        let defaults = try makeIsolatedDefaults("SettingsPresenterTests")
        let store = SettingsStore(defaults: defaults)
        #if DEBUG
        let debug = SettingsDebugActions(
            setWeather: { _ in }, forceEvolve: {}, careTest: {}, killPet: {}, morph: { _ in }
        )
        return (SettingsPresenter(settings: store, debug: debug), defaults)
        #else
        return (SettingsPresenter(settings: store), defaults)
        #endif
    }

    @Test func `each toggle writes its own persisted flag`() throws {
        let previousHaptics = WKInterfaceDevice.hapticsEnabled
        defer { WKInterfaceDevice.hapticsEnabled = previousHaptics }
        let (presenter, defaults) = try makeTestSubject()

        presenter.settings.batterySaverEnabled = true
        presenter.settings.notificationsEnabled = false
        presenter.settings.weatherEnabled = false
        presenter.settings.stepsEnabled = false
        presenter.settings.hapticsEnabled = false

        #expect(defaults.bool(forKey: "settings.batterySaver"))
        #expect(defaults.object(forKey: "settings.notifications") as? Bool == false)
        #expect(defaults.object(forKey: "settings.weather") as? Bool == false)
        #expect(defaults.object(forKey: "settings.steps") as? Bool == false)
        #expect(defaults.object(forKey: "settings.haptics") as? Bool == false)
    }

    @Test func `toggling haptics flips the device master switch`() throws {
        let previousHaptics = WKInterfaceDevice.hapticsEnabled
        defer { WKInterfaceDevice.hapticsEnabled = previousHaptics }
        let (presenter, _) = try makeTestSubject()

        presenter.settings.hapticsEnabled = false
        #expect(!WKInterfaceDevice.hapticsEnabled)
        presenter.settings.hapticsEnabled = true
        #expect(WKInterfaceDevice.hapticsEnabled)
    }

    @Test func `the version label is not empty`() throws {
        let (presenter, _) = try makeTestSubject()
        #expect(!presenter.versionLabel.isEmpty)
    }
}
