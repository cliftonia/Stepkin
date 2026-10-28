import Foundation

// MARK: - Hopkin (In-Training / Baby II) - round with floppy ears

extension SpriteCatalog {

    // Hopkin: ball shape with two pointy ear/horn flaps on top, wide mouth
    //
    //          ..#........#..        ears
    //          .##........##.
    //          .###.####.###.
    //          ..############
    //          ...##########.
    //          ..##.####.##..        eyes
    //          ..############
    //          ..##..##..##..        mouth open
    //          ..############
    //          ...##########.
    //          ....########..
    //          .....######...

    static func hopkinFrames(
        _ kind: AnimationKind
    ) -> [SpriteFrame] {
        let idle1 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x2008, //  ..#..........#..
            0x3018, //  ..##.........##.
            0x3C78, //  ..####....####..
            0x1FF0, //  ...#########....
            0x1FF8, //  ...##########...
            0x37B8, //  ..##.####.###..
            0x3FF8, //  ..###########..
            0x3018, //  ..##.......##..
            0x3FF8, //  ..###########..
            0x1FF0, //  ...#########....
            0x0FE0, //  ....#######.....
            0x07C0, //  .....#####......
            0x0000  //  ................
        ])

        let idle2 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0000, //  ................
            0x2008, //  ..#..........#..
            0x3018, //  ..##.........##.
            0x3C78, //  ..####....####..
            0x1FF0, //  ...#########....
            0x1FF8, //  ...##########...
            0x37B8, //  ..##.####.###..
            0x3FF8, //  ..###########..
            0x3018, //  ..##.......##..
            0x3FF8, //  ..###########..
            0x1FF0, //  ...#########....
            0x0FE0, //  ....#######.....
            0x07C0, //  .....#####......
            0x0000, //  ................
            0x0000  //  ................
        ])

        let happy1 = SpriteFrame(rows: [
            0x0000, 0x0000, 0x0000,
            0x2008,
            0x3018,
            0x3C78,
            0x1FF0,
            0x1FF8,
            0x3398, //  ..##..###..##..  ^_^ eyes
            0x3FF8,
            0x3C78, //  ..####...####..  smile
            0x3FF8,
            0x1FF0,
            0x0FE0,
            0x07C0,
            0x0000
        ])

        let happy2 = SpriteFrame(rows: [
            0x0000, 0x0000,
            0x2008,
            0x3018,
            0x3C78,
            0x1FF0,
            0x1FF8,
            0x3398,
            0x3FF8,
            0x3C78,
            0x3FF8,
            0x1FF0,
            0x0FE0,
            0x07C0,
            0x0000, 0x0000
        ])

        let eat1 = SpriteFrame(rows: [
            0x0000, 0x0000, 0x0000,
            0x2008, 0x3018, 0x3C78,
            0x1FF0, 0x1FF8,
            0x37B8,
            0x3FF8,
            0x33D8, //  ..##..####.##..  mouth open
            0x3FF8,
            0x1FF0, 0x0FE0, 0x07C0,
            0x0000
        ])

        let eat2 = SpriteFrame(rows: [
            0x0000, 0x0000, 0x0000,
            0x2008, 0x3018, 0x3C78,
            0x1FF0, 0x1FF8,
            0x37B8,
            0x3FF8,
            0x3FF8, //  mouth closed
            0x3FF8,
            0x1FF0, 0x0FE0, 0x07C0,
            0x0000
        ])

        let sleep1 = SpriteFrame(rows: [
            0x0000, 0x0000, 0x001C,
            0x0018, 0x0000,
            0x3C78,
            0x1FF0, 0x1FF8,
            0x3DB8, //  closed eyes
            0x3FF8, 0x3FF8, 0x3FF8,
            0x1FF0, 0x0FE0, 0x07C0,
            0x0000
        ])

        let sleep2 = SpriteFrame(rows: [
            0x0000, 0x001C, 0x0000,
            0x0018, 0x0000,
            0x3C78,
            0x1FF0, 0x1FF8,
            0x3DB8,
            0x3FF8, 0x3FF8, 0x3FF8,
            0x1FF0, 0x0FE0, 0x07C0,
            0x0000
        ])

        let attack1 = SpriteFrame(rows: [
            0x0000, 0x0000, 0x0000,
            0x2008, 0x3018, 0x3C78,
            0x1FF0, 0x1FF8,
            0x37B8,
            0x3FF8,
            0x3018, //  mouth wide open
            0x3FF8,
            0x1FF0,
            0x0FE0,
            0x87C2, //  #....#####....#.  impact lines
            0x0000
        ])

        // Side profile facing left: rounded body, one ear back, big eye.
        let sideWalk1 = SpriteFrame(rows: [
            0x0000, //  ................
            0x01C0, //  .......###......  ear
            0x0380, //  ......###.......
            0x0780, //  .....####.......
            0x1FC0, //  ...#######......  head
            0x3FE0, //  ..#########.....
            0x7FF0, //  .###########....
            0x6FF0, //  .##.########....  big eye
            0x6FF0, //  .##.########....
            0x7FF0, //  .###########....
            0x7FE0, //  .##########.....
            0x3FC0, //  ..########......
            0x1F80, //  ...######.......
            0x0F00, //  ....####........
            0x0000, //  ................
            0x0000  //  ................
        ])

        // Bobbed down — second stance frame.
        let sideWalk2 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0000, //  ................
            0x01C0, //  .......###......  ear
            0x0380, //  ......###.......
            0x0780, //  .....####.......
            0x1FC0, //  ...#######......  head
            0x3FE0, //  ..#########.....
            0x7FF0, //  .###########....
            0x6FF0, //  .##.########....  big eye
            0x6FF0, //  .##.########....
            0x7FF0, //  .###########....
            0x7FE0, //  .##########.....
            0x3FC0, //  ..########......
            0x1F80, //  ...######.......
            0x0F00, //  ....####........
            0x0000  //  ................
        ])

        switch kind {
        case .idle, .walk:
            return [idle1, idle2]
        case .sideWalk:
            return [sideWalk1, sideWalk2]
        case .happy:
            return bounceHappy(idle: idle1, happy1, happy2)
        case .eat:
            return chomp(eat1, eat2, rest: idle1)
        case .sleep:
            return [
                sleep1,
                idle1.overlaying(SharedSprites.sleepZ2),
                sleep2,
                idle2.overlaying(SharedSprites.sleepZ3)
            ]
        case .attack:
            return strike(idle: idle1, attack1)
        case .refuse:
            return defaultAnimationFromIdle(idle1, idle2, kind)
        }
    }
}
