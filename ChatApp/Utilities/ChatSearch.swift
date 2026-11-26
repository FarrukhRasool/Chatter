import SwiftUI

/// Pure search helpers for the chat list: matching by contact name and message text,
/// and building highlighted snippets. Matching ignores case and diacritics.
enum ChatSearch {
    /// Characters kept before a match in a snippet, so the match stays visible in a short row.
    static let snippetLeadingContext = 20

    /// The query with surrounding whitespace removed. An empty result means search is inactive.
    static func normalized(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Conversations whose contact name contains `query`, keeping the input order.
    static func conversations(in conversations: [Conversation], matching query: String) -> [Conversation] {
        guard !query.isEmpty else { return [] }
        return conversations.filter { $0.participant.name.localizedStandardContains(query) }
    }

    /// Messages from all conversations whose text contains `query`, newest first.
    static func messages(in conversations: [Conversation], matching query: String) -> [MessageSearchResult] {
        guard !query.isEmpty else { return [] }
        return conversations
            .flatMap { conversation in
                conversation.messages
                    .filter { $0.text.localizedStandardContains(query) }
                    .map { MessageSearchResult(message: $0, participant: conversation.participant) }
            }
            .sorted { $0.message.sentAt > $1.message.sentAt }
    }

    /// A single-line excerpt of `text` around the first match of `query`, with the match emphasised.
    static func snippet(for text: String, matching query: String) -> AttributedString {
        let line = text.replacing("\n", with: " ")
        guard !query.isEmpty, let match = line.localizedStandardRange(of: query) else {
            return AttributedString(line)
        }

        let start = line.index(match.lowerBound, offsetBy: -snippetLeadingContext, limitedBy: line.startIndex)
            ?? line.startIndex
        let prefix = start == line.startIndex ? "" : "…"

        var highlight = AttributedString(line[match])
        highlight.inlinePresentationIntent = .stronglyEmphasized
        highlight.swiftUI.foregroundColor = .accentColor

        return AttributedString(prefix + line[start..<match.lowerBound])
            + highlight
            + AttributedString(line[match.upperBound...])
    }
}
