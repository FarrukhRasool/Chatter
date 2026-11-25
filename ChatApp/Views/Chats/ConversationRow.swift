import SwiftUI

struct ConversationRow: View {
    let conversation: Conversation

    private var lastMessage: Message {
        conversation.messages.last
        ?? Message(conversationID: conversation.id,
            senderID: conversation.participant.id,
            text: "")
    }

    private var hasUnread: Bool {
        conversation.unreadCount > 0
    }

    var body: some View {
        HStack(spacing: 14) {
            AvatarView(user: conversation.participant)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(conversation.participant.name)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text(lastMessage.sentAt.chatListTimestamp)
                        .font(.subheadline)
                        .foregroundStyle(hasUnread ? Color.accentColor : Color.secondary)
                }

                HStack(alignment: .top) {
                    Text(lastMessage.isOutgoing ? "You: \(lastMessage.text)" : lastMessage.text)
                        .font(.subheadline)
                        .foregroundStyle(hasUnread ? Color.primary : Color.secondary)
                        .lineLimit(2)

                    Spacer(minLength: 8)

                    if hasUnread {
                        UnreadBadge(count: conversation.unreadCount)
                    }
                }
            }
            .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    List {
        ForEach(MockData.conversations) { conversation in
            ConversationRow(conversation: conversation)
        }
    }
    .listStyle(.plain)
}
