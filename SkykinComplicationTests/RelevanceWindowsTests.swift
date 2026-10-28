import Testing
import Foundation

@Suite("RelevanceWindows")
struct RelevanceWindowsTests {

    private static let start = Date(timeIntervalSince1970: 1_700_000_000)
    private static let hour: TimeInterval = 3_600

    @Test
    func `an empty timeline has no windows`() {
        #expect(RelevanceWindows.windows(in: []).isEmpty)
    }

    @Test
    func `a single calling entry is relevant for one hour`() {
        let windows = RelevanceWindows.windows(in: [makeEntry(hours: 0, calling: true)])
        #expect(windows == [interval(from: 0, to: 1)])
    }

    @Test
    func `a run in the middle ends at the next entry`() {
        let entries = [
            makeEntry(hours: 0, calling: false),
            makeEntry(hours: 1, calling: true),
            makeEntry(hours: 2, calling: true),
            makeEntry(hours: 3, calling: false)
        ]
        #expect(RelevanceWindows.windows(in: entries) == [interval(from: 1, to: 3)])
    }

    @Test
    func `a run at the end ends one hour after its last entry`() {
        let entries = [
            makeEntry(hours: 0, calling: false),
            makeEntry(hours: 1, calling: true),
            makeEntry(hours: 2, calling: true)
        ]
        #expect(RelevanceWindows.windows(in: entries) == [interval(from: 1, to: 3)])
    }

    @Test
    func `two runs give two windows`() {
        let entries = [
            makeEntry(hours: 0, calling: true),
            makeEntry(hours: 1, calling: false),
            makeEntry(hours: 2, calling: true),
            makeEntry(hours: 3, calling: false)
        ]
        #expect(RelevanceWindows.windows(in: entries) == [interval(from: 0, to: 1), interval(from: 2, to: 3)])
    }

    @Test
    func `a dead pet or an egg is never relevant`() {
        let entries = [
            makeEntry(hours: 0, calling: true, isDead: true),
            makeEntry(hours: 1, calling: true, isEgg: true)
        ]
        #expect(RelevanceWindows.windows(in: entries).isEmpty)
    }

    @Test
    func `unsorted input gives the same windows as sorted input`() {
        let sorted = [
            makeEntry(hours: 0, calling: true),
            makeEntry(hours: 1, calling: false),
            makeEntry(hours: 2, calling: true),
            makeEntry(hours: 3, calling: true)
        ]
        let shuffled = [sorted[2], sorted[0], sorted[3], sorted[1]]
        #expect(RelevanceWindows.windows(in: shuffled) == RelevanceWindows.windows(in: sorted))
        #expect(RelevanceWindows.windows(in: shuffled) == [interval(from: 0, to: 1), interval(from: 2, to: 4)])
    }

    // Builds an entry the given number of hours after the fixed start; only the flags matter here.
    private func makeEntry(hours: Double, calling: Bool, isDead: Bool? = nil, isEgg: Bool? = nil) -> WidgetEntry {
        WidgetEntry(
            date: Self.start.addingTimeInterval(hours * Self.hour),
            speciesName: "Dotkin",
            spriteRows: [],
            hungerValue: 2,
            hungerMax: 4,
            needsAttention: calling,
            statusText: calling ? "hungry" : "happy",
            isInjured: nil,
            isDead: isDead,
            isEgg: isEgg
        )
    }

    // The interval between two whole-hour offsets from the fixed start.
    private func interval(from startHours: Double, to endHours: Double) -> DateInterval {
        DateInterval(
            start: Self.start.addingTimeInterval(startHours * Self.hour),
            end: Self.start.addingTimeInterval(endHours * Self.hour)
        )
    }
}
