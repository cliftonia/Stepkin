import Foundation
import Observation

/// Display state for the onboarding walkthrough, holding the current step.
///
/// An observable class so the view redraws as `index` advances through
/// `OnboardingTip.walkthrough`.
@Observable
final class OnboardingViewModel {

    /// The step currently on screen, as a zero-based subscript into `OnboardingTip.walkthrough`.
    var index: Int = 0

    var currentTip: OnboardingTip { OnboardingTip.walkthrough[index] }

    var isLastStep: Bool { index >= OnboardingTip.walkthrough.count - 1 }
}
