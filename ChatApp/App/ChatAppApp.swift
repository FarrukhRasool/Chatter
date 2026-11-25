import SwiftUI

@main
struct ChatAppApp: App {
    @StateObject private var store = ChatStore()
    private let service: any ChatService = MockChatService()

    var body: some Scene {
        WindowGroup {
            ConversationListView(service: service)
                .environmentObject(store)
        }
    }
}
