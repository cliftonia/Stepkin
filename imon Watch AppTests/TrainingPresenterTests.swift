import Testing
import Foundation
@testable import imon_Watch_App

// Covers the synchronous surface of the best-of-5 training session:
// session reset, the challenge-phase guard, and win/loss round recording.
// The outcome thresholds in the private `advanceOrComplete()` are reachable
// only through chained `Task.sleep` phase timers, so they stay untested
// until that decision is extracted into a pure helper.
@Suite("TrainingPresenter session state machine")
@MainActor
struct TrainingPresenterTests {

    /// Captures every session outcome the presenter reports on completion.
    private final class OutcomeBox: @unchecked Sendable {
        var outcomes: [Bool] = []
    }

    private func makePresenter(_ box: OutcomeBox) -> TrainingPresenter {
        TrainingPresenter(species: .emberkin) { box.outcomes.append($0) }
    }

    // MARK: - startTraining

    @Test
    func `starting training resets a stale session to a fresh ready round`() {
        let box = OutcomeBox()
        let presenter = makePresenter(box)
        presenter.viewModel.phase = .defeat
        presenter.viewModel.roundResults = (0..<3).map {
            TrainingViewModel.RoundResult(id: $0, won: false)
        }
        presenter.viewModel.showingNumber = true

        presenter.startTraining()

        #expect(presenter.viewModel.phase == .ready)
        #expect(presenter.viewModel.roundResults.isEmpty)
        #expect(presenter.viewModel.showingNumber == false)
        #expect(presenter.viewModel.currentRound == 0)
        #expect((1...9).contains(presenter.viewModel.currentNumber))
        #expect(presenter.viewModel.currentNumber != 5)
        #expect(box.outcomes.isEmpty)
        presenter.cancel()
    }

    // MARK: - guessAction guard

    @Test(arguments: [
        TrainingViewModel.TrainingPhase.ready,
        .attacking,
        .projectile,
        .hit,
        .miss,
        .victory,
        .defeat
    ])
    func `guessing outside the challenge phase is a no-op`(
        phase: TrainingViewModel.TrainingPhase
    ) {
        let box = OutcomeBox()
        let presenter = makePresenter(box)
        presenter.viewModel.phase = phase
        presenter.viewModel.currentNumber = 7

        presenter.guessAction(.high)

        #expect(presenter.viewModel.roundResults.isEmpty)
        #expect(presenter.viewModel.phase == phase)
        #expect(presenter.viewModel.showingNumber == false)
        #expect(box.outcomes.isEmpty)
        presenter.cancel()
    }

    // MARK: - Round recording

    @Test(arguments: [
        (7, TrainAction.Guess.high, true),
        (3, TrainAction.Guess.high, false),
        (3, TrainAction.Guess.low, true),
        (7, TrainAction.Guess.low, false)
    ])
    func `a challenge guess records the round result and starts the attack`(
        number: Int,
        guess: TrainAction.Guess,
        expectedWon: Bool
    ) {
        let box = OutcomeBox()
        let presenter = makePresenter(box)
        presenter.viewModel.phase = .challenge
        presenter.viewModel.currentNumber = number

        presenter.guessAction(guess)

        #expect(presenter.viewModel.roundResults == [TrainingViewModel.RoundResult(id: 0, won: expectedWon)])
        #expect(presenter.viewModel.phase == .attacking)
        #expect(presenter.viewModel.showingNumber == true)
        #expect(presenter.viewModel.lastGuessHigh == (guess == .high))
        // A single round never resolves the session.
        #expect(box.outcomes.isEmpty)
        presenter.cancel()
    }

    @Test
    func `round results accumulate wins and losses across successive challenges`() {
        let box = OutcomeBox()
        let presenter = makePresenter(box)
        let rounds: [(number: Int, guess: TrainAction.Guess)] = [
            (7, .high), (3, .high), (9, .high)
        ]

        for round in rounds {
            presenter.viewModel.phase = .challenge
            presenter.viewModel.currentNumber = round.number
            presenter.guessAction(round.guess)
        }

        #expect(presenter.viewModel.roundResults.map(\.won) == [true, false, true])
        #expect(box.outcomes.isEmpty)
        presenter.cancel()
    }
}
