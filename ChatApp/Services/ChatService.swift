import Combine
import Foundation

/// Real-time events pushed by the backend.
enum ChatEvent {
    case typing(conversationID: UUID, isTyping: Bool)
    case messagesRead(conversationID: UUID)
    case incomingMessage(conversationID: UUID, senderID: UUID, text: String, sentAt: Date)

    var conversationID: UUID {
        switch self {
        case .typing(let id, _),
             .messagesRead(let id),
             .incomingMessage(let id, _, _, _):
            return id
        }
    }
}

enum ChatServiceError: LocalizedError {
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "The network connection appears to be offline."
        }
    }
}

/// Abstraction over the chat backend. The app ships with `MockChatService`;
/// a real implementation (WebSocket, REST, …) would conform to the same protocol.
protocol ChatService: AnyObject {
    /// Stream of real-time events (typing, read receipts, incoming messages).
    var events: AnyPublisher<ChatEvent, Never> { get }

    /// Sends a message. `completion` is called on the main queue.
    func send(
        _ message: Message,
        to recipient: User,
        completion: @escaping (Result<Void, ChatServiceError>) -> Void
    )
}
