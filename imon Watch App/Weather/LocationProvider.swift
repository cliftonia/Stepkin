import CoreLocation
import Foundation

/// One-shot current-location lookup, a witness standing in for CoreLocation
/// so it can be mocked.
nonisolated struct LocationProvider: Sendable {
    /// The one-shot lookup, throwing when no fix is available.
    let currentLocation: @Sendable () async throws -> CLLocation
}

nonisolated extension LocationProvider {

    /// Builds the witness backed by CoreLocation: its `currentLocation`
    /// requests authorization, then returns the first good fix, throwing
    /// `WeatherError.locationUnavailable` on denial or after ten seconds.
    static func live() -> LocationProvider {
        LocationProvider {
            await LocationAuthorizer.shared.requestIfNeeded()
            return try await firstFix(timeout: timeout)
        }
    }

    /// How long to wait for a fix before giving up.
    private static let timeout: Duration = .seconds(10)

    /// Returns the first good fix from a live updates session, throwing
    /// `WeatherError.locationUnavailable` on timeout or denial.
    private static func firstFix(timeout: Duration) async throws -> CLLocation {
        try await withThrowingTaskGroup(of: CLLocation?.self) { group in
            group.addTask {
                for try await update in CLLocationUpdate.liveUpdates() {
                    if update.authorizationDenied { return nil }
                    if let location = update.location { return location }
                }
                return nil
            }
            group.addTask {
                try? await Task.sleep(for: timeout)
                return nil
            }
            defer { group.cancelAll() }
            let result = (try await group.next()) ?? nil
            guard let location = result else {
                throw WeatherError.locationUnavailable
            }
            return location
        }
    }
}

/// Owns a long-lived `CLLocationManager` so the authorization prompt isn't
/// dismissed by the manager deallocating mid-request.
@MainActor
private final class LocationAuthorizer {
    /// The single instance all requests share; its long life keeps the authorization prompt alive.
    static let shared = LocationAuthorizer()
    private let manager = CLLocationManager()

    /// Requests when-in-use authorization only while the status is
    /// undetermined; repeat calls are no-ops.
    func requestIfNeeded() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }
}
