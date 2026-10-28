import Foundation

// MARK: - Tidekin (Champion) - sea serpent, long neck

extension SpriteCatalog {

    // Tidekin: rearing sea serpent — fin crest, long pointed snout,
    // body sweeping through a clear S-curve. The front idle turns the
    // WHOLE serpent to face left, then right, tail flicking between.
    // The side profile slithers along the ground like a snake.
    //
    //         ........##......    fin crest
    //         ....#####.......    head top
    //         .########.......    long pointed snout
    //         ..####.##.......    eye + snout underside
    //         ....#####.......    jaw
    //         ......####......    neck
    //         .......####.....
    //         ........####....    neck curves right
    //         .....#######....    body sweeps left
    //         ...#######......
    //         ..#######.......
    //         ..######........
    //         ...########.....    bottom curves right
    //         .....########...
    //         ...........####.    tail tip
    //
    // swiftlint:disable:next function_body_length
    static func tidekinFrames(
        _ kind: AnimationKind
    ) -> [SpriteFrame] {
        // The whole serpent faces left.
        let idle1 = SpriteFrame(rows: [
            0x00C0, //  ........##......  fin crest
            0x0F80, //  ....#####.......  head top
            0x7F80, //  .########.......  long pointed snout
            0x3D80, //  ..####.##.......  eye + snout underside
            0x0F80, //  ....#####.......  jaw
            0x03C0, //  ......####......  neck
            0x01E0, //  .......####.....
            0x00F0, //  ........####....  neck curves right
            0x07F0, //  .....#######....  body sweeps left
            0x1FC0, //  ...#######......
            0x3F80, //  ..#######.......
            0x3F00, //  ..######........
            0x1FE0, //  ...########.....  bottom curves right
            0x07F8, //  .....########...
            0x001E, //  ...........####.  tail tip
            0x0000  //  ................
        ])

        // Tail flicks while facing left.
        let idleLeftFlick = SpriteFrame(rows: [
            0x00C0, 0x0F80, 0x7F80, 0x3D80, 0x0F80, //  head left
            0x03C0,
            0x01E0,
            0x00F0,
            0x07F0,
            0x1FC0,
            0x3F80,
            0x3F00,
            0x1FE0,
            0x07F8,
            0x003C, //  ..........####..  tail tip flicks in
            0x0000
        ])

        // The whole serpent turns to face right — a full mirror.
        let idle2 = SpriteFrame(rows: [
            0x0300, //  ......##........  fin crest
            0x01F0, //  .......#####....  head top
            0x01FE, //  .......########.  long pointed snout
            0x01BC, //  .......##.####..  eye + snout underside
            0x01F0, //  .......#####....  jaw
            0x03C0, //  ......####......  neck
            0x0780, //  .....####.......
            0x0F00, //  ....####........  neck curves left
            0x0FE0, //  ....#######.....  body sweeps right
            0x03F8, //  ......#######...
            0x01FC, //  .......#######..
            0x00FC, //  ........######..
            0x07F8, //  .....########...  bottom curves left
            0x1FE0, //  ...########.....
            0x7800, //  .####...........  tail tip
            0x0000  //  ................
        ])

        // Tail flicks while facing right.
        let idleRightFlick = SpriteFrame(rows: [
            0x0300, 0x01F0, 0x01FE, 0x01BC, 0x01F0, //  head right
            0x03C0,
            0x0780,
            0x0F00,
            0x0FE0,
            0x03F8,
            0x01FC,
            0x00FC,
            0x07F8,
            0x1FE0,
            0x3C00, //  ..####..........  tail tip flicks in
            0x0000
        ])

        let eat1 = SpriteFrame(rows: [
            0x00C0,
            0x0F80,
            0x7F80, //  .########.......  upper snout
            0x0D80, //  ....##.##.......  lower jaw drops open
            0x0F80,
            0x03C0,
            0x01E0,
            0x00F0,
            0x07F0,
            0x1FC0,
            0x3F80,
            0x3F00,
            0x1FE0,
            0x07F8,
            0x001E,
            0x0000
        ])

        let eat2 = SpriteFrame(rows: [
            0x00C0,
            0x0F80,
            0x7F80,
            0x3D80, //  ..####.##.......  jaw snaps shut
            0x0F80,
            0x03C0,
            0x01E0,
            0x00F0,
            0x07F0,
            0x1FC0,
            0x3F80,
            0x3F00,
            0x1FE0,
            0x07F8,
            0x001E,
            0x0000
        ])

        // Sleep: piled into a low coil, snout resting on it.
        let sleep1 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0038, //  ..........###...  Z
            0x0010, //  ...........#....
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0F80, //  ....#####.......  head rests on the coil
            0x7F80, //  .########.......  snout
            0x3F80, //  ..#######.......  eye shut
            0x1F80, //  ...######.......
            0x3FF8, //  ..###########...  low coil
            0x3FFC, //  ..############..
            0x3FFC, //  ..############..
            0x3FF8, //  ..###########...
            0x0000  //  ................
        ])

        let sleep2 = SpriteFrame(rows: [
            0x001C, //  Z drifts up
            0x0008,
            0x0000,
            0x0000,
            0x0000,
            0x0000,
            0x0000,
            0x0F80,
            0x7F80,
            0x3F80,
            0x1F80,
            0x3FF8,
            0x3FFC,
            0x3FFC,
            0x3FF8,
            0x0000
        ])

        // Ice Arrow — the snout whips right and an ice diamond forms
        // beside the reared body.
        let attack1 = SpriteFrame(rows: [
            0x0300, //  ......##........  fin crest
            0x01F0, //  .......#####....  head whips right
            0x01FE, //  .......########.  pointed snout right
            0x01BC, //  .......##.####..  eye
            0x01F0, //  .......#####....  jaw
            0x01E0, //  .......####.....  neck
            0x00F0, //  ........####....
            0x00F0, //  ........####....
            0x07F0, //  .....#######....  body braced
            0x1FC0, //  ...#######......
            0x3F80, //  ..#######.......
            0x3F00, //  ..######........
            0x1FE0, //  ...########.....
            0x07F8, //  .....########...
            0x001E, //  ...........####.
            0x0000  //  ................
        ])

        // Side-walk: a snake slithering along the ground — raised
        // head at the front, a single body-hump travelling from the
        // neck back to the tail across three phases
        let sideWalk1 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x3000, //  ..##............  fin crest
            0xD800, //  ##.##...........  head + eye
            0xF800, //  #####...........  snout
            0x1F80, //  ...######.......  hump rises behind the neck
            0x3FFE, //  ..#############.  body
            0x7FFE, //  .##############.  belly on the ground
            0x0000  //  ................
        ])

        // The hump travels to mid-body.
        let sideWalk2 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x3000, //  ..##............  fin crest
            0xD800, //  ##.##...........  head + eye
            0xF800, //  #####...........  snout
            0x1C70, //  ...###...###....  hump at mid-body
            0x3FFC, //  ..############..  body, tail tip tucks
            0x7FFE, //  .##############.  belly on the ground
            0x0000  //  ................
        ])

        // The hump rolls out toward the tail.
        let sideWalk3 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x3000, //  ..##............  fin crest
            0xD800, //  ##.##...........  head + eye
            0xF800, //  #####...........  snout
            0x1C0E, //  ...###......###.  hump reaches the tail
            0x3FFE, //  ..#############.  body
            0x7FFE, //  .##############.  belly on the ground
            0x0000  //  ................
        ])

        switch kind {
        case .idle, .walk:
            // The whole serpent turns, holding each side for four
            // beats (tail flicking within) so the flip stays calm.
            return [
                idle1, idleLeftFlick, idle1, idleLeftFlick,
                idle2, idleRightFlick, idle2, idleRightFlick
            ]
        case .sideWalk:
            // The hump travels front-to-tail — a rolling slither.
            return [sideWalk1, sideWalk2, sideWalk3]
        case .happy:
            // Rear up out of the water and splash back down.
            return bounceHappy(idle: idle1, idle1, idle2)
        case .eat:
            return chomp(eat1, eat2, rest: idle1)
        case .sleep:
            // Eyes stay shut on every beat while the Z's pulse.
            return sleepCycle(sleep1, sleep2)
        case .attack:
            return strike(idle: idle1, attack1)
        case .refuse:
            return defaultAnimationFromIdle(idle1, idle2, kind)
        }
    }
}
