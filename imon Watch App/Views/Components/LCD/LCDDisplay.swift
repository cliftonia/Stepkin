import SwiftUI

/// The LCD screen: a SwiftUI `Canvas` painting a 32×20 grid of 1-bit cells.
/// Every layer — sprites, weather, room, poop, call sign — is a list of lit
/// cells filled per frame, and a `TimelineView` drives redraws only while
/// something on screen animates.
struct LCDDisplay: View {

    /// Everything a frame draws — sprites, poop, weather, and the call sign.
    let configuration: LCDDisplayConfiguration

    /// A frozen animation phase, set only by the test-only initialiser so a
    /// render is reproducible; nil in production, where the clock drives it.
    private let fixedWeatherPhase: Int?

    /// Creates the live LCD, animated by a `TimelineView` whenever something on
    /// screen moves.
    init(configuration: LCDDisplayConfiguration) {
        self.configuration = configuration
        self.fixedWeatherPhase = nil
    }

    /// Test-only seam: creates an LCD frozen at `fixedWeatherPhase`, drawn
    /// without the `TimelineView`, so snapshot tests render one exact frame.
    /// Production code never calls this.
    init(configuration: LCDDisplayConfiguration, fixedWeatherPhase: Int) {
        self.configuration = configuration
        self.fixedWeatherPhase = fixedWeatherPhase
    }

    /// The active palette - `nightRed` in battery-saver mode, else `classic`.
    @Environment(\.lcdTheme) private var theme

    private var isAnimated: Bool {
        configuration.weatherCondition != nil || configuration.stormFlash || configuration.evolveFlash || configuration.showCallSign
    }

    /// Lit at night - the weather plays in a window inside a room.
    private var isIndoor: Bool {
        configuration.dayPhase == .inside
    }

    private static let weatherFrameInterval: TimeInterval = 0.18

    // MARK: - Colors

    private var backgroundColor: Color {
        theme.backgroundColor(lightsOn: configuration.lightsOn)
    }

    /// The "lit pixel" colour. Not private - the weather extension draws with it.
    var basePixelColor: Color {
        theme.pixelColor(lightsOn: configuration.lightsOn)
    }

    /// True when the screen background is dark - the lights-off night scene or the
    /// red battery-saver palette. Not private - the scene extension reads it to
    /// lift the faint grid and ground, since a bright line at low opacity is all
    /// but invisible on black. On the lit green day screen the low opacity reads.
    var isDarkScreen: Bool {
        theme == .nightRed || !configuration.lightsOn
    }

    /// The room's ambient shade, away from the lamp's bright pool. Shared by the
    /// indoor glow and the eye-hole backing so they stay in step.
    static let roomAmbientColor = Color(red: 84 / 255, green: 108 / 255, blue: 68 / 255)

    /// Interior-hole masks are pure functions of the sprite, so cache them —
    /// the flood fill would otherwise rerun for every sprite on every redraw
    /// (several per second whenever weather or the call sign animates).
    private static var holeCache: [SpriteFrame: SpriteFrame] = [:]

    private static func interiorHoles(of sprite: SpriteFrame) -> SpriteFrame {
        if let cached = holeCache[sprite] { return cached }
        let holes = sprite.interiorHoles()
        // The frame catalog is finite, but composed one-off frames (overlays,
        // shifts) could grow the cache slowly — reset rather than grow forever.
        if holeCache.count > 512 { holeCache.removeAll(keepingCapacity: true) }
        holeCache[sprite] = holes
        return holes
    }

    var body: some View {
        if let fixedWeatherPhase {
            styledCanvas(weatherPhase: fixedWeatherPhase)
        } else if isAnimated {
            TimelineView(.periodic(from: .now, by: Self.weatherFrameInterval)) { timeline in
                // Wrap the tick count well within 32-bit Int range (watchOS is
                // arm64_32) - the effects all cycle on `% n` so a slow wrap is fine.
                let ticks = timeline.date.timeIntervalSinceReferenceDate
                    / Self.weatherFrameInterval
                let phase = Int(ticks.truncatingRemainder(dividingBy: 1_000_000))
                styledCanvas(weatherPhase: phase)
            }
        } else {
            styledCanvas(weatherPhase: 0)
        }
    }

    private func styledCanvas(weatherPhase: Int) -> some View {
        Canvas { context, size in
            drawScene(weatherPhase: weatherPhase, in: context, size: size)
        }
        .background(backgroundColor)
        .aspectRatio(Double(LCDGeometry.columns) / Double(LCDGeometry.rows), contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .accessibilityHidden(true)
    }

    private func drawScene(
        weatherPhase: Int,
        in context: GraphicsContext,
        size: CGSize
    ) {
        let pixelWidth = size.width / CGFloat(LCDGeometry.columns)
        let pixelHeight = size.height / CGFloat(LCDGeometry.rows)

        if isIndoor {
            drawRoomGlow(
                in: context, size: size,
                pixelWidth: pixelWidth, pixelHeight: pixelHeight
            )
        }

        drawGrid(in: context, size: size, pixelWidth: pixelWidth, pixelHeight: pixelHeight)
        drawGround(in: context, size: size, pixelWidth: pixelWidth, pixelHeight: pixelHeight)

        // Indoors the room (window, weather, furniture, lamp) sits behind the
        // pet; outdoors the weather plays over everything.
        if isIndoor {
            drawWeather(
                phase: weatherPhase, in: context,
                pixelWidth: pixelWidth, pixelHeight: pixelHeight
            )
        }

        drawSprites(in: context, pixelWidth: pixelWidth, pixelHeight: pixelHeight)
        drawPoop(in: context, pixelWidth: pixelWidth, pixelHeight: pixelHeight)

        if !isIndoor {
            drawWeather(
                phase: weatherPhase, in: context,
                pixelWidth: pixelWidth, pixelHeight: pixelHeight
            )
            drawLightning(
                phase: weatherPhase, in: context, size: size,
                pixelWidth: pixelWidth, pixelHeight: pixelHeight
            )
            // Re-stamp the eyes over the front weather; skipped on flash frames.
            if !isFlashFrame(phase: weatherPhase) {
                fillInteriorHoles(
                    configuration.leftSprite, in: context,
                    offsetX: configuration.leftSpriteOffsetX, offsetY: configuration.leftSpriteOffsetY,
                    pixelWidth: pixelWidth, pixelHeight: pixelHeight
                )
            }
        }

        // Call sign last of all, so the care call reads over any scene.
        drawCallSign(
            phase: weatherPhase, in: context,
            pixelWidth: pixelWidth, pixelHeight: pixelHeight
        )
    }

    // MARK: - Call Sign

    /// The care call on screen: a blinking "!" in the top-left corner while the
    /// pet is languishing.
    private func drawCallSign(
        phase: Int,
        in context: GraphicsContext,
        pixelWidth: CGFloat,
        pixelHeight: CGFloat
    ) {
        guard configuration.showCallSign, (phase / 3) % 2 == 0 else { return }

        context.fillLCDCells(
            [
                (1, 0), (2, 0), (1, 1), (2, 1), (1, 2), (2, 2),
                (1, 4), (2, 4)
            ],
            pixelWidth: pixelWidth, pixelHeight: pixelHeight,
            color: basePixelColor
        )
    }

    // MARK: - Sprites

    /// Draws the creature and any right-hand effect sprite (food, skull).
    private func drawSprites(
        in context: GraphicsContext,
        pixelWidth: CGFloat,
        pixelHeight: CGFloat
    ) {
        drawSprite(
            configuration.leftSprite,
            in: context,
            offsetX: configuration.leftSpriteOffsetX,
            offsetY: configuration.leftSpriteOffsetY,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight
        )
        if let rightSprite = configuration.rightSprite {
            drawSprite(
                rightSprite,
                in: context,
                offsetX: 20,
                offsetY: configuration.rightSpriteOffsetY,
                pixelWidth: pixelWidth,
                pixelHeight: pixelHeight
            )
        }
    }

    private func drawSprite(
        _ sprite: SpriteFrame,
        in context: GraphicsContext,
        offsetX: Int,
        offsetY: Int = 0,
        pixelWidth: CGFloat,
        pixelHeight: CGFloat
    ) {
        let pixelColor = basePixelColor

        // Enclosed holes first, blocking whatever is drawn behind the body.
        fillInteriorHoles(
            sprite, in: context,
            offsetX: offsetX, offsetY: offsetY,
            pixelWidth: pixelWidth, pixelHeight: pixelHeight
        )

        for y in 0..<SpriteFrame.size {
            for x in 0..<SpriteFrame.size where sprite.pixel(x: x, y: y) {
                context.fillCell(
                    x: x + offsetX, y: y + offsetY,
                    pixelWidth: pixelWidth, pixelHeight: pixelHeight,
                    color: pixelColor
                )
            }
        }
    }

    /// Fills a sprite's enclosed holes (eyes, mouths) so the backdrop never
    /// shows through the bare-eye gap. It runs under the body, and again over
    /// the front-drawn weather, so a walking pet's eyes never flicker; indoors
    /// the backing is the room glow's gradient, matching the wall behind them.
    func fillInteriorHoles(
        _ sprite: SpriteFrame,
        in context: GraphicsContext,
        offsetX: Int,
        offsetY: Int = 0,
        pixelWidth: CGFloat,
        pixelHeight: CGFloat
    ) {
        let holes = Self.interiorHoles(of: sprite)
        var path = Path()
        for y in 0..<SpriteFrame.size {
            for x in 0..<SpriteFrame.size where holes.pixel(x: x, y: y) {
                path.addRect(CGRect(
                    x: Double(x + offsetX) * pixelWidth,
                    y: Double(y + offsetY) * pixelHeight,
                    width: pixelWidth + 0.5,
                    height: pixelHeight + 0.5
                ))
            }
        }
        guard !path.isEmpty else { return }
        let shading: GraphicsContext.Shading = isIndoor
            ? roomGlowShading(pixelWidth: pixelWidth, pixelHeight: pixelHeight)
            : .color(backgroundColor)
        context.fill(path, with: shading)
    }

    // MARK: - Poop

    private func drawPoop(
        in context: GraphicsContext,
        pixelWidth: CGFloat,
        pixelHeight: CGFloat
    ) {
        guard configuration.poopCount > 0 else { return }
        let color = basePixelColor

        // Poop pile positions on the LCD, sitting just above the ground row.
        let bases: [(x: Int, y: Int)] = [
            (25, 16), (29, 16),
            (25, 13), (29, 13)
        ]

        // The coiled poop pile: tip, mound and base.
        let pilePixels: [(dx: Int, dy: Int)] = [
            (1, 0),
            (0, 1), (1, 1),
            (0, 2), (1, 2), (2, 2)
        ]

        for i in 0..<min(configuration.poopCount, 4) {
            let base = bases[i]
            for p in pilePixels {
                context.fillCell(
                    x: base.x + p.dx, y: base.y + p.dy,
                    pixelWidth: pixelWidth, pixelHeight: pixelHeight,
                    color: color
                )
            }
        }

        let stinkColor = basePixelColor.opacity(0.7)
        let stinkPixels: [(x: Int, y: Int)]
        if configuration.stinkPhase % 2 == 0 {
            stinkPixels = [(26, 12), (28, 11), (30, 12)]
        } else {
            stinkPixels = [(25, 11), (27, 12), (31, 11)]
        }
        context.fillLCDCells(
            stinkPixels,
            pixelWidth: pixelWidth, pixelHeight: pixelHeight,
            color: stinkColor
        )
    }
}
