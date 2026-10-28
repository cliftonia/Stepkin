import Foundation
import Testing
@testable import imon_Watch_App

@Suite("StepProgress")
struct StepProgressTests {

    /// A gregorian calendar pinned to UTC so day boundaries do not depend on the host time zone.
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    /// Noon UTC on a fixed day, so the six-hour same-day offset stays inside that day.
    private static let day1 = Date(timeIntervalSince1970: 1_699_963_200)
    private static var day2: Date { day1.addingTimeInterval(24 * 60 * 60) }
    private static var day3: Date { day1.addingTimeInterval(2 * 24 * 60 * 60) }
    private static var day4: Date { day1.addingTimeInterval(3 * 24 * 60 * 60) }
    private static var sameDayLater: Date { day1.addingTimeInterval(6 * 60 * 60) }

    /// A representative stage penalty so the lazy-day branch is observable.
    private static let penalty = 4_000

    private func advance(
        _ progress: StepProgress.Progress,
        todaySteps: Int,
        now: Date
    ) -> StepProgress.Progress {
        StepProgress.advance(
            progress, todaySteps: todaySteps, now: now,
            stagePenalty: Self.penalty, calendar: Self.calendar
        )
    }

    @Test func `first credit baselines today without crediting pre-hatch steps`() {
        // A pet hatched mid-day (or freshly reset) must not inherit the steps
        // already walked today - it only earns the delta from here on.
        let start = StepProgress.Progress(
            lifetime: 0, creditedToday: 0, trackedDay: nil, goalPenalty: 0
        )
        let result = advance(start, todaySteps: 3_000, now: Self.day1)
        #expect(result.lifetime == 0)
        #expect(result.creditedToday == 3_000)
        #expect(result.trackedDay == Self.day1)
        #expect(result.goalPenalty == 0)
    }

    @Test func `steps after the first credit accrue from the baseline`() {
        // Born at 3_000 steps today, later reaching 5_000 → only 2_000 credited.
        let start = StepProgress.Progress(
            lifetime: 0, creditedToday: 3_000, trackedDay: Self.day1, goalPenalty: 0
        )
        let result = advance(start, todaySteps: 5_000, now: Self.sameDayLater)
        #expect(result.lifetime == 2_000)
        #expect(result.creditedToday == 5_000)
    }

    @Test func `same day credits only the delta since last seen`() {
        let start = StepProgress.Progress(
            lifetime: 3_000, creditedToday: 3_000, trackedDay: Self.day1, goalPenalty: 0
        )
        let result = advance(start, todaySteps: 5_000, now: Self.sameDayLater)
        #expect(result.lifetime == 5_000)
        #expect(result.creditedToday == 5_000)
        #expect(result.trackedDay == Self.day1)
        #expect(result.goalPenalty == 0)
    }

    @Test func `a backward step count does not subtract from the lifetime`() {
        let start = StepProgress.Progress(
            lifetime: 5_000, creditedToday: 5_000, trackedDay: Self.day1, goalPenalty: 0
        )
        let result = advance(start, todaySteps: 4_000, now: Self.sameDayLater)
        #expect(result.lifetime == 5_000)
        #expect(result.creditedToday == 5_000)
    }

    @Test func `an active day rolls over with no penalty`() {
        let start = StepProgress.Progress(
            lifetime: 9_000, creditedToday: 9_000, trackedDay: Self.day1, goalPenalty: 0
        )
        let result = advance(start, todaySteps: 1_200, now: Self.day2)
        #expect(result.lifetime == 9_000 + 1_200)
        #expect(result.creditedToday == 1_200)
        #expect(result.trackedDay == Self.day2)
        #expect(result.goalPenalty == 0)
    }

    @Test func `a lazy day raises the goal without touching the lifetime`() {
        let start = StepProgress.Progress(
            lifetime: 9_000, creditedToday: 500, trackedDay: Self.day1, goalPenalty: 0
        )
        let result = advance(start, todaySteps: 100, now: Self.day2)
        #expect(result.lifetime == 9_000 + 100)        // lifetime only ever grows
        #expect(result.goalPenalty == Self.penalty)    // the goal moved instead
        #expect(result.creditedToday == 100)
        #expect(result.trackedDay == Self.day2)
    }

    @Test func `a multi-day lazy gap charges a single penalty`() {
        // Three days elapse since the last lazy day. The rollover collapses the
        // gap into one penalty (documented approximation), not one per day.
        let start = StepProgress.Progress(
            lifetime: 9_000, creditedToday: 500, trackedDay: Self.day1, goalPenalty: 0
        )
        let result = advance(start, todaySteps: 100, now: Self.day4)
        #expect(result.lifetime == 9_000 + 100)
        #expect(result.goalPenalty == Self.penalty)
        #expect(result.trackedDay == Self.day4)
    }

    @Test func `lazy penalties accumulate across lazy days`() {
        var progress = StepProgress.Progress(
            lifetime: 0, creditedToday: 0, trackedDay: Self.day1, goalPenalty: 0
        )
        progress = advance(progress, todaySteps: 100, now: Self.day2) // lazy
        progress = advance(progress, todaySteps: 100, now: Self.day3) // lazy again
        #expect(progress.goalPenalty == Self.penalty * 2)
    }
}
