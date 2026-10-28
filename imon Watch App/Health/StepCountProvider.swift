import Foundation
import HealthKit
import os

/// Fetches step totals, injected as a protocol witness so everything built on
/// steps can be tested without HealthKit. Days are anchored to local midnight —
/// a count never carries across days.
nonisolated struct StepCountProvider: Sendable {
    /// Today's step total from local midnight to now, read as a running count.
    let fetchTodaySteps: @Sendable () async throws -> Int

    /// The total for the calendar day containing the given date. Lets a day
    /// that ended while the app was closed still be credited in full, since
    /// HealthKit kept counting when nothing was watching.
    let fetchStepsForDay: @Sendable (Date) async throws -> Int

    /// `fetchStepsForDay` defaults to today's total so existing call sites and
    /// tests that only care about "now" need not supply it.
    init(
        fetchTodaySteps: @escaping @Sendable () async throws -> Int,
        fetchStepsForDay: (@Sendable (Date) async throws -> Int)? = nil
    ) {
        self.fetchTodaySteps = fetchTodaySteps
        self.fetchStepsForDay = fetchStepsForDay ?? { _ in try await fetchTodaySteps() }
    }
}

extension StepCountProvider {
    /// Builds the HealthKit-backed witness; both closures share one `HKHealthStore`.
    static func live() -> StepCountProvider {
        let store = HKHealthStore()
        return StepCountProvider(
            fetchTodaySteps: { try await totalSteps(inDayContaining: .now, from: store) },
            fetchStepsForDay: { try await totalSteps(inDayContaining: $0, from: store) }
        )
    }

    /// Sums the calendar day containing `date`, stopping at the day's close or
    /// now — whichever comes first — so today reads as a running total and a
    /// past day reads as its settled final.
    private static func totalSteps(
        inDayContaining date: Date,
        from store: HKHealthStore
    ) async throws -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        let end = min(dayEnd, .now)
        guard end > start else { return 0 }

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )
        // .cumulativeSum already dedupes watch + iPhone sources — no source filter.
        let samplePredicate = HKSamplePredicate.quantitySample(
            type: HKQuantityType(.stepCount),
            predicate: predicate
        )
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: samplePredicate,
            options: .cumulativeSum
        )
        let result = try await descriptor.result(for: store)
        return Int(result?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
    }

    /// Requests read access to step count. Safe to call at every launch;
    /// HealthKit only prompts once. No-op if HealthKit is unavailable.
    static func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let store = HKHealthStore()
        try? await store.requestAuthorization(
            toShare: [],
            read: [HKQuantityType(.stepCount)]
        )
    }
}

extension StepCountProvider {
    /// The store that owns the observer query for the app's lifetime.
    private static let backgroundStore = HKHealthStore()
    /// The running observer query, retained for the app's lifetime; non-nil
    /// also means delivery has started. Guarded by one lock so a second call
    /// cannot start another.
    private static let observerQuery = OSAllocatedUnfairLock<HKObserverQuery?>(initialState: nil)

    /// Carries HealthKit's completion handler into a `Task`. The SDK handler
    /// type is not marked Sendable, but HealthKit allows it to be called from
    /// any queue, so wrapping it once here is safe.
    private nonisolated struct CompletionBox: @unchecked Sendable {
        /// The handler to call once the update has been processed.
        let call: () -> Void
    }

    /// Asks HealthKit to wake the app in the background, at most hourly, when
    /// new step samples arrive, and runs `onUpdate` for each wake. Needs the
    /// background-delivery entitlement; the simulator cannot exercise it.
    /// Idempotent: a second call does nothing. The caller starts it at launch
    /// when Steps is on, so switching Steps on takes effect at the next launch.
    static func startBackgroundDelivery(onUpdate: @escaping @Sendable () async -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let stepType = HKQuantityType(.stepCount)
        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { _, completionHandler, error in
            if let error {
                Log.health.error("Step observer failed: \(error, privacy: .public)")
            }
            // The completion must always run, or HealthKit stops delivering after three misses.
            let box = CompletionBox(call: completionHandler)
            Task {
                await onUpdate()
                box.call()
            }
        }
        let isFirstStart = observerQuery.withLock { held -> Bool in
            guard held == nil else { return false }
            held = query
            return true
        }
        guard isFirstStart else { return }
        backgroundStore.execute(query)
        backgroundStore.enableBackgroundDelivery(for: stepType, frequency: .hourly) { success, error in
            if let error {
                Log.health.error("Background delivery failed: \(error, privacy: .public)")
            } else {
                Log.health.info("Background delivery enabled: \(success, privacy: .public)")
            }
        }
    }
}
