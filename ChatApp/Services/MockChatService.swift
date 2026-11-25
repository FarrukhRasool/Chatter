import Combine
import Foundation

/// Simulates a chat backend: network latency, occasional failures,
/// read receipts, typing indicators and automatic replies.
final class MockChatService: ChatService {
    var events: AnyPublisher<ChatEvent, Never> {
        subject.eraseToAnyPublisher()
    }

    private let subject = PassthroughSubject<ChatEvent, Never>()
    private let networkQueue = DispatchQueue(label: "com.example.chatapp.mock-network", qos: .userInitiated)
    private let failureRate: Double

    /// Conversations with a reply already scheduled. Only accessed on `networkQueue`.
    private var conversationsAwaitingReply = Set<UUID>()

    init(failureRate: Double = 0.1) {
        self.failureRate = failureRate
    }

    func send(
        _ message: Message,
        to recipient: User,
        completion: @escaping (Result<Void, ChatServiceError>) -> Void
    ) {
        let latency = Double.random(in: 0.4...1.0)

        networkQueue.asyncAfter(deadline: .now() + latency) { [weak self] in
            guard let self else { return }

            let didFail = Double.random(in: 0..<1) < self.failureRate

            DispatchQueue.main.async {
                completion(didFail ? .failure(.networkUnavailable) : .success(()))
            }

            if !didFail {
                self.scheduleReply(to: message, from: recipient)
            }
        }
    }

    // MARK: - Simulation

    private func scheduleReply(to message: Message, from recipient: User) {
        let conversationID = message.conversationID
        guard !conversationsAwaitingReply.contains(conversationID) else { return }
        conversationsAwaitingReply.insert(conversationID)

        let readDelay = Double.random(in: 0.6...1.4)
        let typingDuration = Double.random(in: 1.2...2.6)

        networkQueue.asyncAfter(deadline: .now() + readDelay) { [weak self] in
            guard let self else { return }
            self.subject.send(.messagesRead(conversationID: conversationID))
            self.subject.send(.typing(conversationID: conversationID, isTyping: true))

            self.networkQueue.asyncAfter(deadline: .now() + typingDuration) { [weak self] in
                guard let self else { return }
                self.conversationsAwaitingReply.remove(conversationID)

                self.subject.send(.messagesRead(conversationID: conversationID))
                self.subject.send(.typing(conversationID: conversationID, isTyping: false))
                self.subject.send(
                    .incomingMessage(
                        conversationID: conversationID,
                        senderID: recipient.id,
                        text: ReplyGenerator.reply(to: message.text, from: recipient),
                        sentAt: Date()
                    )
                )
            }
        }
    }
}
