import SwiftUI

/// List content shown while searching: matching chats, then matching messages.
struct ChatSearchResultsView: View {
    let conversations: [Conversation]
    let messages: [MessageSearchResult]
    let query: String

    var body: some View {
        if !conversations.isEmpty {
            Section("Chats") {
                ForEach(conversations) { conversation in
                    ZStack {
                        NavigationLink(value: ChatRoute(conversationID: conversation.id)) { EmptyView() }
                            .opacity(0)
                        ConversationRow(conversation: conversation)
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
            }
        }

        if !messages.isEmpty {
            Section("Messages") {
                ForEach(messages) { result in
                    ZStack {
                        NavigationLink(
                            value: ChatRoute(
                                conversationID: result.message.conversationID,
                                focusedMessageID: result.message.id
                            )
                        ) { EmptyView() }
                            .opacity(0)
                        MessageSearchRow(result: result, query: query)
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
            }
        }
    }
}
