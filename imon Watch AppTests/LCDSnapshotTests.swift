import CoreGraphics
import Testing
@testable import imon_Watch_App

/// One LCD scene to snapshot: the configuration, the palette and the frozen
/// animation phase, named after its reference PNG.
nonisolated struct LCDSnapshotCase: Sendable, CustomTestStringConvertible {
    /// The reference file's base name in `Snapshots/`.
    let name: String
    /// What the LCD draws.
    let configuration: LCDDisplayConfiguration
    /// The palette the LCD is rendered under.
    let theme: LCDTheme
    /// The frozen animation phase the frame is drawn at.
    let weatherPhase: Int

    /// The case's name, shown in the test report.
    var testDescription: String { name }

    /// Creates a case; the palette defaults to `classic` and the phase to 0,
    /// a flash frame for the strobes and a visible frame for the call sign.
    init(_ name: String, theme: LCDTheme = .classic, weatherPhase: Int = 0, configuration: LCDDisplayConfiguration) {
        self.name = name
        self.configuration = configuration
        self.theme = theme
        self.weatherPhase = weatherPhase
    }
}

/// Pins the LCD's look: each scene renders to pixels identical to its
/// committed reference. Record new references with `TEST_RUNNER_RECORD_SNAPSHOTS=1 xcodebuild test …`
/// or `RECORD_SNAPSHOTS=1` in the scheme's environment.
@MainActor
struct LCDSnapshotTests {

    nonisolated private static let pet = SpriteCatalog.frames(for: .dotkin, kind: .idle)[0]

    /// Every snapshotted scene, one reference PNG each.
    nonisolated static let cases: [LCDSnapshotCase] = [
        LCDSnapshotCase("day-idle", configuration: scene()),
        LCDSnapshotCase("night-inside", configuration: scene(dayPhase: .inside)),
        LCDSnapshotCase("night-lights-off", configuration: scene(lightsOn: false, dayPhase: .night)),
        LCDSnapshotCase("poop-4", configuration: LCDDisplayConfiguration(leftSprite: pet, poopCount: 4, moonPhase: .full)),
        LCDSnapshotCase("call-sign", configuration: LCDDisplayConfiguration(leftSprite: pet, moonPhase: .full, showCallSign: true)),
        LCDSnapshotCase("storm-flash", configuration: LCDDisplayConfiguration(leftSprite: pet, moonPhase: .full, stormFlash: true)),
        LCDSnapshotCase("evolve-flash", configuration: LCDDisplayConfiguration(leftSprite: pet, moonPhase: .full, evolveFlash: true)),
        LCDSnapshotCase("night-red-theme", theme: .nightRed, configuration: scene()),
        LCDSnapshotCase(
            "right-sprite",
            configuration: LCDDisplayConfiguration(leftSprite: pet, rightSprite: SharedSprites.meatServing.frames[0], moonPhase: .full)
        )
    ] + WeatherIconCondition.allCases.map { condition in
        LCDSnapshotCase("weather-\(condition)", weatherPhase: 3, configuration: scene(weather: condition))
    }

    /// A Dotkin idling in the left slot under a full moon.
    nonisolated private static func scene(
        lightsOn: Bool = true,
        weather: WeatherIconCondition? = nil,
        dayPhase: DayPhase = .day
    ) -> LCDDisplayConfiguration {
        LCDDisplayConfiguration(
            leftSprite: pet, lightsOn: lightsOn,
            weatherCondition: weather, moonPhase: .full, dayPhase: dayPhase
        )
    }

    @Test(arguments: cases)
    func `the scene matches its reference`(_ snapshot: LCDSnapshotCase) throws {
        let first = try #require(renderLCD(snapshot.configuration, theme: snapshot.theme, weatherPhase: snapshot.weatherPhase))
        let second = try #require(renderLCD(snapshot.configuration, theme: snapshot.theme, weatherPhase: snapshot.weatherPhase))
        #expect(first.width == 320 && first.height == 200)
        // Two renders of one frame must agree before a reference can mean anything.
        try #require(SnapshotBitmap(first) == SnapshotBitmap(second), "\(snapshot.name) renders differently twice")
        assertSnapshot(first, named: snapshot.name)
    }
}
