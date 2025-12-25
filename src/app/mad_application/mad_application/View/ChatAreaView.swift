import SwiftUI

struct ChatAreaView: View {
    let messages: [ChatBubbleMessage]
    let isSending: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    if messages.isEmpty {
                        WelcomeCardView()
                            .transition(.opacity)
                    }
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .transition(.move(edge: message.role == .user ? .trailing : .leading)
                                .combined(with: .opacity))
                    }
                    if isSending {
                        TypingBubbleView()
                            .transition(.opacity)
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
            .onChange(of: messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: isSending) { _, _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
