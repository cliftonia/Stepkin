import Testing
import Foundation
@testable import imon_Watch_App

@Suite("ComplicationStore")
struct ComplicationStoreTests {

    @Test
    func `round-trips the timeline through the shared store`() throws {
        let defaults = try makeIsolatedDefaults("ComplicationStoreTests")
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let entries = ComplicationTimeline.entries(
            for: makeTestState(species: .emberkin, at: now), from: now, count: 4, stride: 1_800
        )

        ComplicationStore.save(entries, to: defaults)
        let loaded = ComplicationStore.load(from: defaults)

        #expect(loaded == entries)
    }

    @Test
    func `an empty store loads no entries`() throws {
        let defaults = try makeIsolatedDefaults("ComplicationStoreTests")
        #expect(ComplicationStore.load(from: defaults).isEmpty)
    }
}
