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

    /// The pet's spoken sentence, or nil when there is no pet; defaults to the
    /// live presenter's status, else the save read through the delegate's store.
    static var describe: @MainActor () async -> String? = {
        guard let delegate = WKApplication.shared().delegate as? AppDelegate else { return nil }
        let app = delegate.appPresenter
        if let status = app.petPresenter?.viewModel.status {
            return PetStatusSentence.describe(status)
        }
        let offline = app.offlineDependencies(
            witnesses: CareHandoff.Witnesses(notifications: .live(), complications: .live()),
            refresh: nil
        )
        guard let saved = try? offline.store.load(), !saved.isEgg else { return nil }
        return PetStatusSentence.describe(PetStatus(from: saved))
    }
}
