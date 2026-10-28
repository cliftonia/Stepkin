import Foundation
import WatchKit

/// Feeding and cleaning ceremonies for `PetPresenter`.
///
/// A ceremony plays as the view model's single `activity`, blocking input
/// while it runs; the multi-stage sequences are split into phase helpers so
/// each stage's sprites, haptics and pause stay together.
extension PetPresenter {

    // MARK: - Feeding (Inline LCD Ceremony)

    /// Opens food selection for the feeding ceremony, or plays `refuse()`
    /// when `FeedAction.canFeed` fails.
    func startFeeding() {
        guard FeedAction.canFeed(state) else {
            refuse()
            return
        }
        viewModel.activity = .feeding(.selecting)
    }

    /// Feeds the selected food and starts the feeding sequence. Does nothing
    /// unless the ceremony is `.selecting`, cancels the ceremony when
    /// `FeedAction.canFeed` fails, and refuses a food the pet is already
    /// sated on rather than overfeeding.
    func selectAndFeed(_ food: FeedAction.FoodKind) {
        guard viewModel.feedingPhase == .selecting else { return }
        guard FeedAction.canFeed(state) else {
            WKInterfaceDevice.rejectHaptic()
            cancelActivity()
            return
        }
        guard !FeedAction.isSated(state, food: food) else {
            refuse()
            return
        }
        viewModel.selectedFood = food
        WKInterfaceDevice.buttonHaptic()
        startActivity { await $0.runFeedingSequence() }
    }

    // MARK: - Feeding Sequence

    /// Runs the serving, bite and satisfaction stages in order, dropping the
    /// remaining stages when the task is cancelled between them; only the
    /// final stage applies the feed and saves. Returns whether it got that
    /// far, so a routed feed can tell a fed pet from a cancelled ceremony.
    @discardableResult
    func runFeedingSequence() async -> Bool {
        let food = viewModel.selectedFood
        await runServingPhase(food: food)
        guard !Task.isCancelled else { return false }
        await runBitePhase(food: food)
        guard !Task.isCancelled else { return false }
        await runSatisfactionPhase(food: food)
        return true
    }

    private func runServingPhase(
        food: FeedAction.FoodKind
    ) async {
        viewModel.activity = .feeding(.serving)
        let servingAnim = food == .meat
            ? SharedSprites.meatServing
            : SharedSprites.vitaminServing
        feedingAnimator.play(servingAnim)

        let idle = SpriteCatalog.animation(for: state.species, kind: .idle)
        spriteAnimator.play(idle.facing(.left))

        _ = await pause(ms: 800)
    }

    private func runBitePhase(
        food: FeedAction.FoodKind
    ) async {
        let foodStages: [SpriteFrame] = food == .meat
            ? [SharedSprites.meatBite1, SharedSprites.meatBite2,
               SharedSprites.meatBone]
            : [SharedSprites.vitaminBite1, SharedSprites.vitaminBite2,
               SharedSprites.vitaminEmpty]

        let chomp = SpriteCatalog.animation(
            for: state.species, kind: .eat
        ).facing(.left)

        for (index, stage) in foodStages.enumerated() {
            viewModel.activity = .feeding(.bite(index + 1))
            spriteAnimator.play(chomp)
            guard await pause(ms: 300) else { return }

            feedingAnimator.play(.still(stage))
            WKInterfaceDevice.chompHaptic()
            guard await pause(ms: 400) else { return }
        }
    }

    private func runSatisfactionPhase(
        food: FeedAction.FoodKind
    ) async {
        viewModel.activity = .feeding(.satisfied)
        feedingAnimator.play(.still(SharedSprites.satisfactionHeart))
        let happy = SpriteCatalog.animation(
            for: state.species, kind: .happy
        ).facing(.left)
        spriteAnimator.play(happy)
        WKInterfaceDevice.feedHaptic()

        state = FeedAction.apply(to: state, food: food, at: .now)
        updateViewModel()
        save()

        guard await pause(ms: 1000) else { return }

        endActivity()
    }

    // MARK: - Clean

    /// Runs the cleaning ceremony, ignoring the call while another activity
    /// is in flight and refusing when `CleanAction.canClean` fails.
    func cleanAction() {
        guard !viewModel.isBusy else { return }
        guard CleanAction.canClean(state) else {
            refuse()
            return
        }
        startActivity { await $0.runCleaningSequence() }
    }

    /// Plays the water drops, applies the clean and saves, then ends on the
    /// sparkle; a cancellation at either pause abandons the rest.
    func runCleaningSequence() async {
        viewModel.activity = .cleaning

        feedingAnimator.play(SharedSprites.waterDrops)
        WKInterfaceDevice.cleanHaptic()

        guard await pause(ms: 1200) else { return }

        state = CleanAction.apply(to: state, at: .now)
        updateViewModel()
        save()

        feedingAnimator.play(SharedSprites.cleanSparkle)

        guard await pause(ms: 800) else { return }

        endActivity()
    }
}
