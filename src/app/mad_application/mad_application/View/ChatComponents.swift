import SwiftUI

struct WelcomeCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Привет! Я ваш локальный ассистент")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Text("Напишите вопрос, выберите модель и получайте ответы прямо здесь.")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .accessibilityIdentifier("responsePlaceholderText")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct TypingBubbleView: View {
    var body: some View {
        HStack {
            TypingIndicator()
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
            Spacer()
        }
    }
}

struct MessageBubble: View {
    let message: ChatBubbleMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer() }
            selectableText
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(message.role == .system ? .white.opacity(0.9) : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(bubbleBackground)
                .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
                .accessibilityIdentifier(accessibilityID)
            if message.role != .user { Spacer() }
        }
    }

    @ViewBuilder
    private var selectableText: some View {
        if message.role == .assistant {
            renderedText.textSelection(.enabled)
        } else {
            renderedText
        }
    }

    private var renderedText: Text {
        if let attributed = try? AttributedString(
            markdown: message.text,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
        ) {
            return Text(attributed)
        }
        return Text(message.text)
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        switch message.role {
        case .user:
            LinearGradient(
                colors: [Color(red: 0.22, green: 0.5, blue: 0.95), Color(red: 0.38, green: 0.7, blue: 0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
        case .assistant:
            Color.white.opacity(0.12)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        case .system:
            Color.orange.opacity(0.3)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    private var accessibilityID: String {
        switch message.role {
        case .assistant:
            return "responseText"
        case .system:
            return "errorText"
        case .user:
            return "userText"
        }
    }
}

struct TypingIndicator: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 6, height: 6)
                        .scaleEffect(0.6 + pulse(at: time, index: index))
                        .opacity(0.4 + pulse(at: time, index: index))
                }
            }
        }
    }

    private func pulse(at time: TimeInterval, index: Int) -> CGFloat {
        let speed = 4.0
        let phase = time * speed + Double(index) * 0.7
        return CGFloat((sin(phase) + 1) / 2) * 0.6
    }
}

struct StatusDotView: View {
    let tint: Color

    var body: some View {
        Circle()
            .fill(tint)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(tint.opacity(0.6), lineWidth: 2)
            )
            .shadow(color: tint.opacity(0.5), radius: 4, x: 0, y: 0)
    }
}
