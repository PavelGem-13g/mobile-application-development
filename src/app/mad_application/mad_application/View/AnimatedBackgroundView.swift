import SwiftUI

struct AnimatedBackgroundView: View {
    let backgroundShift: Bool

    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.1, blue: 0.16),
                Color(red: 0.12, green: 0.18, blue: 0.28),
                Color(red: 0.18, green: 0.2, blue: 0.32)
            ],
            startPoint: backgroundShift ? .topLeading : .bottomLeading,
            endPoint: backgroundShift ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .overlay(
            RadialGradient(
                colors: [Color.white.opacity(0.14), Color.clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 220
            )
            .blendMode(.screen)
        )
    }
}
