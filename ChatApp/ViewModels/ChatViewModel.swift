import Combine
import Foundation

final class ChatViewModel: ObservableObject {
    @Published var draft = ""
    @Published private(set) var isPartnerTyping = false

    let conversationID: UUID

    private let store: ChatStore
    private let service: any ChatService
    private var cancellables = Set<AnyCancellable>()

    init(conversationID: UUID, store: ChatStore, service: any ChatService) {
        self.conversationID = conversationID
        self.store = store
        self.service = service

        // Re-render whenever the underlying conversation changes.
        store.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        service.events
            .filter { $0.conversationID == conversationID }
            .receive(on: DispatchQueue.main)
            .sink{ [weak self] in self?.handle($0) }
            .store(in: &cancellables)
    }

    // MARK: State

    var conversation: Conversation? {
        store.conversation(withID: conversationID)
    }

    var participant: User {
        conversation?.participant ?? User(name: "Unknown")
    }

    var messages: [Message] {
        conversation?.messages ?? []
    }

    var subtitle: String {
        if isPartnerTyping { return "typing…" }
        return participant.isOnline ? "online" : "last seen recently"
    }

    var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: Lifecycle

    func onAppear() {
        store.activeConversationID = conversationID
        store.markAsRead(conversationID)
    }
    
    
    func onDisappear() {
        if store.activeConversationID == conversationID {
            store.activeConversationID = nil
        }
        if let conversation = self.conversation,
           conversation.messages.isEmpty {
            store.deleteConversation(conversationID)
        }
        
    }

    
    // MARK: Actions
    func send() {
        guard canSend, let recipient = conversation?.participant else { return }

        let message = Message(
            conversationID: conversationID,
            senderID: User.me.id,
            text: draft
        )
        draft = ""
        store.append(message)

        let conversationID = self.conversationID
        let messageID = message.id
        service.send(message, to: recipient) { [store] result in
            switch result {
            case .success:
                 store.updateStatus(.sent, messageID: messageID, in: conversationID)
            case .failure:
                 store.updateStatus(.failed, messageID: messageID, in: conversationID)
            }
        }
    }

    /// Resends a failed message in place, keeping its ID, position and time.
    func retry(messageID: UUID) {
        guard var message = failedMessage(withID: messageID),
              let recipient = conversation?.participant
        else { return }

        message.status = .sending
        store.updateStatus(.sending, messageID: messageID, in: conversationID)

        // Captures the store, not self, so the status still updates after leaving the chat.
        service.send(message, to: recipient) { [store, conversationID] result in
            switch result {
            case .success:
                store.updateStatus(.sent, messageID: messageID, in: conversationID)
            case .failure:
                store.updateStatus(.failed, messageID: messageID, in: conversationID)
            }
        }
    }

    func delete(messageID: UUID) {
        guard failedMessage(withID: messageID) != nil else { return }
        store.deleteMessage(messageID, in: conversationID)
    }

    private func failedMessage(withID messageID: UUID) -> Message? {
        messages.first { $0.id == messageID && $0.status == .failed }
    }

    // MARK: Events

    private func handle(_ event: ChatEvent) {
        switch event {
        case .typing(_, let isTyping):
            isPartnerTyping = isTyping

        case .messagesRead:
            store.markOutgoingAsRead(in: conversationID)

        case let .incomingMessage(conversationID, senderID, text, sentAt):
            isPartnerTyping = false
            store.append(
                Message(
                    conversationID: conversationID,
                    senderID: senderID,
                    text: text,
                    sentAt: sentAt,
                    status: .read
                )
            )
        }
    }
}
