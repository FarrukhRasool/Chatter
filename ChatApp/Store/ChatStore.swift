import Combine
import Foundation

/// Single source of truth for all conversations in the app.
final class ChatStore: ObservableObject {
    @Published private(set) var conversations: [Conversation]
    let contacts: [User]

    /// The conversation currently on screen. Incoming messages for it don't bump the unread counter.
    var activeConversationID: UUID?

    init(
        conversations: [Conversation] = MockData.conversations,
        contacts: [User] = MockData.contacts
    ) {
        self.conversations = conversations
        self.contacts = contacts
    }

    // MARK: Queries

    var sortedConversations: [Conversation] {
        conversations.sorted { $0.lastActivity > $1.lastActivity }
    }

    func conversation(withID id: UUID) -> Conversation? {
        conversations.first { $0.id == id }
    }

    // MARK: Messages

    func append(_ message: Message) {
        guard let index = indexOfConversation(message.conversationID) else { return }

        conversations[index].messages.append(message)

        if !message.isOutgoing && activeConversationID != message.conversationID {
            conversations[index].unreadCount += 1
        }
    }
    

    func updateStatus(_ status: Message.Status, messageID: UUID, in conversationID: UUID) {
        guard let index = indexOfConversation(conversationID),
              let messageIndex = conversations[index].messages.firstIndex(where: { $0.id == messageID })
        else { return }
        
        conversations[index].messages[messageIndex].status = status
    }

    func deleteMessage(_ messageID: UUID, in conversationID: UUID) {
        guard let index = indexOfConversation(conversationID) else { return }
        conversations[index].messages.removeAll { $0.id == messageID }
    }

    /// Marks every delivered outgoing message as read by the other participant.
    func markOutgoingAsRead(in conversationID: UUID) {
        guard let index = indexOfConversation(conversationID) else { return }

        for messageIndex in conversations[index].messages.indices {
            let message = conversations[index].messages[messageIndex]
            if message.isOutgoing && message.status == .sent {
                conversations[index].messages[messageIndex].status = .read
            }
        }
    }

    // MARK: Conversations

    func markAsRead(_ conversationID: UUID) {
        guard let index = indexOfConversation(conversationID),
              conversations[index].unreadCount != 0
        else { return }

        conversations[index].unreadCount = 0
    }

    func markAsUnread(_ conversationID: UUID) {
        guard let index = indexOfConversation(conversationID) else { return }
        conversations[index].unreadCount = max(conversations[index].unreadCount, 1)
    }

    /// Returns the existing conversation with `user`, or creates a new empty one.
    @discardableResult
    func startConversation(with user: User) -> Conversation {
        if let existing = conversations.first(where: { $0.participant.id == user.id }) {
            return existing
        }

        let conversation = Conversation(participant: user)
        conversations.append(conversation)
        return conversation
    }

    func deleteConversation(_ conversationID: UUID) {
        conversations.removeAll { $0.id == conversationID }
    }

    // MARK: Private

    private func indexOfConversation(_ id: UUID) -> Int? {
        conversations.firstIndex { $0.id == id }
    }
}
