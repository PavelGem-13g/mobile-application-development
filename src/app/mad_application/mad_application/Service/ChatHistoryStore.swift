import Foundation

struct ChatHistorySnapshot: Codable {
    var sessions: [ChatSession]
    var selectedSessionID: UUID?
}

protocol ChatHistoryStoring {
    func load() -> ChatHistorySnapshot
    func save(_ snapshot: ChatHistorySnapshot)
}

final class UserDefaultsChatHistoryStore: ChatHistoryStoring {
    private let sessionsKey = "chat_sessions_v1"
    private let selectedKey = "chat_selected_session_id"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> ChatHistorySnapshot {
        let selected = defaults.string(forKey: selectedKey).flatMap(UUID.init(uuidString:))
        guard let data = defaults.data(forKey: sessionsKey) else {
            return ChatHistorySnapshot(sessions: [], selectedSessionID: selected)
        }
        do {
            let sessions = try JSONDecoder().decode([ChatSession].self, from: data)
            let resolvedSelected: UUID?
            if let selected, sessions.contains(where: { $0.id == selected }) {
                resolvedSelected = selected
            } else {
                resolvedSelected = sessions.first?.id
            }
            return ChatHistorySnapshot(sessions: sessions, selectedSessionID: resolvedSelected)
        } catch {
            return ChatHistorySnapshot(sessions: [], selectedSessionID: nil)
        }
    }

    func save(_ snapshot: ChatHistorySnapshot) {
        do {
            let data = try JSONEncoder().encode(snapshot.sessions)
            defaults.set(data, forKey: sessionsKey)
            defaults.set(snapshot.selectedSessionID?.uuidString ?? "", forKey: selectedKey)
        } catch {
            return
        }
    }
}
