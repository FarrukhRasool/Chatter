import Foundation

struct Message: Identifiable, Hashable {
    enum Status: Hashable {
        case sending
        case sent
        case read
        case failed
    }

    let id: UUID
    let conversationID: UUID
    let senderID: UUID
    let text: String
    let sentAt: Date
    var status: Status

    init(
        id: UUID = UUID(),
        conversationID: UUID,
        senderID: UUID,
        text: String,
        sentAt: Date = Date(),
        status: Status = .sending
    ) {
        self.id = id
        self.conversationID = conversationID
        self.senderID = senderID
        self.text = text
        self.sentAt = sentAt
        self.status = status
    }

    var isOutgoing: Bool {
        senderID == User.me.id
    }
}
