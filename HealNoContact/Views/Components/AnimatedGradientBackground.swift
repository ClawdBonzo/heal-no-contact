import SwiftUI

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [animateGradient ? 0.6 : 0.4, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                Color.theme.deepBackground,
                Color.theme.healPurple.opacity(0.15),
                Color.theme.deepBackground,
                Color.theme.healBlue.opacity(0.1),
                Color.theme.healPink.opacity(0.08),
                Color.theme.healBlue.opacity(0.1),
                Color.theme.deepBackground,
                Color.theme.healPurple.opacity(0.1),
                Color.theme.deepBackground
            ]
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                .easeInOut(duration: 6).repeatForever(autoreverses: true)
            ) {
                animateGradient.toggle()
            }
        }
    }
}
