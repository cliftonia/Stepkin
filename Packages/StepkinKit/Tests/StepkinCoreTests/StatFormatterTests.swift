import Testing
import Foundation
@testable import StepkinCore

@Suite("StatFormatter")
struct StatFormatterTests {

    @Test(arguments: [
        (part: 0, whole: 0, expected: String?.none),   // no battles -> nil
        (part: 1, whole: -1, expected: String?.none),  // negative whole guard
        (part: 1, whole: 3, expected: "33%"),          // rounds down
        (part: 2, whole: 3, expected: "67%"),          // rounds up
        (part: 1, whole: 200, expected: "1%"),         // .5 rounds away from zero
        (part: 5, whole: 3, expected: "100%"),         // clamps above 100
        (part: -1, whole: 3, expected: "0%"),          // clamps below 0
        (part: Int.max, whole: 1, expected: "100%"),   // extreme ratio must not trap
        (part: Int.min, whole: 1, expected: "0%"),     // extreme negative must not trap
    ])
    func `percent guards, rounds and clamps`(
        part: Int, whole: Int, expected: String?
    ) {
        #expect(StatFormatter.percent(part, of: whole) == expected)
    }

    @Test
    func `grouped keeps every digit regardless of locale separators`() {
        let formatted = StatFormatter.grouped(12_340)
        #expect(formatted.filter(\.isNumber) == "12340")
    }
}
