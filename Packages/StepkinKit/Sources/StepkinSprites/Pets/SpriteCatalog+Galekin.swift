import Foundation

// MARK: - Galekin (Champion) - winged pterosaur

extension SpriteCatalog {

    // Galekin: pterosaur — long pointed beak, head crest swept
    // back-up, full-span flapping wings, legless body flowing into
    // a swishing tail
    //
    //         ..........##....    crest tip
    //         .....######.....    skull + crest taper
    //         #########.......    long pointed beak
    //         ..####.##.......    beak underside + eye
    //         .....####.......    chin
    //         ......####......    neck
    //         .#....####....#.    neck + wing tips
    //         ##...######...##    wings span wide
    //         .##############.    wings merge into the chest
    //         ..##..####..##..    wing membrane + body
    //         ......####......    body
    //         .......####.....    tail flows right
    //
    // swiftlint:disable:next function_body_length
    static func galekinFrames(
        _ kind: AnimationKind
    ) -> [SpriteFrame] {
        // Wings raised, tail tip swept up.
        let idle1 = SpriteFrame(rows: [
            0x0030, //  ..........##....  crest tip
            0x07E0, //  .....######.....  skull + crest taper
            0xFF80, //  #########.......  long pointed beak
            0x3D80, //  ..####.##.......  beak underside + eye
            0x0780, //  .....####.......  chin
            0x03C0, //  ......####......  neck
            0x43C2, //  .#....####....#.  neck + wing tips high
            0xC7E3, //  ##...######...##  wings span wide
            0x7FFE, //  .##############.  wings merge into the chest
            0x33CC, //  ..##..####..##..  wing membrane + body
            0x03C0, //  ......####......  body
            0x01E0, //  .......####.....  tail flows right
            0x00F0, //  ........####....
            0x0078, //  .........####...
            0x0038, //  ..........###...  tail tip
            0x0000  //  ................
        ])

        // Wings swept down, tail tip flicks.
        let idle2 = SpriteFrame(rows: [
            0x0030, //  ..........##....  crest tip
            0x07E0, //  .....######.....
            0xFF80, //  #########.......  beak
            0x3D80, //  ..####.##.......  eye
            0x0780, //  .....####.......
            0x03C0, //  ......####......  neck
            0x03C0, //  ......####......
            0x07E0, //  .....######.....  chest
            0x3FFC, //  ..############..  wings merge, sweeping down
            0x63C6, //  .##...####...##.  wings + body
            0x53CA, //  .#.#..####..#.#.  jagged wing tips low
            0x01E0, //  .......####.....  tail
            0x00F0, //  ........####....
            0x0078, //  .........####...
            0x001C, //  ...........###..  tail tip flicks
            0x0000  //  ................
        ])

        let eat1 = SpriteFrame(rows: [
            0x0030,
            0x07E0,
            0xFF80, //  #########.......  upper beak
            0x0580, //  .....#.##.......  lower beak drops open
            0x0780,
            0x03C0,
            0x03C0,
            0x07E0,
            0x3FFC, //  wings down while feeding
            0x63C6,
            0x53CA,
            0x01E0,
            0x00F0,
            0x0078,
            0x001C,
            0x0000
        ])

        let eat2 = SpriteFrame(rows: [
            0x0030,
            0x07E0,
            0xFF80,
            0x3D80, //  ..####.##.......  beak snaps shut
            0x0780,
            0x03C0,
            0x03C0,
            0x07E0,
            0x3FFC,
            0x63C6,
            0x53CA,
            0x01E0,
            0x00F0,
            0x0078,
            0x001C,
            0x0000
        ])

        // Sleep: grounded, wings folded, coiled around itself,
        // beak tucked low.
        let sleep1 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0038, //  ..........###...  Z
            0x0010, //  ...........#....
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x0060, //  .........##.....  crest
            0x0FC0, //  ....######......  skull
            0xFF80, //  #########.......  beak resting on the coil
            0x1F80, //  ...######.......
            0x1FF0, //  ...#########....  coiled body
            0x3FF8, //  ..###########...
            0x3FFC, //  ..############..
            0x3FFC, //  ..############..
            0x1FF8, //  ...##########...
            0x0000  //  ................
        ])

        let sleep2 = SpriteFrame(rows: [
            0x001C, //  Z drifts up
            0x0008,
            0x0000,
            0x0000,
            0x0000,
            0x0000,
            0x0060,
            0x0FC0,
            0xFF80,
            0x1F80,
            0x1FF0,
            0x3FF8,
            0x3FFC,
            0x3FFC,
            0x1FF8,
            0x0000
        ])

        // Spinning Needle — the beak whips right and wind marks swirl.
        let attack1 = SpriteFrame(rows: [
            0x0C00, //  ....##..........  crest tip
            0x07E0, //  .....######.....  skull
            0x01FF, //  .......#########  beak whipped right
            0x01BC, //  .......##.####..  eye + beak underside
            0x01E0, //  .......####.....  chin
            0x03C0, //  ......####......  neck
            0x43C2, //  .#....####....#.  wing tips high
            0xC7E3, //  ##...######...##  wings span wide
            0x7FFE, //  .##############.
            0x33CC, //  ..##..####..##..
            0x03C0, //  ......####......
            0x01E0, //  .......####.....
            0x00F0, //  ........####....
            0x0078, //  .........####...
            0x0038, //  ..........###...
            0x0000  //  ................
        ])

        // Side-walk: standing pterosaur — beak profile with crest,
        // wing on the back, body onto a coiled tail base
        let sideWalk1 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0300, //  ......##........  crest swept back
            0x1F00, //  ...#####........  skull + crest
            0xFF00, //  ########........  long pointed beak
            0x7B00, //  .####.##........  eye + beak underside
            0x0F00, //  ....####........  chin
            0x0700, //  .....###........  neck
            0x07F0, //  .....#######....  body + wing low
            0x0FB0, //  ....#####.##....  body + wing tips
            0x0FC0, //  ....######......  body
            0x07E0, //  .....######.....
            0x03F0, //  ......######....  tail
            0x00F8, //  ........#####...
            0x003C, //  ..........####..
            0x01F8, //  .......######...  coiled tail base
            0x0000  //  ................
        ])

        // The wing lifts as the pterosaur sways.
        let sideWalk2 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0300, //  ......##........  crest
            0x1F00, //  ...#####........
            0xFF00, //  ########........  beak
            0x7B00, //  .####.##........  eye
            0x0F00, //  ....####........
            0x0760, //  .....###.##.....  neck, wing tip lifts
            0x0770, //  .....###.###....  neck + wing
            0x0780, //  .....####.......  body
            0x0F80, //  ....#####.......
            0x0FC0, //  ....######......
            0x07E0, //  .....######.....
            0x00F8, //  ........#####...
            0x003C, //  ..........####..
            0x01F8, //  .......######...  coiled tail base
            0x0000  //  ................
        ])

        switch kind {
        case .idle, .walk:
            // Uneven wingbeat so the hover doesn't tick like a clock.
            return [
                idle1, idle2, idle2,
                idle1, idle2, idle1
            ]
        case .sideWalk:
            return [sideWalk1, sideWalk2]
        case .happy:
            // Crouch, then climb on beating wings and land in dust.
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
            return sleepCycle(sleep1, sleep2)
        case .attack:
            return strike(idle: idle1, attack1)
        case .refuse:
            // Head-shake: the beak whips right and back while the
            // wings and tail stay anchored.
            return [attack1, idle1, attack1, idle1]
        }
    }
}
