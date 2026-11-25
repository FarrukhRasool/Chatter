import Foundation

/// Seed data so the app has something to show without a backend.
enum MockData {
    // MARK: Contacts

    static let emma = User(name: "Emma Johansson", statusText: "Designing things ✏️", avatarPalette: 0, isOnline: true)
    static let liam = User(name: "Liam Carter", statusText: "At the gym 🏋️", avatarPalette: 1)
    static let sofia = User(name: "Sofia Rossi", statusText: "Ciao!", avatarPalette: 2, isOnline: true)
    static let noah = User(name: "Noah Kim", statusText: "Shipping 🚀", avatarPalette: 4, isOnline: true)
    static let olivia = User(name: "Olivia Martin", statusText: "Reading 📚", avatarPalette: 3)
    static let lucas = User(name: "Lucas Berg", statusText: "Out hiking ⛰️", avatarPalette: 1)
    static let maya = User(name: "Maya Patel", statusText: "Hey there! I'm using Chatter", avatarPalette: 0, isOnline: true)

    static let contacts: [User] = [emma, liam, sofia, noah, olivia, lucas, maya]
        .sorted { $0.name < $1.name }

    // MARK: Conversations

    static var conversations: [Conversation] {
        [
            makeConversation(with: emma, unread: 0, script: [
                (2900, false, "Did you get a chance to look at the new onboarding flow?"),
                (2880, true, "Not yet, I'll check it tonight"),
                (95, false, "Okay I pushed the final version to Figma 🎨"),
                (94, false, "Would love your eyes on the empty states"),
                (60, true, "Just looked — the illustrations are lovely"),
                (59, true, "Maybe bump the contrast on the secondary button?"),
                (12, false, "Good call, updating now"),
                (11, true, "Thanks!"),
            ]),
            makeConversation(with: noah, unread: 2, script: [
                (1500, true, "Is the release still on for tomorrow?"),
                (1490, false, "Yep, QA signed off this morning"),
                (30, false, "Heads up: staging is down for ~15 min"),
                (28, false, "Back up now 🚀"),
            ]),
            makeConversation(with: liam, unread: 0, script: [
                (1600, false, "Leg day tomorrow? 💪"),
                (1590, true, "Only if you promise no burpees"),
                (1585, false, "No promises 😅"),
            ]),
            makeConversation(with: sofia, unread: 1, script: [
                (4400, true, "Any tips for Rome? Going in two weeks"),
                (4380, false, "Skip the restaurants right next to the big sights"),
                (4379, false, "Trastevere for dinner, trust me 🍝"),
                (4300, false, "Also book the Vatican museums early!"),
            ]),
            makeConversation(with: olivia, unread: 0, script: [
                (13000, false, "Book club moved to Thursday"),
                (12990, true, "Works for me 👍"),
            ]),
        ]
    }

    // MARK: Helpers

    private typealias ScriptLine = (minutesAgo: Double, fromMe: Bool, text: String)

    private static func makeConversation(with user: User, unread: Int, script: [ScriptLine]) -> Conversation {
        let conversationID = UUID()
        let now = Date()

        let messages = script.map { line in
            Message(
                conversationID: conversationID,
                senderID: line.fromMe ? User.me.id : user.id,
                text: line.text,
                sentAt: now.addingTimeInterval(-line.minutesAgo * 60),
                status: .read
            )
        }

        return Conversation(
            id: conversationID,
            participant: user,
            messages: messages,
            unreadCount: unread,
            createdAt: messages.first?.sentAt ?? now
        )
    }
}
