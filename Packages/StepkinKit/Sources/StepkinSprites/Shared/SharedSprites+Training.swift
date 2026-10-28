import Foundation

extension SharedSprites {

    // MARK: - Training

    // `trainingTargetHit` and `trainingTargetRecoil` keep the chain's top
    // two rows identical to this frame, so the bag swings without its
    // hanger moving.
    /// The hanging bag at rest; `trainingHitSequence` finishes on this frame.
    static let trainingTarget = SpriteFrame(rows: [
        0x0C00,
        0x0C00,
        0x0C00,
        0x1E00,
        0x7F80,
        0x7F80,
        0x7F80,
        0x7F80,
        0x7F80,
        0x7F80,
        0x7F80,
        0x7F80,
        0x7F80,
        0x7F80,
        0x3F00,
        0x1E00
    ])

    /// The bag buckled at the moment of impact.
    static let trainingTargetHit = SpriteFrame(rows: [
        0x0C00,
        0x0C00,
        0x0600,
        0x0F00,
        0x3FC0,
        0x3FC0,
        0xBFC0,
        0x7FC0,
        0x3FC0,
        0x3FC0,
        0x3FC0,
        0x3FC0,
        0x3FC0,
        0x3FC0,
        0x1F80,
        0x0F00
    ])

    /// The bag swung wide on the rebound, past its rest pose.
    static let trainingTargetRecoil = SpriteFrame(rows: [
        0x0C00,
        0x0C00,
        0x1800,
        0x3C00,
        0xFF00,
        0xFF00,
        0xFF00,
        0xFF00,
        0xFF00,
        0xFF00,
        0xFF00,
        0xFF00,
        0xFF00,
        0xFF00,
        0x7E00,
        0x3C00
    ])

    /// First twinkle phase of the victory sparkle, a sparse scatter of pixels.
    static let trainingStar1 = SpriteFrame(rows: [
        0x0100,
        0x0280,
        0x0100,
        0x0000,
        0x8001,
        0x0000,
        0x0000,
        0x0000,
        0x0000,
        0x0000,
        0x0000,
        0x0100,
        0x0280,
        0x0100,
        0x0000,
        0x0000
    ])

    /// Second twinkle phase of the victory sparkle, the same sparse scatter at new points.
    static let trainingStar2 = SpriteFrame(rows: [
        0x0000,
        0x0000,
        0x2004,
        0x0000,
        0x0100,
        0x0280,
        0x0100,
        0x0000,
        0x0000,
        0x0100,
        0x0280,
        0x0100,
        0x0000,
        0x2004,
        0x0000,
        0x0000
    ])

    /// One complete hit swing: impact, recoil, rest, played through once.
    public static let trainingHitSequence = SpriteAnimation(
        frames: [trainingTargetHit, trainingTargetRecoil, trainingTarget],
        frameDuration: 0.2,
        loops: false
    )

    /// The victory twinkle, alternating the two star phases continuously.
    public static let trainingVictorySparkle = SpriteAnimation(
        frames: [trainingStar1, trainingStar2],
        frameDuration: 0.3,
        loops: true
    )
}
