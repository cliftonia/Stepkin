import Foundation

// MARK: - Pyrekin (Champion) - humanoid fire creature

extension SpriteCatalog {

    // Pyrekin: lanky flame humanoid — dancing flame crown, jagged
    // flame wings beating from the shoulders, a waist-pinched torso,
    // long legs, and splayed three-toed feet
    //
    //         ......#.#.......    flame tips
    //         .....#.#.#......    dancing flame
    //         .....######.....    flame base / head top
    //         .....#.##.#.....    eyes
    //         .....######.....    solid face row
    //         .....##.##......    small mouth
    //         ......####......    neck
    //         ##...######...##    flame wings span wide
    //         .##############.    wings merge into the chest
    //         ..##..####..##..    wing membrane + torso
    //         ...#..####..#...    flame jags + torso
    //         ......####......    torso
    //         .......##.......    pinched waist
    //         ......#..#......    long legs
    //         ....###..###....    splayed feet

    static func pyrekinFrames(
        _ kind: AnimationKind
    ) -> [SpriteFrame] {
        // Wings raised, crown licking left.
        let idle1 = SpriteFrame(rows: [
            0x0280, //  ......#.#.......  flame tips
            0x0540, //  .....#.#.#......  dancing flame
            0x07E0, //  .....######.....  flame base / head top
            0x05A0, //  .....#.##.#.....  eyes
            0x07E0, //  .....######.....  solid face row
            0x06C0, //  .....##.##......  small mouth
            0x43C2, //  .#....####....#.  neck, wing tips high
            0xC7E3, //  ##...######...##  flame wings span wide
            0x7FFE, //  .##############.  wings merge into the chest
            0x33CC, //  ..##..####..##..  wing membrane + torso
            0x13C8, //  ...#..####..#...  flame jags + torso
            0x03C0, //  ......####......  torso
            0x0180, //  .......##.......  pinched waist
            0x0240, //  ......#..#......  long legs
            0x0240, //  ......#..#......
            0x0E70  //  ....###..###....  splayed feet
        ])

        // Wings swept down, crown licking right.
        let idle2 = SpriteFrame(rows: [
            0x0140, //  .......#.#......  flame tips flicker
            0x02A0, //  ......#.#.#.....  flame dances right
            0x07E0, //  .....######.....
            0x05A0, //  .....#.##.#.....  eyes
            0x07E0, //  .....######.....  solid face row
            0x06C0, //  .....##.##......  small mouth
            0x03C0, //  ......####......
            0x07E0, //  .....######.....  shoulders
            0x3FFC, //  ..############..  wings merge, sweeping down
            0x63C6, //  .##...####...##.  wings + torso
            0x53CA, //  .#.#..####..#.#.  flame-jagged wing tips low
            0x03C0, //  ......####......
            0x0180, //  .......##.......  pinched waist
            0x0240, //  ......#..#......
            0x0240, //  ......#..#......
            0x0E70  //  ....###..###....
        ])

        let walk1 = SpriteFrame(rows: [
            0x0280, 0x0540, //  flame left, wings raised
            0x07E0, 0x05A0, 0x07E0, 0x06C0,
            0x43C2,
            0xC7E3,
            0x7FFE,
            0x33CC,
            0x13C8,
            0x03C0,
            0x0180,
            0x0420, //  .....#....#.....  legs striding apart
            0x0810, //  ....#......#....
            0x1818  //  ...##......##...  feet apart
        ])

        let eat1 = SpriteFrame(rows: [
            0x0280, 0x0540,
            0x07E0, 0x05A0, 0x07E0,
            0x0640, //  .....##..#......  mouth open
            0x03C0,
            0x07E0, //  wings down while feeding
            0x3FFC,
            0x63C6,
            0x53CA,
            0x03C0,
            0x0180,
            0x0240,
            0x0240,
            0x0E70
        ])

        let eat2 = SpriteFrame(rows: [
            0x0280, 0x0540,
            0x07E0, 0x05A0, 0x07E0,
            0x07E0, //  .....######.....  mouth shut
            0x03C0,
            0x07E0,
            0x3FFC,
            0x63C6,
            0x53CA,
            0x03C0,
            0x0180,
            0x0240,
            0x0240,
            0x0E70
        ])

        // Sleep: eyes shut, wings drooped, the crown burns down to
        // a single ember.
        let sleep1 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0100, //  .......#........  lone ember
            0x07E0, //  .....######.....
            0x07E0, //  .....######.....  eyes shut
            0x07E0, //  .....######.....
            0x06C0, //  .....##.##......
            0x03C0, //  ......####......
            0x07E0, //  .....######.....  wings drooped
            0x3FFC, //  ..############..
            0x63C6, //  .##...####...##.
            0x53CA, //  .#.#..####..#.#.
            0x03C0, //  ......####......
            0x0180, //  .......##.......
            0x0240, //  ......#..#......
            0x0240, //  ......#..#......
            0x0E70  //  ....###..###....
        ])

        // Burning Fist — wings sweep down for the windup tell.
        let attack1 = SpriteFrame(rows: [
            0x0280, 0x0540,
            0x07E0, 0x05A0, 0x07E0, 0x06C0,
            0x03C0,
            0x07E0, //  wings cocked down
            0x3FFC,
            0x63C6,
            0x53CA,
            0x03C0,
            0x0180,
            0x0240,
            0x0240,
            0x0E70
        ])

        // Side-walk: lanky flame profile — trailing crown, flame wing
        // wisp on the back, swinging arm, long striding legs
        let sideWalk1 = SpriteFrame(rows: [
            0x0500, //  .....#.#........  flame tips
            0x0A80, //  ....#.#.#.......  flame trails back
            0x1F00, //  ...#####........  flame base
            0x3F00, //  ..######........  head
            0x2F00, //  ..#.####........  eye
            0x1F00, //  ...#####........  jaw
            0x0E60, //  ....###..##.....  neck, wing wisp behind
            0x1FA0, //  ...######.#.....  shoulders + wing
            0x37E0, //  ..##.######.....  arm swings + wing on the back
            0x2780, //  ..#..####.......  fist + torso
            0x0780, //  .....####.......  torso
            0x0700, //  .....###........  hips
            0x0700, //  .....###........
            0x0880, //  ....#...#.......  long legs stride
            0x1080, //  ...#....#.......
            0x3180  //  ..##...##.......  feet
        ])

        // The flame licks the other way as the legs pass under.
        let sideWalk2 = SpriteFrame(rows: [
            0x0A00, //  ....#.#.........  flame flickers
            0x0500, //  .....#.#........
            0x1F00, //  ...#####........
            0x3F00, //  ..######........
            0x2F00, //  ..#.####........  eye
            0x1F00, //  ...#####........
            0x0E60, //  ....###..##.....  neck, wing wisp
            0x1FA0, //  ...######.#.....
            0x37E0, //  ..##.######.....
            0x2780, //  ..#..####.......
            0x0780, //  .....####.......
            0x0700, //  .....###........
            0x0700, //  .....###........
            0x0500, //  .....#.#........  legs together
            0x0500, //  .....#.#........
            0x0D80  //  ....##.##.......  feet
        ])

        switch kind {
        case .idle:
            // Uneven wingbeat and flicker so the loop doesn't tick
            // like a clock.
            return [
                idle1, idle2, idle2,
                idle1, idle2, idle1
            ]
        case .walk:
            return [walk1, idle2]
        case .sideWalk:
            return [sideWalk1, sideWalk2]
        case .happy:
            // Crouch with wings down, then leap on beating wings.
            return [
                idle2.shiftedDown(1),
                idle1,
                idle2,
                idle1.overlaying(SharedSprites.landingDust)
            ]
        case .eat:
            return chomp(eat1, eat2, rest: idle2)
        case .sleep:
            // Eyes stay shut on every beat while the Z's pulse.
            return sleepCycle(sleep1, sleep1, overlayingZOn: sleep1)
        case .attack:
            return strike(idle: idle1, attack1)
        case .refuse:
            return defaultAnimationFromIdle(idle1, idle2, kind)
        }
    }
}
