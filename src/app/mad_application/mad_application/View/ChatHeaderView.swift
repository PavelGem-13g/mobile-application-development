import SwiftUI

struct ChatHeaderView: View {
    let title: String
    let modelName: String
    let statusTint: Color
    let onHistory: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)
                HStack(spacing: 8) {
                    StatusDotView(tint: statusTint)
                    Text(modelName)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .layoutPriority(1)
            Spacer()
            Button(action: onHistory) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityIdentifier("historyButton")
            Button(action: onSettings) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityIdentifier("settingsButton")
        }
    }
}
