# Release roadmap

The campaign plan for shipping this app to the App Store, and what follows it.
This document carries over to the new repository and is the single place the
plan lives; update it as epics close or decisions land.

## Vision

Ship the watch virtual pet to the App Store under a new name. Then bring the
same pet to iPhone and iPad as companions that stay **in sync with the watch**
— one creature, every screen. The watch remains the primary home: it is where
the steps are counted and the wrist is raised.

## Decisions made

- **Fresh repository, no history**, founded early rather than last — the
  rename is now also a restructure, so it happens once.
- **Architecture**: MVVMP retained; layers become compiler-enforced by moving
  to a workspace of thin app shells over local Swift packages (below).
- **Watch launch is not gated** on the iPhone/iPad work. Ship the wrist,
  then annex the pocket.
- **The name: Stepkin** (decided 2026-07-19, lowercase k like Skykin before
  it). It names the differentiating mechanic — steps feed evolution — and
  keeps the `-kin` species family. Search-clear; the nearest neighbour,
  StepKing (a three-rating step-alert utility, different category), was
  assessed and accepted. Bundle id root `cliftonia.stepkin`, App Group
  `group.cliftonia.stepkin`, watch app `cliftonia.stepkin.watchkitapp`,
  complication `cliftonia.stepkin.watchkitapp.StepkinComplication` (the
  extension's suffix is its **target name** — today's is
  `…watchkitapp.SkykinComplication`). Verified against the current project:
  the root id belongs to the `watchapp2-container` stub, which carries no
  entitlements and is the id the App Store Connect record uses; the watch
  app holds HealthKit + WeatherKit + App Groups; the complication holds App
  Groups only. Epic 6 replaces that stub with the real iPhone/iPad target in
  the **same app record** — ids never change. Note App Store Connect offers
  no watchOS platform: a watch-only app is created as an **iOS** record
  against the container id, and the store lists it under Apple Watch apps by
  virtue of `WKWatchOnly`. That makes Epic 6 a target swap inside the
  existing record rather than a new listing. USPTO checked 2026-07-19: zero filings for
  "stepkin", live or dead. Fallbacks if the App Store Connect reservation
  surprises us: Wristkin, Hatchkin, Wanderkin (all verified clear
  2026-07-19).

## Decisions pending

- ~~**The pet hand-off.**~~ Decided 2026-09-09: no hand-off. The new
  identifiers hatch a fresh egg, which is also the only way to test
  hatching, onboarding and the first evolution before review.
- **Sync transport** (Epic 6): `NSUbiquitousKeyValueStore` (the DTO is tiny
  JSON, well under the 1 MB cap) vs CloudKit (more machinery, more control).
  Decide when the epic opens; the founding only needs to keep the DTO the
  single serialized form so either transport carries it unchanged.

## Target architecture

Decided 2026-10-28: one local package beside the app, done in place.

```
imon.xcodeproj
├── imon Watch App/        presentation, stores, providers, the sprite
│                          animator, CareHandoff, complication store, tick
├── SkykinComplication/    complication extension
├── Packages/StepkinKit/
│   ├── StepkinCore        Tagged, TickMath, TimeConstants, logging → deps: none
│   ├── StepkinEngine      models, simulation, actions, evolution,
│   │                      battle, persistence DTO                  → deps: Core
│   ├── StepkinSprites     frames, catalog, shared art              → deps: Core, Engine
│   └── StepkinTestSupport shared test fixtures
├── Tools/                 sprite round-trip pipeline
└── docs/                  this file, DOCUMENTATION.md
```

Why: the package cannot import WatchKit or SwiftUI (layer purity by the
compiler); package tests run via bare `swift test` with no simulator; the
package skips MainActor default isolation so the explicit `nonisolated`
markings disappear. The UI package was dropped: a package's platforms are
declared once and the UI imports WatchKit, so the presentation layer stays
in the app until a second platform needs it (Epic 6).

## Sync model (Epic 6 groundwork)

The engine is already shaped for sync. State is a value advanced by
`GameEngine.advance(state, to: .now)`, and the save is a flat versioned
`PetStateDTO`. Sync is therefore: ship the DTO, take the record with the
newest timestamp, and let the engine's catch-up replay close any gap — the
same mechanism that already handles the app being closed for eight hours.
No merge logic, no CRDTs. iPad note: HealthKit exists on iPadOS and step
data arrives via iCloud Health sync, so the loop works there too.

## Epic order

| # | Epic | Where | Why this position |
|---|------|-------|-------------------|
| 0 | ✅ **Done 2026-07-19** — name locked, USPTO clear, ids + App Group registered, ASC record created (iOS record, *Prepare for Submission*, no build) | — | Blocks package naming; the name can be taken while we wait |
| 1 | ✅ **Done 2026-07-19** — rollover tail recovered, collapse countdown dated from the true emptying (schema v3), v2-save migration proved, night reminders deferred not dropped, STEPS row relabelled TODAY. The "5k vs 75" report resolved as a label misreading: the app's own arithmetic checks out (today 4,015 − lifetime 2,537 = the 1,478 baseline at first credit); pending a Health-app cross-check | old repo | These change the persisted schema — settle it **before** the migration so the save format moves once |
| 2 | ✅ **Done 2026-10-28** — in place, no fresh repository; `StepkinKit` with Core, Engine, Sprites and a test-support target; presentation stays in the app | this repo | Everything after lands in the new home |
| 3 | Deferred polish: defer-night-notifications, lifecycle items, debug-only items | new repo | No schema impact; benefits from the fast package test loop |
| 4 | Sprite treatment for Hopkin, Dotkin, Orbkin, Marshkin | new repo | Zero dependencies — runs parallel to Epic 3 |
| 5 | Watch submission: WeatherKit provisioning on the new App ID, privacy strings, icon, screenshots, TestFlight, App Review. **Code side done 2026-09-08** (privacy manifests, attribution, permission timing, sleep-pause and save-backup fixes — see `release-checklist.md`); the identifier swap and the App Store Connect work remain | new repo | Last, because every prior epic changes what the reviewer sees |
| 6 | Sync + iPhone/iPad shells: transport decision, `iOSApp` target, platform shims (haptics, `BGTaskScheduler`), home-screen widget | new repo | Post-launch (v1.x); the packages make it thin-shell work |

Epics 3 and 4 run in parallel; everything else is a chain.

**Shortcut taken 2026-09-08:** the release audit was done in this repository
rather than after Epic 2. If shipping soon matters more than the package
restructure, Epic 2 can shrink to the identity rename alone (migration-plan
§ 1–3) and the package extraction can follow the launch — the code does not
need it to pass review.

## Standing risks

- **WeatherKit** needs the capability provisioned on the new App ID before
  release builds show live weather.
- **App Review**: HealthKit and notification usage strings must honestly
  describe the game loop; virtual-pet death mechanics are fine, but the
  metadata must not lean on trademarked franchises.
- **The stranded pet**: without the hand-off, launch day orphans the
  developer's own longest-lived creature. Decide with a clear heart.
