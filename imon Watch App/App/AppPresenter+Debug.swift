#if DEBUG
import Foundation

extension AppPresenter {

    /// The DEBUG-only settings actions. Each pops to the pet screen first so
    /// its effect is visible at once; killing the pet routes through `restartPet`.
    func makeDebugActions() -> SettingsDebugActions {
        SettingsDebugActions(
            setWeather: { [weak self, weatherStore] condition in
                self?.router.popToRoot()
                weatherStore.setDebugCondition(condition)
            },
            forceEvolve: { [weak self] in self?.router.popToRoot(); self?.petPresenter?.debugEvolve() },
            careTest: { [weak self] in self?.router.popToRoot(); self?.petPresenter?.debugCareTest() },
            killPet: { [weak self] in self?.restartPet() },
            morph: { [weak self] species in
                self?.router.popToRoot()
                self?.petPresenter?.debugMorph(into: species)
            }
        )
    }
}
#endif
