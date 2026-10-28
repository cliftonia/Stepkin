import Foundation

// MARK: - Emberkin (Rookie) - lean bipedal raptor

extension SpriteCatalog {

    // Emberkin: bipedal raptor — head turned to the side, snout + eye,
    // solid body with arm nubs, swishing side tail, clawed feet
    //
    //         ....####........    head top
    //         ..#######.......    skull + snout left
    //         ..####.##.......    eye
    //         ...######.......    jaw (mouth step at snout)
    //         ....#####.......    chin
    //         ....#####.......    chest
    //         ...#######......    shoulders
    //         ..#########..##.    arm nubs + tail tip
    //         ...##########...    belly + tail
    //         ....#####.......    hips
    //         ....##.##.......    thighs
    //         ....#...#.......    shins
    //         ...##..##.......    clawed feet

    static func emberkinFrames(
        _ kind: AnimationKind
    ) -> [SpriteFrame] {
        let idle1 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0000, //  ................
            0x0F00, //  ....####........  head top
            0x3F80, //  ..#######.......  skull + snout left
            0x3D80, //  ..####.##.......  eye
            0x1F80, //  ...######.......  jaw, mouth step at snout
            0x0F80, //  ....#####.......  chin
            0x0F80, //  ....#####.......  chest
            0x1FC0, //  ...#######......  shoulders
            0x3FE6, //  ..#########..##.  arm nubs, tail tip raised
            0x1FF8, //  ...##########...  belly + tail
            0x0F80, //  ....#####.......  hips
            0x0D80, //  ....##.##.......  thighs
            0x0880, //  ....#...#.......  shins
            0x1980, //  ...##..##.......  clawed feet
            0x0000  //  ................
        ])

        // Second idle beat: the head glances right, tail swishes down.
        let idle2 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0000, //  ................
            0x0780, //  .....####.......  head top
            0x0FE0, //  ....#######.....  skull + snout right
            0x0DE0, //  ....##.####.....  eye
            0x0FC0, //  ....######......  jaw, mouth step at snout
            0x0F80, //  ....#####.......  chin
            0x0F80, //  ....#####.......
            0x1FC0, //  ...#######......
            0x3FE0, //  ..#########.....  tail swings down
            0x1FF8, //  ...##########...
            0x0F8C, //  ....#####...##..  tail tip low
            0x0D80, //  ....##.##.......
            0x0880, //  ....#...#.......
            0x1980, //  ...##..##.......
            0x0000  //  ................
        ])

        // In-between idle beats: the glance holds each side for two
        // beats while the tail wags every beat.
        let idleLeftLow = SpriteFrame(rows: [
            0x0000, 0x0000,
            0x0F00, 0x3F80, 0x3D80, 0x1F80, //  head left
            0x0F80,
            0x0F80,
            0x1FC0,
            0x3FE0, //  tail swings down
            0x1FF8,
            0x0F8C,
            0x0D80,
            0x0880,
            0x1980,
            0x0000
        ])

        let idleRightHigh = SpriteFrame(rows: [
            0x0000, 0x0000,
            0x0780, 0x0FE0, 0x0DE0, 0x0FC0, //  head right
            0x0F80,
            0x0F80,
            0x1FC0,
            0x3FE6, //  tail tip raised
            0x1FF8,
            0x0F80,
            0x0D80,
            0x0880,
            0x1980,
            0x0000
        ])

        let walk1 = SpriteFrame(rows: [
            0x0000, 0x0000,
            0x0F00, 0x3F80, 0x3D80, 0x1F80,
            0x0F80,
            0x0F80,
            0x1FC0,
            0x3FE6,
            0x1FF8,
            0x0F80,
            0x0D80,
            0x1080, //  ...#....#.......  legs striding apart
            0x3180, //  ..##...##.......  both feet point left
            0x0000
        ])

        let walk2 = SpriteFrame(rows: [
            0x0000, 0x0000,
            0x0780, 0x0FE0, 0x0DE0, 0x0FC0, //  head glances right
            0x0F80,
            0x0F80,
            0x1FC0,
            0x3FE0, //  tail swings down mid-stride
            0x1FF8,
            0x0F8C,
            0x0D80,
            0x0880,
            0x1980, //  ...##..##.......  feet together
            0x0000
        ])

        // Happy: mouth thrown open mid-leap.
        let happy1 = SpriteFrame(rows: [
            0x0000, 0x0000,
            0x0F00,
            0x3F80,
            0x3D80, //  ..####.##.......  eye
            0x0780, //  .....####.......  jaw open wide
            0x0F80,
            0x0F80,
            0x1FC0,
            0x3FE6,
            0x1FF8,
            0x0F80,
            0x0D80,
            0x0880,
            0x1980,
            0x0000
        ])

        let happy2 = SpriteFrame(rows: [
            0x0000,
            0x0F00,
            0x3F80,
            0x3D80,
            0x0780,
            0x0F80,
            0x0F80,
            0x1FC0,
            0x3FE6,
            0x1FF8,
            0x0F80,
            0x0D80,
            0x0880,
            0x1980,
            0x0000, 0x0000
        ])

        let eat1 = SpriteFrame(rows: [
            0x0000, 0x0000,
            0x0F00,
            0x3F80,
            0x3D80,
            0x0780, //  .....####.......  jaw open
            0x0F80,
            0x0F80,
            0x1FC0,
            0x3FE6,
            0x1FF8,
            0x0F80,
            0x0D80,
            0x0880,
            0x1980,
            0x0000
        ])

        let eat2 = SpriteFrame(rows: [
            0x0000, 0x0000,
            0x0F00,
            0x3F80,
            0x3D80,
            0x3F80, //  ..#######.......  jaw clamped shut
            0x0F80,
            0x0F80,
            0x1FC0,
            0x3FE6,
            0x1FF8,
            0x0F80,
            0x0D80,
            0x0880,
            0x1980,
            0x0000
        ])

        // Hunched sleep: eyes shut, tail curled low.
        let sleep1 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0038, //  ..........###...  Z
            0x0010, //  ...........#....
            0x0F00, //  ....####........  head drooped
            0x3F80, //  ..#######.......
            0x3F80, //  ..#######.......  eye shut
            0x1F80, //  ...######.......
            0x0F80, //  ....#####.......
            0x1FC0, //  ...#######......  shoulders (neck tucked)
            0x3FE0, //  ..#########.....
            0x1FF8, //  ...##########...
            0x0F8C, //  ....#####...##..  tail curled low
            0x0D80, //  ....##.##.......
            0x0880, //  ....#...#.......
            0x1980, //  ...##..##.......
            0x0000  //  ................
        ])

        let sleep2 = SpriteFrame(rows: [
            0x0038, //  Z drifts up
            0x0010,
            0x0000,
            0x0F00,
            0x3F80,
            0x3F80,
            0x1F80,
            0x0F80,
            0x1FC0,
            0x3FE0,
            0x1FF8,
            0x0F8C,
            0x0D80,
            0x0880,
            0x1980,
            0x0000
        ])

        // Pepper Breath attack - head whips to face the fireball,
        // maw open toward it, tail braced low.
        let attack1 = SpriteFrame(rows: [
            0x0000, 0x0000,
            0x0780, //  .....####.......  head top
            0x0FE0, //  ....#######.....  skull + snout right
            0x0DE0, //  ....##.####.....  eye
            0x0F00, //  ....####........  maw open under snout
            0x0F80, //  ....#####.......  chin
            0x0F80,
            0x1FC0,
            0x3FE0, //  tail braced low
            0x1FF8,
            0x0F8C,
            0x0D80,
            0x0880,
            0x0CC0, //  ....##..##......  feet point at the foe
            0x0000
        ])

        // Side-walk: raptor profile — long snout, horizontal body,
        // upswept tail, striding digitigrade legs
        let sideWalk1 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0000, //  ................
            0x3C00, //  ..####..........  head top
            0x7E00, //  .######.........  long snout
            0x7600, //  .###.##.........  eye
            0x3E00, //  ..#####.........  jaw
            0x0F00, //  ....####........  neck
            0x0780, //  .....####.......  shoulders
            0x0FE6, //  ....#######..##.  body + tail tip kicked up
            0x1FFC, //  ...###########..  body + tail
            0x1FE0, //  ...########.....  tail underside
            0x0FC0, //  ....######......  belly
            0x0EC0, //  ....###.##......  thighs
            0x1860, //  ...##....##.....  legs striding
            0x3830, //  ..###.....##....  front foot claw, rear toe-off
            0x0000  //  ................
        ])

        // Legs pass under the body; the head bobs down a pixel.
        let sideWalk2 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0000, //  ................
            0x0000, //  ................
            0x3C00, //  ..####..........  head bobs down
            0x7E00, //  .######.........
            0x7600, //  .###.##.........  eye
            0x3E00, //  ..#####.........
            0x0F00, //  ....####........  neck
            0x0FE6, //  ....#######..##.  body + tail tip
            0x1FFC, //  ...###########..
            0x1FE0, //  ...########.....
            0x0FC0, //  ....######......
            0x0780, //  .....####.......  legs together
            0x0480, //  .....#..#.......
            0x0CC0, //  ....##..##......  feet
            0x0000  //  ................
        ])

        // Frames are authored facing left (the shared convention). Contexts
        // mirror via `.facing(_:)` when the creature should face right.
        // Attack frames alone bake the head + fireball facing right so the
        // maw always agrees with the projectile, mirrored or not.
        switch kind {
        case .idle:
            // Head holds left for two beats, then right for two beats;
            // the tail wags up-down on every beat.
            return [idle1, idleLeftLow, idleRightHigh, idle2]
        case .walk:
            return [
                walk1,
                walk1.shiftedDown(1),
                walk2,
                walk2.shiftedDown(1)
            ]
        case .sideWalk:
            return [sideWalk1, sideWalk2]
        case .happy:
            return bounceHappy(idle: idle1, happy1, happy2)
        case .eat:
            return chomp(eat1, eat2, rest: idle1)
        case .sleep:
            // Overlay onto idle1 only — idle2 glances right, and a
            // sleeping pet must not whip its head about.
            return sleepCycle(sleep1, sleep2, overlayingZOn: idle1)
        case .attack:
            return strike(idle: idle1, attack1)
        case .refuse:
            return defaultAnimationFromIdle(idle1, idle2, kind)
        }
    }
}
