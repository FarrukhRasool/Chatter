import SwiftUI

/// A message search result: contact, time and a snippet with the match highlighted.
struct MessageSearchRow: View {
    let result: MessageSearchResult
    let query: String

    private var snippet: AttributedString {
        let highlighted = ChatSearch.snippet(for: result.message.text, matching: query)
        return result.message.isOutgoing ? AttributedString("You: ") + highlighted : highlighted
    }

    var body: some View {
        HStack(spacing: 14) {
            AvatarView(user: result.participant, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(result.participant.name)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text(result.message.sentAt.chatListTimestamp)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(snippet)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
        }
        .padding(.vertical, 4)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let conversationID = UUID()
    List {
        MessageSearchRow(
            result: MessageSearchResult(
                message: Message(
                    conversationID: conversationID,
                    senderID: MockData.noah.id,
                    text: "Heads up: staging is down for ~15 min",
                    status: .read
                ),
                participant: MockData.noah
            ),
            query: "down"
        )
    }
    .listStyle(.plain)
}
