import Foundation

/// A message that matched a chat-list search, together with the contact it belongs to.
struct MessageSearchResult: Identifiable, Hashable {
    let message: Message
    /// The other participant of the conversation, used for the avatar and name in the row.
    let participant: User

    var id: UUID { message.id }
}
