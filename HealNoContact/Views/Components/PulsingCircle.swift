import SwiftUI

struct PulsingCircle: View {
    let color: Color
    var size: CGFloat = 12
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(color.opacity(0.4), lineWidth: 2)
                    .scaleEffect(isPulsing ? 2.0 : 1.0)
                    .opacity(isPulsing ? 0 : 0.6)
            )
            .onAppear {
                withAnimation(
                    .easeOut(duration: 1.5).repeatForever(autoreverses: false)
                ) {
                    isPulsing = true
                }
            }
    }
}
