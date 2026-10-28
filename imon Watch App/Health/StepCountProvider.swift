import Foundation
import HealthKit

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
