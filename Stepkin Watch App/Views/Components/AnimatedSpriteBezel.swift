import SwiftUI

/// A shared bezel-and-sprite assembly used by the death, hatch, and
/// onboarding screens.
struct AnimatedSpriteBezel: View {

    /// The animator driving the embedded `SpriteView`.
    let animator: SpriteAnimator

    /// The pixel size handed to the embedded `SpriteView`.
    let pixelSize: CGFloat

    var body: some View {
        LCDBezel {
            SpriteView(animator: animator, pixelSize: pixelSize)
                .background(Color("LCDBackground"))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(4)
        }
    }
}
