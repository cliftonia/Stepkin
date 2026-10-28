# Epic 2 — the founding

> Steps 4–6 are superseded by `docs/packages-and-polish-plan.md`: the package
> split was done in place on 2026-10-28 with no fresh history. The providers
> stayed in the app, as this plan said.

The one-time move from this repository to **Stepkin**: renamed, restructured
into packages, and re-homed in a fresh history. Written before the work so the
order is decided calmly rather than mid-flight.

Measured surface as of 2026-07-19: 60 `@testable import imon_Watch_App` lines,
an 897-line `project.pbxproj`, only 5 references to `imon` in app source (the
name lives almost entirely in project metadata), and a `Tools/` directory whose
scripts are already named `skykin_*`.

## Order of operations

Each step ends green — the build compiles and the suite passes — before the
next begins. Nothing is deleted until its replacement is proven.

### 1. Identity rename (Xcode, by hand — mine to specify, thine to perform)

Xcode owns project and target renames; they are not scriptable. In the current
project rename:

- the project `imon` → `Stepkin`
- target `imon Watch App` → `Stepkin Watch App` (module becomes
  `Stepkin_Watch_App`)
- target `imon` (the `watchapp2-container` stub) → `Stepkin`
- target `SkykinComplicationExtension` → `StepkinComplicationExtension`
- targets `imon Watch AppTests` / `imon Watch AppUITests` → `Stepkin …`
- the scheme names to match

Xcode will offer to rename folders and the scheme; accept. It will *not* fix
everything — that is step 2.

### 2. Repair the fallout (mine)

- every `@testable import imon_Watch_App` → `Stepkin_Watch_App` (60 lines)
- folder paths and group references left stale in `project.pbxproj`
- the entitlements filenames (`imon Watch App.entitlements`,
  `SkykinComplicationExtension.entitlements`)
- the five bundle ids → the identifiers registered in Epic 0:
  `cliftonia.stepkin`, `cliftonia.stepkin.watchkitapp`,
  `cliftonia.stepkin.watchkitapp.StepkinComplication`, and the two test bundles
- the App Group `group.cliftonia.skykin` → `group.cliftonia.stepkin`, in both
  entitlements files and `AppGroup.swift`
- display names (`INFOPLIST_KEY_CFBundleDisplayName`) → `Stepkin`
- `Tools/skykin_*.py` → `stepkin_*.py`, and their README
- the last references in `README.md`

**Gate**: build green, 332+ tests green, and a run on the watch showing the
pet intact under the new name before proceeding.

### 3. The pet hand-off (decision pending)

New bundle ids mean a new App Group container: the pet currently on the wrist
will not be found by the renamed app. If the hand-off is wanted, it ships
here — the new app reads the old group (`group.cliftonia.skykin`) once at
first launch, adopts any save it finds, writes it to the new group, and never
looks again. It requires the *old* App Group to stay listed in the new app's
entitlements (and ticked on the new App ID), which can be added later if
forgotten.

**The point of no return is deleting the old app from the watch** — that
destroys the old container, and no entitlement recovers it. Keep the old app
installed until the hand-off has run.

If declined, the wearer's creature dies with the old bundle id and Stepkin
hatches a fresh egg — which has its own merit, since a virgin install is the
only way to test hatching, onboarding and the first evolution before
submitting. Decide deliberately rather than discovering it on launch day.

### 4. Package extraction

Move code in dependency order, compiling after each package:

1. `StepkinCore` — `Tagged`, `TickMath`, `TimeConstants`, logging, extensions
2. `StepkinEngine` — models, simulation, actions, evolution, battle,
   persistence DTO. **This package does not set MainActor default isolation**,
   so every explicit `nonisolated` marking on engine types can come off — the
   package boundary now enforces what the keyword was asserting by hand.
3. `StepkinSprites` — frames, animator, catalog, the per-species art
4. `StepkinUI` — presenters, view models, LCD canvas, screens, components

Engine and Core tests move with their packages and run via `swift test` — no
simulator, no scheme, seconds rather than half a minute. Only the presenter,
store, and UI tests stay in the app target.

### 5. Thin the app shells

`Apps/WatchApp` keeps only the entry point, dependency wiring, and the
platform shims (haptics, `WKApplicationRefreshBackgroundTask`, HealthKit and
WeatherKit providers). `Apps/WatchWidgets` keeps the complication.

### 6. Fresh history

`git init` in the new location, one commit, no `imon` anywhere in it — verify
with `git log -p | grep -i imon` returning nothing. The user creates the
GitHub remote and pushes. `docs/DOCUMENTATION.md`, `docs/roadmap.md`, this
plan, `Tools/`, and the README travel along.

## Known risks

- **Provisioning**: new App IDs mean new profiles. HealthKit, WeatherKit, App
  Groups and notifications must all be re-granted on the device — expect the
  first device run to prompt afresh.
- **WeatherKit propagation** is not instant after enabling the capability;
  a release build may show no weather for a while. In DEBUG a sample snapshot
  stands in, which can mask it.
- **The complication's bundle id** must remain nested under the watch app's,
  or the extension will not load.
- **Do not rename the `PetStateDTO` fields** during any of this. The DTO is
  the one thing the hand-off depends on being byte-compatible.
