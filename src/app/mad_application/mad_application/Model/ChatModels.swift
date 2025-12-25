import Foundation

struct ChatSession: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var messages: [ChatBubbleMessage]
    let createdAt: Date

    init(title: String, messages: [ChatBubbleMessage]) {
        self.id = UUID()
        self.title = title
        self.messages = messages
        self.createdAt = Date()
    }

    var preview: String {
        if let last = messages.last {
            return last.text.isEmpty ? "Пустой ответ" : last.text
        }
        return "Новый чат"
    }
}

struct ChatBubbleMessage: Identifiable, Equatable, Codable {
    enum Role: String, Codable {
        case user
        case assistant
        case system
    }

    let id: UUID
    let role: Role
    var text: String
    let timestamp: Date

    init(role: Role, text: String) {
        self.id = UUID()
        self.role = role
        self.text = text
        self.timestamp = Date()
    }
}
