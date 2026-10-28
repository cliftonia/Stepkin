import Foundation
import WatchKit

/// The seam between the app's intents and the pet. Intents for a watch-only
/// app run in the app process, so the defaults reach the `AppDelegate` that
/// owns the presenter and the save; tests replace the two closures.
@MainActor
enum IntentGateway {

    /// Routes an action to the pet and reports the outcome; defaults to the
    /// delegate's `PetActionRouter` path with no refresh scheduler.
    static var route: @MainActor (PetAction) async -> PetActionOutcome = { action in
        guard let delegate = WKApplication.shared().delegate as? AppDelegate else { return .noPet }
        let app = delegate.appPresenter
        let offline = app.offlineDependencies(
            witnesses: CareHandoff.Witnesses(notifications: .live(), complications: .live()),
            refresh: nil
        )
        return await PetActionRouter.perform(action, app: app, offline: offline, now: Date())
    }

    /// The pet's spoken sentence, or nil when there is no pet; defaults to a
    /// tick through `route` (so the single writer advances and saves the pet
    /// first), then the live presenter's status, else the freshly saved state.
    static var describe: @MainActor () async -> String? = {
        await sentence(after: route, reading: currentStatus)
    }

    /// Ticks the pet through `route`, then speaks the status `status` reads;
    /// the order matters, since a suspended app's last status is stale.
    static func sentence(
        after route: @MainActor (PetAction) async -> PetActionOutcome,
        reading status: @MainActor () -> PetStatus?
    ) async -> String? {
        _ = await route(.tick)
        return status().map { PetStatusSentence.describe($0) }
    }

    /// The live presenter's status, else the save's read through the
    /// delegate's store; nil without a delegate, a save or a hatched pet.
    private static func currentStatus() -> PetStatus? {
        guard let delegate = WKApplication.shared().delegate as? AppDelegate else { return nil }
        let app = delegate.appPresenter
        if let status = app.petPresenter?.viewModel.status {
            return status
        }
        let offline = app.offlineDependencies(
            witnesses: CareHandoff.Witnesses(notifications: .live(), complications: .live()),
            refresh: nil
        )
        guard let saved = try? offline.store.load(), !saved.isEgg else { return nil }
        return PetStatus(from: saved)
    }
}
