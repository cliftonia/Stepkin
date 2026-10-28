# Packages and polish — the second campaign

The design for the work that follows the release audit: the package split
the roadmap promised, a consolidation pass against repetition and dead
weight, the player-facing features the October review proposed, and the
fortifications (continuous integration, tests, localization) that let the
project keep growing without rotting. Written before the work, as the
roadmap and the migration plan were, so that a builder can plan from it
without the conversation that produced it.

## Intent

The app is release-ready but is held together by discipline rather than by
the compiler: layer rules are prose in the README, the gate runs only when
someone remembers, and the home presenter has grown nine extension files and
three timers. At the same time the pet is invisible to the parts of watchOS
that would surface it (the Smart Stack, Siri) and silently stops growing for
a player who declines HealthKit. This campaign fixes both halves at once,
because the restructure is the moment every file is touched anyway.

Decisions taken by the developer on 2026-10-28:

- **Evolution for players without steps is time-fed.** When no step reading
  is available, waking hours of care count toward the evolution goal
  instead. Players with steps are unchanged.
- **The package split happens now, in this repository.** No fresh history,
  no project rename. The roadmap's "fresh repository" decision is
  superseded; the GitHub remote already carries the product name.
- **Every user-facing string moves into String Catalogs.** English only, but
  a second language becomes a translation job rather than a code job.
- **Repetition and speculation are removed as part of the move**, not after.
  The audit in the appendix is the list; it is done before code moves so
  that less code moves.
- **The pure layers become one local package; presentation stays in the
  app target** (decided after the builder check on 2026-10-28: a package's
  platforms are declared per package, and the UI imports WatchKit, so the
  Mac-side `swift test` cannot share a package with it).

Calls made by the author, open to challenge but not blocking:

- Time-fed evolution is gated on the Steps switch, never on a missing
  reading (§4.4).
- Step crediting, including the per-day settle, leaves the home presenter
  and becomes a domain step both the presenter and the offline session run
  (§4.2).
- The battle-gate row appears only when every chart row for the species is
  gated, so the original toy's hidden branches stay hidden (§4.5).

## Goals

1. The layer rules are enforced by the build: Core, Engine and Sprites live
   in a package that cannot see the app, cannot import WatchKit or SwiftUI,
   and whose tests run with a bare `swift test` on a Mac in seconds.
2. Every push and pull request runs the full gate (build, tests, SwiftLint,
   the doc checker) on GitHub Actions. The repository is public, so the
   macOS runners cost nothing.
3. A hungry, injured or languishing pet appears at the top of the Smart
   Stack. Siri on the watch can feed the pet and report on it.
4. A pet with the Steps switch off grows with time at a pace comparable to
   an average walker, and the Stats screen names any battle gate that stands
   between the pet and its next form.
5. Steps are credited toward evolution while the app is closed, on
   HealthKit's own schedule where the system allows it, so a pet can evolve
   while away and the existing evolution notification has a reason to
   fire; background ticks scale hunger by real activity instead of the
   neutral rate.
6. The LCD scene is covered by image snapshots, the four untested presenters
   are tested, and the template UI test target is gone.
7. The codebase holds its current bar throughout: zero SwiftLint findings,
   a clean doc checker, every file under the length limits, no external
   dependencies, every step green before the next begins.

## Non-goals

- The iPhone and iPad companions and the sync transport (Epic 6). The split
  makes them thin-shell work later; nothing here builds them.
- Renaming the Xcode project, targets or schemes to Stepkin. Bundle
  identifiers and display names already carry the product name; the project
  file name is cosmetic and Xcode owns the rename.
- A second language. The catalogs ship with English only.
- Rewriting the LCD renderer into a pure cell composer. Snapshots are taken
  of the rendered image; the composer is a later refactor if the image
  snapshots prove brittle.
- Unifying the battle and training ceremony schedulers. The audit judged
  them different enough to leave.

## Anti-goals

- A save that no longer decodes, or a complication that vanishes from a
  placed watch face. The `PetStateDTO` field names, the UserDefaults keys,
  the App Group identifier and the widget `kind` string do not change.
- A player with steps noticing any change in how fast their pet evolves.
- New abstraction for its own sake: no protocols, no witnesses with a single
  caller and no test, no "manager" types. Each extraction in the appendix
  exists because two or more copies of the code exist today.
- Any new third-party dependency, including for localization or snapshots.
- A green pipeline that only runs part of the gate.

## Constraints

- watchOS 26.2 deployment target, Swift 6 language mode, strict concurrency,
  `MainActor` default isolation in presentation code only.
- SwiftLint limits as in `.swiftlint.yml`; `Tools/doc_lint.py` must pass.
- Commit messages follow `docs/DOCUMENTATION.md`; nothing in the tree or the
  history names an AI tool.
- Xcode 27.1 is the local toolchain; the CI runner must offer an Xcode with
  the watchOS 26.2 SDK or newer.
- The simulator cannot exercise HealthKit background delivery; that feature
  is verified on the developer's wrist.

## Order of work

Each stream ends green. The order is chosen so that the gate exists before
anything moves, less code moves, and the features land on the final layout.

1. **Continuous integration** — so every later step is checked by a machine.
2. **Consolidation** — the appendix, in the audit's order: deletions, then
   the pause/haptic fixes, then the shared helpers, then the extractions.
3. **The package split** — one local package with three pure targets; the
   app target keeps presentation.
4. **Features** — Smart Stack relevance, App Intents, background delivery,
   time-fed evolution, the battle-gate row.
5. **Fortifications** — presenter tests, LCD snapshots, the Swift 6
   complication, removal of the UI test target.
6. **Localization** — last, so one pass catches every string the features
   added.
7. **Documents** — README folder map and commands, roadmap epics closed,
   release checklist gains the new entitlement.

## 1. Continuous integration

A single GitHub Actions workflow on push to `main` and on pull requests,
running on the newest macOS runner image that carries Xcode 27 (verify the
image name and select the Xcode version explicitly in the first run). Jobs:

- **lint** — SwiftLint from Homebrew pinned to the version in use locally
  (0.53.0 today) and `python3 Tools/doc_lint.py`. Fails on any finding.
- **package-tests** — `swift test` in the package directory on the macOS
  host. Fast; no simulator.
- **watch** — `xcodebuild build` and `xcodebuild test` for the watch scheme
  on a watchOS 26.2 simulator, with the SwiftPM and DerivedData caches keyed
  on the project and package files.

The README gains the status badge and the commands stay the README's
commands: CI runs what the README says to run, nothing else.

## 2. Consolidation

The appendix lists every finding with its decision. The rules that produced
the decisions:

- A duplicate body is folded into the place that already owns the concept
  (the `ThrottledFetch` helper, the `pause` helper, the haptics switch).
- Domain rules found in presenters move into the engine type that owns the
  neighbouring rule (`TrainAction`, `BattleEngine`, `PetStatus`).
- Dead code is deleted with its tests. A test-only mock lives in the test
  target.
- A one-caller convenience with no test is folded back into its caller.
- Extractions take closures, never protocols, and are observable only if a
  view binds to them.

## 3. The package split

One local Swift package at `Packages/StepkinKit` with three library targets
and a test target for each. Presentation stays in the watch app target.

```
Packages/StepkinKit/
├── Package.swift
├── Sources/
│   ├── StepkinCore/      Tagged, TickMath, TimeConstants, logging, extensions
│   ├── StepkinEngine/    models, simulation, actions, evolution, battle,
│   │                     step crediting, the DTO and JSON store, the care
│   │                     reminder planner, complication entry and timeline
│   └── StepkinSprites/   frames, animations, catalog, per-species art, facing
└── Tests/
    ├── StepkinCoreTests/
    ├── StepkinEngineTests/
    └── StepkinSpritesTests/

imon Watch App/                presenters, view models, scene resolver, LCD
                               canvas, screens, components, stores, the
                               HealthKit, WeatherKit and location providers,
                               the sprite animator, background tick and
                               offline session, intents, String Catalog
```

- The package declares macOS and watchOS platforms, Swift 6 language mode,
  no default isolation. Its targets import Foundation and `os` only, and
  what the app target must see is `public`; what only the sibling targets
  see is `package`. The explicit `nonisolated` markings come off.
- Target dependencies are Core ← Engine ← Sprites, so Sprites may read
  species and status but Engine never sees a bitmap.
- The app target depends on the package product and keeps `MainActor`
  default isolation. The sprite animator stays in the app, since it owns a
  timer and is observed by views.
- The complication extension stays a separate target reading JSON from the
  App Group, as today. It does not depend on the package.
- The project file gains the local package reference; the synchronized
  folder groups drop moved files from the app target on their own.
- `.swiftlint.yml` and `Tools/doc_lint.py` learn the new roots. The
  per-species bitmap exclusion follows the art into Sprites.
- The watch scheme's test action runs the app test bundle and the three
  package test bundles, so one `xcodebuild test` still runs everything on
  the simulator; `swift test` in the package directory is the fast path.

The move is done in dependency order (Core, Engine, Sprites), compiling
after each, as the migration plan describes.

## 4. Features

### 4.1 Smart Stack relevance

The complication's timeline provider implements the relevance requirement
(watchOS 11 and later) and returns one date-bounded relevance per run of
consecutive baked entries whose attention flag is set, from the first such
entry's date to the first entry after the run. The baked entry already
carries the flag; the widget's decoded entry gains the injured and dead
fields it currently ignores, so a hurt pet is relevant even before its
hearts empty and a dead pet is never relevant. No conversion to an
intent-configured widget; no change to the JSON contract beyond reading
keys the app already writes.

### 4.2 App Intents

Two intents, both running in the app process, plus an App Shortcuts
provider with exact phrases (watchOS matches phrases literally):

- **Feed** — a food parameter (meat or vitamin, an App Enum). Feeds through
  the same engine action the home screen uses and answers with a one-line
  dialog: fed, or the reason it refused (asleep, full, gone).
- **Check** — answers with the same spoken sentence the home screen gives
  VoiceOver. One source for that sentence, not two.

**One writer at a time.** Every external actor (an intent, a HealthKit
wake, a background refresh) first asks the app for its live pet presenter.
If one exists, the action goes through it, exactly as a button press would,
and the presenter remains the single writer of the save. Only when no
presenter exists (a cold background launch) does the "offline session" run:
load the save, advance to now with the current readings, credit steps,
apply an optional action, save, then hand care off (plan or cancel
reminders, bake the complication timeline, reload the face). The background
tick, the HealthKit wake and the intents are three callers of that one
pipeline; the presenter's tick and care hand-off call the same functions.
To make the live presenter reachable, the app presenter is created by the
application delegate rather than inside the root view.

**Step crediting becomes a domain step.** The crediting the home presenter
does today (same-day delta, rollover with the lazy-day verdict, and the
per-day HealthKit settle for days missed while closed) moves into the
engine as one async function taking the day-total closure; the presenter's
steps extension shrinks to a call. The offline session runs the same
function, which is what lets a pet evolve while the app is closed. The
step accumulator lives in `PetState`, so it is saved with everything else.

**The saved state is the single truth.** As a safety net, whenever the
home presenter becomes active it adopts the saved state if its
last-advanced stamp is newer than the state in memory, before advancing.

### 4.3 HealthKit background delivery

At launch the application delegate registers an observer query for step
count with hourly background delivery and forwards each wake to the live
presenter or the offline session (§4.2) with a fresh step reading, calling
HealthKit's completion handler when done.
The background-delivery entitlement is added to the watch app and recorded
in the release checklist as a capability the developer must tick on the
App ID. The hourly refresh chain stays; the two share the system's budget,
and the chain remains the fallback if delivery proves unreliable on the
device (a regression on watchOS 26 is reported on Apple's forums and is
unconfirmed).

### 4.4 Time-fed evolution

The engine's step input becomes a three-way reading rather than an
optional count: steps switched off, steps on but no reading yet, or a
count. A new simulator in the engine's step, run only when steps are
switched off, credits lifetime active steps for waking, living time at a
fixed rate from a new anchor timestamp. A missing reading with the switch
on behaves exactly as `nil` does today (neutral activity scaling, no
credit), so the launch catch-up, a failed background read and the first
seconds after midnight never credit a steps-on player. Whole steps only; the anchor advances by
the time those steps cost, so no fraction is lost across 30-second ticks.
The rate is a `TimeConstants` value, 500 step-equivalents per waking hour
(about 7,500 a day over a 15-hour waking day, an average walker), so the
fresh stage takes roughly a day and a half and the in-training stage about
a week, in line with the step goals. Lazy-day penalties never apply in
time-fed mode, since there is no day's count to judge.

- The anchor is persisted; the DTO moves to schema version 4, with an
  absent anchor decoding as the last-advanced stamp.
- Stats stops saying "Needs steps" and shows the normal progress row; the
  activity row still says "Steps off". The Settings footer says that with
  Steps off the pet grows with time instead.
- A player who declined HealthKit but left Steps on reads zero steps all
  day and is penalised for it, because HealthKit does not reveal a denied
  read. Within this campaign the Settings footer tells them to switch Steps
  off; automatic detection is out of scope.
- Every caller of the engine (the presenter, the offline session, the
  complication projection, the reminder planner) passes the reading
  explicitly; there is no default.

### 4.5 The battle gate row

Stats gains a row, shown only when every chart row for the pet's current
species carries a battle-wins or win-rate gate, so that battle is the only
way forward. It reads the gate generically from the chart: wins so far
against wins needed, and the rate if one is required. A species with an
ungated row beside a gated one shows nothing, so the original toy's hidden
branches stay hidden. Nothing names Rexkin; any future blocking row shows
the same way.

## 5. Fortifications

- **Presenter tests** for Hatch, Death, Onboarding and Settings: the
  lifecycle contract each presenter's header documents, nothing more. The
  Hatch ceremony's double-fire on a re-fired `.task` (audit §2) is fixed
  and covered.
- **LCD snapshots**: a test renders the LCD view for a fixed set of
  configurations (each day phase, each weather condition, the room, poop,
  call sign, the two flashes, the battery-saver palette) through
  `ImageRenderer` at a fixed point size and scale, and compares pixels
  against PNG references stored in the test bundle. A record mode, switched
  by an environment variable, rewrites the references. Rendering happens on
  the main actor on the simulator; the comparison is exact.
- **The complication extension moves to Swift 6 language mode** with the
  same strict concurrency as the app.
- **The UI test target is deleted** along with its scheme entry. The
  journeys it might have covered are presenter tests.

## 6. Localization

One String Catalog in the watch app target and one in the complication
extension; the package carries no user-facing strings, so engine-owned
words (stage names, reminder bodies) become keys the app resolves. Every user-facing string moves in: screen labels,
status words, stage names, menu labels, settings copy, onboarding tips,
notification titles and bodies, intent dialogs, the complication's words.
Species names stay as proper nouns. Presenter-built strings become
localized resources resolved at the point of display. The baked complication
entry carries a mood key rather than an English word, and the widget
localizes it; both sides change in the same build, and a stale baked
timeline shows the placeholder until the next bake. Generated string symbols
are used if the toolchain provides them for package resources; otherwise
plain keys. No tooling dependency.

## 7. Documents

- README: the folder map shows the package beside the app folder, the
  build and test commands gain `swift test`, the architecture section says
  the pure layers are enforced by the package boundary, the badge is added.
- Roadmap: Epic 2 closes as "done in place, no fresh repository"; Epic 3's
  items are listed as done; Epic 5 gains the new entitlement; the
  "stranded pet" risk is unchanged.
- Release checklist: the HealthKit background-delivery capability joins the
  provisioning list; the "known and accepted" entries for step-only
  evolution and the invisible Rexkin gate are removed.
- Migration plan: marked superseded by this document for steps 4 to 6;
  the providers stay in the app as that plan said.

## Left to the builder

- The exact `public` surface of the package and how the app presenter is
  exposed to intents and the delegate.
- How the scheme includes the package test bundles; whichever keeps one
  `xcodebuild test` command.
- The CI runner image and caching details.
- The names of the extracted helpers in the appendix; the appendix's names
  are suggestions.
- The reference-image set for the LCD snapshots beyond the list above.
- How the presenter adopts a newer save (reload on activation versus a
  change signal), as long as the single-truth rule holds.

## Appendix — the consolidation list

From the 2026-10-28 audit. Every item is accepted unless marked otherwise.
S and M are size estimates.

**Deletions (first)**

- `BattlePower` and its only consumers (`trainedPowerWeight`,
  `strengthPowerWeight`, `overweightPowerPenalty`, `Weight.isOverweight`)
  with `BattlePowerTests`; confirm `PetSpecies.basePower` has no other live
  reader before removing it. S
- `PetPresenter.getCurrentState()`; callers read `state`. S
- `ComplicationStore.load` if no app caller remains after the intents land
  (the offline session may want it; decide then). S
- The fourteen forwarding accessors at the top of `LCDDisplay`; extensions
  read the configuration directly. S
- `StepActivityStore.makeDefault()`. S
- `SpriteAnimator+Catalog.swift` folded into `SpriteAnimator.swift`. S
- `OnboardingViewModel.tips`; read the static walkthrough. S
- Unused parameters `LocationProvider.live(timeout:)` and
  `NotificationScheduler.live(now:)`. S
- Test-only mocks `WeatherProvider.mockFailing` and `StepCountProvider.mock`
  move to the test target. S
- Duplicate test helpers (`makeDefaults`, `today(at:)`, `makePresenter`)
  move to `TestHelpers.swift`. S

**Pause and haptic fixes**

- Eight raw sleeps in `BattlePresenter` and `+Rounds`, one in
  `PetPresenter+Feeding`, three in `HatchPresenter`, become the shared
  `pause` with its cancellation check. S
- `HatchPresenter` stores its ceremony task and cancels it. S
- `OnboardingPresenter` uses the haptics switch instead of the raw device
  call. S

**Shared helpers (each replaces two or more copies)**

- A main-actor repeating timer wrapper replacing the four
  `Timer.scheduledTimer` plus `Task { @MainActor }` copies in
  `PetPresenter`, `+Wander` (twice) and `SpriteAnimator`. S
- A cancel-previous delayed task replacing `sleepToggleTask` in `+Lights`
  and `TrainingPresenter.schedule(after:)`. S
- The care hand-off function (plan or cancel, bake, reload) replacing the
  copies in `PetPresenter.scheduleCareNotifications` and `BackgroundTick`;
  becomes part of the offline session in §4.2. S
- A logged-save extension on `PetStateStore` replacing `AppPresenter.persist`
  and `PetPresenter.save`. S
- `ThrottledFetch` absorbs the do/catch/record body shared by `WeatherStore`
  and `StepActivityStore`; each store keeps only its freshness predicate. M
- `AppPresenter.restartPet` reuses `startDeath`; the DEBUG settings wiring
  moves to `AppPresenter+Debug.swift`. S

**Extractions**

- A wander controller owning `wanderTimer`, `wanderState`, `WanderState`
  and the pet offset, taking three closures (should pause, play walk,
  on idle). The presenter keeps start and stop; the screen reads the
  offset. M
- A cells-only LCD geometry enum (moon centre and disc, star spots, tuft
  columns, grid and ground rows) shared by the LCD renderer and
  `NotificationSpriteRenderer`, replacing the byte-identical copies. M
- `GameModeLayout` gains an optional header slot and the home screen's
  `normalLayout` uses it. M
- A monospaced LCD font helper replacing nineteen font declarations. S

**Domain rules out of presenters**

- `TrainAction.sessionOutcome(results:)` replaces the win/lose decision in
  `TrainingPresenter`. S
- `BattleEngine` gains the round cap and the HP tiebreak the presenter
  currently decides. S
- `PetStatus` gains the drooping and care-mess flags the presenter and the
  screen each re-derive. S
- `PetViewModel` carries the moon phase; the screen stops reading the clock. S
- `GameEngine.step` takes its calendar from the caller or computes age
  through `TickMath`; the engine's action and schedule signatures lose
  their `.now` and `.current` defaults. S

**Views**

- Battle info row and buttons, and the hatch screen, switch from
  conditional view swaps to the opacity pattern the training screen uses. S
- Manual `ForEach` ids in the training screen, `MenuIconRow` and
  `HeartMeter` give way to `Identifiable`. S
- The seven training and battle action buttons gain spoken labels. S

**Declined**

- Unifying the battle and training ceremony schedulers.
- Replacing `HatchViewModel`; the presenter mutates its phase, so
  observation is earned. `DeathViewModel` becomes a configuration struct.
- Removing the single-closure witnesses (`PermissionRequester`,
  `ComplicationReloader`, `BackgroundRefreshScheduler`); each has a test.
