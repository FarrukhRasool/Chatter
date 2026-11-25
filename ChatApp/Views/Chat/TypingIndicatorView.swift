import SwiftUI

struct TypingIndicatorView: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 7, height: 7)
                    .scaleEffect(isAnimating ? 1 : 0.55)
                    .opacity(isAnimating ? 1 : 0.35)
                    .animation(
                        .easeInOut(duration: 0.55)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.18),
                        value: isAnimating
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(
            Theme.incomingBubble,
            in: UnevenRoundedRectangle(
                topLeadingRadius: Theme.bubbleCornerRadius,
                bottomLeadingRadius: Theme.bubbleTailRadius,
                bottomTrailingRadius: Theme.bubbleCornerRadius,
                topTrailingRadius: Theme.bubbleCornerRadius,
                style: .continuous
            )
        )
        .onAppear { isAnimating = true }
        .accessibilityLabel("Typing")
    }
}

#Preview {
    TypingIndicatorView()
        .padding()
}
