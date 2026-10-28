import Testing
import Foundation
@testable import imon_Watch_App

@MainActor
@Suite("StatsPresenter mapping")
struct StatsPresenterTests {

    private func makeViewModel(
        species: PetSpecies = .emberkin,
        steps: Int? = nil,
        mutate: (inout PetState) -> Void = { _ in }
    ) -> StatsViewModel {
        var state = makeTestState(species: species)
        mutate(&state)
        let presenter = StatsPresenter()
        presenter.update(from: state, steps: steps)
        return presenter.viewModel
    }

    @Test
    func `untrained HP renders a plain value`() {
        let viewModel = makeViewModel()
        #expect(!viewModel.hpDisplay.contains("(+"))
    }

    @Test
    func `trained HP appends the bonus suffix`() {
        let viewModel = makeViewModel { $0.trainedHP = 5 }
        #expect(viewModel.hpDisplay.hasSuffix("(+5)"))
    }

    @Test
    func `missing steps render an em-dash activity label`() {
        let viewModel = makeViewModel(steps: nil)
        #expect(viewModel.activityLabel == "\u{2014}")
    }

    @Test
    func `sedentary steps read as Resting and active steps as Active`() {
        let resting = makeViewModel(steps: 1_000)
        #expect(resting.activityLabel == "1000 \u{00b7} Resting")

        let active = makeViewModel(steps: 5_000)
        #expect(active.activityLabel == "5000 \u{00b7} Active")
    }

    @Test
    func `ultimate stage shows MAX instead of an evolution goal`() {
        let viewModel = makeViewModel(species: .steelkin) {
            $0.lifetimeActiveSteps = 12_340
        }
        #expect(viewModel.evolveProgress.hasPrefix("MAX \u{00b7} "))
        #expect(!viewModel.evolveProgress.contains("/"))
    }

    @Test
    func `pre-ultimate stage shows credited steps over the goal`() {
        var goal = 0
        let viewModel = makeViewModel { state in
            state.lifetimeActiveSteps = 12_340
            goal = state.evolutionGoal
        }
        let expected = StatFormatter.grouped(12_340) + " / " + StatFormatter.grouped(goal)
        #expect(viewModel.evolveProgress == expected)
    }

    @Test
    func `with steps off the activity row says so and evolution shows credited total over goal`() {
        var state = makeTestState()
        state.lifetimeActiveSteps = 12_340
        let presenter = StatsPresenter()
        presenter.update(from: state, steps: nil, stepsEnabled: false)

        let expected = StatFormatter.grouped(12_340) + " / " + StatFormatter.grouped(state.evolutionGoal)
        #expect(presenter.viewModel.activityLabel == "Steps off")
        #expect(presenter.viewModel.evolveProgress == expected)
    }

    @Test
    func `zero battles fall back to an em-dash win rate`() {
        let viewModel = makeViewModel()
        #expect(viewModel.winRate == "\u{2014}")
    }

    @Test
    func `win rate is a whole-number percent of all battles`() {
        let viewModel = makeViewModel {
            $0.battleWins = 3
            $0.battleLosses = 1
        }
        #expect(viewModel.winRate == "75%")
    }
}
