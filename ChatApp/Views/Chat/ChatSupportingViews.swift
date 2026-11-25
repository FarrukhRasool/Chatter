import SwiftUI

/// Avatar + name + status shown in the navigation bar of a chat.
struct ChatHeaderView: View {
    let user: User
    let subtitle: String
    let isHighlighted: Bool

    var body: some View {
        HStack(spacing: 10) {
            AvatarView(user: user, size: 34)

            VStack(alignment: .leading, spacing: 0) {
                Text(user.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(isHighlighted ? Color.accentColor : Color.secondary)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: subtitle)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// "Today", "Yesterday", … pill between days.
struct DateSeparatorView: View {
    let date: Date

    var body: some View {
        Text(date.daySeparatorTitle)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Color(.tertiarySystemFill), in: Capsule())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
    }
}

/// Shown in a brand-new conversation without messages.
struct EmptyChatView: View {
    let user: User

    var body: some View {
        VStack(spacing: 12) {
            AvatarView(user: user, size: 88, showsOnlineIndicator: false)

            Text(user.name)
                .font(.title3.weight(.semibold))

            Text("Say hi to \(user.firstName) 👋")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}
