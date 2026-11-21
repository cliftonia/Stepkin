import Foundation
import Testing
@testable import Stepkin_Watch_App

@MainActor
@Suite("StepActivityStore")
struct StepActivityStoreTests {

    @Test
    func `refresh populates steps from provider`() async {
        let store = StepActivityStore(provider: .mock(steps: 5_000))
        #expect(store.todaySteps == nil)
        await store.refresh()
        #expect(store.todaySteps == 5_000)
    }

    @Test
    func `failing provider leaves steps nil`() async {
        let store = StepActivityStore(
            provider: StepCountProvider(fetchTodaySteps: { throw CancellationError() })
        )
        await store.refresh()
        #expect(store.todaySteps == nil)
    }

    @Test
    func `refreshIfStale skips within the cache window`() async {
        let counter = StepCounter()
        let store = StepActivityStore(provider: .counting(counter))
        let base = Date(timeIntervalSinceReferenceDate: 0)

        await store.refreshIfStale(now: base)?.value
        #expect(counter.count == 1)

        let window = TimeConstants.stepCacheInterval - 1
        let skipped = store.refreshIfStale(now: base.addingTimeInterval(window))
        #expect(skipped == nil)
        #expect(counter.count == 1)
    }

    @Test
    func `refreshIfStale refetches after the cache window`() async {
        let counter = StepCounter()
        let store = StepActivityStore(provider: .counting(counter))
        let base = Date(timeIntervalSinceReferenceDate: 0)

        await store.refreshIfStale(now: base)?.value
        let beyond = TimeConstants.stepCacheInterval + 1
        await store.refreshIfStale(now: base.addingTimeInterval(beyond))?.value
        #expect(counter.count == 2)
    }
}

private final class StepCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0
    func increment() { lock.lock(); defer { lock.unlock() }; value += 1 }
    var count: Int { lock.lock(); defer { lock.unlock() }; return value }
}

private extension StepCountProvider {
    static func counting(_ counter: StepCounter) -> StepCountProvider {
        StepCountProvider(fetchTodaySteps: {
            counter.increment()
            return 1_000
        })
    }
}
