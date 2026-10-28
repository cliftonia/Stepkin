import Foundation

// MARK: - Blazekin (Champion) - red fire dinosaur, bulky

extension SpriteCatalog {

    // Blazekin: stocky fire dinosaur — jagged flame crest on the skull,
    // blunt deep muzzle, the bulkiest body of the line, flame-tipped tail
    //
    //         ....#.#.#.......    flame crest
    //         ..########......    flat skull top
    //         .#########......    skull + snout left
    //         .#####.###......    eye
    //         .#########......    deep jaw
    //         ...#######......    chin (mouth step)
    //         ...#######......    chest
    //         ..#########.....    shoulders
    //         .###########..#.    arm nubs + body, flame lick
    //         ..##########.##.    body + flame-tip tail
    //         ..############..    belly + tail
    //         ...########.....    hips
    //         ...###..###.....    thighs
    //         ...##....##.....    shins
    //         ..###...###.....    feet

    static func blazekinFrames(
        _ kind: AnimationKind
    ) -> [SpriteFrame] {
        let idle1 = SpriteFrame(rows: [
            0x0A80, //  ....#.#.#.......  flame crest
            0x3FC0, //  ..########......  flat skull top
            0x7FC0, //  .#########......  skull + snout left
            0x7DC0, //  .#####.###......  eye
            0x7FC0, //  .#########......  deep jaw
            0x1FC0, //  ...#######......  chin, mouth step
            0x1FC0, //  ...#######......  chest
            0x3FE0, //  ..#########.....  shoulders
            0x7FF2, //  .###########..#.  arm nubs + body, flame lick
            0x3FF6, //  ..##########.##.  body, flame-tip tail raised
            0x3FFC, //  ..############..  belly + tail
            0x1FE0, //  ...########.....  hips
            0x1CE0, //  ...###..###.....  thighs
            0x1860, //  ...##....##.....  shins
            0x38E0, //  ..###...###.....  feet
            0x0000  //  ................
        ])

        // Second beat of the left gaze: the tail flame sweeps down wide.
        let idleLeftLow = SpriteFrame(rows: [
            0x0A80, //  flame crest
            0x3FC0, 0x7FC0, 0x7DC0, 0x7FC0, 0x1FC0, //  head left
            0x1FC0,
            0x3FE0,
            0x7FF0, //  .###########....  lick gone
            0x3FF0, //  ..##########....  tail swings down
            0x3FFC,
            0x1FEE, //  ...########.###.  wide flame tip low
            0x1CE0,
            0x1860,
            0x38E0,
            0x0000
        ])

        // The head glances right, tail flame back up.
        let idleRightHigh = SpriteFrame(rows: [
            0x0540, //  .....#.#.#......  flame crest
            0x1FE0, //  ...########.....  flat skull top
            0x1FF0, //  ...#########....  skull + snout right
            0x1DF0, //  ...##.######....  eye
            0x1FF0, //  ...#########....  deep jaw
            0x1FC0, //  ...#######......  chin, mouth step
            0x1FC0,
            0x3FE0,
            0x7FF2, //  flame lick
            0x3FF6, //  flame-tip tail raised
            0x3FFC,
            0x1FE0,
            0x1CE0,
            0x1860,
            0x38E0,
            0x0000
        ])

        let idle2 = SpriteFrame(rows: [
            0x0540, //  flame crest
            0x1FE0, 0x1FF0, 0x1DF0, 0x1FF0, 0x1FC0, //  head right
            0x1FC0,
            0x3FE0,
            0x7FF0,
            0x3FF0, //  tail swings down
            0x3FFC,
            0x1FEE, //  wide flame tip low
            0x1CE0,
            0x1860,
            0x38E0,
            0x0000
        ])

        let walk1 = SpriteFrame(rows: [
            0x0A80, //  flame crest
            0x3FC0, 0x7FC0, 0x7DC0, 0x7FC0, 0x1FC0, //  head left
            0x1FC0,
            0x3FE0,
            0x7FF2,
            0x3FF6,
            0x3FFC,
            0x1FE0,
            0x1CE0,
            0x3030, //  ..##......##....  legs striding apart
            0x6060, //  .##......##.....
            0x0000
        ])

        let walk2 = SpriteFrame(rows: [
            0x0540, //  flame crest
            0x1FE0, 0x1FF0, 0x1DF0, 0x1FF0, 0x1FC0, //  head right
            0x1FC0,
            0x3FE0,
            0x7FF0,
            0x3FF0, //  tail swings down mid-stride
            0x3FFC,
            0x1FEE,
            0x1CE0,
            0x0CC0, //  ....##..##......  legs together
            0x1980, //  ...##..##.......  feet
            0x0000
        ])

        // Happy: maw thrown open mid-leap.
        let happy1 = SpriteFrame(rows: [
            0x0A80, //  flame crest
            0x3FC0,
            0x7FC0,
            0x7DC0, //  .#####.###......  eye
            0x0FC0, //  ....######......  jaw open wide
            0x1FC0,
            0x1FC0,
            0x3FE0,
            0x7FF2,
            0x3FF6,
            0x3FFC,
            0x1FE0,
            0x1CE0,
            0x1860,
            0x38E0,
            0x0000
        ])

        let happy2 = SpriteFrame(rows: [
            0x0000,
            0x0A80, //  flame crest
            0x3FC0,
            0x7FC0,
            0x7DC0,
            0x0FC0,
            0x1FC0,
            0x1FC0,
            0x3FE0,
            0x7FF2,
            0x3FF6,
            0x3FFC,
            0x1FE0,
            0x1CE0,
            0x1860,
            0x38E0
        ])

        let eat1 = SpriteFrame(rows: [
            0x0A80, //  flame crest
            0x3FC0,
            0x7FC0,
            0x7DC0,
            0x0FC0, //  ....######......  jaw open
            0x1FC0,
            0x1FC0,
            0x3FE0,
            0x7FF2,
            0x3FF6,
            0x3FFC,
            0x1FE0,
            0x1CE0,
            0x1860,
            0x38E0,
            0x0000
        ])

        let eat2 = SpriteFrame(rows: [
            0x0A80, //  flame crest
            0x3FC0,
            0x7FC0,
            0x7DC0,
            0x7FC0, //  .#########......  jaw shut
            0x7FC0, //  .#########......  chin clamped flush
            0x1FC0,
            0x3FE0,
            0x7FF2,
            0x3FF6,
            0x3FFC,
            0x1FE0,
            0x1CE0,
            0x1860,
            0x38E0,
            0x0000
        ])

        // Hunched sleep: head drooped, eyes shut, the crest flame is out.
        let sleep1 = SpriteFrame(rows: [
            0x0038, //  ..........###...  Z
            0x0010, //  ...........#....
            0x3FC0, //  ..########......  skull top, drooped (no crest)
            0x7FC0, //  .#########......
            0x7FC0, //  .#########......  eye shut
            0x7FC0, //  .#########......
            0x1FC0, //  ...#######......  chin
            0x3FE0, //  ..#########.....  shoulders (neck tucked)
            0x7FF0, //  .###########....
            0x3FF0, //  ..##########....
            0x3FFC, //  ..############..
            0x1FEE, //  ...########.###.  flame tip curled low
            0x1CE0, //  ...###..###.....
            0x1860, //  ...##....##.....
            0x38E0, //  ..###...###.....
            0x0000  //  ................
        ])

        let sleep2 = SpriteFrame(rows: [
            0x001C, //  Z drifts up
            0x0008,
            0x3FC0,
            0x7FC0,
            0x7FC0,
            0x7FC0,
            0x1FC0,
            0x3FE0,
            0x7FF0,
            0x3FF0,
            0x3FFC,
            0x1FEE,
            0x1CE0,
            0x1860,
            0x38E0,
            0x0000
        ])

        // Fire Breath attack - head whips to face the flames,
        // maw open toward them, tail braced low.
        let attack1 = SpriteFrame(rows: [
            0x0540, //  flame crest
            0x1FE0, //  ...########.....  skull top
            0x1FF0, //  ...#########....  skull + snout right
            0x1DF0, //  ...##.######....  eye
            0x1FC0, //  ...#######......  maw open under snout
            0x1FC0, //  ...#######......  chin
            0x1FC0,
            0x3FE0,
            0x7FF0,
            0x3FF0, //  tail braced low
            0x3FFC,
            0x1FEE,
            0x1CE0,
            0x1860,
            0x1C70, //  ...###...###....  feet point at the foe
            0x0000
        ])

        // Side-walk: stocky profile — flame crest, blunt snout, deep
        // chest, flame-tipped tail, striding legs
        let sideWalk1 = SpriteFrame(rows: [
            0x0000, //  ................
            0x2A00, //  ..#.#.#.........  flame crest
            0x3E00, //  ..#####.........  skull top
            0xFF00, //  ########........  blunt snout
            0xF700, //  ####.###........  eye
            0x7F00, //  .#######........  jaw
            0x1F00, //  ...#####........  chin
            0x0FC2, //  ....######....#.  neck, flame lick over tail
            0x1FF6, //  ...#########.##.  body + flame-tip tail
            0x3FFE, //  ..#############.  deep body + tail
            0x3FF8, //  ..############..  tail underside
            0x1FE0, //  ...########.....  belly
            0x0EE0, //  ....###.###.....  thighs
            0x1860, //  ...##....##.....  legs striding
            0x3830, //  ..###.....##....  front foot claw, rear toe-off
            0x0000  //  ................
        ])

        // Legs pass under the body; the head bobs down a pixel.
        let sideWalk2 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0000, //  ................
            0x2A00, //  ..#.#.#.........  flame crest, head bobs down
            0x3E00, //  ..#####.........
            0xFF00, //  ########........
            0xF700, //  ####.###........  eye
            0x7F00, //  .#######........
            0x1F02, //  ...#####......#.  chin, flame lick over tail
            0x1FF6, //  ...#########.##.  body + flame-tip tail
            0x3FFE, //  ..#############.
            0x3FF8, //  ..############..
            0x1FE0, //  ...########.....
            0x07C0, //  .....#####......  legs together
            0x0480, //  .....#..#.......
            0x0CC0, //  ....##..##......  feet
            0x0000  //  ................
        ])

        // Frames are authored facing left (the shared convention). Contexts
        // mirror via `.facing(_:)` when the creature should face right.
        // Attack frames alone bake the head + flames facing right so the
        // maw always agrees with the projectile, mirrored or not.
        switch kind {
        case .idle:
            // Head holds left for two beats, then right for two beats;
            // the tail flame flickers up-down on every beat.
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
