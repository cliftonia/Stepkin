import SwiftUI
import WatchKit

/// The pet's home screen, showing the LCD display, menu icon row and A/B/C
/// buttons. Binds `PetPresenter`: the digital crown drives menu selection and
/// the game loop runs only while the screen is visible. Swaps to training or
/// battle layout when the presenter's screen mode leaves normal play.
struct PetScreen: View {

    /// The presenter the view delegates to; it drives menu selection and the game loop.
    let presenter: PetPresenter
    // Not private — the `+Actions` extension reads it for menu navigation.
    @Environment(AppPresenter.self) var appPresenter
    @Environment(\.scenePhase) private var scenePhase
    @State private var crownValue: Double = 0

    private var screenMode: PetViewModel.ScreenMode {
        presenter.viewModel.screenMode
    }

    var body: some View {
        screenContent
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .focusable()
            .digitalCrownRotation(
                $crownValue,
                from: 0,
                through: 7,
                by: 1,
                sensitivity: .medium,
                isContinuous: false
            )
            .onChange(of: crownValue) { _, newValue in
                presenter.selectMenu(crownValue: newValue)
            }
            .onChange(of: presenter.viewModel.menuSelection) { _, newValue in
                crownValue = Double(newValue.rawValue)
            }
            .task {
                presenter.startGameLoop()
                refreshEnabledIntegrations()
            }
            .onChange(of: scenePhase) { _, newPhase in
                presenter.handleScenePhase(
                    isActive: newPhase == .active,
                    notificationsEnabled: appPresenter.settings.notificationsEnabled
                )
                if newPhase == .active {
                    refreshEnabledIntegrations()
                }
            }
            .onChange(of: appPresenter.weatherStore.snapshot) { _, _ in
                presenter.environmentDidChange()
            }
            .onDisappear {
                presenter.stopGameLoop()
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(presenter.viewModel.accessibilityDescription)
    }

    // MARK: - Weather

    private func refreshEnabledIntegrations() {
        if appPresenter.settings.weatherEnabled {
            appPresenter.weatherStore.refreshIfStale()
        }
        if appPresenter.settings.stepsEnabled {
            appPresenter.stepActivityStore.refreshIfStale()
        }
    }

    @ViewBuilder
    private var weatherHeader: some View {
        HStack(spacing: 0) {
            if appPresenter.settings.weatherEnabled,
               let snapshot = appPresenter.weatherStore.displaySnapshot {
                WeatherOverlay(snapshot: snapshot)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        // Reserve the top-right for the system clock (which can't be hidden).
        .padding(.trailing, 58)
        .frame(height: 18)
    }

    // MARK: - Debug Menu

    @ViewBuilder
    private var debugNameOverlay: some View {
        #if DEBUG
        if let species = presenter.viewModel.status?.species {
            HStack(spacing: 4) {
                if let snapshot = appPresenter.weatherStore.displaySnapshot {
                    SpriteView(
                        frame: WeatherIconMapper.frame(
                            for: snapshot.condition,
                            isDaylight: snapshot.isDaylight
                        ),
                        pixelSize: 0.75,
                        pixelColor: .white
                    )
                    Text("|")
                        .font(.lcd(9, weight: .bold))
                        .foregroundStyle(.yellow.opacity(0.4))
                }
                Text(species.displayName)
                    .font(.lcd(9, weight: .bold))
                    .foregroundStyle(.yellow)
                if !presenter.viewModel.debugNotice.isEmpty {
                    Text(presenter.viewModel.debugNotice)
                        .font(.lcd(9, weight: .bold))
                        .foregroundStyle(.cyan)
                }
            }
            .accessibilityHidden(true)
        }
        #endif
    }

    // MARK: - Debug Long-Press Actions

    private var debugWeatherCycle: (() -> Void)? {
        #if DEBUG
        { appPresenter.weatherStore.cycleDebugCondition() }
        #else
        nil
        #endif
    }

    private var debugEvolveAction: (() -> Void)? {
        #if DEBUG
        { presenter.debugEvolve() }
        #else
        nil
        #endif
    }

    private var debugCareAction: (() -> Void)? {
        #if DEBUG
        { presenter.debugCareTest() }
        #else
        nil
        #endif
    }

    // MARK: - Screen Content

    @ViewBuilder
    private var screenContent: some View {
        switch screenMode {
        case .normal:
            normalLayout
        case .training:
            GameModeLayout {
                trainingLCD
            } info: {
                trainingInfoRow
            } buttons: {
                trainingButtons
            }
        case .battle:
            GameModeLayout {
                battleLCD
            } info: {
                battleInfoRow
            } buttons: {
                battleButtons
            }
        }
    }

    // MARK: - Normal Layout

    private var normalLayout: some View {
        GameModeLayout(
            header: weatherHeader,
            evolutionProgress: presenter.viewModel.evolutionProgress,
            dayPhase: presenter.viewModel.dayPhase
        ) {
            LCDDisplay(configuration: LCDDisplayConfiguration(
                leftSprite: presenter.spriteAnimator.currentFrame,
                rightSprite: effectRightSprite,
                poopCount: presenter.viewModel.isInActionScene
                    ? 0
                    : presenter.viewModel.status?.poopCount ?? 0,
                stinkPhase: presenter.spriteAnimator.currentFrameIndex,
                lightsOn: homeScene.lightsOn,
                leftSpriteOffsetX: presenter.wander.offsetX,
                weatherCondition: homeScene.weather,
                moonPhase: presenter.viewModel.moonPhase,
                dayPhase: homeScene.dayPhase,
                evolveFlash: presenter.viewModel.isEvolving,
                showCallSign: !presenter.viewModel.isInActionScene
                    && presenter.viewModel.status?.isDrooping == true
            ))
        } info: {
            MenuIconRow(
                selectedIndex: presenter.viewModel
                    .menuSelection.rawValue
            )
        } buttons: {
            VStack(spacing: 2) {
                normalButtons
                debugNameOverlay
            }
        }
    }

    // MARK: - Normal Buttons

    private var normalButtons: some View {
        HStack(spacing: 4) {
            ActionButton(
                label: buttonALabel, accessibilityLabel: buttonAAccessibilityLabel,
                longPressAction: debugWeatherCycle
            ) {
                handleButtonA()
            }
            ActionButton(
                label: buttonBLabel, accessibilityLabel: buttonBAccessibilityLabel,
                longPressAction: debugEvolveAction
            ) {
                handleButtonB()
            }
            ActionButton(
                label: buttonCLabel, accessibilityLabel: buttonCAccessibilityLabel,
                longPressAction: debugCareAction
            ) {
                handleButtonC()
            }
        }
    }

}
