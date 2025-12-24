import Foundation

struct ModelSummary: Codable, Identifiable {
    let name: String
    let modifiedAt: String?

    var id: String { name }

    enum CodingKeys: String, CodingKey {
        case name
        case modifiedAt = "modified_at"
    }
}

private struct ModelListResponse: Codable {
    let models: [ModelSummary]
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatResponse: Codable {
    let model: String
    let message: ChatMessage
    let done: Bool

    enum CodingKeys: String, CodingKey {
        case model
        case message
        case done
    }
}

struct ChatGatewayRequest: Codable {
    let model: String
    let prompt: String
    let stream: Bool
}

struct LLMClient {
    let baseURL: URL
    let token: String

    private static var isUITestMockEnabled: Bool {
        ProcessInfo.processInfo.environment["UITEST_MOCK"] == "1"
    }

    private static var uiTestDelayNanos: UInt64 {
        let raw = ProcessInfo.processInfo.environment["UITEST_DELAY_MS"] ?? "0"
        let ms = UInt64(raw) ?? 0
        return ms * 1_000_000
    }

    init(baseURL: URL, token: String) {
        self.baseURL = baseURL
        self.token = token
    }

    func fetchModels() async throws -> [ModelSummary] {
        if Self.isUITestMockEnabled {
            if Self.uiTestDelayNanos > 0 {
                try await Task.sleep(nanoseconds: Self.uiTestDelayNanos)
            }
            return [
                ModelSummary(name: "llama3.1", modifiedAt: nil),
                ModelSummary(name: "qwen2.5", modifiedAt: nil)
            ]
        }
        let request = try buildRequest(path: "models", method: "GET", body: Optional<ChatGatewayRequest>.none)
        let (data, response) = try await URLSession.shared.data(for: request)
        try HTTPErrorMapper.throwIfNeeded(response: response, data: data)
        let decoded = try JSONDecoder().decode(ModelListResponse.self, from: data)
        return decoded.models.sorted(by: { $0.name < $1.name })
    }

    func sendChat(model: String, prompt: String) async throws -> ChatResponse {
        if Self.isUITestMockEnabled {
            if Self.uiTestDelayNanos > 0 {
                try await Task.sleep(nanoseconds: Self.uiTestDelayNanos)
            }
            let message = ChatMessage(role: "assistant", content: "Mock response: \(prompt)")
            return ChatResponse(model: model, message: message, done: true)
        }
        let payload = ChatGatewayRequest(model: model, prompt: prompt, stream: false)
        let request = try buildRequest(path: "chat", method: "POST", body: payload)
        let (data, response) = try await URLSession.shared.data(for: request)
        try HTTPErrorMapper.throwIfNeeded(response: response, data: data)
        return try JSONDecoder().decode(ChatResponse.self, from: data)
    }

    private func buildRequest<T: Encodable>(path: String, method: String, body: T?) throws -> URLRequest {
        let endpoint = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: endpoint)
        request.httpMethod = method
        if !token.isEmpty {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }
        return request
    }
}

enum HTTPErrorMapper {
    static func throwIfNeeded(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            return
        }
        guard !(400 ... 599).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: message])
        }
    }
}
