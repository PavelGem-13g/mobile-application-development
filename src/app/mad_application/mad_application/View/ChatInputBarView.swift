import SwiftUI

struct ChatInputBarView: View {
    @Binding var prompt: String
    @Binding var selectedModelID: String?
    @FocusState.Binding var promptFocused: Bool
    let isSending: Bool
    let models: [ModelSummary]
    let onRefreshModels: () -> Void
    let onSend: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Menu {
                    Button("Обновить модели", action: onRefreshModels)
                        .accessibilityIdentifier("refreshModelsButton")
                    ForEach(models) { model in
                        Button {
                            selectedModelID = model.id
                        } label: {
                            if model.id == selectedModelID {
                                Label(model.name, systemImage: "checkmark")
                            } else {
                                Text(model.name)
                            }
                        }
                    }
                } label: {
                    Label(selectedModelID ?? "Выбрать модель", systemImage: "cpu")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .accessibilityIdentifier("modelPicker")
                Spacer()
            }
            HStack(alignment: .bottom, spacing: 12) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $prompt)
                        .frame(minHeight: 44, maxHeight: 120)
                        .focused($promptFocused)
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.white.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .accessibilityIdentifier("promptEditor")
                    if prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Напишите запрос…")
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                    }
                }
                Button(action: onSend) {
                    Image(systemName: isSending ? "paperplane.fill" : "arrow.up.circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(isSending ? 20 : 0))
                        .scaleEffect(isSending ? 0.9 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSending)
                }
                .accessibilityIdentifier("sendPromptButton")
                .disabled(isSending)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
}
