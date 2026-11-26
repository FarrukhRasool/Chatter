import Foundation
import SwiftUI
import Testing
@testable import ChatApp

struct ChatSearchTests {
    // MARK: Fixtures

    private let emma = User(name: "Emma Johansson")
    private let jose = User(name: "José Álvarez")
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private var emmaConversation: Conversation {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        return Conversation(
            id: id,
            participant: emma,
            messages: [
                Message(conversationID: id, senderID: emma.id, text: "Pushed the onboarding flow",
                        sentAt: now.addingTimeInterval(-300), status: .read),
                Message(conversationID: id, senderID: User.me.id, text: "Looks great, ship it",
                        sentAt: now.addingTimeInterval(-100), status: .read),
            ]
        )
    }

    private var joseConversation: Conversation {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        return Conversation(
            id: id,
            participant: jose,
            messages: [
                Message(conversationID: id, senderID: jose.id, text: "Dinner in Trastevere?",
                        sentAt: now.addingTimeInterval(-200), status: .read),
                Message(conversationID: id, senderID: jose.id, text: "Ask Emma too",
                        sentAt: now.addingTimeInterval(-50), status: .read),
            ]
        )
    }

    private var allConversations: [Conversation] { [emmaConversation, joseConversation] }

    // MARK: normalized

    @Test(arguments: ["", "   ", "\n\t "])
    func blankQueryNormalizesToEmpty(query: String) {
        #expect(ChatSearch.normalized(query).isEmpty)
    }

    @Test func normalizedTrimsSurroundingWhitespace() {
        #expect(ChatSearch.normalized("  emma \n") == "emma")
    }

    // MARK: conversations

    @Test(arguments: ["emma", "EMMA", "johan"])
    func nameMatchIgnoresCase(query: String) {
        let result = ChatSearch.conversations(in: allConversations, matching: query)
        #expect(result.map(\.participant.name) == ["Emma Johansson"])
    }

    @Test func nameMatchIgnoresDiacritics() {
        let result = ChatSearch.conversations(in: allConversations, matching: "jose alvarez")
        #expect(result.map(\.participant.name) == ["José Álvarez"])
    }

    @Test func nameMatchKeepsInputOrder() {
        let reversed = [joseConversation, emmaConversation]
        let result = ChatSearch.conversations(in: reversed, matching: "a")
        #expect(result.map(\.participant.name) == ["José Álvarez", "Emma Johansson"])
    }

    @Test func emptyQueryMatchesNoConversations() {
        #expect(ChatSearch.conversations(in: allConversations, matching: "").isEmpty)
    }

    // MARK: messages

    @Test func messageMatchesSpanConversationsNewestFirst() {
        let result = ChatSearch.messages(in: allConversations, matching: "e")
        let dates = result.map(\.message.sentAt)
        #expect(result.count == 4)
        #expect(dates == dates.sorted(by: >))
    }

    @Test func messageResultCarriesItsParticipant() {
        let result = ChatSearch.messages(in: allConversations, matching: "trastevere")
        #expect(result.count == 1)
        #expect(result.first?.participant == jose)
        #expect(result.first?.message.conversationID == joseConversation.id)
    }

    @Test func messageMatchIgnoresCaseAndDiacritics() {
        let result = ChatSearch.messages(in: allConversations, matching: "TRASTEVÈRE")
        #expect(result.map(\.message.text) == ["Dinner in Trastevere?"])
    }

    @Test func oneQueryCanMatchNamesAndMessages() {
        let names = ChatSearch.conversations(in: allConversations, matching: "emma")
        let messages = ChatSearch.messages(in: allConversations, matching: "emma")
        #expect(names.map(\.participant) == [emma])
        #expect(messages.map(\.message.text) == ["Ask Emma too"])
        #expect(messages.first?.participant == jose)
    }

    @Test func noMatchesGivesEmptyResults() {
        #expect(ChatSearch.conversations(in: allConversations, matching: "zzz").isEmpty)
        #expect(ChatSearch.messages(in: allConversations, matching: "zzz").isEmpty)
    }

    // MARK: snippet

    @Test func snippetEmphasisesExactlyTheMatch() {
        let snippet = ChatSearch.snippet(for: "Heads up: staging is down", matching: "STAGING")
        let emphasised = snippet.runs
            .filter { $0.inlinePresentationIntent == .stronglyEmphasized }
            .map { String(snippet[$0.range].characters) }

        #expect(emphasised == ["staging"])
        #expect(String(snippet.characters) == "Heads up: staging is down")
    }

    @Test func snippetTrimsLongLeadingTextWithEllipsis() {
        let text = String(repeating: "a", count: 50) + " needle here"
        let snippet = String(ChatSearch.snippet(for: text, matching: "needle").characters)

        #expect(snippet.hasPrefix("…"))
        #expect(snippet.hasSuffix("needle here"))
        #expect(snippet.count == 1 + ChatSearch.snippetLeadingContext + "needle here".count)
    }

    @Test func snippetFlattensNewlines() {
        let snippet = String(ChatSearch.snippet(for: "line one\nline two", matching: "two").characters)
        #expect(snippet == "line one line two")
    }

    @Test func snippetWithoutMatchReturnsPlainText() {
        let snippet = ChatSearch.snippet(for: "Nothing to see", matching: "zzz")
        #expect(String(snippet.characters) == "Nothing to see")
        #expect(snippet.runs.allSatisfy { $0.inlinePresentationIntent == nil })
    }
}
