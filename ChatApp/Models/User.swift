import Foundation

struct User: Identifiable, Hashable {
    let id: UUID
    let name: String
    let statusText: String
    let avatarPalette: Int
    var isOnline: Bool

    init(
        id: UUID = UUID(),
        name: String,
        statusText: String = "",
        avatarPalette: Int = 0,
        isOnline: Bool = false
    ) {
        self.id = id
        self.name = name
        self.statusText = statusText
        self.avatarPalette = avatarPalette
        self.isOnline = isOnline
    }

    var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? name
    }

    var initials: String {
        name.split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map(String.init)
            .joined()
            .uppercased()
    }

    /// The signed-in user of the app.
    static let me = User(name: "Me", statusText: "Available", avatarPalette: 5, isOnline: true)
}
