/// The LCD's fixed cell layout, shared by the screen and the notification image.
nonisolated enum LCDGeometry {

    /// The number of cell columns across the screen.
    static let columns = 32

    /// The number of cell rows down the screen.
    static let rows = 20

    /// The row the ground line and the poop piles rest on.
    static let groundRow = 19

    /// The spacing, in cells, between the backdrop grid's lines.
    static let gridStride = 4

    /// The columns that carry a tuft of grass one row above the ground.
    static let tuftColumns: [Int] = [1, 5, 10, 15, 21, 26, 30]

    /// The cell at the centre of the moon disc.
    static let moonCenter = (x: 26, y: 4)

    /// The 37 cell offsets, from the moon's centre, that make up the full moon disc.
    static let moonDisc: [(dx: Int, dy: Int)] = [
        (-1, -3), (0, -3), (1, -3),
        (-2, -2), (-1, -2), (0, -2), (1, -2), (2, -2),
        (-3, -1), (-2, -1), (-1, -1), (0, -1), (1, -1), (2, -1), (3, -1),
        (-3, 0), (-2, 0), (-1, 0), (0, 0), (1, 0), (2, 0), (3, 0),
        (-3, 1), (-2, 1), (-1, 1), (0, 1), (1, 1), (2, 1), (3, 1),
        (-2, 2), (-1, 2), (0, 2), (1, 2), (2, 2),
        (-1, 3), (0, 3), (1, 3)
    ]

    /// The six fixed cells of the night-sky star field kept clear of the pet.
    static let starSpots: [(x: Int, y: Int)] = [(3, 2), (6, 5), (4, 9), (2, 13), (30, 11), (28, 14)]
}
