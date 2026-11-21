import Foundation

// MARK: - View Frames & Positions

/// Sprite frame and horizontal-offset selection during battle.
///
/// One sprite is active per phase, so both properties switch on
/// `viewModel.phase` instead of exposing a frame per fighter.
extension BattlePresenter {

    // Pet fights from the left, enemy from the right; sprites natively face left.

    private static let petOffsetX = 1
    private static let opponentOffsetX = 15

    var petFrame: SpriteFrame {
        petAnimator.currentFrame.facing(.right)
    }

    var opponentFrame: SpriteFrame {
        opponentAnimator.currentFrame.facing(.left)
    }

    /// Horizontal offset of the active sprite; 8 is the centre between the pet
    /// and enemy offsets, where projectiles cross.
    var activeOffsetX: Int {
        switch viewModel.phase {
        case .introPet, .introVS, .introEnemy, .choosing, .projectile, .opponentProjectile:
            return 8
        case .attacking:
            return Self.petOffsetX
        case .opponentAttacking, .defeat:
            return Self.opponentOffsetX
        case .impact:
            switch viewModel.lastRoundOutcome {
            case .playerHit: return Self.opponentOffsetX
            case .opponentHit: return Self.petOffsetX
            case .clash, .none: return 8
            }
        case .victory:
            return viewModel.result == .lose
                ? Self.opponentOffsetX : Self.petOffsetX
        }
    }

    var activeFrame: SpriteFrame {
        switch viewModel.phase {
        case .introPet:
            return petFrame
        case .introVS:
            // The flashing "VS" is drawn by the LCD flash layer, not a sprite.
            return .empty
        case .introEnemy:
            return opponentFrame
        case .choosing, .attacking:
            return petFrame
        case .projectile:
            // Raw frame — projectile already travels left→right.
            return petAnimator.currentFrame
        case .opponentAttacking:
            return opponentFrame
        case .opponentProjectile:
            // Raw frame — projectileReversed already goes R→L.
            return opponentAnimator.currentFrame
        case .impact:
            switch viewModel.lastRoundOutcome {
            case .playerHit: return opponentFrame
            case .opponentHit, .clash, .none:
                return petFrame
            }
        case .victory:
            return viewModel.result == .lose
                ? opponentFrame : petFrame
        case .defeat:
            return opponentFrame
        }
    }
}
