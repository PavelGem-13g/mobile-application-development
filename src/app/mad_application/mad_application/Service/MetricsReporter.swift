import Foundation

struct ClientMetricEvent: Codable {
    let event: String
    let durationMs: Double?
    let status: String
    let timestamp: String

    enum CodingKeys: String, CodingKey {
        case event
        case durationMs = "duration_ms"
        case status
        case timestamp
    }
}

final class MetricsReporter {
    static let shared = MetricsReporter()

    private let session: URLSession
    private let encoder = JSONEncoder()

    private init() {
        session = .shared
        encoder.dateEncodingStrategy = .iso8601
    }

    func record(
        event: String,
        durationMs: Double?,
        status: String,
        baseURL: String,
        token: String
    ) {
        guard let url = URL(string: baseURL)?.appendingPathComponent("client-metrics") else {
            return
        }
        let payload = ClientMetricEvent(
            event: event,
            durationMs: durationMs,
            status: status,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
        Task.detached { [session, encoder] in
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            if !token.isEmpty {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            request.httpBody = try? encoder.encode(payload)
            _ = try? await session.data(for: request)
        }
    }
}
