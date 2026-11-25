import SwiftUI

struct UnreadBadge: View {
    let count: Int

    var body: some View {
        Text(count > 99 ? "99+" : String(count))
            .font(.caption.weight(.bold))
            .monospacedDigit()
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .frame(minWidth: 22, minHeight: 22)
            .background(Color.accentColor, in: Capsule())
            .accessibilityLabel("\(count) unread")
    }
}
