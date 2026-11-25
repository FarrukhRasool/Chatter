import SwiftUI

enum Theme {
    static let brandStart = Color(red: 0.33, green: 0.40, blue: 0.98)
    static let brandEnd = Color(red: 0.58, green: 0.36, blue: 0.96)

    static let outgoingGradient = LinearGradient(
        colors: [brandStart, brandEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let incomingBubble = Color(.secondarySystemBackground)

    static let bubbleCornerRadius: CGFloat = 18
    static let bubbleTailRadius: CGFloat = 6

    private static let avatarPalettes: [[Color]] = [
        [Color(red: 1.00, green: 0.62, blue: 0.42), Color(red: 0.96, green: 0.35, blue: 0.47)], // sunset
        [Color(red: 0.30, green: 0.78, blue: 0.96), Color(red: 0.24, green: 0.45, blue: 0.95)], // ocean
        [Color(red: 0.45, green: 0.88, blue: 0.62), Color(red: 0.13, green: 0.66, blue: 0.56)], // mint
        [Color(red: 0.98, green: 0.80, blue: 0.30), Color(red: 0.96, green: 0.55, blue: 0.20)], // amber
        [Color(red: 0.80, green: 0.52, blue: 0.98), Color(red: 0.52, green: 0.33, blue: 0.94)], // violet
        [Color(red: 0.55, green: 0.60, blue: 0.68), Color(red: 0.35, green: 0.40, blue: 0.48)], // slate
    ]

    static func avatarGradient(for user: User) -> LinearGradient {
        let colors = avatarPalettes[abs(user.avatarPalette) % avatarPalettes.count]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
