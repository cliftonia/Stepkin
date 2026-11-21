import Foundation
import Testing
@testable import Stepkin_Watch_App

@MainActor
@Suite("WeatherStore")
struct WeatherStoreTests {

    @Test
    func `refresh populates snapshot from provider`() async {
        let store = WeatherStore(provider: .mock(.sample))
        #expect(store.snapshot == nil)
        await store.refresh()
        #expect(store.snapshot == .sample)
    }

    @Test
    func `failing provider leaves snapshot nil`() async {
        let store = WeatherStore(provider: .mockFailing())
        await store.refresh()
        #expect(store.snapshot == nil)
    }

    @Test
    func `a failed fetch still applies the cache window`() async {
        // Otherwise a missing authorization spins a fetch on every wrist raise.
        let store = WeatherStore(provider: .mockFailing())
        let base = Date(timeIntervalSinceReferenceDate: 0)

        await store.refreshIfStale(now: base)?.value   // fails, but stamps lastFetch
        let skipped = store.refreshIfStale(
            now: base.addingTimeInterval(TimeConstants.weatherCacheInterval - 1)
        )
        #expect(skipped == nil)
    }

    @Test
    func `refreshIfStale skips within the cache window`() async {
        let counter = Counter()
        let store = WeatherStore(provider: .counting(counter))
        let base = Date(timeIntervalSinceReferenceDate: 0)

        await store.refreshIfStale(now: base)?.value
        #expect(counter.count == 1)

        let window = TimeConstants.weatherCacheInterval - 1
        let skipped = store.refreshIfStale(now: base.addingTimeInterval(window))
        #expect(skipped == nil)
        #expect(counter.count == 1)
    }

    @Test
    func `refreshIfStale refetches after the cache window`() async {
        let counter = Counter()
        let store = WeatherStore(provider: .counting(counter))
        let base = Date(timeIntervalSinceReferenceDate: 0)

        await store.refreshIfStale(now: base)?.value
        let beyond = TimeConstants.weatherCacheInterval + 1
        await store.refreshIfStale(now: base.addingTimeInterval(beyond))?.value
        #expect(counter.count == 2)
    }
}

private final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    func increment() {
        lock.lock(); defer { lock.unlock() }
        value += 1
    }

    var count: Int {
        lock.lock(); defer { lock.unlock() }
        return value
    }
}

private extension WeatherProvider {
    static func counting(_ counter: Counter) -> WeatherProvider {
        WeatherProvider {
            counter.increment()
            return .sample
        }
    }
}
