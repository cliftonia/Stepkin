import Foundation

// MARK: - Steelkin (Ultimate) - cyborg dinosaur, massive

extension SpriteCatalog {

    // Steelkin: armored bruiser — turned head with a metal visor slit
    // and back-swept horn, broad shoulders with massive arms whose
    // knuckles drag the ground, a single chest hatch that slides open
    // to fire the Giga Blaster, and heavy mech legs
    //
    //         .........##.....    horn
    //         ...#######......    skull top
    //         .#########......    skull + snout left
    //         .####..###......    visor slit
    //         ..########......    jaw
    //         ....######......    chin
    //         ...########.....    broad chest
    //         ..############..    shoulders
    //         .##.########.##.    massive arms + torso
    //         ##..########..##    knuckles drag the ground
    //         ....########....    torso
    //         ....##....##....    chest hatch
    //         ....########....    belly
    //         ...###...###....    heavy legs
    //         ..####....####..    mech feet
    //
    // swiftlint:disable:next function_body_length
    static func steelkinFrames(
        _ kind: AnimationKind
    ) -> [SpriteFrame] {
        let idle1 = SpriteFrame(rows: [
            0x0060, //  .........##.....  horn
            0x1FC0, //  ...#######......  skull top
            0x7FC0, //  .#########......  skull + snout left
            0x79C0, //  .####..###......  visor slit
            0x3FC0, //  ..########......  jaw
            0x0FC0, //  ....######......  chin
            0x1FE0, //  ...########.....  broad chest
            0x3FFC, //  ..############..  shoulders
            0x6FF6, //  .##.########.##.  massive arms + torso
            0xCFF3, //  ##..########..##  knuckles drag the ground
            0x0FF0, //  ....########....  torso
            0x0C30, //  ....##....##....  chest hatch
            0x0FF0, //  ....########....  belly
            0x1C70, //  ...###...###....  heavy legs
            0x1C70, //  ...###...###....
            0x3C3C  //  ..####....####..  mech feet
        ])

        // Second beat of the left gaze: the fists tuck in.
        let idleLeftLow = SpriteFrame(rows: [
            0x0060, 0x1FC0, 0x7FC0, 0x79C0, 0x3FC0, 0x0FC0, //  head left
            0x1FE0,
            0x3FFC,
            0x6FF6,
            0x6FF6, //  .##.########.##.  fists tuck in
            0x0FF0,
            0x0C30,
            0x0FF0,
            0x1C70,
            0x1C70,
            0x3C3C
        ])

        // The head glances right, knuckles back down.
        let idleRightHigh = SpriteFrame(rows: [
            0x1800, //  ...##...........  horn
            0x0FE0, //  ....#######.....  skull top
            0x0FF8, //  ....#########...  skull + snout right
            0x0E78, //  ....###..####...  visor slit
            0x0FF0, //  ....########....  jaw
            0x0FC0, //  ....######......  chin
            0x1FE0,
            0x3FFC,
            0x6FF6,
            0xCFF3, //  knuckles drag
            0x0FF0,
            0x0C30,
            0x0FF0,
            0x1C70,
            0x1C70,
            0x3C3C
        ])

        let idle2 = SpriteFrame(rows: [
            0x1800, 0x0FE0, 0x0FF8, 0x0E78, 0x0FF0, 0x0FC0, //  head right
            0x1FE0,
            0x3FFC,
            0x6FF6,
            0x6FF6, //  fists tuck in
            0x0FF0,
            0x0C30,
            0x0FF0,
            0x1C70,
            0x1C70,
            0x3C3C
        ])

        let walk1 = SpriteFrame(rows: [
            0x0060, 0x1FC0, 0x7FC0, 0x79C0, 0x3FC0, 0x0FC0, //  head left
            0x1FE0,
            0x3FFC,
            0x6FF6,
            0xCFF3,
            0x0FF0,
            0x0C30,
            0x0FF0,
            0x1C70,
            0x3838, //  ..###.....###...  legs striding apart
            0x701C  //  .###.......###..  feet
        ])

        let eat1 = SpriteFrame(rows: [
            0x0060,
            0x1FC0,
            0x7FC0,
            0x79C0,
            0x07C0, //  .....#####......  jaw open wide
            0x0FC0,
            0x1FE0,
            0x3FFC,
            0x6FF6,
            0x6FF6, //  fists tucked while feeding
            0x0FF0,
            0x0C30,
            0x0FF0,
            0x1C70,
            0x1C70,
            0x3C3C
        ])

        let eat2 = SpriteFrame(rows: [
            0x0060,
            0x1FC0,
            0x7FC0,
            0x79C0,
            0x7FC0, //  .#########......  jaw clamped shut
            0x0FC0,
            0x1FE0,
            0x3FFC,
            0x6FF6,
            0x6FF6,
            0x0FF0,
            0x0C30,
            0x0FF0,
            0x1C70,
            0x1C70,
            0x3C3C
        ])

        // Powered-down sleep: head drooped, visor dark, arms slack.
        let sleep1 = SpriteFrame(rows: [
            0x0038, //  ..........###...  Z
            0x0010, //  ...........#....
            0x1FC0, //  ...#######......  skull top, drooped
            0x7FC0, //  .#########......
            0x7FC0, //  .#########......  visor dark
            0x3FC0, //  ..########......
            0x0FC0, //  ....######......
            0x3FFC, //  ..############..  shoulders (neck tucked)
            0x6FF6, //  .##.########.##.  arms slack
            0x0FF0, //  ....########....
            0x0C30, //  ....##....##....  chest hatch
            0x0FF0, //  ....########....
            0x1C70, //  ...###...###....
            0x1C70, //  ...###...###....
            0x3C3C, //  ..####....####..
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
            0x3FFC,
            0x6FF6,
            0x0FF0,
            0x0C30,
            0x0FF0,
            0x1C70,
            0x1C70,
            0x3C3C,
            0x0000
        ])

        // Giga Blaster — the head whips right and the chest hatch
        // slides open tall.
        let attack1 = SpriteFrame(rows: [
            0x1800, 0x0FE0, 0x0FF8, 0x0E78, 0x0FF0, 0x0FC0, //  head right
            0x1FE0,
            0x3FFC,
            0x6FF6, //  arms braced
            0xCFF3,
            0x0C30, //  ....##....##....  hatch slides open tall
            0x0C30,
            0x0FF0,
            0x1C70,
            0x1C70,
            0x3C3C
        ])

        // Side-walk: mech profile — horn, visor slit, dorsal armor
        // spikes on the back, heavy tail, striding legs
        let sideWalk1 = SpriteFrame(rows: [
            0x0180, //  .......##.......  horn
            0x3F00, //  ..######........  skull top
            0xFF00, //  ########........  long snout
            0xE700, //  ###..###........  visor slit
            0x7F00, //  .#######........  jaw
            0x1F00, //  ...#####........  chin
            0x0FA0, //  ....#####.#.....  neck + armor spike
            0x0FC8, //  ....######..#...  shoulders + spike
            0x1FF6, //  ...#########.##.  body + tail tip
            0x1FFC, //  ...###########..  body + tail
            0x1FE0, //  ...########.....  tail underside
            0x0FC0, //  ....######......  belly
            0x0EC0, //  ....###.##......  thighs
            0x1860, //  ...##....##.....  legs striding
            0x3830, //  ..###.....##....  feet
            0x0000  //  ................
        ])

        // Legs pass under the body; the head bobs down a pixel.
        let sideWalk2 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0180, //  .......##.......  horn, head bobs down
            0x3F00, //  ..######........
            0xFF00, //  ########........
            0xE700, //  ###..###........  visor slit
            0x7F00, //  .#######........
            0x1F00, //  ...#####........
            0x0FA0, //  ....#####.#.....  neck + spike
            0x1FF6, //  ...#########.##.  body + tail tip
            0x1FFC, //  ...###########..
            0x1FE0, //  ...########.....
            0x0FC0, //  ....######......
            0x07C0, //  .....#####......  legs together
            0x0480, //  .....#..#.......
            0x0CC0, //  ....##..##......  feet
            0x0000  //  ................
        ])

        switch kind {
        case .idle:
            // Head holds left for two beats, then right for two beats;
            // the fists pump on every second beat.
            return [idle1, idleLeftLow, idleRightHigh, idle2]
        case .walk:
            return [
                walk1,
                walk1.shiftedDown(1),
                idle2,
                idle2.shiftedDown(1)
            ]
        case .sideWalk:
            return [sideWalk1, sideWalk2]
        case .happy:
            return bounceHappy(idle: idle1, idle1, idleRightHigh)
        case .eat:
            return chomp(eat1, eat2, rest: idle1)
        case .sleep:
            // Overlay onto idle1 only — idle2 glances right, and a
            // powered-down mech must not whip its head about.
            return sleepCycle(sleep1, sleep2, overlayingZOn: idle1)
        case .attack:
            return strike(idle: idle1, attack1)
        case .refuse:
            return defaultAnimationFromIdle(idle1, idle2, kind)
        }
    }
}
