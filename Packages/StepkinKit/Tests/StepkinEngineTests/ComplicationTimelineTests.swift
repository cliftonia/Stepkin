import Testing
import Foundation
import StepkinCore
@testable import StepkinEngine
import StepkinTestSupport

@Suite("ComplicationTimeline")
struct ComplicationTimelineTests {

    /// A fixed daytime hour so projected states stay awake (and deplete).
    private func today(at hour: Int) -> Date {
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        return calendar.date(byAdding: .hour, value: hour, to: midnight) ?? midnight
    }

    /// Sixteen empty rows, standing in for the app's sprite lookup.
    private func blankRows(_ state: PetState) -> [UInt16] {
        [UInt16](repeating: 0, count: 16)
    }

    @Test
    func `entries are spaced by the stride`() {
        let now = today(at: 9)
        let entries = ComplicationTimeline.entries(
            for: makeTestState(at: now), from: now, count: 4, stride: 1_800, spriteRows: blankRows
        )
        #expect(entries.count == 4)
        #expect(entries[1].date == now.addingTimeInterval(1_800))
        #expect(entries[3].date == now.addingTimeInterval(3 * 1_800))
    }

    @Test
    func `hunger drains across the timeline`() throws {
        let now = today(at: 8)
        let state = makeTestState(species: .emberkin, hunger: 4, at: now)
        let entries = ComplicationTimeline.entries(
            for: state, from: now, count: 8, stride: 1_800, spriteRows: blankRows
        )
        let first = try #require(entries.first)
        let last = try #require(entries.last)
        #expect(last.hungerValue < first.hungerValue)
    }

    @Test
    func `needs attention once hunger runs out`() throws {
        let now = today(at: 7)
        let state = makeTestState(species: .emberkin, hunger: 4, strength: 4, at: now)
        let entries = ComplicationTimeline.entries(
            for: state, from: now, count: 12, stride: 1_800, spriteRows: blankRows
        )
        let last = try #require(entries.last)
        #expect(last.needsAttention)
    }

    @Test
    func `a dead pet yields a single static entry`() {
        let now = today(at: 9)
        var state = makeTestState(at: now)
        state.isDead = true
        let entries = ComplicationTimeline.entries(
            for: state, from: now, count: 8, stride: 1_800, spriteRows: blankRows
        )
        #expect(entries.count == 1)
        #expect(entries.first?.date == now)
    }

    @Test
    func `each entry bakes the rows the sprite closure supplies`() {
        let now = today(at: 9)
        let rows: [UInt16] = [0xFFFF, 0x0001]
        let entries = ComplicationTimeline.entries(
            for: makeTestState(at: now), from: now, count: 3, stride: 1_800, spriteRows: { _ in rows }
        )
        #expect(entries.allSatisfy { $0.spriteRows == rows })
    }
}
