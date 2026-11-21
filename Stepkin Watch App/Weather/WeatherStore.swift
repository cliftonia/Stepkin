import Foundation
import os

/// The store for the current weather reading: refreshes on demand, throttled
/// to the cache window. The reading stays nil when weather is unavailable so
/// the UI can hide the overlay.
@Observable
final class WeatherStore {

    /// The latest fetched reading; nil until a fetch succeeds, unchanged when one fails.
    private(set) var snapshot: WeatherSnapshot?

    private let provider: WeatherProvider
    private let fallback: WeatherSnapshot?
    private let throttle = ThrottledFetch()

    /// The snapshot the UI renders. Falls back to the injected `fallback` when
    /// no live reading exists; in DEBUG a set `debugCondition` forces the
    /// condition onto the current reading, or onto `.sample` when there is none.
    var displaySnapshot: WeatherSnapshot? {
        #if DEBUG
        if let debugCondition {
            let base = snapshot ?? .sample
            return WeatherSnapshot(
                temperature: base.temperature,
                condition: debugCondition,
                isDaylight: base.isDaylight,
                humidity: base.humidity
            )
        }
        #endif
        return snapshot ?? fallback
    }

    #if DEBUG
    /// Preview override for cycling through weather effects on-device.
    private(set) var debugCondition: WeatherIconCondition?

    /// Forces a specific condition, or nil to return to the real weather.
    func setDebugCondition(_ condition: WeatherIconCondition?) {
        debugCondition = condition
    }

    /// Advances the preview: real → clear → cloudy → … → fog → wind → real.
    func cycleDebugCondition() {
        let all = WeatherIconCondition.allCases
        switch debugCondition {
        case .none:
            debugCondition = all.first
        case .some(let current):
            let next = (all.firstIndex(of: current) ?? -1) + 1
            debugCondition = next < all.count ? all[next] : nil
        }
    }
    #endif

    /// Creates the store. `fallback` is shown only when no real reading exists
    /// yet; left nil in Release so the overlay simply hides.
    init(provider: WeatherProvider = .live(), fallback: WeatherSnapshot? = nil) {
        self.provider = provider
        self.fallback = fallback
    }

    /// Derives night from the reading's daylight flag, but only while the reading
    /// is still fresh. A stale reading (e.g. last night's, on reopening the next
    /// day) returns nil so day/night falls back to the clock instead of showing
    /// the old night until a fetch completes.
    func nightSignal(now: Date = .now) -> Bool? {
        guard let snapshot, let lastSuccess = throttle.lastSuccess,
              now.timeIntervalSince(lastSuccess) < TimeConstants.weatherCacheInterval
        else {
            return nil
        }
        return !snapshot.isDaylight
    }

    /// Starts a refresh unless one is in flight or the last fetch is still
    /// within the cache window. The returned task is nil when the refresh is
    /// skipped.
    @discardableResult
    func refreshIfStale(now: Date = .now) -> Task<Void, Never>? {
        throttle.startIfStale(
            now: now,
            isFresh: { now.timeIntervalSince($0) < TimeConstants.weatherCacheInterval },
            run: { [weak self] in
                await self?.refresh(now: now)
            }
        )
    }

    /// Fetches and stores a snapshot, leaving the existing value on failure.
    /// Failures still count toward the cache window (so a missing
    /// authorization doesn't spin a fetch on every wrist raise) but never
    /// refresh the reading's age — the surviving snapshot keeps its true age.
    func refresh(now: Date = .now) async {
        await throttle.perform(
            now: now,
            { snapshot = try await provider.fetchCurrent() },
            onFailure: { Log.weather.error("Weather fetch failed: \($0, privacy: .public)") }
        )
    }

    /// Creates the live store with a DEBUG-only placeholder so the overlay is
    /// visible before the WeatherKit capability is provisioned. Release shows
    /// real data only.
    static func makeDefault() -> WeatherStore {
        #if DEBUG
        return WeatherStore(provider: .live(), fallback: .sample)
        #else
        return WeatherStore(provider: .live())
        #endif
    }

}
