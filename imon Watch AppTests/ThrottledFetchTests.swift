import Testing
import Foundation
@testable import imon_Watch_App

@MainActor
@Suite("ThrottledFetch")
struct ThrottledFetchTests {

    private static let base = Date(timeIntervalSinceReferenceDate: 0)

    @Test
    func `an in-flight fetch dedups until it lands, then the slot reopens`() async {
        let fetch = ThrottledFetch()
        let (gate, release) = AsyncStream.makeStream(of: Void.self)
        let neverFresh: (Date) -> Bool = { _ in false }

        // First call spawns and suspends on the gate.
        let first = fetch.startIfStale(now: Self.base, isFresh: neverFresh) {
            for await _ in gate { }
        }
        #expect(first != nil)

        // While the first is still airborne, a second call must not spawn —
        // this is the sole guard against double-hitting WeatherKit/HealthKit.
        let second = fetch.startIfStale(now: Self.base, isFresh: neverFresh) { }
        #expect(second == nil)

        // Land the first flight; the task slot must clear so a stale check
        // can spawn again.
        release.finish()
        await first?.value

        let third = fetch.startIfStale(now: Self.base, isFresh: neverFresh) { }
        #expect(third != nil)
        await third?.value
    }

    @Test
    func `a failed attempt stamps lastFetch but never lastSuccess`() {
        let fetch = ThrottledFetch()
        let attempt = Self.base.addingTimeInterval(100)

        fetch.record(now: attempt, success: false)
        #expect(fetch.lastFetch == attempt)
        #expect(fetch.lastSuccess == nil)
    }

    @Test
    func `a successful attempt refreshes both lastFetch and lastSuccess`() {
        let fetch = ThrottledFetch()
        let failure = Self.base.addingTimeInterval(100)
        let success = Self.base.addingTimeInterval(200)

        fetch.record(now: failure, success: false)
        fetch.record(now: success, success: true)
        #expect(fetch.lastFetch == success)
        #expect(fetch.lastSuccess == success)
    }

    @Test
    func `perform records a success`() async {
        let fetch = ThrottledFetch()
        let attempt = Self.base.addingTimeInterval(100)
        var ran = false

        await fetch.perform(now: attempt, { ran = true }, onFailure: { _ in Issue.record("unexpected failure") })
        #expect(ran)
        #expect(fetch.lastFetch == attempt)
        #expect(fetch.lastSuccess == attempt)
    }

    @Test
    func `perform records a failure and reports the error`() async {
        struct Boom: Error, Equatable {}
        let fetch = ThrottledFetch()
        let attempt = Self.base.addingTimeInterval(100)
        var reported: (any Error)?

        await fetch.perform(now: attempt, { throw Boom() }, onFailure: { reported = $0 })
        #expect(reported as? Boom == Boom())
        #expect(fetch.lastFetch == attempt)
        #expect(fetch.lastSuccess == nil)
    }
}
