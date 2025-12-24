import Foundation
import SwiftUI

@MainActor
final class ChatViewModel: ObservableObject {
    enum ConnectionState: Equatable {
        case idle
        case connecting
        case connected
        case failed(String)

        var description: String {
            switch self {
            case .idle:
                return "Нет подключения"
            case .connecting:
                return "Подключение…"
            case .connected:
                return "Подключено"
            case let .failed(message):
                return "Ошибка: \(message)"
            }
        }
    }

    @Published var models: [ModelSummary] = []
    @Published var selectedModelID: String?
    @Published var prompt: String = ""
    @Published var responseText: String = ""
    @Published var isSending: Bool = false
    @Published var isLoadingModels: Bool = false
    @Published var connectionState: ConnectionState = .idle
    @Published var errorMessage: String?

    func refreshModels(baseURL: String, token: String) async {
        guard let client = buildClient(baseURL: baseURL, token: token) else { return }
        connectionState = .connecting
        errorMessage = nil
        isLoadingModels = true
        defer { isLoadingModels = false }
        do {
            let fetched = try await client.fetchModels()
            models = fetched
            if let selected = selectedModelID, fetched.contains(where: { $0.id == selected }) == false {
                selectedModelID = fetched.first?.id
            } else if selectedModelID == nil {
                selectedModelID = fetched.first?.id
            }
            connectionState = .connected
        } catch {
            connectionState = .failed(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }

    func sendPrompt(baseURL: String, token: String) async {
        guard let modelID = selectedModelID, !modelID.isEmpty else {
            errorMessage = "Выберите модель"
            return
        }
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Введите промпт"
            return
        }
        guard let client = buildClient(baseURL: baseURL, token: token) else { return }

        isSending = true
        errorMessage = nil
        defer { isSending = false }

        do {
            let response = try await client.sendChat(model: modelID, prompt: prompt)
            responseText = response.message.content
            connectionState = .connected
        } catch {
            connectionState = .failed(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }

    private func buildClient(baseURL: String, token: String) -> LLMClient? {
        guard let url = URL(string: baseURL), !baseURL.isEmpty else {
            errorMessage = "Неверный URL gateway"
            connectionState = .failed("Некорректный URL")
            return nil
        }
        return LLMClient(baseURL: url, token: token)
    }
}
