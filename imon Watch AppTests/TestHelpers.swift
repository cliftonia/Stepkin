import Foundation
@_exported import StepkinTestSupport
@testable import imon_Watch_App

/// A fixed, repeatable moment at `hour` o'clock on the same calendar day.
func today(at hour: Int) -> Date {
    let calendar = Calendar.current
    let midnight = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
    return calendar.date(byAdding: .hour, value: hour, to: midnight) ?? midnight
}

/// Builds a `PetPresenter` whose collaborators default to inert no-ops, so a test overrides only what it observes.
@MainActor
func makePetPresenter(
    state: PetState = makeTestState(),
    store: PetStateStore = PetStateStore(save: { _ in }, load: { nil }, delete: {}),
    scheduler: NotificationScheduler = NotificationScheduler(
        schedule: { _ in }, notify: { _, _, _ in }, cancelAll: {}, requestAuthorization: { true }
    ),
    reloader: ComplicationReloader = ComplicationReloader(reload: {}),
    steps: Int? = nil,
    finalSteps: Int? = nil,
    onDeath: @escaping () -> Void = {}
) -> PetPresenter {
    PetPresenter(
        state: state,
        store: store,
        currentSteps: { steps },
        finalSteps: { _ in finalSteps },
        onDeath: onDeath,
        notificationScheduler: scheduler,
        complicationReloader: reloader
    )
}
