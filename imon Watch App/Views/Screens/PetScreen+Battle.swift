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
            let showsHearts = phaseText.isEmpty
            let showsPhaseText = !showsHearts
            ZStack {
                choosingInfoRow(battle)
                    .opacity(showsHearts ? 1 : 0)
                    .accessibilityHidden(!showsHearts)
                Text(phaseText)
                    .font(.lcd(11, weight: .bold))
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .opacity(showsPhaseText ? 1 : 0)
                    .accessibilityHidden(!showsPhaseText)
            }
        }
    }

    // MARK: - Battle Buttons

    @ViewBuilder
    var battleButtons: some View {
        if let battle = presenter.battlePresenter {
            let phase = battle.viewModel.phase
            let showsAttackButtons = phase == .choosing
            let showsDoneButton = phase == .victory || phase == .defeat

            ZStack {
                HStack(spacing: 4) {
                    ActionButton(
                        label: String(localized: "HIGH", comment: "Printed face of a button on the LCD screen; keep it short and capitalised."),
                        accessibilityLabel: String(localized: "Attack high", comment: "VoiceOver label: attack the opponent's upper body.")
                    ) {
                        battle.pickAction(.high)
                    }
                    ActionButton(
                        label: String(localized: "MED", comment: "Printed face of a button on the LCD screen; keep it short and capitalised."),
                        accessibilityLabel: String(localized: "Attack medium", comment: "VoiceOver label: attack the opponent's middle.")
                    ) {
                        battle.pickAction(.medium)
                    }
                    ActionButton(
                        label: String(localized: "LOW", comment: "Printed face of a button on the LCD screen; keep it short and capitalised."),
                        accessibilityLabel: String(localized: "Attack low", comment: "VoiceOver label: attack the opponent's lower body.")
                    ) {
                        battle.pickAction(.low)
                    }
                }
                .opacity(showsAttackButtons ? 1 : 0)
                .allowsHitTesting(showsAttackButtons)
                .accessibilityHidden(!showsAttackButtons)

                HStack(spacing: 4) {
                    ActionButton(
                        label: String(localized: "DONE", comment: "Printed face of the button that leaves a finished game; keep it short and capitalised."),
                        accessibilityLabel: String(localized: "Finish battle", comment: "VoiceOver label: leave the battle.")
                    ) {
                        presenter.dismissBattle()
                    }
                }
                .opacity(showsDoneButton ? 1 : 0)
                .allowsHitTesting(showsDoneButton)
                .accessibilityHidden(!showsDoneButton)
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
            Text("\(petName) \(petHearts)", comment: "Battle LCD header half: species name then hearts.")
            Text(verbatim: "|")
            Text("\(oppName) \(oppHearts)", comment: "Battle LCD header half: species name then hearts.")
        }
        .font(.lcd(9, weight: .medium))
        .minimumScaleFactor(0.7)
        .lineLimit(1)
        .accessibilityLabel(
            Text(
                "\(petName) \(battle.viewModel.petHP) HP, \(oppName) \(battle.viewModel.opponentHP) HP",
                comment: "VoiceOver for the battle header: each species name followed by its hit points."
            )
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
        case .attacking, .projectile: String(localized: "ATTACK!", comment: "LCD caption while your monster attacks; keep it short and capitalised.")
        case .opponentAttacking: String(localized: "COUNTER!", comment: "LCD caption while the opponent strikes back; keep it short and capitalised.")
        case .opponentProjectile: String(localized: "INCOMING!", comment: "LCD caption while the opponent's shot flies in; keep it short and capitalised.")
        case .impact: impactText(battle)
        case .victory: victoryText(battle)
        case .defeat: String(localized: "YOU LOSE", comment: "LCD caption when the battle is lost; keep it short and capitalised.")
        }
    }

    private func impactText(
        _ battle: BattlePresenter
    ) -> String {
        switch battle.viewModel.lastRoundOutcome {
        case .playerHit: String(localized: "HIT!", comment: "LCD caption when an attack or guess lands; keep it short and capitalised.")
        case .opponentHit: String(localized: "MISS!", comment: "LCD caption when your attack misses; keep it short and capitalised.")
        case .clash: String(localized: "CLASH!", comment: "LCD caption when both attacks collide; keep it short and capitalised.")
        case .none: ""
        }
    }

    private func victoryText(
        _ battle: BattlePresenter
    ) -> String {
        switch battle.viewModel.result {
        case .win: String(localized: "YOU WIN!", comment: "LCD caption when the battle is won; keep it short and capitalised.")
        case .draw: String(localized: "DRAW", comment: "LCD caption when the battle ends level; keep it short and capitalised.")
        case .lose, .none: ""
        }
    }
}
