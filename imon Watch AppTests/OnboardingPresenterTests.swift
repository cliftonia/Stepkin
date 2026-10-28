import Foundation
import Testing
@testable import imon_Watch_App

@Suite("OnboardingPresenter") @MainActor struct OnboardingPresenterTests {
    @Test func `advancing steps one tip at a time and completes once on the last`() {
        var completions = 0
        let presenter = OnboardingPresenter(onComplete: { completions += 1 })
        let lastIndex = OnboardingTip.walkthrough.count - 1
        #expect(presenter.spriteAnimator.isPlaying)

        for expected in 1...lastIndex {
            presenter.advanceAction()
            #expect(presenter.viewModel.index == expected)
            #expect(completions == 0)
        }
        #expect(presenter.viewModel.isLastStep)

        presenter.advanceAction()
        #expect(completions == 1)
        #expect(!presenter.spriteAnimator.isPlaying)
        #expect(presenter.viewModel.index == lastIndex)
    }

    @Test func `the first tip is not the last step`() {
        let presenter = OnboardingPresenter(onComplete: {})
        #expect(presenter.viewModel.index == 0)
        #expect(!presenter.viewModel.isLastStep)
    }

    @Test func `skipping completes once and stops the animator`() {
        var completions = 0
        let presenter = OnboardingPresenter(onComplete: { completions += 1 })
        presenter.skipAction()
        #expect(completions == 1)
        #expect(!presenter.spriteAnimator.isPlaying)
    }
}
