import Foundation

// MARK: - Plushkin (Ultimate) - teddy bear, heart on belly

extension SpriteCatalog {

    // Plushkin: round teddy — wiggling ears, button eyes, stitched
    // mouth, hug-ready arms with paw tips, and a heart pressed into
    // the belly as negative space
    //
    //         ..###......###..    big round ears
    //         .#####....#####.
    //         ....########....    head top
    //         ...##########...
    //         ...##.####.##...    button eyes
    //         ...##########...
    //         ...####..####...    stitched mouth
    //         ....########....    chin
    //         .##############.    arms spread for a hug
    //         .#.##########.#.    paw tips
    //         ...###..#..##...    heart lobes on the belly
    //         ...###.....##...    heart body
    //         ...####...###...    heart point
    //         ....########....
    //         .....##..##.....    legs
    //         ....###..###....    feet
    //
    // swiftlint:disable:next function_body_length
    static func plushkinFrames(
        _ kind: AnimationKind
    ) -> [SpriteFrame] {
        let idle1 = SpriteFrame(rows: [
            0x381C, //  ..###......###..  ears
            0x7C3E, //  .#####....#####.  big round ears
            0x0FF0, //  ....########....  head top
            0x1FF8, //  ...##########...
            0x1BD8, //  ...##.####.##...  button eyes
            0x1FF8, //  ...##########...
            0x1E78, //  ...####..####...  stitched mouth
            0x0FF0, //  ....########....  chin
            0x7FFE, //  .##############.  arms spread for a hug
            0x5FFA, //  .#.##########.#.  paw tips
            0x1C98, //  ...###..#..##...  heart lobes on the belly
            0x1C18, //  ...###.....##...  heart body
            0x1E38, //  ...####...###...  heart point
            0x0FF0, //  ....########....
            0x0660, //  .....##..##.....  legs
            0x0E70  //  ....###..###....  feet
        ])

        // Ears wiggle in and the arms settle lower.
        let idle2 = SpriteFrame(rows: [
            0x1C38, //  ...###....###...  ears wiggle
            0x7C3E, //  .#####....#####.  big round ears
            0x0FF0,
            0x1FF8,
            0x1BD8, //  button eyes
            0x1FF8,
            0x1E78, //  stitched mouth
            0x0FF0,
            0x1FF8, //  ...##########...  shoulders
            0x7FFE, //  .##############.  arms settle lower
            0x5C9A, //  .#.###..#..##.#.  paw tips + heart lobes
            0x1C18, //  heart body
            0x1E38, //  ...####...###...  heart point
            0x0FF0,
            0x0660,
            0x0E70
        ])

        // Happy: arms thrown high in a cheer.
        let happy1 = SpriteFrame(rows: [
            0x381C,
            0x7C3E,
            0x0FF0,
            0x1FF8,
            0x1BD8,
            0x1FF8,
            0x1E78,
            0x6FF6, //  .##.########.##.  arms thrown high
            0x7FFE, //  .##############.
            0x1FF8,
            0x1C98, //  heart
            0x1C18,
            0x1E38, //  ...####...###...  heart point
            0x0FF0,
            0x0660,
            0x0E70
        ])

        let happy2 = SpriteFrame(rows: [
            0x1C38, //  ears wiggle mid-cheer
            0x7C3E,
            0x0FF0,
            0x1FF8,
            0x1BD8,
            0x1FF8,
            0x1E78,
            0x6FF6,
            0x7FFE,
            0x1FF8,
            0x1C98,
            0x1C18,
            0x1E38, //  ...####...###...  heart point
            0x0FF0,
            0x0660,
            0x0E70
        ])

        let eat1 = SpriteFrame(rows: [
            0x381C,
            0x7C3E,
            0x0FF0,
            0x1FF8,
            0x1BD8,
            0x1FF8,
            0x1C38, //  ...###....###...  mouth open wide
            0x0FF0,
            0x1FF8, //  arms tucked while nibbling
            0x1FF8,
            0x1C98,
            0x1C18,
            0x1E38, //  ...####...###...  heart point
            0x0FF0,
            0x0660,
            0x0E70
        ])

        let eat2 = SpriteFrame(rows: [
            0x381C,
            0x7C3E,
            0x0FF0,
            0x1FF8,
            0x1BD8,
            0x1FF8,
            0x1FF8, //  ...##########...  mouth closed
            0x0FF0,
            0x1FF8,
            0x1FF8,
            0x1C98,
            0x1C18,
            0x1E38, //  ...####...###...  heart point
            0x0FF0,
            0x0660,
            0x0E70
        ])

        // Sleep: ears flopped flat, eyes shut, arms hugging itself.
        let sleep1 = SpriteFrame(rows: [
            0x0038, //  ..........###...  Z
            0x6006, //  .##..........##.  ears flopped flat
            0x0FF0, //  ....########....
            0x1FF8, //  ...##########...
            0x1FF8, //  ...##########...  eyes shut
            0x1FF8, //  ...##########...
            0x1E78, //  ...####..####...
            0x0FF0, //  ....########....
            0x3FFC, //  ..############..  arms hugging itself
            0x1FF8, //  ...##########...
            0x1C98, //  heart
            0x1C18,
            0x1E38, //  ...####...###...  heart point
            0x0FF0,
            0x0660,
            0x0E70
        ])

        let sleep2 = SpriteFrame(rows: [
            0x001C, //  Z drifts up
            0x6006,
            0x0FF0,
            0x1FF8,
            0x1FF8,
            0x1FF8,
            0x1E78,
            0x0FF0,
            0x3FFC,
            0x1FF8,
            0x1C98,
            0x1C18,
            0x1E38, //  ...####...###...  heart point
            0x0FF0,
            0x0660,
            0x0E70
        ])

        // Hearts Attack — the bear leans in, arms reaching out.
        let attack1 = SpriteFrame(rows: [
            0x7038, //  .###......###...  ears (leaning in)
            0xF87C, //  #####....#####..
            0x1FE0, //  ...########.....  head top
            0x3FF0, //  ..##########....
            0x37B0, //  ..##.####.##....  button eyes
            0x3FF0, //  ..##########....
            0x3CF0, //  ..####..####....  stitched mouth
            0x1FE0, //  ...########.....
            0x3FFE, //  ..#############.  arm reaches out
            0x7FF0, //  .###########....  paw braced
            0x3930, //  ..###..#..##....  heart lobes
            0x3830, //  ..###.....##....  heart body
            0x3C70, //  ..####...###....  heart point
            0x1FE0, //  ...########.....
            0x0CC0, //  ....##..##......
            0x1CE0  //  ...###..###.....
        ])

        // Side profile: waddling teddy — one ear, muzzle poking out,
        // tail nub on the back, stubby waddling legs
        let sideWalk1 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0000, //  ................
            0x3C00, //  ..####..........  ear
            0x7E00, //  .######.........
            0x3F00, //  ..######........  head
            0x7F80, //  .########.......
            0xEF80, //  ###.#####.......  muzzle + eye
            0x7F80, //  .########.......
            0x3F00, //  ..######........  chin
            0x3FD8, //  ..########.##...  body + tail nub
            0x7FF8, //  .############...  body + tail
            0x7FE0, //  .##########.....
            0x7FE0, //  .##########.....
            0x3FC0, //  ..########......
            0x30C0, //  ..##....##......  waddle stride
            0x70E0  //  .###....###.....  feet
        ])

        // Ear bobs as the legs come together mid-waddle.
        let sideWalk2 = SpriteFrame(rows: [
            0x0000, //  ................
            0x0000, //  ................
            0x1E00, //  ...####.........  ear bobs
            0x7E00, //  .######.........
            0x3F00, //  ..######........
            0x7F80, //  .########.......
            0xEF80, //  ###.#####.......  muzzle + eye
            0x7F80, //  .########.......
            0x3F00, //  ..######........
            0x3FD8, //  ..########.##...  body + tail nub
            0x7FF8, //  .############...
            0x7FE0, //  .##########.....
            0x7FE0, //  .##########.....
            0x3FC0, //  ..########......
            0x0CC0, //  ....##..##......  legs together
            0x1CE0  //  ...###..###.....  feet
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
            // Eyes stay shut on every beat while the Z's pulse.
            return sleepCycle(sleep1, sleep2)
        case .attack:
            return strike(idle: idle1, attack1)
        case .refuse:
            return defaultAnimationFromIdle(idle1, idle2, kind)
        }
    }
}
