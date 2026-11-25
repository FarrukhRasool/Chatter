import SwiftUI

struct ConversationListView: View {
    @EnvironmentObject private var store: ChatStore
    let service: any ChatService

    @State private var path: [UUID] = []
    @State private var isComposing = false
    @State private var pendingConversationID: UUID?

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(store.sortedConversations) { conversation in
                    ZStack {
                        NavigationLink(value: conversation.id) { EmptyView() }
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
            .listStyle(.plain)
            .overlay {
                if store.conversations.isEmpty {
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
            .navigationDestination(for: UUID.self) { conversationID in
                ChatView(conversationID: conversationID, store: store, service: service)
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
        path.append(conversationID)
    }
}

#Preview {
    ConversationListView(service: MockChatService())
        .environmentObject(ChatStore())
}
