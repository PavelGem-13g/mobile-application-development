import SwiftUI

struct SettingsSheetView: View {
    let backgroundShift: Bool
    @Binding var gatewayBaseURL: String
    @Binding var gatewayToken: String
    let models: [ModelSummary]
    @Binding var selectedModelID: String?
    let connectionStatusText: String
    let statusIcon: String
    let statusTint: Color
    let isLoadingModels: Bool
    let onRefreshModels: () -> Void
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackgroundView(backgroundShift: backgroundShift)
                ScrollView {
                    VStack(spacing: 16) {
                        settingsCard
                        connectionActions
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово", action: onDone)
                }
            }
        }
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Подключение")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 10) {
                Text("Gateway URL")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                TextField("http://localhost:8000", text: $gatewayBaseURL)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                    .accessibilityIdentifier("gatewayURLField")
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("Токен")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                SecureField("Если задан", text: $gatewayToken)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                    .accessibilityIdentifier("gatewayTokenField")
            }
            Divider().background(Color.white.opacity(0.2))
            Text("Модель")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            VStack(spacing: 8) {
                ForEach(models) { model in
                    Button {
                        selectedModelID = model.id
                    } label: {
                        HStack {
                            Text(model.name)
                                .foregroundStyle(.white)
                            Spacer()
                            if model.id == selectedModelID {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .accessibilityIdentifier("modelPicker")
                }
                if models.isEmpty {
                    Text("Нет доступных моделей. Проверьте дом. ПК и Ollama.")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var connectionActions: some View {
        VStack(spacing: 12) {
            HStack {
                Label(connectionStatusText, systemImage: statusIcon)
                    .foregroundStyle(statusTint)
                Spacer()
                if isLoadingModels {
                    ProgressView()
                }
            }
            Button("Проверить соединение", action: onRefreshModels)
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("checkConnectionButton")
        }
        .padding(16)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}
