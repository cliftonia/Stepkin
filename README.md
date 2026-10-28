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
  -destination "platform=watchOS Simulator,name=Apple Watch Ultra 3 (49mm)" \
  -only-testing "imon Watch AppTests"
```

The simulator builds and runs everything, but two integrations only produce
real data on a physical watch: HealthKit step counts and WeatherKit (which
also needs the WeatherKit capability provisioned; in DEBUG a sample snapshot
stands in). SwiftLint is not a build phase; run `swiftlint lint` from the repo root —
the codebase holds a zero-warning bar. `python3 Tools/doc_lint.py` checks
every comment against `docs/DOCUMENTATION.md` and must report nothing.
The same four commands run on every push and pull request through GitHub Actions
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

Weather maps to the LCD scene (rain, snow, storm with lightning, fog, wind),
and the reading's daylight flag drives day/night; when the reading is stale
or unavailable, a clock window (18:00–06:00) takes over. At night the pet
moves indoors to a lamp-lit room.

## Architecture

MVVMP adapted for watchOS — no Coordinators; navigation is a SwiftUI
`NavigationStack` driven by an `AppRouter`.

```
View (SwiftUI)  →  Presenter (@MainActor, owns ViewModel)  →  Engine (pure, nonisolated)
      ↑                        ↓                                     ↓
  @Observable ViewModel   Stores (Weather / Steps / Settings)   PetStateStore (persistence)
```

**Layer rules**

- `Engine/**` is pure and `nonisolated`: value types, no clocks, no I/O.
  Simulators are functions `(PetState, Date) → PetState`. With MainActor
  default isolation, every engine type is explicitly marked `nonisolated`
  (extensions too — isolation does not inherit).
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
imon Watch App/
├── App/            imonApp, ContentView, AppPresenter (phase machine), Navigation
├── Core/           TimeConstants, Tagged IDs, logging, small extensions
├── Engine/
│   ├── Models/     PetState, PetSpecies, EvolutionStage, StatHearts, …
│   ├── Simulation/ GameEngine + one simulator per rule (hunger, sleep, …)
│   ├── Actions/    Feed / Train / Clean / Heal / Lights — pure state edits
│   ├── Evolution/  Requirements and the species evolution chart
│   ├── Battle/     Power, opponents, round resolution
│   └── Persistence/ PetStateStore witness + JSON implementation
├── Presentation/   One folder per screen: Presenter + ViewModel; Scene/ holds
│                   the LCD scene resolver shared by the home and arena views
├── Views/
│   ├── Screens/    SwiftUI screens (thin — delegate to presenters)
│   └── Components/ LCD display (Canvas), bezel, menu rows, meters
├── Sprites/        SpriteFrame/Animator/Catalog + per-species frame files
├── Health/         HealthKit step provider + store
├── Weather/        WeatherKit provider + store, scene mapping, moon phase
├── Settings/       SettingsStore — the feature toggles behind the Settings page
├── Power/          PowerSaverStore — mirrors system Low Power Mode
├── Notifications/  Care-call and exercise-nudge scheduling
├── Background/     Background refresh so the pet advances while closed
└── Complication/   App-side timeline baking for the watch-face complication;
                    the widget itself is the SkykinComplication extension target
```

## Sprites

Every species has a file in `Sprites/Pets/` with its full animation set
(idle, walk, side-walk, happy, eat, sleep, attack, refuse) as hex rows with
ASCII-art comments. Shared battle poses live in `Sprites/Catalog/`. The
renderer fills each sprite's enclosed holes (eyes, mouths) with
scene-matched shading so backdrops never bleed through.

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
coverage; run them with the `xcodebuild test` line above.
