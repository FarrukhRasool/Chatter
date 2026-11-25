import SwiftUI

struct AvatarView: View {
    let user: User
    var size: CGFloat = 52
    var showsOnlineIndicator = true

    var body: some View {
        Circle()
            .fill(Theme.avatarGradient(for: user))
            .frame(width: size, height: size)
            .overlay {
                Text(user.initials)
                    .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .overlay(alignment: .bottomTrailing) {
                if showsOnlineIndicator && user.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: size * 0.27, height: size * 0.27)
                        .overlay {
                            Circle().strokeBorder(Color(.systemBackground), lineWidth: max(2, size * 0.05))
                        }
                }
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 16) {
        AvatarView(user: MockData.emma)
        AvatarView(user: MockData.liam)
        AvatarView(user: MockData.sofia, size: 34)
    }
    .padding()
}
