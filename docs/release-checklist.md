# Release checklist

What stands between the current tree and a build in App Review, written after
the September 2026 release audit. Items are grouped by who can do them: the
code is done; the identifier decision and the App Store Connect work are the
developer's.

## Done in the audit pass (2026-09-08)

- `PrivacyInfo.xcprivacy` in the watch app and the complication extension,
  declaring the UserDefaults required-reason API (CA92.1), no tracking, no
  collected data. Without it App Store Connect refuses the upload (ITMS-91053).
- The complication extension's deployment target lowered to 26.2 to match the
  app — an extension may not require a newer OS than its container.
- Display names and the complication's picker name changed to **Stepkin**;
  the complication's `kind` string is unchanged so placed complications
  survive an update.
- Apple Weather attribution and a version row under Settings → About, as the
  WeatherKit terms require wherever Apple Weather data is shown.
- Permission prompts (HealthKit, notifications) moved from the first frame of
  a fresh install to the moment the pet is alive — after the walkthrough that
  explains what steps and reminders are for. A freshly granted permission
  re-reads today's steps at once.
- Sleep is now a pause: waking re-anchors the hunger, strength and poop
  clocks, so the pet no longer wakes starved and injured after every night.
- The save keeps one backup copy; a torn or undecodable write falls back to
  the previous good save instead of hatching a new egg over a months-old pet.
- A dead pet can no longer evolve on the grave tick; leaving the pet screen
  stops the wander and sprite timers; the multi-day step catch-up is bounded
  by days rather than by successful fetches.
- With the Steps switch off the pet evolves through time (500 step-equivalents
  per waking hour); Stats names the battle gate when fighting is the only way
  forward, and the Settings footer explains the two sources.
- VoiceOver: the three buttons announce what they do; the home screen reads
  the pet's condition.
- Build warning-free, SwiftLint clean, 437 tests green (package 305, app 132).

## Decide before the upload (developer)

1. **Bundle identifiers — done 2026-09-09.** The project now builds
   `cliftonia.stepkin`, `cliftonia.stepkin.watchkitapp` and
   `…watchkitapp.SkykinComplication`, with App Group
   `group.cliftonia.stepkin`, matching the App Store Connect record. The
   decision was a fresh egg: no hand-off, and the pet under the old
   identifiers stays on the wrist until the old app is deleted. The
   UserDefaults keys (`com.cliftonia.imon.petState`, `.backup`,
   `.complicationTimeline`) were deliberately kept.
2. **Provisioning on the new App ID.** HealthKit, HealthKit Background
   Delivery, WeatherKit, App Groups and the notification capability must be
   ticked on `cliftonia.stepkin.watchkitapp` in the developer portal;
   WeatherKit takes time to propagate, so the first TestFlight build may show
   no weather. The simulator cannot exercise background delivery, so test it
   on the watch; it shares the four-wakes-per-hour budget with the refresh
   chain. Delivery starts at launch when Steps is on, so switching Steps on
   takes effect at the next launch.
3. **Export compliance.** The app uses only Apple's TLS. Set the
   "App Encryption Documentation" answer once in App Store Connect (or add
   `ITSAppUsesNonExemptEncryption = NO` to the Info tab of both targets) so
   every build is not held for the question.

## App Store Connect (developer)

- Privacy policy URL (required for every app; HealthKit makes it mandatory).
  A one-page statement that nothing leaves the device suffices.
- Privacy nutrition labels: Health & Fitness → not collected (data never
  leaves the device); Location → not collected. Declare "Data Not Collected".
- Screenshots from the largest simulator (Ultra 3 49mm, `xcrun simctl io
  booted screenshot`) — one set covers all watch sizes.
- Age rating questionnaire: infrequent mild cartoon violence (training and
  battles), no other flags. The pet's death is fine; do not mention any
  trademarked franchise in the name, subtitle, keywords or description.
- Review notes: explain that HealthKit steps drive evolution and can be
  declined (the pet then grows with time), that HealthKit background delivery
  needs its capability and can be declined, that Siri answers "Feed Stepkin"
  and "Check on Stepkin", that the Smart Stack relevance is passive, that
  weather needs location and can be declined, and that the reviewer can reach
  every screen without granting anything.
- TestFlight on the physical watch for at least one full day/night cycle
  before submitting — the sleep-pause change and the permission timing are
  the two behaviours that cannot be judged in the simulator.

## Known and accepted for 1.0

- The care-reminder replan and complication reload run on every wrist-down
  (`.inactive`); WidgetKit's reload budget may throttle some of them.
- The DEBUG build shows a sample weather reading; Release shows nothing until
  WeatherKit is provisioned and location granted.
