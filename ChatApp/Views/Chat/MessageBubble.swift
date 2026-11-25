import SwiftUI
import UIKit

struct MessageBubble: View {
    let message: Message
    let isLastInGroup: Bool

    private var isOutgoing: Bool { message.isOutgoing }

    private var showsMetadata: Bool {
        isLastInGroup || message.status == .sending || message.status == .failed
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if isOutgoing { Spacer(minLength: 56) }

            VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 3) {
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(isOutgoing ? Color.white : Color.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(bubbleBackground, in: bubbleShape)
                    .opacity(message.status == .failed ? 0.55 : 1)
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = message.text
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }

                if showsMetadata {
                    metadata
                        .padding(.horizontal, 6)
                        .transition(.opacity)
                }
            }

            if !isOutgoing { Spacer(minLength: 56) }
        }
        .padding(.bottom, isLastInGroup ? 8 : 0)
        .animation(.easeInOut(duration: 0.2), value: message.status)
    }

    // MARK: Pieces

    private var bubbleShape: UnevenRoundedRectangle {
        let corner = Theme.bubbleCornerRadius
        let tail = isLastInGroup ? Theme.bubbleTailRadius : corner

        return UnevenRoundedRectangle(
            topLeadingRadius: corner,
            bottomLeadingRadius: isOutgoing ? corner : tail,
            bottomTrailingRadius: isOutgoing ? tail : corner,
            topTrailingRadius: corner,
            style: .continuous
        )
    }

    private var bubbleBackground: AnyShapeStyle {
        isOutgoing ? AnyShapeStyle(Theme.outgoingGradient) : AnyShapeStyle(Theme.incomingBubble)
    }

    @ViewBuilder
    private var metadata: some View {
        if message.status == .failed {
            Label("Not delivered", systemImage: "exclamationmark.circle.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.red)
        } else {
            HStack(spacing: 3) {
                Text(message.sentAt.bubbleTimestamp)
                if isOutgoing {
                    statusIcon
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch message.status {
        case .sending:
            Image(systemName: "clock")
        case .sent:
            Image(systemName: "checkmark")
        case .read:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.accentColor)
        case .failed:
            EmptyView()
        }
    }
}

#Preview {
    let conversationID = UUID()
    VStack(spacing: 2) {
        MessageBubble(
            message: Message(conversationID: conversationID, senderID: MockData.emma.id, text: "Hey! Did you see the new designs?", status: .read),
            isLastInGroup: true
        )
        MessageBubble(
            message: Message(conversationID: conversationID, senderID: User.me.id, text: "Yes, they look great", status: .read),
            isLastInGroup: false
        )
        MessageBubble(
            message: Message(conversationID: conversationID, senderID: User.me.id, text: "Let's ship it 🚀", status: .sent),
            isLastInGroup: true
        )
        MessageBubble(
            message: Message(conversationID: conversationID, senderID: User.me.id, text: "This one failed", status: .failed),
            isLastInGroup: true
        )
    }
    .padding()
}
