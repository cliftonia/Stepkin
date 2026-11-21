import Testing
@testable import Stepkin_Watch_App

// The rules, codified:
// - Home idle/refusing → full environment (real light, day phase, weather).
// - An action ceremony → its own clean scene (no room, no weather), but the
//   lighting matches where the pet is: lit inside/by day, dark outside at night.
// - Arena (battle/training) → outdoors: lit by day, dark at night, no room/weather.
struct SceneResolverTests {

    // MARK: - Home: full environment when not in an action scene

    @Test func `idle home shows the full environment`() {
        let scene = SceneResolver.home(
            dayPhase: .night, lightsOn: false,
            weather: .rain, isInActionScene: false,
            careMessPresent: false
        )
        #expect(scene.lightsOn == false)
        #expect(scene.dayPhase == .night)
        #expect(scene.weather == .rain)
    }

    @Test func `inside at night keeps the room and weather when idle`() {
        let scene = SceneResolver.home(
            dayPhase: .inside, lightsOn: true,
            weather: .cloudy, isInActionScene: false,
            careMessPresent: false
        )
        #expect(scene.dayPhase == .inside)
        #expect(scene.weather == .cloudy)
    }

    // A refusal is not an action scene, so it stays in the full environment.
    @Test func `refusal at night stays outside in the dark`() {
        let scene = SceneResolver.home(
            dayPhase: .night, lightsOn: false,
            weather: .storm, isInActionScene: false,
            careMessPresent: false
        )
        #expect(scene.lightsOn == false)
        #expect(scene.dayPhase == .night)
        #expect(scene.weather == .storm)
    }

    // MARK: - Home: an action is its own clean scene, lit to match the pet

    // Own scene → no room (.day) and no weather, but the light follows reality.
    @Test func `action outside at night is a dark clean booth`() {
        let scene = SceneResolver.home(
            dayPhase: .night, lightsOn: false,
            weather: .rain, isInActionScene: true,
            careMessPresent: false
        )
        #expect(scene.lightsOn == false)        // dark outside at night
        #expect(scene.dayPhase == .day)         // own scene — no room
        #expect(scene.weather == nil)           // own scene — no weather
    }

    @Test func `action inside is a lit clean booth`() {
        let scene = SceneResolver.home(
            dayPhase: .inside, lightsOn: true,
            weather: .cloudy, isInActionScene: true,
            careMessPresent: false
        )
        #expect(scene.lightsOn)                 // lit because the light is on
        #expect(scene.dayPhase == .day)         // own scene — no room
        #expect(scene.weather == nil)
    }

    @Test func `action by day is a lit clean booth`() {
        let scene = SceneResolver.home(
            dayPhase: .day, lightsOn: true,
            weather: .snow, isInActionScene: true,
            careMessPresent: false
        )
        #expect(scene.lightsOn)
        #expect(scene.dayPhase == .day)
        #expect(scene.weather == nil)
    }

    // MARK: - Home: a care mess (poop / injury) hides the weather

    @Test func `a care mess hides the weather but keeps the environment`() {
        let scene = SceneResolver.home(
            dayPhase: .day, lightsOn: true,
            weather: .rain, isInActionScene: false,
            careMessPresent: true
        )
        #expect(scene.weather == nil)       // weather hidden for the care cue
        #expect(scene.dayPhase == .day)     // still the full environment
        #expect(scene.lightsOn)
    }

    // MARK: - Arena: outdoors, follows day/night, never the room

    @Test func `arena is lit by day`() {
        let scene = SceneResolver.arena(dayPhase: .day)
        #expect(scene.lightsOn)
        #expect(scene.dayPhase == .day)
        #expect(scene.weather == nil)
    }

    @Test func `arena is dark at night`() {
        let scene = SceneResolver.arena(dayPhase: .night)
        #expect(scene.lightsOn == false)
        #expect(scene.dayPhase == .day)   // outdoors, never the room
        #expect(scene.weather == nil)
    }

    // "If night && inside, training/battle is night" — inside still reads dark.
    @Test func `arena is dark when entered from inside at night`() {
        let scene = SceneResolver.arena(dayPhase: .inside)
        #expect(scene.lightsOn == false)
        #expect(scene.dayPhase == .day)
        #expect(scene.weather == nil)
    }
}
