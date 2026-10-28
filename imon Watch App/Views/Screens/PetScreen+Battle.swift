import SwiftUI

extension PetScreen {

    // MARK: - Battle LCD

    @ViewBuilder
    var battleLCD: some View {
        if let battle = presenter.battlePresenter {
            LCDDisplay(configuration: LCDDisplayConfiguration(
                leftSprite: battle.activeFrame,
                lightsOn: arenaScene.lightsOn,
                leftSpriteOffsetX: battle.activeOffsetX,
                leftSpriteOffsetY: battleSpriteOffsetY(battle),
                stormFlash: battle.viewModel.phase == .introVS
            ))
        }
    }

    // MARK: - Battle Info Row

    @ViewBuilder
    var battleInfoRow: some View {
        if let battle = presenter.battlePresenter {
            let phaseText = battlePhaseText(battle)
            let isChoosing = phaseText.isEmpty
            ZStack {
                choosingInfoRow(battle)
                    .opacity(isChoosing ? 1 : 0)
                Text(phaseText)
                    .font(.lcd(11, weight: .bold))
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .opacity(isChoosing ? 0 : 1)
            }
        }
    }

    // MARK: - Battle Buttons

    @ViewBuilder
    var battleButtons: some View {
        if let battle = presenter.battlePresenter {
            let phase = battle.viewModel.phase
            let isChoosing = phase == .choosing
            let isComplete = phase == .victory || phase == .defeat

            ZStack {
                HStack(spacing: 4) {
                    ActionButton(label: "HIGH", accessibilityLabel: "Attack high") {
                        battle.pickAction(.high)
                    }
                    ActionButton(label: "MED", accessibilityLabel: "Attack medium") {
                        battle.pickAction(.medium)
                    }
                    ActionButton(label: "LOW", accessibilityLabel: "Attack low") {
                        battle.pickAction(.low)
                    }
                }
                .opacity(isChoosing ? 1 : 0)
                .allowsHitTesting(isChoosing)

                HStack(spacing: 4) {
                    ActionButton(label: "DONE", accessibilityLabel: "Finish battle") {
                        presenter.dismissBattle()
                    }
                }
                .opacity(isComplete ? 1 : 0)
                .allowsHitTesting(isComplete)
            }
        }
    }

    // MARK: - Private Helpers

    private func battleSpriteOffsetY(
        _ battle: BattlePresenter
    ) -> Int {
        let isCenteredImpact = battle.viewModel.phase == .impact
            && (battle.viewModel.lastRoundOutcome == .clash
                || battle.viewModel.lastRoundOutcome == .opponentHit)
        return isCenteredImpact ? 2 : 4
    }

    private func choosingInfoRow(
        _ battle: BattlePresenter
    ) -> some View {
        let petHearts = BattleHP.heartsString(
            hp: battle.viewModel.petHP,
            maxHP: battle.viewModel.petMaxHP
        )
        let oppHearts = BattleHP.heartsString(
            hp: battle.viewModel.opponentHP,
            maxHP: battle.viewModel.opponentMaxHP
        )
        let petName = battle.viewModel.petSpecies.displayName
        let oppName = battle.viewModel.opponentSpecies
            .displayName
        return HStack(spacing: 2) {
            Text("\(petName) \(petHearts)")
            Text("|")
            Text("\(oppName) \(oppHearts)")
        }
        .font(.lcd(9, weight: .medium))
        .minimumScaleFactor(0.7)
        .lineLimit(1)
        .accessibilityLabel(
            "\(petName) \(battle.viewModel.petHP) HP,"
                + " \(oppName) \(battle.viewModel.opponentHP) HP"
        )
    }

    private func battlePhaseText(
        _ battle: BattlePresenter
    ) -> String {
        switch battle.viewModel.phase {
        case .introPet: battle.viewModel.petSpecies.displayName
        case .introVS: ""
        case .introEnemy: battle.viewModel.opponentSpecies.displayName
        case .choosing: ""
        case .attacking, .projectile: "ATTACK!"
        case .opponentAttacking: "COUNTER!"
        case .opponentProjectile: "INCOMING!"
        case .impact: impactText(battle)
        case .victory: victoryText(battle)
        case .defeat: "YOU LOSE"
        }
    }

    private func impactText(
        _ battle: BattlePresenter
    ) -> String {
        switch battle.viewModel.lastRoundOutcome {
        case .playerHit: "HIT!"
        case .opponentHit: "MISS!"
        case .clash: "CLASH!"
        case .none: ""
        }
    }

    private func victoryText(
        _ battle: BattlePresenter
    ) -> String {
        switch battle.viewModel.result {
        case .win: "YOU WIN!"
        case .draw: "DRAW"
        case .lose, .none: ""
        }
    }
}
