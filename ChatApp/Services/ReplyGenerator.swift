import Foundation

/// Produces canned, slightly personalised replies for the mock backend.
enum ReplyGenerator {
    static func reply(to text: String, from user: User) -> String {
        let firstWord = text
            .lowercased()
            .split(whereSeparator: { !$0.isLetter })
            .first
            .map(String.init)

        if let firstWord, greetingTriggers.contains(firstWord) {
            return greetings.randomElement() ?? "Hey!"
        }

        if text.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("?") {
            return questionReplies.randomElement() ?? "Good question!"
        }

        let pool = personaReplies[user.firstName] ?? genericReplies
        return pool.randomElement() ?? "👍"
    }

    private static let greetingTriggers: Set<String> = ["hi", "hey", "hello", "yo", "hej", "hola", "ciao"]

    private static let greetings = [
        "Hey! 👋",
        "Hi there!",
        "Hello 😊",
        "Hey hey! What's up?",
    ]

    private static let questionReplies = [
        "Good question 🤔",
        "Hmm, let me think about it",
        "Yes, definitely!",
        "Not sure yet, I'll get back to you",
        "Probably — why not?",
    ]

    private static let genericReplies = [
        "Sounds good!",
        "Haha 😄",
        "Got it 👍",
        "Interesting, tell me more",
        "Sure thing",
    ]

    private static let personaReplies: [String: [String]] = [
        "Emma": [
            "Love it! ✨",
            "Let me sketch something quickly",
            "Can we jump on a quick call later?",
            "I'll update the mockups tonight",
            "That spacing feels so much better now",
        ],
        "Liam": [
            "Haha classic",
            "On my way to the gym, talk later 🏋️",
            "Bro 😂",
            "Sounds like a plan",
            "Let's grab food after",
        ],
        "Sofia": [
            "Perfetto! 🇮🇹",
            "Ahah, of course",
            "Send me pics!",
            "I'll make you a list of places",
            "Va bene 👍",
        ],
        "Noah": [
            "Ship it 🚀",
            "Let me check the logs",
            "LGTM",
            "Can you open a ticket for that?",
            "Deploying in 5",
        ],
        "Olivia": [
            "Ooh, adding that to my reading list 📚",
            "Totally agree",
            "Tell me more!",
            "Haha yes",
        ],
    ]
}
