import Foundation

// MARK: - Dreadkin (Champion) - winged demon, tall and thin

extension SpriteCatalog {

    // Dreadkin: gaunt bat-winged demon — out-curved horns at the skull's
    // corners, grim slit face, long thin legs. The front frames carry
    // three wing positions (up / mid / down) so the idle beats a full
    // wingflap. A solid face row separates the eyes from the mouth slit.
    //
    //         ...#........#...    horn tips curve outward
    //         .#..#......#..#.    horns + wing tips (mid)
    //         .#...######...#.    head + wings
    //         .##..#.##.#..##.    eyes
    //         .##..######..##.    solid face row
    //         ..##.##..##.##..    grim mouth slit + membrane
    //         ...##########...    wings meet the shoulders
    //         ..#.########.#..    scalloped membrane edge
    //         .....######.....    chest
    //         ......####......    gaunt body
    //         ......#..#......    long thin legs
    //         .....##..##.....    feet

    static func dreadkinFrames(
        _ kind: AnimationKind
    ) -> [SpriteFrame] {
        // Wings spread wide at shoulder height.
        let wingsMid = SpriteFrame(rows: [
            0x1008, //  ...#........#...  horn tips
            0x4812, //  .#..#......#..#.  horns + wing tips
            0x47E2, //  .#...######...#.  head + wings
            0x65A6, //  .##..#.##.#..##.  eyes
            0x67E6, //  .##..######..##.  solid face row
            0x366C, //  ..##.##..##.##..  mouth slit + membrane
            0x1FF8, //  ...##########...  wings meet shoulders
            0x2FF4, //  ..#.########.#..  scalloped membrane edge
            0x07E0, //  .....######.....  chest
            0x03C0, //  ......####......
            0x03C0, //  ......####......
            0x03C0, //  ......####......
            0x0240, //  ......#..#......
            0x0240, //  ......#..#......
            0x0660, //  .....##..##.....
            0x0000  //  ................
        ])

        // Wings swept fully down along the body, tips pointing low.
        let wingsDown = SpriteFrame(rows: [
            0x1008, //  ...#........#...  horn tips
            0x0810, //  ....#......#....  horns
            0x07E0, //  .....######.....  head
            0x05A0, //  .....#.##.#.....  eyes
            0x07E0, //  .....######.....  solid face row
            0x1668, //  ...#.##..##.#...  mouth slit + wing roots
            0x37EC, //  ..##.######.##..  chin + wings sweeping down
            0x6FF6, //  .##.########.##.  shoulders + wings
            0x67E6, //  .##..######..##.  chest + wings
            0x43C2, //  .#....####....#.  body + wing tips low
            0x03C0, //  ......####......
            0x03C0, //  ......####......
            0x0240, //  ......#..#......
            0x0240, //  ......#..#......
            0x0660, //  .....##..##.....
            0x0000  //  ................
        ])

        let walk1 = SpriteFrame(rows: [
            0x1008, 0x4812, 0x47E2, 0x65A6, 0x67E6, //  wings mid
            0x366C,
            0x1FF8,
            0x2FF4,
            0x07E0,
            0x03C0,
            0x03C0,
            0x03C0,
            0x0240,
            0x0420, //  .....#....#.....  legs striding apart
            0x0C30, //  ....##....##....
            0x0000
        ])

        let eat1 = SpriteFrame(rows: [
            0x1008,
            0x4812,
            0x47E2,
            0x65A6,
            0x67E6,
            0x342C, //  ..##.#....#.##..  maw gapes wide
            0x1FF8,
            0x2FF4,
            0x07E0,
            0x03C0,
            0x03C0,
            0x03C0,
            0x0240,
            0x0240,
            0x0660,
            0x0000
        ])

        let eat2 = SpriteFrame(rows: [
            0x1008,
            0x4812,
            0x47E2,
            0x65A6,
            0x67E6,
            0x37EC, //  ..##.######.##..  mouth clamped shut
            0x1FF8,
            0x2FF4,
            0x07E0,
            0x03C0,
            0x03C0,
            0x03C0,
            0x0240,
            0x0240,
            0x0660,
            0x0000
        ])

        // Sleep: eyes shut, wings drooped fully down.
        let sleep1 = SpriteFrame(rows: [
            0x1008,
            0x0810,
            0x07E0,
            0x07E0, //  .....######.....  eyes shut
            0x07E0,
            0x1668,
            0x37EC,
            0x6FF6,
            0x67E6,
            0x43C2,
            0x03C0,
            0x03C0,
            0x0240,
            0x0240,
            0x0660,
            0x0000
        ])

        // Side-walk: gaunt profile — swept horns, folded cloak-wing on
        // the back, long striding legs
        let sideWalk1 = SpriteFrame(rows: [
            0x0300, //  ......##........  horns swept back
            0x3E00, //  ..#####.........  head top
            0x7F00, //  .#######........  head
            0x6F00, //  .##.####........  eye
            0x3F00, //  ..######........  jaw
            0x0E20, //  ....###...#.....  neck, wing tip behind
            0x1F20, //  ...#####..#.....  shoulders + wing
            0x0F60, //  ....####.##.....  body + wing
            0x0FF0, //  ....########....  wing folds against the back
            0x0FE0, //  ....#######.....
            0x0F80, //  ....#####.......
            0x0700, //  .....###........  waist
            0x0700, //  .....###........
            0x0880, //  ....#...#.......  long legs stride
            0x1080, //  ...#....#.......
            0x3180  //  ..##...##.......  feet
        ])

        // Legs pass under the body; the demon stalks down a pixel.
        let sideWalk2 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0300, //  ......##........  horns, head bobs down
            0x3E00, //  ..#####.........
            0x7F00, //  .#######........
            0x6F00, //  .##.####........  eye
            0x3F00, //  ..######........
            0x0E20, //  ....###...#.....  neck, wing tip
            0x1F20, //  ...#####..#.....
            0x0F60, //  ....####.##.....
            0x0FF0, //  ....########....
            0x0FE0, //  ....#######.....
            0x0F80, //  ....#####.......
            0x0700, //  .....###........
            0x0700, //  .....###........
            0x0500, //  .....#.#........  legs together
            0x0D80  //  ....##.##.......  feet
        ])

        switch kind {
        case .idle:
            // An uneven wingbeat — held glides and quick double flaps —
            // so the looping idle doesn't read as a metronome.
            return [
                wingsMid, wingsDown,
                wingsMid, wingsMid,
                wingsDown, wingsMid,
                wingsDown, wingsDown
            ]
        case .walk:
            return [walk1, wingsDown]
        case .sideWalk:
            return [sideWalk1, sideWalk2]
        case .happy:
            // Crouch with wings down, then leap on beating wings.
            return [
                wingsDown.shiftedDown(1),
                wingsMid,
                wingsDown,
                wingsMid.overlaying(SharedSprites.landingDust)
            ]
        case .eat:
            return chomp(eat1, eat2, rest: wingsMid)
        case .sleep:
            // Eyes stay shut on every beat while the Z's pulse.
            return sleepCycle(sleep1, sleep1, overlayingZOn: sleep1)
        case .attack:
            return strike(idle: wingsMid, wingsDown)
        case .refuse:
            return defaultAnimationFromIdle(wingsMid, wingsDown, kind)
        }
    }
}
