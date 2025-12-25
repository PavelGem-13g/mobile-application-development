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
    @Published var sessions: [ChatSession] = []
    @Published var selectedSessionID: UUID?

    private let historyStore: ChatHistoryStoring
    private var streamingMessageID: UUID?

    init(historyStore: ChatHistoryStoring = UserDefaultsChatHistoryStore()) {
        self.historyStore = historyStore
        let snapshot = historyStore.load()
        sessions = snapshot.sessions
        selectedSessionID = snapshot.selectedSessionID
        ensureSessionExists()
    }

    func refreshModels(baseURL: String, token: String) async {
        guard let client = buildClient(baseURL: baseURL, token: token) else { return }
        let start = Date()
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
            MetricsReporter.shared.record(
                event: "models_fetch",
                durationMs: Date().timeIntervalSince(start) * 1000,
                status: "ok",
                baseURL: baseURL,
                token: token
            )
        } catch {
            connectionState = .failed(error.localizedDescription)
            errorMessage = error.localizedDescription
            MetricsReporter.shared.record(
                event: "models_fetch",
                durationMs: Date().timeIntervalSince(start) * 1000,
                status: "error",
                baseURL: baseURL,
                token: token
            )
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

        let start = Date()
        isSending = true
        errorMessage = nil
        defer { isSending = false }

        do {
            let response = try await client.sendChat(model: modelID, prompt: prompt)
            responseText = response.message.content
            connectionState = .connected
            MetricsReporter.shared.record(
                event: "chat_request",
                durationMs: Date().timeIntervalSince(start) * 1000,
                status: "ok",
                baseURL: baseURL,
                token: token
            )
        } catch {
            connectionState = .failed(error.localizedDescription)
            errorMessage = error.localizedDescription
            MetricsReporter.shared.record(
                event: "chat_request",
                durationMs: Date().timeIntervalSince(start) * 1000,
                status: "error",
                baseURL: baseURL,
                token: token
            )
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

    func sendPromptStream(baseURL: String, token: String) async {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Введите промпт"
            appendSystemMessage("Введите промпт")
            return
        }
        guard let modelID = selectedModelID, !modelID.isEmpty else {
            errorMessage = "Выберите модель"
            appendSystemMessage("Выберите модель")
            return
        }
        guard let client = buildClient(baseURL: baseURL, token: token) else { return }

        ensureSessionExists()
        appendUserMessage(trimmed)
        let assistantID = appendAssistantMessage("")
        streamingMessageID = assistantID
        prompt = ""

        let start = Date()
        isSending = true
        errorMessage = nil
        responseText = ""
        defer {
            isSending = false
            saveSessions()
        }

        do {
            var aggregated = ""
            let stream = try await client.streamChat(model: modelID, prompt: trimmed)
            for try await chunk in stream {
                aggregated += chunk
                updateStreamingMessage(aggregated)
            }
            responseText = aggregated
            connectionState = .connected
            MetricsReporter.shared.record(
                event: "chat_request",
                durationMs: Date().timeIntervalSince(start) * 1000,
                status: "ok",
                baseURL: baseURL,
                token: token
            )
        } catch {
            connectionState = .failed(error.localizedDescription)
            errorMessage = error.localizedDescription
            appendSystemMessage(error.localizedDescription)
            MetricsReporter.shared.record(
                event: "chat_request",
                durationMs: Date().timeIntervalSince(start) * 1000,
                status: "error",
                baseURL: baseURL,
                token: token
            )
        }
    }

    func createNewSession() {
        let session = ChatSession(title: "Новый чат", messages: [])
        sessions.insert(session, at: 0)
        selectedSessionID = session.id
        saveSessions()
    }

    func selectSession(_ id: UUID) {
        selectedSessionID = id
        saveSessions()
    }

    func deleteSession(_ id: UUID) {
        sessions.removeAll { $0.id == id }
        if selectedSessionID == id {
            selectedSessionID = sessions.first?.id
        }
        ensureSessionExists()
        saveSessions()
    }

    var currentMessages: [ChatBubbleMessage] {
        guard let index = currentSessionIndex else { return [] }
        return sessions[index].messages
    }

    private var currentSessionIndex: Int? {
        sessions.firstIndex { $0.id == selectedSessionID }
    }

    private func ensureSessionExists() {
        if sessions.isEmpty {
            let session = ChatSession(title: "Новый чат", messages: [])
            sessions = [session]
            selectedSessionID = session.id
        } else if selectedSessionID == nil {
            selectedSessionID = sessions.first?.id
        }
    }

    private func updateCurrentSession(_ update: (inout ChatSession) -> Void) {
        ensureSessionExists()
        guard let index = currentSessionIndex else { return }
        update(&sessions[index])
    }

    private func appendUserMessage(_ text: String) {
        let message = ChatBubbleMessage(role: .user, text: text)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            updateCurrentSession { session in
                session.messages.append(message)
                if session.title == "Новый чат" {
                    session.title = String(text.prefix(36))
                }
            }
        }
        saveSessions()
    }

    private func appendAssistantMessage(_ text: String) -> UUID {
        let message = ChatBubbleMessage(role: .assistant, text: text)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            updateCurrentSession { session in
                session.messages.append(message)
            }
        }
        return message.id
    }

    private func updateStreamingMessage(_ text: String) {
        guard let messageID = streamingMessageID else { return }
        updateCurrentSession { session in
            if let index = session.messages.firstIndex(where: { $0.id == messageID }) {
                session.messages[index].text = text
            }
        }
    }

    private func appendSystemMessage(_ text: String) {
        let message = ChatBubbleMessage(role: .system, text: text)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            updateCurrentSession { session in
                session.messages.append(message)
            }
        }
        saveSessions()
    }

    private func saveSessions() {
        historyStore.save(ChatHistorySnapshot(sessions: sessions, selectedSessionID: selectedSessionID))
    }
}
