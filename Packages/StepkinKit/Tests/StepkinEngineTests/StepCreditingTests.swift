import Foundation
import Testing
@testable import StepkinEngine
import StepkinTestSupport

@Suite("StepCrediting")
struct StepCreditingTests {

    /// A gregorian calendar pinned to UTC so day boundaries do not depend on the host time zone.
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    /// Noon UTC on a fixed day, the "now" every case settles at.
    private static let now = Date(timeIntervalSince1970: 1_699_963_200)
    private static var yesterday: Date { now.addingTimeInterval(-24 * 60 * 60) }

    /// Records each day a final total was asked for, in order.
    private final class FetchLog: @unchecked Sendable {
        var days: [Date] = []
    }

    /// A pet whose step accumulator last tracked `day` with `credited` steps.
    private func makeState(trackedDay: Date?, credited: Int, lifetime: Int = 0) -> PetState {
        var state = makeTestState(at: Self.yesterday)
        state.stepTrackedDay = trackedDay
        state.stepsCreditedToday = credited
        state.lifetimeActiveSteps = lifetime
        return state
    }

    private func settle(
        _ state: PetState,
        todaySteps: Int?,
        log: FetchLog = FetchLog(),
        finalSteps: @escaping (Date) -> Int? = { _ in nil }
    ) async -> PetState {
        await StepCrediting.settle(
            state, todaySteps: todaySteps, now: Self.now,
            finalSteps: { day in
                log.days.append(day)
                return finalSteps(day)
            },
            calendar: Self.calendar
        )
    }

    /// A day that ends while the app is closed must still credit the steps
    /// taken after its last reading: HealthKit kept counting, the app did not.
    @Test func `a day that ended while closed credits its uncounted tail`() async {
        let state = makeState(trackedDay: Self.yesterday, credited: 1_500, lifetime: 1_500)

        let settled = await settle(state, todaySteps: 200) { _ in 3_000 }

        // 1,500 already credited + the 1,500 tail recovered + today's 200.
        #expect(settled.lifetimeActiveSteps == 3_200)
        #expect(settled.stepsCreditedToday == 200)
        #expect(settled.stepTrackedDay == Self.now)
    }

    /// The recovered tail must also decide the lazy-day penalty: a day that
    /// finished above the threshold was never lazy, whatever the app last saw.
    @Test func `a recovered day above the lazy threshold escapes the penalty`() async {
        let state = makeState(trackedDay: Self.yesterday, credited: 500)

        let settled = await settle(state, todaySteps: 10) { _ in 9_000 }

        #expect(settled.evolutionGoalPenalty == 0)
    }

    /// A lazy day whose final total stays under the threshold is still charged.
    @Test func `a recovered day under the lazy threshold is penalised`() async {
        let state = makeState(trackedDay: Self.yesterday, credited: 500)

        let settled = await settle(state, todaySteps: 10) { _ in 900 }

        #expect(settled.evolutionGoalPenalty == state.species.stage.lazyDayPenalty)
    }

    /// A missing tail must delay the rollover, never stall it.
    @Test func `an unavailable tail still rolls the day over`() async {
        let state = makeState(trackedDay: Self.yesterday, credited: 4_000)

        let settled = await settle(state, todaySteps: 120)

        #expect(settled.stepsCreditedToday == 120)
        #expect(settled.stepTrackedDay == Self.now)
        #expect(settled.evolutionGoalPenalty == 0)
    }

    /// A long absence settles at most `maxCatchUpDays` days, oldest first, and
    /// never asks for today.
    @Test func `a long absence fetches at most seven days, oldest first`() async {
        let tracked = Self.now.addingTimeInterval(-20 * 24 * 60 * 60)
        let log = FetchLog()

        _ = await settle(makeState(trackedDay: tracked, credited: 0), todaySteps: 0, log: log)

        #expect(log.days.count == StepCrediting.maxCatchUpDays)
        #expect(log.days.first == tracked)
        #expect(log.days == log.days.sorted())
        #expect(log.days.allSatisfy { !Self.calendar.isDate($0, inSameDayAs: Self.now) })
    }

    /// Two missed days each get their own verdict and credit.
    @Test func `each missed day is replayed with its own total`() async {
        let tracked = Self.now.addingTimeInterval(-2 * 24 * 60 * 60)
        let state = makeState(trackedDay: tracked, credited: 1_000, lifetime: 1_000)

        let settled = await settle(state, todaySteps: 50) { day in
            Self.calendar.isDate(day, inSameDayAs: tracked) ? 3_000 : 800
        }

        // 1,000 + a 2,000 tail + 800 for the lazy middle day + 50 today.
        #expect(settled.lifetimeActiveSteps == 3_850)
        #expect(settled.evolutionGoalPenalty == state.species.stage.lazyDayPenalty)
    }

    /// Within the tracked day only the delta since the last credit counts, and
    /// no final total is fetched.
    @Test func `the same tracked day credits the delta without fetching`() async {
        let log = FetchLog()
        let state = makeState(trackedDay: Self.now.addingTimeInterval(-3_600), credited: 1_000, lifetime: 5_000)

        let settled = await settle(state, todaySteps: 1_400, log: log)

        #expect(settled.lifetimeActiveSteps == 5_400)
        #expect(settled.stepsCreditedToday == 1_400)
        #expect(log.days.isEmpty)
    }

    /// Without a live count there is nothing to credit and no field changes.
    @Test func `a nil reading leaves the state unchanged`() async {
        let log = FetchLog()
        let state = makeState(trackedDay: Self.yesterday, credited: 300, lifetime: 300)

        let settled = await settle(state, todaySteps: nil, log: log)

        #expect(StepProgress.Progress(of: settled) == StepProgress.Progress(of: state))
        #expect(log.days.isEmpty)
    }

    /// Settling touches only the four step-accumulator fields.
    @Test func `settling leaves every non-step field alone`() async {
        var state = makeState(trackedDay: Self.yesterday, credited: 300)
        state.battleWins = 4
        state.poopCount = 2

        let settled = await settle(state, todaySteps: 90) { _ in 2_500 }

        #expect(StepProgress.Progress(of: settled) != StepProgress.Progress(of: state))
        #expect(settled.battleWins == 4)
        #expect(settled.poopCount == 2)
        #expect(settled.species == state.species)
        #expect(settled.hungerHearts == state.hungerHearts)
        #expect(settled.timestamps.lastAdvancedAt == state.timestamps.lastAdvancedAt)
    }
}
