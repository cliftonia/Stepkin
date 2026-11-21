import Foundation
import UserNotifications
import WatchKit

#if DEBUG

// MARK: - Debug Evolution

extension PetPresenter {

    /// Ordered evolution journeys walked by `debugEvolve`. The persisted
    /// `debugJourneyIndex` points into this list, so its order must stay
    /// stable across launches.
    private static let debugJourneys: [[PetSpecies]] = [
        [.dotkin, .hopkin, .emberkin, .rexkin, .steelkin],
        [.dotkin, .hopkin, .marshkin, .blazekin, .orbkin],
        [.dotkin, .hopkin, .emberkin, .dreadkin, .steelkin],
        [.dotkin, .hopkin, .emberkin, .pyrekin, .orbkin],
        [.dotkin, .hopkin, .marshkin, .galekin, .steelkin],
        [.dotkin, .hopkin, .marshkin, .tidekin, .orbkin],
        [.dotkin, .hopkin, .emberkin, .sludgekin, .plushkin]
    ]

    private static let debugJourneyKey = "debugJourneyIndex"

    private var debugJourneyIndex: Int {
        get { UserDefaults.standard.integer(forKey: Self.debugJourneyKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.debugJourneyKey) }
    }

    /// Advances one species along the current journey in `debugJourneys`,
    /// persisting the position; finishing a journey marks the pet dead so the
    /// next starts from an egg, looping back to journey 1 at the end.
    func debugEvolve() {
        guard !viewModel.isBusy else { return }

        let journeys = Self.debugJourneys
        let journey = journeys[debugJourneyIndex]

        let nextStep = debugStepIndex + 1
        if nextStep >= journey.count {
            state.isDead = true
            let next = debugJourneyIndex + 1
            debugJourneyIndex = next >= journeys.count ? 0 : next
            debugStepIndex = 0
            updateViewModel()
            save()
        } else {
            let target = journey[nextStep]
            debugStepIndex = nextStep
            beginEvolution(to: target)
        }
    }

    /// Morphs the pet straight into any species, skipping the evolution tree,
    /// so every creature's animations can be reviewed on demand.
    func debugMorph(into species: PetSpecies) {
        state = EvolutionEngine.evolve(state, to: species, at: .now)
        state.isEgg = false
        state.isDead = false
        updateViewModel()
        updateAnimation()
        save()
        WKInterfaceDevice.evolveHaptic()
    }

    /// Drains both stats to languishing so the pet visibly needs care (screen
    /// and complication flip to "hungry"), then schedules a real care reminder
    /// 12 s out to verify on-device notification delivery; foreground banners
    /// are suppressed, so the banner appears only after the wrist drops.
    func debugCareTest() {
        guard !viewModel.isBusy else { return }
        // Empty both stats so the languishing state shows at once.
        state.hungerHearts = StatHearts(0)
        state.strengthHearts = StatHearts(0)
        updateViewModel()
        updateAnimation()
        save()
        viewModel.debugNotice = "checking…"
        Task { @MainActor [weak self] in
            guard let self else { return }
            let center = UNUserNotificationCenter.current()
            var settings = await center.notificationSettings()
            // Prompt now if permission was never answered — the launch request can be missed.
            if settings.authorizationStatus == .notDetermined {
                _ = try? await center.requestAuthorization(options: [.alert, .sound])
                settings = await center.notificationSettings()
            }
            self.viewModel.debugNotice = "N:" + Self.describe(settings.authorizationStatus)
            // Unique id per press — a repeated id silently updates, showing no new banner.
            let content = UNMutableNotificationContent()
            content.title = "Care test"
            content.body = "Your pet is hungry!"
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 12, repeats: false)
            let request = UNNotificationRequest(
                identifier: "care-test-" + UUID().uuidString, content: content, trigger: trigger
            )
            try? await center.add(request)
        }
    }

    private static func describe(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized: "auth"
        case .denied: "DENIED"
        case .notDetermined: "notAsked"
        case .provisional: "provisional"
        case .ephemeral: "ephemeral"
        @unknown default: "unknown"
        }
    }
}

#endif
