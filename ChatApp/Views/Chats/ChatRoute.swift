import Foundation

/// A navigation destination for a chat, optionally scrolled to a specific message.
struct ChatRoute: Hashable {
    let conversationID: UUID
    /// When set, the chat opens scrolled to this message and briefly highlights it.
    var focusedMessageID: UUID?
}
