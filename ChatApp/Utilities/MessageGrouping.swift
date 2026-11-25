import Foundation

/// Decides how consecutive messages are visually grouped in a chat.
enum MessageGrouping {
    /// Messages from the same sender within this interval are grouped together.
    static let groupingInterval: TimeInterval = 5 * 60

    static func showsDateSeparator(in messages: [Message], at index: Int) -> Bool {
        guard index > 0 else { return true }
        return !Calendar.current.isDate(messages[index].sentAt, inSameDayAs: messages[index - 1].sentAt)
    }

    static func isLastInGroup(in messages: [Message], at index: Int) -> Bool {
        guard index + 1 < messages.count else { return true }

        let current = messages[index]
        let next = messages[index + 1]

        return current.senderID != next.senderID
            || next.sentAt.timeIntervalSince(current.sentAt) > groupingInterval
            || showsDateSeparator(in: messages, at: index + 1)
    }
}
