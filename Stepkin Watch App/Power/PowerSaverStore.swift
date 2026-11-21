import Foundation
import Observation

/// Store holding the system Low Power Mode reading so the UI can switch to the
/// red battery-saver palette. The low-power check is injected (witness style) so
/// it can be mocked in tests.
@MainActor
@Observable
final class PowerSaverStore {

    /// The sampled Low Power Mode reading; true puts the UI in the red battery-saver palette.
    private(set) var isActive: Bool
    private let isLowPowerEnabled: @Sendable () -> Bool

    /// Creates the store with an injected low-power check, sampling it once so
    /// `isActive` starts at the current system value.
    init(isLowPowerEnabled: @escaping @Sendable () -> Bool) {
        self.isLowPowerEnabled = isLowPowerEnabled
        self.isActive = isLowPowerEnabled()
    }

    /// Re-reads the system Low Power Mode state. This is the only way `isActive`
    /// updates after init, so callers invoke it when the system value changes.
    func refresh() {
        isActive = isLowPowerEnabled()
    }
}

extension PowerSaverStore {
    /// Returns the store backed by the real system check,
    /// `ProcessInfo.isLowPowerModeEnabled`, rather than a test mock.
    static func live() -> PowerSaverStore {
        PowerSaverStore(
            isLowPowerEnabled: { ProcessInfo.processInfo.isLowPowerModeEnabled }
        )
    }
}
