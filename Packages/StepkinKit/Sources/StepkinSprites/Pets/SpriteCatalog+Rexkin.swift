import Foundation

// MARK: - Rexkin (Champion) - large horned dinosaur

extension SpriteCatalog {

    // Rexkin: horned T-rex — head turned to the side with a back-swept
    // horn, snout + eye, broad body with arm nubs, heavy swishing tail
    //
    //         .........##.....    horn
    //         ...#######......    skull top
    //         .#########......    skull + snout left
    //         .#####.###......    eye
    //         ..########......    jaw (mouth step at snout)
    //         ....######......    chin
    //         ....######......    chest
    //         ...########.....    shoulders
    //         ..##########....    arm nubs + body
    //         ..##########.##.    body + tail tip
    //         ...###########..    belly + tail
    //         ....#######.....    hips
    //         ....##..##......    thighs
    //         ....#....#......    shins
    //         ...##...##......    feet

    static func rexkinFrames(
        _ kind: AnimationKind
    ) -> [SpriteFrame] {
        let idle1 = SpriteFrame(rows: [
            0x0060, //  .........##.....  horn
            0x1FC0, //  ...#######......  skull top
            0x7FC0, //  .#########......  skull + snout left
            0x7DC0, //  .#####.###......  eye
            0x3FC0, //  ..########......  jaw, mouth step at snout
            0x0FC0, //  ....######......  chin
            0x0FC0, //  ....######......  chest
            0x1FE0, //  ...########.....  shoulders
            0x3FF0, //  ..##########....  arm nubs + body
            0x3FF6, //  ..##########.##.  body, tail tip raised
            0x1FFC, //  ...###########..  belly + tail
            0x0FE0, //  ....#######.....  hips
            0x0CC0, //  ....##..##......  thighs
            0x0840, //  ....#....#......  shins
            0x18C0, //  ...##...##......  feet
            0x0000  //  ................
        ])

        // Second beat of the left gaze: tail swishes down.
        let idleLeftLow = SpriteFrame(rows: [
            0x0060, 0x1FC0, 0x7FC0, 0x7DC0, 0x3FC0, 0x0FC0, //  head left
            0x0FC0,
            0x1FE0,
            0x3FF0,
            0x3FF0, //  ..##########....  tail swings down
            0x1FFC,
            0x0FEC, //  ....#######.##..  tail tip low
            0x0CC0,
            0x0840,
            0x18C0,
            0x0000
        ])

        // The head glances right, tail back up.
        let idleRightHigh = SpriteFrame(rows: [
            0x1800, //  ...##...........  horn
            0x0FE0, //  ....#######.....  skull top
            0x0FF8, //  ....#########...  skull + snout right
            0x0EF8, //  ....###.#####...  eye
            0x0FF0, //  ....########....  jaw, mouth step at snout
            0x0FC0, //  ....######......  chin
            0x0FC0,
            0x1FE0,
            0x3FF0,
            0x3FF6, //  tail tip raised
            0x1FFC,
            0x0FE0,
            0x0CC0,
            0x0840,
            0x18C0,
            0x0000
        ])

        let idle2 = SpriteFrame(rows: [
            0x1800, 0x0FE0, 0x0FF8, 0x0EF8, 0x0FF0, 0x0FC0, //  head right
            0x0FC0,
            0x1FE0,
            0x3FF0,
            0x3FF0, //  tail swings down
            0x1FFC,
            0x0FEC, //  tail tip low
            0x0CC0,
            0x0840,
            0x18C0,
            0x0000
        ])

        let walk1 = SpriteFrame(rows: [
            0x0060, 0x1FC0, 0x7FC0, 0x7DC0, 0x3FC0, 0x0FC0, //  head left
            0x0FC0,
            0x1FE0,
            0x3FF0,
            0x3FF6,
            0x1FFC,
            0x0FE0,
            0x0CC0,
            0x1020, //  ...#......#.....  legs striding apart
            0x3060, //  ..##......##....
            0x0000
        ])

        let walk2 = SpriteFrame(rows: [
            0x1800, 0x0FE0, 0x0FF8, 0x0EF8, 0x0FF0, 0x0FC0, //  head right
            0x0FC0,
            0x1FE0,
            0x3FF0,
            0x3FF0, //  tail swings down mid-stride
            0x1FFC,
            0x0FEC,
            0x0CC0,
            0x0840,
            0x0CC0, //  ....##..##......  feet together
            0x0000
        ])

        // Happy: maw thrown open mid-leap.
        let happy1 = SpriteFrame(rows: [
            0x0060,
            0x1FC0,
            0x7FC0,
            0x7DC0, //  .#####.###......  eye
            0x07C0, //  .....#####......  jaw open wide
            0x0FC0,
            0x0FC0,
            0x1FE0,
            0x3FF0,
            0x3FF6,
            0x1FFC,
            0x0FE0,
            0x0CC0,
            0x0840,
            0x18C0,
            0x0000
        ])

        let happy2 = SpriteFrame(rows: [
            0x0000,
            0x0060,
            0x1FC0,
            0x7FC0,
            0x7DC0,
            0x07C0,
            0x0FC0,
            0x0FC0,
            0x1FE0,
            0x3FF0,
            0x3FF6,
            0x1FFC,
            0x0FE0,
            0x0CC0,
            0x0840,
            0x18C0
        ])

        let eat1 = SpriteFrame(rows: [
            0x0060,
            0x1FC0,
            0x7FC0,
            0x7DC0,
            0x07C0, //  .....#####......  jaw open
            0x0FC0,
            0x0FC0,
            0x1FE0,
            0x3FF0,
            0x3FF6,
            0x1FFC,
            0x0FE0,
            0x0CC0,
            0x0840,
            0x18C0,
            0x0000
        ])

        let eat2 = SpriteFrame(rows: [
            0x0060,
            0x1FC0,
            0x7FC0,
            0x7DC0,
            0x7FC0, //  .#########......  jaw clamped shut
            0x0FC0,
            0x0FC0,
            0x1FE0,
            0x3FF0,
            0x3FF6,
            0x1FFC,
            0x0FE0,
            0x0CC0,
            0x0840,
            0x18C0,
            0x0000
        ])

        // Hunched sleep: head drooped (horn tucked), eyes shut, tail low.
        let sleep1 = SpriteFrame(rows: [
            0x0038, //  ..........###...  Z
            0x0010, //  ...........#....
            0x1FC0, //  ...#######......  skull top, drooped
            0x7FC0, //  .#########......
            0x7FC0, //  .#########......  eye shut
            0x3FC0, //  ..########......
            0x0FC0, //  ....######......
            0x1FE0, //  ...########.....  shoulders (neck tucked)
            0x3FF0, //  ..##########....
            0x3FF0, //  ..##########....
            0x1FFC, //  ...###########..
            0x0FEC, //  ....#######.##..  tail curled low
            0x0CC0, //  ....##..##......
            0x0840, //  ....#....#......
            0x18C0, //  ...##...##......
            0x0000  //  ................
        ])

        let sleep2 = SpriteFrame(rows: [
            0x001C, //  Z drifts up
            0x0008,
            0x1FC0,
            0x7FC0,
            0x7FC0,
            0x3FC0,
            0x0FC0,
            0x1FE0,
            0x3FF0,
            0x3FF0,
            0x1FFC,
            0x0FEC,
            0x0CC0,
            0x0840,
            0x18C0,
            0x0000
        ])

        // Nova Blast attack - head whips to face the blast,
        // maw open toward it, tail braced low.
        let attack1 = SpriteFrame(rows: [
            0x1800, //  ...##...........  horn
            0x0FE0, //  ....#######.....  skull top
            0x0FF8, //  ....#########...  skull + snout right
            0x0EF8, //  ....###.#####...  eye
            0x0FE0, //  ....#######.....  maw open under snout
            0x0FC0, //  ....######......  chin
            0x0FC0,
            0x1FE0,
            0x3FF0,
            0x3FF0, //  tail braced low
            0x1FFC,
            0x0FEC,
            0x0CC0,
            0x0840,
            0x0C60, //  ....##...##.....  feet point at the foe
            0x0000
        ])

        // Side-walk: T-rex profile — horn swept back, long snout,
        // thick horizontal body, upswept tail, striding legs
        let sideWalk1 = SpriteFrame(rows: [
            0x0180, //  .......##.......  horn
            0x3F00, //  ..######........  skull top
            0xFF00, //  ########........  long snout
            0xF700, //  ####.###........  eye
            0x7F00, //  .#######........  jaw
            0x1F00, //  ...#####........  chin
            0x0F80, //  ....#####.......  neck
            0x0FE0, //  ....#######.....  shoulders
            0x1FF6, //  ...#########.##.  body + tail tip kicked up
            0x1FFE, //  ...############.  body + tail
            0x1FF8, //  ...##########...  tail underside
            0x0FE0, //  ....#######.....  belly
            0x0EC0, //  ....###.##......  thighs
            0x1860, //  ...##....##.....  legs striding
            0x3830, //  ..###.....##....  front foot claw, rear toe-off
            0x0000  //  ................
        ])

        // Legs pass under the body; the head bobs down a pixel.
        let sideWalk2 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0180, //  .......##.......  horn, head bobs down
            0x3F00, //  ..######........
            0xFF00, //  ########........
            0xF700, //  ####.###........  eye
            0x7F00, //  .#######........
            0x1F00, //  ...#####........
            0x0F80, //  ....#####.......  neck
            0x1FF6, //  ...#########.##.  body + tail tip
            0x1FFE, //  ...############.
            0x1FF8, //  ...##########...
            0x0FE0, //  ....#######.....
            0x07C0, //  .....#####......  legs together
            0x0480, //  .....#..#.......
            0x0CC0, //  ....##..##......  feet
            0x0000  //  ................
        ])

        // Frames are authored facing left (the shared convention). Contexts
        // mirror via `.facing(_:)` when the creature should face right.
        // Attack frames alone bake the head + blast facing right so the
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
