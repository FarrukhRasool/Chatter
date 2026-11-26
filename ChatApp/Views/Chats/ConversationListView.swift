import SwiftUI

struct ConversationListView: View {
    @EnvironmentObject private var store: ChatStore
    let service: any ChatService

    @State private var path: [ChatRoute] = []
    @State private var isComposing = false
    @State private var pendingConversationID: UUID?
    @State private var query = ""

    var body: some View {
        let activeQuery = ChatSearch.normalized(query)
        let isSearching = !activeQuery.isEmpty
        let matchingConversations = ChatSearch.conversations(in: store.sortedConversations, matching: activeQuery)
        let matchingMessages = ChatSearch.messages(in: store.conversations, matching: activeQuery)

        NavigationStack(path: $path) {
            List {
                if isSearching {
                    ChatSearchResultsView(
                        conversations: matchingConversations,
                        messages: matchingMessages,
                        query: activeQuery
                    )
                } else {
                    ForEach(store.sortedConversations) { conversation in
                        ZStack {
                            NavigationLink(value: ChatRoute(conversationID: conversation.id)) { EmptyView() }
                                .opacity(0)
                            ConversationRow(conversation: conversation)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation { store.deleteConversation(conversation.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            readToggleButton(for: conversation)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $query, prompt: "Search chats and messages")
            .overlay {
                if isSearching {
                    if matchingConversations.isEmpty && matchingMessages.isEmpty {
                        ContentUnavailableView.search(text: activeQuery)
                    }
                } else if store.conversations.isEmpty {
                    ContentUnavailableView(
                        "No Chats Yet",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Tap the compose button to start a conversation.")
                    )
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isComposing = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("New message")
                }
            }
            .navigationDestination(for: ChatRoute.self) { route in
                ChatView(
                    conversationID: route.conversationID,
                    focusedMessageID: route.focusedMessageID,
                    store: store,
                    service: service
                )
            }
            .sheet(isPresented: $isComposing, onDismiss: openPendingConversation) {
                NewChatSheet(contacts: store.contacts) { contact in
                    pendingConversationID = store.startConversation(with: contact).id
                }
            }
        }
    }

    @ViewBuilder
    private func readToggleButton(for conversation: Conversation) -> some View {
        if conversation.unreadCount > 0 {
            Button {
                store.markAsRead(conversation.id)
            } label: {
                Label("Read", systemImage: "envelope.open")
            }
            .tint(.blue)
        } else {
            Button {
                store.markAsUnread(conversation.id)
            } label: {
                Label("Unread", systemImage: "envelope.badge")
            }
            .tint(.blue)
        }
    }

    private func openPendingConversation() {
        guard let conversationID = pendingConversationID else { return }
        pendingConversationID = nil
        path.append(ChatRoute(conversationID: conversationID))
    }
}

#Preview {
    ConversationListView(service: MockChatService())
        .environmentObject(ChatStore())
}
