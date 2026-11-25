import Foundation

extension Date {
    /// "14:32", "Yesterday", "Monday" or "12 Nov" – used in the chat list.
    var chatListTimestamp: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(self) {
            return formatted(date: .omitted, time: .shortened)
        }
        if calendar.isDateInYesterday(self) {
            return "Yesterday"
        }
        if let days = calendar.dateComponents([.day], from: self, to: Date()).day, days < 7 {
            return formatted(.dateTime.weekday(.wide))
        }
        return formatted(.dateTime.day().month(.abbreviated))
    }

    /// "14:32" – shown under message bubbles.
    var bubbleTimestamp: String {
        formatted(date: .omitted, time: .shortened)
    }

    /// "Today", "Yesterday" or "Monday, 17 November" – shown between days in a chat.
    var daySeparatorTitle: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(self) { return "Today" }
        if calendar.isDateInYesterday(self) { return "Yesterday" }
        return formatted(.dateTime.weekday(.wide).day().month(.wide))
    }
}
