# Stepkin

[![CI](https://github.com/cliftonia/Stepkin/actions/workflows/ci.yml/badge.svg)](https://github.com/cliftonia/Stepkin/actions/workflows/ci.yml)

A virtual pet for Apple Watch, inspired by late-'90s LCD pets and built
natively for watchOS. A creature lives on a 32×20 pixel LCD on your
wrist: it hatches, begs for food, poops, sleeps when the lights go out,
battles, evolves — and dies if you neglect it. Real-world signals feed the
simulation: your **step count** drives evolution and **live weather** drives
the scene and day/night cycle.

- **Platform**: watchOS 26+, Swift 6 (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`)
- **Dependencies**: none — SwiftUI, HealthKit, WeatherKit, UserNotifications only
- **Rendering**: SwiftUI `Canvas` drawing a 32×20 1-bit LCD; sprites are 16×16
  bitmaps stored as `[UInt16]` rows

## Building & running

Open `imon.xcodeproj` and run the **imon Watch App** scheme.

```sh
# Compile gate (CI-equivalent)
xcodebuild build -project imon.xcodeproj -scheme "imon Watch App" \
  -destination "generic/platform=watchOS Simulator"

# Unit tests
xcodebuild test -project imon.xcodeproj -scheme "imon Watch App" \
  -destination "platform=watchOS Simulator,name=Apple Watch Ultra 4 (49mm)"

# Package tests (fast path, no simulator)
swift test --package-path Packages/StepkinKit
```

`swift test --package-path Packages/StepkinKit` runs the pure layers (Core, Engine and Sprites) on the host in seconds;
the watch scheme's `xcodebuild test` runs the app bundle (presenters, stores and the LCD snapshots in
`imon Watch AppTests/Snapshots/`) and the host-less complication bundle `SkykinComplicationTests`.
To re-record the snapshots, run `TEST_RUNNER_RECORD_SNAPSHOTS=1 xcodebuild test …` (xcodebuild forwards only
`TEST_RUNNER_`-prefixed variables to the test process); in Xcode, set `RECORD_SNAPSHOTS=1` in the scheme's environment.
The simulator builds and runs everything, but two integrations only produce
real data on a physical watch: HealthKit step counts and WeatherKit (which
also needs the WeatherKit capability provisioned; in DEBUG a sample snapshot
stands in). SwiftLint is not a build phase; run `swiftlint lint --strict` from the repo root —
the codebase holds a zero-warning bar. `python3 Tools/doc_lint.py` checks
every comment against `docs/DOCUMENTATION.md` and must report nothing.
The same commands run, quietly, on every push and pull request through GitHub Actions
(`.github/workflows/ci.yml`).

## How the game works

The engine is **timestamp-based**: nothing ticks while the app is closed.
On every launch, foreground, or 30-second tick, the presenter calls
`GameEngine.advance(state, to: .now, isNight:steps:)`, which replays elapsed
time through pure simulators and returns a new state. Quit for eight hours
and the pet catches up in one call — including anything that befell it.

| Rule | Value |
|---|---|
| Hunger hearts | deplete one per 70 min |
| Strength hearts | deplete one per 60 min |
| Poop | a pile every 2 h; 4 piles risk injury |
| Care call | 20 min to respond before it counts as a care mistake |
| Sleep | from 21:00, 2 min after the lights go out; lights left on accrue mistakes |
| Injury | untreated 6 h → death; 20 lifetime injuries → death |
| Collapse | hunger *and* strength empty for 48 h → death |
| Evolution | lifetime steps: 10k → 50k → 300k → 1M across five stages |
| Lazy day | under 2,000 steps adds a stage-scaled penalty (4k–10k) to the goal |
| Training | 5 rounds, 3 wins to succeed; −2 g weight; builds conditioning (max +3) |
| Battle | power = stats + trained POW ±20% variance; conditioning decays after 12 h idle |
| Feeding | meat +1 g, vitamin +2 g |
| Time-fed growth | with Steps off, 500 step-equivalents per waking hour |

Weather maps to the LCD scene (rain, snow, storm with lightning, fog, wind),
and the reading's daylight flag drives day/night; when the reading is stale
or unavailable, a clock window (18:00–06:00) takes over. At night the pet
moves indoors to a lamp-lit room.

With the Steps switch off the pet still grows: waking, living time is
credited as step-equivalents at 500 an hour, so evolution is slower than
walking but never closed. With Steps on, HealthKit wakes and the hourly
refresh credit new steps while the app is closed, so the pet advances
without being opened.

**Siri and the Smart Stack.** Two App Intents answer to "Feed Stepkin" and
"Check on Stepkin" (watchOS matches the phrases literally; the Ultra Action
button reaches them only through a Shortcut). The complication reports
relevance to the Smart Stack, so it rises there while the pet needs care.

## Architecture

MVVMP adapted for watchOS — no Coordinators; navigation is a SwiftUI
`NavigationStack` driven by an `AppRouter`.

```
View (SwiftUI)  →  Presenter (@MainActor, owns ViewModel)  →  Engine (pure, nonisolated)
      ↑                        ↓                                     ↓
  @Observable ViewModel   Stores (Weather / Steps / Settings)   PetStateStore (persistence)
```

**Layer rules**

- The engine is pure: value types, no clocks, no I/O. Simulators are
  functions `(PetState, Date) → PetState`. The package has no default
  isolation, so its types need no marking; app-side engine-adjacent types
  still carry `nonisolated` (extensions too — isolation does not inherit).
- The pure layers (Core, Engine, Sprites) live in the `StepkinKit` package,
  so the package cannot import the app, which the build enforces. WatchKit is
  unavailable on the macOS test host, so `swift test` rejects it; SwiftUI is
  kept out by a CI grep over the package sources (the `lint` job). The app
  re-exports the package from one file (`KitImports.swift`).
- Presenters are plain `@Observable`-adjacent classes on the main actor.
  They own their ViewModel, catch errors, and talk to the engine.
- Stores (`WeatherStore`, `StepActivityStore`, `SettingsStore`) hold shared,
  throttled, cache-windowed readings. Failed fetches throttle retries but
  never refresh a reading's age; step counts never survive midnight.
- Persistence goes through a **versioned flat DTO** (`PetStateDTO`) into
  UserDefaults as JSON — `PetState` itself is not `Codable`, so the model
  can evolve without breaking saves.
- Dependency injection is closures and protocol-witness structs, not
  protocols.

**Folder map**

```
Packages/StepkinKit/
├── Sources/
│   ├── StepkinCore/          TimeConstants, Tagged IDs, logging, the main-actor
│   │                         timer and delayed task, throttling
│   ├── StepkinEngine/        Models, Simulation, Actions, Evolution, Battle,
│   │                         Persistence, care-notification planning, the
│   │                         complication entry and timeline
│   ├── StepkinSprites/       Rendering types, the catalog, shared art, per-species
│   │                         frame files, complication sprite baking
│   └── StepkinTestSupport/   Shared test fixtures and the polling wait
└── Tests/                    StepkinCoreTests, StepkinEngineTests, StepkinSpritesTests

imon Watch App/
├── App/            imonApp, ContentView, AppPresenter (phase machine), Navigation
├── Core/           Extensions/ holds the WatchKit haptics wrapper
├── Presentation/   One folder per screen: Presenter + ViewModel; Scene/ holds
│                   the LCD scene resolver shared by the home and arena views;
│                   Shared/ holds the SpriteAnimator
├── Views/
│   ├── Screens/    SwiftUI screens (thin — delegate to presenters)
│   └── Components/ LCD display (Canvas), bezel, menu rows, meters
├── Health/         HealthKit step provider + store
├── Weather/        WeatherKit provider + store, scene mapping, moon phase
├── Settings/       SettingsStore — the feature toggles behind the Settings page
├── Power/          PowerSaverStore — mirrors system Low Power Mode
├── Notifications/  Care-call and exercise-nudge scheduling; CareHandoff plans or
│                   clears the reminders and refreshes the complication on background
├── Background/     Background refresh so the pet advances while closed
└── Complication/   App-side timeline store and reloader for the watch-face
                    complication; the widget itself is the SkykinComplication
                    extension target
```

## Localization

User-facing strings live in two String Catalogs: the watch app's
`imon Watch App/Resources/Localizable.xcstrings` and the complication's
`SkykinComplication/Localizable.xcstrings`. Code resolves them with
`String(localized:comment:)` or a SwiftUI initialiser; the engine package carries
keys only. After adding or changing a string, build and run
`xcrun xcstringstool sync <catalog> --stringsdata <build>/*.stringsdata`.

## Sprites

Every species has a file in `Packages/StepkinKit/Sources/StepkinSprites/Pets/`
with its full animation set (idle, walk, side-walk, happy, eat, sleep, attack,
refuse) as hex rows with ASCII-art comments. Shared battle poses live in
`Packages/StepkinKit/Sources/StepkinSprites/Catalog/`. The renderer fills each
sprite's enclosed holes (eyes, mouths) with scene-matched shading so backdrops
never bleed through.

Author sprites with the round-trip pipeline in [`Tools/`](Tools/README.md):
`swift2png.py` exports frames to PNGs for a pixel editor, `sprite2swift.py`
converts them back into ready-to-paste Swift.

## Documentation

Doc-comment voice, markdown-doc placement, and the commit-message format are
codified in [`docs/DOCUMENTATION.md`](docs/DOCUMENTATION.md).

## Testing

Swift Testing (`@Test`, `#expect`) for engine and store logic — simulators,
evolution, battle math, persistence migration, weather/step caching, and
sprite-anatomy checks. Tests favour a few high-value assertions over
coverage; run them with the `swift test` and `xcodebuild test` lines above.
