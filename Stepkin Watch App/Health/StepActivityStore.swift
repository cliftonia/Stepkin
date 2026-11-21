import Foundation
import os

/// Holds today's step count and refreshes it on demand, throttled to the cache
/// window. Leaves `todaySteps` nil when unavailable, so the engine falls back to
/// baseline (activity-neutral) rates. Mirrors `WeatherStore`.
@Observable
final class StepActivityStore {

    /// Today's step reading, or nil if the last successful fetch belongs to an
    /// earlier calendar day. A count cached before midnight must never be served
    /// as the new day's — the engine's rollover would credit yesterday's
    /// whole total again and poison the new day's baseline and lazy-day check.
    var todaySteps: Int? {
        guard let lastSuccess = throttle.lastSuccess,
              lastSuccess.isSameDay(as: .now)
        else { return nil }
        return fetchedSteps
    }

    private var fetchedSteps: Int?
    private let provider: StepCountProvider
    private let throttle = ThrottledFetch()

    /// Creates the store, reading step counts through the given provider.
    init(provider: StepCountProvider = .live()) {
        self.provider = provider
    }

    /// Starts a refresh unless one is in flight or still within the cache
    /// window. Returns the spawned task (nil if skipped).
    @discardableResult
    func refreshIfStale(now: Date = .now) -> Task<Void, Never>? {
        // The cache never spans midnight — the new day starts from a real reading.
        throttle.startIfStale(
            now: now,
            isFresh: {
                now.timeIntervalSince($0) < TimeConstants.stepCacheInterval
                    && $0.isSameDay(as: now)
            },
            run: { [weak self] in
                await self?.refresh(now: now)
            }
        )
    }

    /// The settled total for a past day, used to credit a day that ended while
    /// the app was closed. Deliberately bypasses the cache — it asks about a
    /// named day rather than the current one — and reports nil rather than
    /// throwing, since a missing tail must not block rollover.
    func finalSteps(for day: Date) async -> Int? {
        try? await provider.fetchStepsForDay(day)
    }

    /// Fetches and stores today's steps, leaving the existing value on failure.
    /// Failures still count toward the cache window, but never refresh the
    /// reading's age.
    func refresh(now: Date = .now) async {
        await throttle.perform(
            now: now,
            { fetchedSteps = try await provider.fetchTodaySteps() },
            onFailure: { Log.health.error("Step fetch failed: \($0, privacy: .public)") }
        )
    }
}
