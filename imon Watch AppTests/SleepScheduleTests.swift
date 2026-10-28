import Testing
import Foundation
@testable import imon_Watch_App

@Suite("SleepSchedule")
struct SleepScheduleTests {

    // MARK: - Helpers

    private func date(hour: Int) -> Date {
        var components = Calendar.current.dateComponents(
            [.year, .month, .day], from: .now
        )
        components.hour = hour
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components) ?? .now
    }

    // MARK: - Night Resolution

    @Test
    func `weather daylight always wins over the clock`() {
        // 3pm but weather says night → night.
        #expect(SleepSchedule.isNight(weatherNight: true, at: date(hour: 15), calendar: .current))
        // 11pm but weather says day → day.
        #expect(!SleepSchedule.isNight(weatherNight: false, at: date(hour: 23), calendar: .current))
    }

    @Test
    func `falls back to a 6am-6pm window without weather`() {
        #expect(SleepSchedule.isNight(weatherNight: nil, at: date(hour: 20), calendar: .current))   // 8pm → night
        #expect(SleepSchedule.isNight(weatherNight: nil, at: date(hour: 3), calendar: .current))    // 3am → night
        #expect(!SleepSchedule.isNight(weatherNight: nil, at: date(hour: 6), calendar: .current))   // 6am → day
        #expect(!SleepSchedule.isNight(weatherNight: nil, at: date(hour: 14), calendar: .current))  // 2pm → day
    }

    // MARK: - Day

    @Test
    func `daytime forces the light on and keeps the pet awake`() {
        var state = makeTestState(at: .now)
        state.lightsOn = false
        state.isSleeping = true

        state = SleepSchedule.apply(to: state, at: .now, night: false, calendar: .current)

        #expect(state.lightsOn == true)
        #expect(state.isSleeping == false)
    }

    // MARK: - Bedtime window

    @Test
    func `bedtime starts at 9pm and runs to the morning wake hour`() {
        #expect(SleepSchedule.isBedtime(at: date(hour: 21), calendar: .current))      // 9pm
        #expect(SleepSchedule.isBedtime(at: date(hour: 2), calendar: .current))       // 2am
        #expect(!SleepSchedule.isBedtime(at: date(hour: 19), calendar: .current))     // 7pm — still up
        #expect(!SleepSchedule.isBedtime(at: date(hour: 6), calendar: .current))      // 6am — awake
    }

    // MARK: - Dusk / Dawn

    @Test
    func `dusk dims the light but the pet stays up before bedtime`() {
        let now = date(hour: 19)   // 7pm — dark, but not yet bedtime
        var state = makeTestState(at: now)
        state.lightsOn = true
        state.isSleeping = false
        state.wasNight = false

        state = SleepSchedule.apply(to: state, at: now, night: true, calendar: .current)

        #expect(state.lightsOn == false)              // dusk dims the light
        #expect(state.wasNight == true)
        #expect(state.isSleeping == false)            // but the pet is still up
        #expect(state.timestamps.lightsOffAt == nil)  // no settle countdown yet
    }

    @Test
    func `a dark evening before bedtime keeps the pet awake with the light off`() {
        let now = date(hour: 20)   // 8pm — outside in the dark
        var state = makeTestState(at: now)
        state.wasNight = true
        state.lightsOn = false
        state.isSleeping = false

        state = SleepSchedule.apply(to: state, at: now, night: true, calendar: .current)

        #expect(state.isSleeping == false)
        #expect(state.timestamps.lightsOffAt == nil)
    }

    @Test
    func `dawn turns the light on and wakes the pet`() {
        let now = date(hour: 8)
        var state = makeTestState(at: now)
        state.lightsOn = false
        state.isSleeping = true
        state.wasNight = true

        state = SleepSchedule.apply(to: state, at: now, night: false, calendar: .current)

        #expect(state.lightsOn == true)
        #expect(state.isSleeping == false)
        #expect(state.wasNight == false)
    }

    // MARK: - Settle Delay (bedtime only)

    @Test
    func `at bedtime with the light out the settle countdown begins`() {
        let now = date(hour: 22)
        var state = makeTestState(at: now)
        state.wasNight = true
        state.lightsOn = false
        state.isSleeping = false

        state = SleepSchedule.apply(to: state, at: now, night: true, calendar: .current)

        #expect(state.timestamps.lightsOffAt == now)
        #expect(state.isSleeping == false)
    }

    @Test
    func `pet sleeps once the settle delay has passed at bedtime`() {
        let now = date(hour: 22)
        var state = makeTestState(at: now)
        state.wasNight = true
        state.lightsOn = false
        state.isSleeping = false
        state.timestamps.lightsOffAt = now.addingTimeInterval(
            -(TimeConstants.sleepDelay + 1)
        )

        state = SleepSchedule.apply(to: state, at: now, night: true, calendar: .current)

        #expect(state.isSleeping == true)
        #expect(state.timestamps.lightsOffAt == nil)
    }

    @Test
    func `pet stays awake before the settle delay`() {
        let now = date(hour: 22)
        var state = makeTestState(at: now)
        state.wasNight = true
        state.lightsOn = false
        state.isSleeping = false
        state.timestamps.lightsOffAt = now.addingTimeInterval(-1)

        state = SleepSchedule.apply(to: state, at: now, night: true, calendar: .current)

        #expect(state.isSleeping == false)
    }

    @Test
    func `bringing it inside with the light wakes the pet at bedtime`() {
        let now = date(hour: 22)
        var state = makeTestState(at: now)
        state.wasNight = true
        state.lightsOn = true
        state.isSleeping = true

        state = SleepSchedule.apply(to: state, at: now, night: true, calendar: .current)

        #expect(state.lightsOn == true)
        #expect(state.isSleeping == false)
    }

    @Test
    func `sleeping pet stays asleep with the light off`() {
        let now = date(hour: 22)
        var state = makeTestState(at: now)
        state.wasNight = true
        state.lightsOn = false
        state.isSleeping = true

        state = SleepSchedule.apply(to: state, at: now, night: true, calendar: .current)

        #expect(state.isSleeping == true)
    }

    // MARK: - Guards

    @Test
    func `replay boundaries name dawn, dusk, bedtime and the settle in order`() {
        let calendar = Calendar.current
        let start = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: .now) ?? .now
        let end = calendar.date(byAdding: .hour, value: 14, to: start) ?? start

        let hours = SleepSchedule.replayBoundaries(from: start, to: end, calendar: .current)
            .map { calendar.component(.hour, from: $0) * 100 + calendar.component(.minute, from: $0) }

        #expect(hours == [1800, 2100, 2102, 600])
    }

    @Test
    func `replay boundaries are empty within a single waking stretch`() {
        let calendar = Calendar.current
        let start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
        let end = calendar.date(byAdding: .hour, value: 5, to: start) ?? start

        #expect(SleepSchedule.replayBoundaries(from: start, to: end, calendar: .current).isEmpty)
        #expect(SleepSchedule.replayBoundaries(from: end, to: start, calendar: .current).isEmpty)
    }

    @Test
    func `dead pet is not affected`() {
        var state = makeTestState(at: .now)
        state.isDead = true
        state.isSleeping = false

        state = SleepSchedule.apply(to: state, at: .now, night: true, calendar: .current)

        #expect(state.isSleeping == false)
    }

    @Test
    func `egg is not affected`() {
        var state = PetState.hatched(at: .now)
        state.isEgg = true
        state.isSleeping = false

        state = SleepSchedule.apply(to: state, at: .now, night: true, calendar: .current)

        #expect(state.isSleeping == false)
    }
}
