import Foundation
import Testing
@testable import imon_Watch_App

@Suite("DeathPresenter") @MainActor struct DeathPresenterTests {
    @Test func `the memorial carries the fallen pet's species name and age`() {
        var state = makeTestState(species: .emberkin)
        state.age = 7
        let presenter = DeathPresenter(state: state, onRestart: {})
        #expect(presenter.configuration.speciesName == PetSpecies.emberkin.displayName)
        #expect(presenter.configuration.ageDays == 7)
    }

    @Test func `restarting calls the hand-off exactly once`() {
        var restarts = 0
        let presenter = DeathPresenter(state: makeTestState(), onRestart: { restarts += 1 })
        #expect(restarts == 0)
        presenter.restartAction()
        #expect(restarts == 1)
    }
}
