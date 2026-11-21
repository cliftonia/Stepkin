import SwiftUI

/// The Settings screen: a list of toggles bound directly to the
/// `SettingsPresenter`'s settings, plus the About section and a DEBUG-only
/// debug menu.
struct SettingsScreen: View {

    /// Owns the settings the toggles bind to, the About version label, and
    /// the debug actions.
    let presenter: SettingsPresenter

    var body: some View {
        @Bindable var settings = presenter.settings
        List {
            Section("Display") {
                Toggle("Battery saver", isOn: $settings.batterySaverEnabled)
            }
            Section {
                Toggle("Notifications", isOn: $settings.notificationsEnabled)
                Toggle("Weather", isOn: $settings.weatherEnabled)
                Toggle("Steps", isOn: $settings.stepsEnabled)
                Toggle("Haptics", isOn: $settings.hapticsEnabled)
            } header: {
                Text("Features")
            } footer: {
                Text("Your steps grow your pet. With Steps off it grows with time instead. If you declined Health access, switch Steps off.")
            }
            aboutSection
            #if DEBUG
            debugSection
            #endif
        }
        .navigationTitle("Settings")
    }

    // MARK: - About

    /// Version and the attribution WeatherKit's terms require wherever Apple
    /// Weather data is shown.
    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: presenter.versionLabel)
            if let url = WeatherAttribution.legalPageURL {
                Link(destination: url) {
                    Label("Weather data by Apple Weather", systemImage: "apple.logo")
                }
                .accessibilityLabel("Weather data by Apple Weather. Opens the attribution page.")
            }
        }
    }

    #if DEBUG
    @ViewBuilder
    private var debugSection: some View {
        Section("Debug") {
            Button("Force evolve") { presenter.debug.forceEvolve() }
            Button("Drain + care test") { presenter.debug.careTest() }
            Button("Kill pet", role: .destructive) { presenter.debug.killPet() }
        }
        Section("Weather") {
            ForEach(WeatherIconCondition.allCases) { condition in
                Button(condition.displayName) { presenter.debug.setWeather(condition) }
            }
            Button("Real weather") { presenter.debug.setWeather(nil) }
        }
        Section("Morph into") {
            ForEach(PetSpecies.allCases) { species in
                Button(species.displayName) { presenter.debug.morph(species) }
            }
        }
    }
    #endif
}
