import Testing
@testable import Stepkin_Watch_App

@MainActor
@Suite("PowerSaverStore")
struct PowerSaverStoreTests {

    /// A flippable Sendable source for the injected low-power check.
    private final class Flag: @unchecked Sendable {
        var on = false
    }

    @Test
    func `reflects the provider on init`() {
        let flag = Flag()
        flag.on = true
        let store = PowerSaverStore(isLowPowerEnabled: { flag.on })
        #expect(store.isActive)
    }

    @Test
    func `refresh re-reads the system power state`() {
        let flag = Flag()
        let store = PowerSaverStore(isLowPowerEnabled: { flag.on })
        #expect(store.isActive == false)

        flag.on = true
        store.refresh()
        #expect(store.isActive)
    }
}
