import Foundation

// MARK: - Sludgekin (Champion) - slug/blob, simple shape

extension SpriteCatalog {

    // Sludgekin: living ooze — eyeballs on waggling stalks, a huge
    // goofy mouth, and a body that squashes and stretches, shedding
    // drips of slime as it moves
    //
    //         .....#....#.....    eye stalks
    //         ....##....##....    eyeballs
    //         .....#....#.....
    //         ......####......    blob top
    //         ....##.##.##....    eyes
    //         ...##########...
    //         ...##......##...    huge mouth
    //         ...##########...
    //         ..############..
    //         ..############..
    //         .##############.    spreading base
    //         ..############..
    //         .#..#......#..#.    slime drips
    //
    // swiftlint:disable:next function_body_length
    static func sludgekinFrames(
        _ kind: AnimationKind
    ) -> [SpriteFrame] {
        // Stretched tall.
        let idle1 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0420, //  .....#....#.....  eye stalks
            0x0C30, //  ....##....##....  eyeballs
            0x0420, //  .....#....#.....
            0x03C0, //  ......####......  blob top
            0x0DB0, //  ....##.##.##....  eyes
            0x1FF8, //  ...##########...
            0x1818, //  ...##......##...  huge mouth
            0x1FF8, //  ...##########...
            0x3FFC, //  ..############..
            0x3FFC, //  ..############..
            0x7FFE, //  .##############.  spreading base
            0x3FFC, //  ..############..
            0x4812  //  .#..#......#..#.  slime drips
        ])

        // Squashed low and wide, stalks bowing outward.
        let idle2 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0810, //  ....#......#....  stalks bow outward
            0x1818, //  ...##......##...  eyeballs
            0x0810, //  ....#......#....
            0x07E0, //  .....######.....  blob top
            0x1FF8, //  ...##########...  face eyes vanish in the squish
            0x381C, //  ..###......###..  mouth stretches wide
            0x3FFC, //  ..############..
            0x7FFE, //  .##############.
            0xFFFF, //  ################  squashed flat
            0x7FFE, //  .##############.
            0x9009  //  #..#........#..#  drips spatter wide
        ])

        let eat1 = SpriteFrame(rows: [
            0x0000, 0x0000, 0x0000,
            0x0420,
            0x0C30, //  eyeballs
            0x0420,
            0x03C0,
            0x0DB0, //  eyes
            0x1FF8,
            0x1818, //  ...##......##...  maw gapes
            0x1818, //  ...##......##...  two rows tall
            0x3FFC,
            0x3FFC,
            0x7FFE,
            0x3FFC,
            0x4812
        ])

        let eat2 = SpriteFrame(rows: [
            0x0000, 0x0000, 0x0000,
            0x0420,
            0x0C30,
            0x0420,
            0x03C0,
            0x0DB0, //  eyes
            0x1FF8,
            0x1FF8, //  ...##########...  mouth closed
            0x1FF8,
            0x3FFC,
            0x3FFC,
            0x7FFE,
            0x3FFC,
            0x4812
        ])

        // Sleep: melted into a puddle, stalks drooped flat.
        let sleep1 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0038, //  ..........###...  Z
            0x0010, //  ...........#....
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x1800, //  ...##...........  stalks drooped flat
            0x0FF0, //  ....########....  melted mound
            0x3FFC, //  ..############..
            0x7FFE, //  .##############.
            0xFFFF, //  ################  puddle
            0x7FFE  //  .##############.
        ])

        let sleep2 = SpriteFrame(rows: [
            0x001C, //  Z drifts up
            0x0008,
            0x0000,
            0x0000,
            0x0000,
            0x0000,
            0x0000,
            0x0000,
            0x0000,
            0x0000,
            0x1800,
            0x0FF0,
            0x3FFC,
            0x7FFE,
            0xFFFF,
            0x7FFE
        ])

        // Side profile: slime mound scooting — eye stalk forward, big
        // mouth, wide dripping base leaving a trail
        let sideWalk1 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x1000, //  ...#............  eye stalk forward
            0x3000, //  ..##............  eyeball
            0x1000, //  ...#............
            0x0F80, //  ....#####.......  mound top
            0x1BE0, //  ...##.#####.....  eye
            0x1860, //  ...##....##.....  mouth
            0x3FF0, //  ..##########....
            0x3FF8, //  ..###########...
            0x7FFC, //  .#############..
            0xFFFE, //  ###############.  wide base
            0x7FFC, //  .#############..
            0x2208  //  ..#...#.....#...  slime trail
        ])

        // The mound leans forward, scooting like an inchworm.
        let sideWalk2 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x2000, //  ..#.............  stalk leans forward
            0x6000, //  .##.............  eyeball
            0x2000, //  ..#.............
            0x1F00, //  ...#####........  mound leans
            0x37C0, //  ..##.#####......  eye
            0x30C0, //  ..##....##......  mouth
            0x7FE0, //  .##########.....
            0x3FF8, //  ..###########...  base stays put
            0x7FFC, //  .#############..
            0xFFFE, //  ###############.
            0x7FFC, //  .#############..
            0x2208  //  ..#...#.....#...  slime trail
        ])

        switch kind {
        case .idle, .walk:
            // Squash and stretch — the blob breathes.
            return [idle1, idle2]
        case .sideWalk:
            return [sideWalk1, sideWalk2]
        case .happy:
            // Jiggling bounce between squash and stretch.
            return [
                idle2,
                idle1,
                idle2,
                idle1.overlaying(SharedSprites.landingDust)
            ]
        case .eat:
            return chomp(eat1, eat2, rest: idle1)
        case .sleep:
            // Melted flat on every beat while the Z's pulse.
            return sleepCycle(sleep1, sleep2)
        case .attack:
            return strike(idle: idle1, idle2)
        case .refuse:
            return defaultAnimationFromIdle(idle1, idle2, kind)
        }
    }
}
