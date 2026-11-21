import Testing
import Foundation
@testable import Stepkin_Watch_App

// Covers the tiebreaker and outcome reporting: the sole conversion point
// from battle HP state to the persisted win/loss record (via `onComplete`).
// `runImpact`'s per-round HP mutation is private and driven by the async
// animation ceremony, so it stays untested until the deltas are extracted.
@Suite("BattlePresenter tiebreaker and outcome reporting")
@MainActor
struct BattlePresenterRoundsTests {

    /// Captures every result the presenter reports through `onComplete`.
    private final class ResultBox: @unchecked Sendable {
        var results: [BattleResult] = []
    }

    private func makePresenter(
        petHP: Int,
        opponentHP: Int,
        hasOpponent: Bool = true,
        box: ResultBox
    ) -> BattlePresenter {
        let state = makeTestState()
        let presenter = BattlePresenter(petState: state, steps: nil) {
            box.results.append($0)
        }
        if hasOpponent {
            presenter.opponent = BattleOpponent.generate(matching: state)
        }
        presenter.viewModel.petHP = petHP
        presenter.viewModel.opponentHP = opponentHP
        return presenter
    }

    // MARK: - Tiebreaker

    @Test(arguments: [
        (2, 1, BattleResult.win, BattleViewModel.BattlePhase.victory),
        (1, 2, BattleResult.lose, BattleViewModel.BattlePhase.defeat),
        (1, 1, BattleResult.draw, BattleViewModel.BattlePhase.victory),
        (0, 0, BattleResult.draw, BattleViewModel.BattlePhase.victory)
    ])
    func `tiebreaker maps remaining HP to the reported outcome`(
        petHP: Int,
        opponentHP: Int,
        expected: BattleResult,
        expectedPhase: BattleViewModel.BattlePhase
    ) {
        let box = ResultBox()
        let presenter = makePresenter(
            petHP: petHP, opponentHP: opponentHP, box: box
        )

        presenter.resolveTiebreaker()

        #expect(presenter.viewModel.result == expected)
        #expect(presenter.viewModel.phase == expectedPhase)
        #expect(box.results == [expected])
    }

    @Test
    func `losing tiebreaker without an opponent never reports an outcome`() {
        // showDefeat guards on a non-nil opponent, so a battle resolved
        // before the opponent exists silently drops the outcome.
        let box = ResultBox()
        let presenter = makePresenter(
            petHP: 1, opponentHP: 2, hasOpponent: false, box: box
        )

        presenter.resolveTiebreaker()

        #expect(presenter.viewModel.result == nil)
        #expect(box.results.isEmpty)
    }

    // MARK: - Outcome reporting

    @Test
    func `knockout victory reports a win exactly once`() {
        let box = ResultBox()
        let presenter = makePresenter(petHP: 2, opponentHP: 0, box: box)

        presenter.showVictory()

        #expect(presenter.viewModel.result == .win)
        #expect(presenter.viewModel.phase == .victory)
        #expect(box.results == [.win])
    }

    @Test
    func `knockout defeat reports a loss exactly once`() {
        let box = ResultBox()
        let presenter = makePresenter(petHP: 0, opponentHP: 2, box: box)

        presenter.showDefeat()

        #expect(presenter.viewModel.result == .lose)
        #expect(presenter.viewModel.phase == .defeat)
        #expect(box.results == [.lose])
    }
}
