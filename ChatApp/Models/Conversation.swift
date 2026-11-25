import Foundation

struct Conversation: Identifiable, Hashable {
    let id: UUID
    let participant: User
    var messages: [Message]
    var unreadCount: Int
    let createdAt: Date

    init(
        id: UUID = UUID(),
        participant: User,
        messages: [Message] = [],
        unreadCount: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.participant = participant
        self.messages = messages
        self.unreadCount = unreadCount
        self.createdAt = createdAt
    }

    /// Used for sorting the chat list – most recent activity first.
    var lastActivity: Date {
        messages.last?.sentAt ?? createdAt
    }
}
