import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel

    private static let typingIndicatorID = "typing-indicator"

    init(conversationID: UUID, store: ChatStore, service: any ChatService) {
        _viewModel = StateObject(
            wrappedValue: ChatViewModel(conversationID: conversationID,
                                        store: store,
                                        service: service)
        )
    }

    var body: some View {
        let messages = viewModel.messages

        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    if messages.isEmpty {
                        EmptyChatView(user: viewModel.participant)
                    }

                    ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                        VStack(spacing: 0) {
                            if MessageGrouping.showsDateSeparator(in: messages, at: index) {
                                DateSeparatorView(date: message.sentAt)
                            }

                            MessageBubble(
                                message: message,
                                isLastInGroup: MessageGrouping.isLastInGroup(in: messages, at: index)
                            )
                        }
                        .id(message.id)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            )
                        )
                    }

                    if viewModel.isPartnerTyping {
                        HStack {
                            TypingIndicatorView()
                            Spacer()
                        }
                        .padding(.top, 4)
                        .id(Self.typingIndicatorID)
                        .transition(.opacity.combined(with: .scale(scale: 0.85, anchor: .bottomLeading)))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: messages.count)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isPartnerTyping)
            }
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages.count) {
                scrollToBottom(proxy)
            }
            .onChange(of: viewModel.isPartnerTyping) {
                scrollToBottom(proxy)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                MessageInputBar(
                    text: $viewModel.draft,
                    canSend: viewModel.canSend,
                    onSend: { viewModel.send() }
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                ChatHeaderView(
                    user: viewModel.participant,
                    subtitle: viewModel.subtitle,
                    isHighlighted: viewModel.isPartnerTyping
                )
            }
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.25)) {
            if viewModel.isPartnerTyping {
                proxy.scrollTo(Self.typingIndicatorID, anchor: .bottom)
            } else if let last = viewModel.messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}

#Preview {
    let store = ChatStore()
    NavigationStack {
        ChatView(conversationID: store.conversations[0].id, store: store, service: MockChatService())
    }
}
