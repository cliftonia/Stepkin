import SwiftUI

// MARK: - Buttons, Effects & Menu Actions

extension PetScreen {

    // MARK: - Scene

    /// The home screen's scene: a clean booth during an action ceremony, else
    /// the full environment. `SceneResolver` owns the resolution rules.
    var homeScene: LCDScene {
        let status = presenter.viewModel.status
        let careMessPresent = status?.hasCareMess == true
        return SceneResolver.home(
            dayPhase: presenter.viewModel.dayPhase,
            lightsOn: status?.lightsOn ?? true,
            weather: appPresenter.settings.weatherEnabled
                ? appPresenter.weatherStore.displaySnapshot?.condition
                : nil,
            isInActionScene: presenter.viewModel.isInActionScene,
            careMessPresent: careMessPresent
        )
    }

    /// The battle / training arena: outdoors, lit by day and dark at night.
    var arenaScene: LCDScene {
        SceneResolver.arena(dayPhase: presenter.viewModel.dayPhase)
    }

    // MARK: - Button Labels

    var buttonALabel: String {
        presenter.viewModel.feedingPhase == .selecting ? String(localized: "MEAT", comment: "Button A label while choosing food.") : "A"
    }

    var buttonBLabel: String {
        presenter.viewModel.feedingPhase == .selecting ? String(localized: "BACK", comment: "Button B label while choosing food.") : "B"
    }

    var buttonCLabel: String {
        presenter.viewModel.feedingPhase == .selecting ? String(localized: "VITA", comment: "Button C label while choosing food; short for vitamin.") : "C"
    }

    // MARK: - Button Accessibility

    var buttonAAccessibilityLabel: String {
        presenter.viewModel.feedingPhase == .selecting
            ? String(localized: "Feed meat", comment: "VoiceOver label for button A.")
            : String(localized: "Previous menu item", comment: "VoiceOver label for button A.")
    }

    var buttonBAccessibilityLabel: String {
        if presenter.viewModel.feedingPhase == .selecting { return String(localized: "Back", comment: "VoiceOver label for button B while choosing food.") }
        if presenter.viewModel.isBusy { return String(localized: "Cancel", comment: "VoiceOver label for button B during an activity.") }
        let entry = presenter.viewModel.menuSelection.accessibilityName
        return String(localized: "Select \(entry)", comment: "VoiceOver label for button B; the argument is the menu entry.")
    }

    var buttonCAccessibilityLabel: String {
        presenter.viewModel.feedingPhase == .selecting
            ? String(localized: "Feed vitamin", comment: "VoiceOver label for button C.")
            : String(localized: "Next menu item", comment: "VoiceOver label for button C.")
    }

    // MARK: - Effect Display

    var effectRightSprite: SpriteFrame? {
        if presenter.feedingAnimator.isPlaying {
            return presenter.feedingAnimator.currentFrame
        }
        // Poop owns the right side; the skull appears only once it's cleared.
        let hasPoop = (presenter.viewModel.status?.poopCount ?? 0) > 0
        if presenter.viewModel.status?.isInjured == true, !hasPoop {
            return SharedSprites.skull
        }
        return nil
    }

    // MARK: - Button Handlers

    /// Handles the A button: a meat choice when the feeding ceremony awaits
    /// selection, otherwise the previous menu item. Ignored while an activity
    /// runs outside that selection.
    func handleButtonA() {
        guard !presenter.viewModel.isBusy
            || presenter.viewModel.feedingPhase == .selecting
        else { return }
        if presenter.viewModel.feedingPhase == .selecting {
            presenter.selectAndFeed(.meat)
        } else {
            presenter.selectPreviousMenu()
        }
    }

    /// Handles the B button: cancels the in-flight activity when one runs,
    /// otherwise executes the selected menu item.
    func handleButtonB() {
        if presenter.viewModel.isBusy {
            presenter.cancelActivity()
        } else {
            executeMenuAction()
        }
    }

    /// Handles the C button: a vitamin choice when the feeding ceremony awaits
    /// selection, otherwise the next menu item. Ignored while an activity runs
    /// outside that selection.
    func handleButtonC() {
        guard !presenter.viewModel.isBusy
            || presenter.viewModel.feedingPhase == .selecting
        else { return }
        if presenter.viewModel.feedingPhase == .selecting {
            presenter.selectAndFeed(.vitamin)
        } else {
            presenter.selectNextMenu()
        }
    }

    // MARK: - Menu Action

    /// Dispatches the highlighted menu item: navigation for stats and
    /// settings, a presenter action or ceremony for the rest.
    func executeMenuAction() {
        switch presenter.viewModel.menuSelection {
        case .stats:
            appPresenter.navigateToStats()
        case .feed:
            presenter.startFeeding()
        case .train:
            presenter.startTrainingMode()
        case .battle:
            presenter.startBattleMode()
        case .clean:
            presenter.cleanAction()
        case .lights:
            presenter.lightsAction()
        case .heal:
            presenter.healAction()
        case .settings:
            appPresenter.navigateToSettings()
        }
    }
}
