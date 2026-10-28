import Foundation
import StepkinEngine

// MARK: - Species Projectiles

extension SpriteCatalog {

    /// Species-specific projectile traveling left-to-right (pet, on the left).
    public static func projectile(
        for species: PetSpecies,
        height: AttackHeight
    ) -> SpriteAnimation {
        traversal(for: species, height: height, reversed: false)
    }

    /// Species-specific projectile traveling right-to-left (enemy, on the right).
    public static func projectileReversed(
        for species: PetSpecies,
        height: AttackHeight
    ) -> SpriteAnimation {
        traversal(for: species, height: height, reversed: true)
    }

    /// Non-clipping traversal: the sprite is flush-left normalized,
    /// then stepped right only as far as its width allows so it
    /// never runs off the 16-wide frame.
    private static func traversal(
        for species: PetSpecies,
        height: AttackHeight,
        reversed: Bool
    ) -> SpriteAnimation {
        let sprite = positioned(
            flushedLeft(projectileSprite(for: species)),
            height: height
        )
        let maxShift = max(3, 15 - rightmostColumn(sprite))
        let steps = [
            0, maxShift / 4, maxShift / 2,
            3 * maxShift / 4, maxShift
        ]
        let frames = steps.map { sprite.shiftedRight($0) }
        return SpriteAnimation(
            frames: reversed ? frames.reversed() : frames,
            frameDuration: 0.1,
            loops: false
        )
    }

    /// Places the projectile in one of three clearly-separated vertical bands —
    /// high near the top, medium centred, low near the bottom — normalised from
    /// the sprite's own lit rows so every species reads the same way and nothing
    /// clips. A fixed ±3 nudge left high and medium near-indistinguishable.
    private static func positioned(
        _ sprite: SpriteFrame,
        height: AttackHeight
    ) -> SpriteFrame {
        guard let top = topmostRow(sprite), let bottom = bottommostRow(sprite) else {
            return sprite
        }
        let spriteHeight = bottom - top + 1
        let targetTop: Int
        switch height {
        case .high: targetTop = 1
        case .medium: targetTop = (SpriteFrame.size - spriteHeight) / 2
        case .low: targetTop = SpriteFrame.size - 1 - spriteHeight
        }
        let delta = targetTop - top
        if delta < 0 { return sprite.shiftedUp(-delta) }
        if delta > 0 { return sprite.shiftedDown(delta) }
        return sprite
    }

    private static func topmostRow(_ frame: SpriteFrame) -> Int? {
        frame.rows.firstIndex { $0 != 0 }
    }

    private static func bottommostRow(_ frame: SpriteFrame) -> Int? {
        frame.rows.lastIndex { $0 != 0 }
    }

    /// Shifts a sprite so its leftmost lit column sits at column 0.
    private static func flushedLeft(
        _ frame: SpriteFrame
    ) -> SpriteFrame {
        let left = leftmostColumn(frame)
        return left > 0 ? frame.shiftedLeft(left) : frame
    }

    private static func leftmostColumn(_ frame: SpriteFrame) -> Int {
        for x in 0..<SpriteFrame.size where columnHasPixel(frame, x) {
            return x
        }
        return 0
    }

    private static func rightmostColumn(_ frame: SpriteFrame) -> Int {
        for x in stride(from: SpriteFrame.size - 1, through: 0, by: -1)
        where columnHasPixel(frame, x) {
            return x
        }
        return 0
    }

    private static func columnHasPixel(
        _ frame: SpriteFrame,
        _ x: Int
    ) -> Bool {
        (0..<SpriteFrame.size).contains { frame.pixel(x: x, y: $0) }
    }

    /// Distinctive signature-attack sprite per species, drawn
    /// left-aligned at medium height. MSB = leftmost pixel.
    private static func projectileSprite(
        for species: PetSpecies
    ) -> SpriteFrame {
        switch species {
        case .dotkin: bubbleSmall
        case .hopkin: bubbleLarge
        case .emberkin: fireballTrail
        case .marshkin: lightningBolt
        case .rexkin: novaBlast
        case .blazekin: flameStream
        case .dreadkin: deathClaw
        case .pyrekin: flameTeardrop
        case .galekin: windSpiral
        case .tidekin: iceCrystal
        case .sludgekin: poopGlob
        case .steelkin: missile
        case .orbkin: windSpiral
        case .plushkin: heart
        }
    }
}

// MARK: - Projectile Sprites

extension SpriteCatalog {

    /// Dotkin — small hollow bubble.
    private static let bubbleSmall = SpriteFrame(rows: [
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
        0x3800, //  ..###...
        0x4400, //  .#...#..
        0x4400, //  .#...#..
        0x3800, //  ..###...
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
    ])

    /// Hopkin — larger hollow bubble.
    private static let bubbleLarge = SpriteFrame(rows: [
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
        0x3800, //  ..###...
        0x4400, //  .#...#..
        0x8200, //  #.....#.
        0x4400, //  .#...#..
        0x3800, //  ..###...
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
    ])

    /// Emberkin — Pepper Breath fireball with a trailing flame.
    private static let fireballTrail = SpriteFrame(rows: [
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
        0x0C00, //  ....##..
        0x1E00, //  ...####.
        0x7F00, //  .#######  trailing flame
        0x1E00, //  ...####.
        0x0C00, //  ....##..
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000
    ])

    /// Marshkin — Electric Shock zigzag bolt.
    private static let lightningBolt = SpriteFrame(rows: [
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
        0x0E00, //  ....###.
        0x1C00, //  ...###..
        0x3800, //  ..###...
        0x7E00, //  .######.
        0x0E00, //  ....###.
        0x1C00, //  ...###..
        0x3800, //  ..###...
        0x0000, 0x0000, 0x0000, 0x0000
    ])

    /// Rexkin — Nova Blast large solid fireball.
    private static let novaBlast = SpriteFrame(rows: [
        0x0000, 0x0000, 0x0000, 0x0000,
        0x1800, //  ...##...
        0x3C00, //  ..####..
        0x7E00, //  .######.
        0xFF00, //  ########
        0xFF00, //  ########
        0x7E00, //  .######.
        0x3C00, //  ..####..
        0x1800, //  ...##...
        0x0000, 0x0000, 0x0000, 0x0000
    ])

    /// Blazekin — Fire Breath wide flame stream.
    private static let flameStream = SpriteFrame(rows: [
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
        0x2200, //  ..#...#.
        0x7700, //  .###.###
        0xFF80, //  #########
        0x7700, //  .###.###
        0x2200, //  ..#...#.
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000
    ])

    /// Dreadkin — Death Claw three parallel slashes.
    private static let deathClaw = SpriteFrame(rows: [
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
        0xA800, //  #.#.#...
        0x5400, //  .#.#.#..
        0x2A00, //  ..#.#.#.
        0x1500, //  ...#.#.#
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
    ])

    /// Pyrekin — Burning Fist pointed flame.
    private static let flameTeardrop = SpriteFrame(rows: [
        0x0000, 0x0000, 0x0000, 0x0000,
        0x0800, //  ....#...
        0x1C00, //  ...###..
        0x3E00, //  ..#####.
        0x7F00, //  .#######
        0x7F00, //  .#######
        0x3E00, //  ..#####.
        0x1C00, //  ...###..
        0x0800, //  ....#...
        0x0000, 0x0000, 0x0000, 0x0000
    ])

    /// Galekin — Spinning Needle wind spiral.
    private static let windSpiral = SpriteFrame(rows: [
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
        0x3C00, //  ..####..
        0x4200, //  .#....#.
        0x9900, //  #..##..#
        0x9900, //  #..##..#
        0x4200, //  .#....#.
        0x3C00, //  ..####..
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000
    ])

    /// Tidekin — Ice Arrow sharp crystal.
    private static let iceCrystal = SpriteFrame(rows: [
        0x0000, 0x0000, 0x0000, 0x0000,
        0x1000, //  ...#....
        0x3800, //  ..###...
        0x7C00, //  .#####..
        0xFE00, //  #######.
        0x7C00, //  .#####..
        0x3800, //  ..###...
        0x1000, //  ...#....
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000
    ])

    /// Sludgekin — Poop Toss glob mound.
    private static let poopGlob = SpriteFrame(rows: [
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
        0x1000, //  ...#....
        0x3800, //  ..###...
        0x3800, //  ..###...
        0x7C00, //  .#####..
        0xFE00, //  #######.
        0xFE00, //  #######.
        0x0000, 0x0000, 0x0000, 0x0000
    ])

    /// Steelkin — Giga Blaster missile.
    private static let missile = SpriteFrame(rows: [
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
        0x4000, //  .#......  top fin
        0x3E00, //  ..#####.  body
        0xFF80, //  #########  nose tip
        0x3E00, //  ..#####.  body
        0x4000, //  .#......  bottom fin
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
    ])

    /// Plushkin — Hearts Attack heart.
    private static let heart = SpriteFrame(rows: [
        0x0000, 0x0000, 0x0000, 0x0000, 0x0000,
        0x6600, //  .##..##.
        0xFF00, //  ########
        0xFF00, //  ########
        0xFF00, //  ########
        0x7E00, //  .######.
        0x3C00, //  ..####..
        0x1800, //  ...##...
        0x0000, 0x0000, 0x0000, 0x0000
    ])
}
