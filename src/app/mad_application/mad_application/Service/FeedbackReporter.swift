import Foundation

struct FeedbackPayload: Codable {
    let rating: Int
    let comment: String?
    let scenario: String
    let timestamp: String
}

final class FeedbackReporter {
    static let shared = FeedbackReporter()

    private let session: URLSession
    private let encoder = JSONEncoder()

    private init() {
        session = .shared
        encoder.dateEncodingStrategy = .iso8601
    }

    func send(
        rating: Int,
        comment: String?,
        scenario: String,
        baseURL: String,
        token: String
    ) {
        guard let url = URL(string: baseURL)?.appendingPathComponent("feedback") else {
            return
        }
        let payload = FeedbackPayload(
            rating: rating,
            comment: comment?.trimmingCharacters(in: .whitespacesAndNewlines),
            scenario: scenario,
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
