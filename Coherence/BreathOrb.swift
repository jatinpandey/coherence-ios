import SwiftUI

struct BreathOrb: View {
    let progress: Double
    let size: CGFloat

    private let accent = Color(red: 123/255, green: 168/255, blue: 170/255)

    var body: some View {
        let scale = 0.5 + 0.5 * progress // 0.5 -> 1.0
        let glowOpacity = 0.08 + 0.14 * progress
        let ringSize = size * 0.86
        let strokeWidth = max(1.5, size * 0.006)

        ZStack {
            Circle()
                .fill(accent)
                .frame(width: size, height: size)
                .opacity(glowOpacity)
                .blur(radius: 60)
                .scaleEffect(scale)

            Circle()
                .stroke(accent, lineWidth: strokeWidth)
                .frame(width: ringSize, height: ringSize)
                .scaleEffect(scale)
        }
        .frame(width: size, height: size)
    }
}
