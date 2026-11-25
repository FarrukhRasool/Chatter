import SwiftUI

struct MessageInputBar: View {
    @Binding var text: String
    let canSend: Bool
    let onSend: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Message", text: $text, axis: .vertical)
                .focused($isFocused)
                .lineLimit(1...5)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(isFocused ? Color.accentColor.opacity(0.6) : Color(.separator), lineWidth: isFocused ? 1 : 0.5)
                }

            Button(action: onSend) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(sendButtonBackground, in: Circle())
                    .shadow(color: canSend ? Theme.brandStart.opacity(0.35) : .clear, radius: 6, y: 3)
            }
            .disabled(!canSend)
            .scaleEffect(canSend ? 1 : 0.88)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: canSend)
            .accessibilityLabel("Send")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }

    private var sendButtonBackground: AnyShapeStyle {
        canSend ? AnyShapeStyle(Theme.outgoingGradient) : AnyShapeStyle(Color(.systemGray4))
    }
}

#Preview {
    VStack {
        Spacer()
        MessageInputBar(text: .constant(""), canSend: false, onSend: {})
        MessageInputBar(text: .constant("Hello!"), canSend: true, onSend: {})
    }
}
