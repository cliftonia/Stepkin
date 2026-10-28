import Foundation

/// Single-flight, cache-windowed fetch bookkeeping composed by the reading
/// stores (weather, steps). Tracks attempts (`lastFetch`, which throttles
/// retries) separately from successes (`lastSuccess`, which dates the
/// reading) so a failed fetch never refreshes a reading's age.
@MainActor
public final class ThrottledFetch {

    /// The last attempt's time, consulted by `isFresh` to throttle retries; nil until the first
    /// attempt.
    public private(set) var lastFetch: Date?
    /// The last success's time, dating the reading's age; nil until the first success.
    public private(set) var lastSuccess: Date?
    private var task: Task<Void, Never>?

    /// Creates bookkeeping with no attempt recorded.
    public init() {}

    /// Spawns `run` unless one is already in flight or the last attempt is
    /// still fresh by `isFresh`; `run` is expected to `record` its outcome.
    /// Returns the spawned task (nil if skipped).
    @discardableResult
    public func startIfStale(
        now: Date,
        isFresh: (Date) -> Bool,
        run: @escaping () async -> Void
    ) -> Task<Void, Never>? {
        guard task == nil else { return nil }
        if let lastFetch, isFresh(lastFetch) { return nil }
        let spawned = Task { [weak self] in
            await run()
            self?.task = nil
        }
        task = spawned
        return spawned
    }

    /// Runs `fetch` and records the outcome at `now`: a success refreshes the
    /// reading's age; a throw is passed to `onFailure` and still counts as an
    /// attempt, without refreshing the age.
    public func perform(
        now: Date,
        _ fetch: () async throws -> Void,
        onFailure: (any Error) -> Void
    ) async {
        do {
            try await fetch()
            record(now: now, success: true)
        } catch {
            onFailure(error)
            record(now: now, success: false)
        }
    }

    /// Notes an attempt at `now`; successes also refresh the reading's age.
    public func record(now: Date, success: Bool) {
        lastFetch = now
        if success { lastSuccess = now }
    }
}
