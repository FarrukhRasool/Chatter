# Plan: Search in the chat list (README Part 2, feature #3)

## Context
README feature #3: *"A search bar in the chat list that filters by contact name and message content.
Matching messages show a snippet with the match highlighted, and tapping one opens the chat."*

Branch: `feature/search-chat` (same commit as `main`, 5d2a35b). The old `search` branch is **not** used;
the logic is written fresh here.

Decisions already made with the user:
- Results appear in **two sections**: "Chats" (the contact name matches) and "Messages" (the text matches, shown as a snippet).
- Tapping a message result **opens the chat, scrolls to that message and briefly highlights it**.
- A **unit-test target** is added, with tests for the search logic.

Out of scope: searching contacts that have no conversation, search history or suggestions, keeping the
search text after navigating away, migrating to `@Observable`, the open bugs 4 and 6–9.

## Design

### 1. Search logic (pure functions, easy to test)
**New file `ChatApp/Models/MessageSearchResult.swift`**
```swift
struct MessageSearchResult: Identifiable, Hashable {
    let message: Message
    let participant: User          // so the row can show the avatar and name
    var id: UUID { message.id }
}
```

**New file `ChatApp/Utilities/ChatSearch.swift`** (`enum ChatSearch`, no state):
- `static func normalized(_ query: String) -> String` trims spaces and newlines. If the result is empty, search is inactive.
- `static func conversations(in: [Conversation], matching query: String) -> [Conversation]`
  keeps conversations whose `participant.name.localizedStandardContains(query)` is true, in the same order they came in
  (the caller passes `store.sortedConversations`).
- `static func messages(in: [Conversation], matching query: String) -> [MessageSearchResult]`
  goes through every message in every conversation, keeps those where `text.localizedStandardContains(query)`, and sorts them by
  `sentAt` with the newest first.
- `static func snippet(for text: String, matching query: String) -> AttributedString`
  1. Replace newlines with spaces (use `replacing(_:with:)`, as CLAUDE.md asks).
  2. Find the match with `localizedStandardRange(of:)`. If there is none, return the plain text.
  3. Keep about 20 characters before the match. If text was cut off at the start, begin with "…".
  4. Style the match: `inlinePresentationIntent = .stronglyEmphasized` plus the SwiftUI accent
     foreground colour. Check the attribute-scope API with Xcode `DocumentationSearch`, because the UIKit and SwiftUI
     `foregroundColor` can be ambiguous.
  5. Leave the text after the match as it is. The row's `lineLimit(2)` cuts it off.

`localizedStandardContains` ignores case and accents and follows the user's language settings, as CLAUDE.md requires.

### 2. Search UI in the chat list
**`ChatApp/Views/Chats/ConversationListView.swift`**
- Add `@State private var query = ""` and `.searchable(text: $query, prompt: "Search chats and messages")`
  to the `List`.
- Work out `let activeQuery = ChatSearch.normalized(query)`.
  - If it's empty, show today's `ForEach(store.sortedConversations)` with no changes (swipe actions stay).
  - If it isn't, show `ChatSearchResultsView(conversations:, messages:, query:)` inside the same `List`.
- Overlay: if search is active and both result lists are empty, show `ContentUnavailableView.search(text: activeQuery)`.
  Keep the existing "No Chats Yet" overlay for when search isn't active.
- The results recalculate automatically when the store changes, for example when a reply arrives during a search.

**New file `ChatApp/Views/Chats/ChatSearchResultsView.swift`** (a View struct, not a computed property)
- `Section("Chats")` appears only if there are matches. Each match is the existing `ConversationRow`, wrapped the same way as
  today (`ZStack` with a hidden `NavigationLink(value:)`). Search results get no swipe actions.
- `Section("Messages")` appears only if there are matches. Each is a `MessageSearchRow` inside a `NavigationLink(value: ChatRoute(conversationID:, focusedMessageID:))`.

**New file `ChatApp/Views/Chats/MessageSearchRow.swift`**
- `AvatarView(user: participant, size: 44)`, the name (`.headline`), and on the right `message.sentAt.chatListTimestamp`.
- Below that, `Text(snippet)` with `.subheadline`, `.secondary` and `lineLimit(2)`. Add "You: " in front if `message.isOutgoing`
  (matches `ConversationRow`).
- `.accessibilityElement(children: .combine)`.

### 3. Navigation and scrolling to the message
**New file `ChatApp/Views/Chats/ChatRoute.swift`**
```swift
struct ChatRoute: Hashable {
    let conversationID: UUID
    var focusedMessageID: UUID? = nil
}
```
**`ConversationListView`**: change `path: [UUID]` to `[ChatRoute]`, and `navigationDestination(for: UUID.self)` to
`for: ChatRoute.self`. Normal rows use `ChatRoute(conversationID:)`. `openPendingConversation()` adds
`ChatRoute(conversationID:)` to the path.

**`ChatApp/Views/Chat/ChatView.swift`**
- Add an optional `focusedMessageID: UUID? = nil` to `init`, plus `@State private var highlightedMessageID: UUID?`.
- On first appear, if `focusedMessageID` is set: call `proxy.scrollTo(id, anchor: .center)` with no animation, then set
  `highlightedMessageID = id`. A `.task` waits `Task.sleep(for: .seconds(1.5))` and then sets it back to `nil`
  with animation. Keep today's `.defaultScrollAnchor(.bottom)` and the `onChange` scroll-to-bottom.
  New messages or typing during the visit still scroll to the bottom, which is fine.
- Only scroll once. A `@State private var didFocus = false` stops it happening again when you come back from somewhere else.

**`ChatApp/Views/Chat/MessageBubble.swift`**
- Add `var isHighlighted = false`. When it's true, draw a soft accent-coloured outline behind the bubble
  (`bubbleShape.stroke(Color.accentColor, lineWidth: 2)` plus a light fill), with an
  `.animation(.easeInOut, value: isHighlighted)`. Existing callers and previews don't need to change.
- Note: this file has uncommitted blank lines at the end. Remove them as part of this change.

### 4. Unit tests
- Add a unit-test target **`ChatAppTests`** (Swift Testing) whose host app is ChatApp. Prefer Xcode MCP
  `XcodeNewTarget`, or create it in Xcode. Don't edit `project.pbxproj` by hand. Add it to the `ChatApp` scheme.
- **New file `ChatAppTests/ChatSearchTests.swift`**. Build the test data in the file itself: two `User`s and their
  conversations with known text and dates. Don't use `MockData`.
  - An empty or spaces-only query → `normalized` returns `""`.
  - A name match is case- and accent-insensitive ("emma", "EMMA", and for example "José" found by "jose").
  - A name match keeps the order the conversations came in.
  - Message matches cover all conversations and are sorted newest first, and each result has the right `participant`.
  - Message text matches don't depend on name matches (one query can fill both sections).
  - No matches → both lists are empty.
  - Snippet: the highlighted run's text equals the matched text and has `.stronglyEmphasized`. A long text gets the
    "…" at the start. Newlines become spaces. With no match, the plain text comes back unchanged.

## Files
| New | Changed |
|---|---|
| `Models/MessageSearchResult.swift` | `Views/Chats/ConversationListView.swift` |
| `Utilities/ChatSearch.swift` | `Views/Chat/ChatView.swift` |
| `Views/Chats/ChatRoute.swift` | `Views/Chat/MessageBubble.swift` |
| `Views/Chats/ChatSearchResultsView.swift` | `ChatApp.xcodeproj` (test target, via Xcode) |
| `Views/Chats/MessageSearchRow.swift` | |
| `ChatAppTests/ChatSearchTests.swift` | |

Reused as they are: `ChatStore.sortedConversations`, `ConversationRow`, `AvatarView`, `Date.chatListTimestamp`,
`Message.isOutgoing`, the hidden-`NavigationLink` row pattern, `ContentUnavailableView`.
No changes to `ChatStore`, `ChatViewModel` or the service.

## Commits
1. `Add ChatSearch logic and MessageSearchResult` plus the test target and `ChatSearchTests`
2. `Add search bar with Chats/Messages results to chat list`
3. `Open chat at matched message with highlight` (ChatRoute, ChatView, MessageBubble)

## Verification
1. **Build** with Xcode MCP `BuildProject` and get no new warnings (`XcodeListNavigatorIssues`).
2. **Tests** with `RunAllTests`: all `ChatSearchTests` pass.
3. **Simulator, iPhone, iOS 17+:**
   - Search for "emma": Emma shows under Chats, and any messages containing "emma" show under Messages.
   - Search for "staging": no Chats section, and Noah's message appears with "staging" in bold, accent colour.
   - Search for "TRASTEVERE" or "trastevère": still matches (ignores case and accents).
   - Spaces only: the normal list shows. "zzz": the "No results" empty state shows.
   - Tap a message result (pick an old one, e.g. Emma's first message): the chat opens scrolled to it and the bubble
     outline appears and fades out. Going back returns to the results and the search text is still there.
   - Tap a Chats result: the chat opens at the bottom (current behaviour).
   - With a search active, open a chat, send a message, go back: the new message is searchable straight away.
   - Clearing or cancelling the search brings back the normal list with its swipe actions.
   - Dark mode, Dynamic Type at the largest size, and VoiceOver reading the rows.
   - Regression: compose a new chat, sending, statuses, and long-press Copy on a bubble.

## Risks / notes
- `scrollTo` on a lazy stack when the screen first appears can miss its target, so test it on old messages. If it misses, call it inside
  `.task` after one run-loop pass (`await Task.yield()`).
- Later merge with `retry-message`: both branches change `ChatView` (init/body). Expect a small, easy conflict.
- Known limit, not caused by this feature: replies that arrive while you're outside a chat are still lost (bug 4), so search can't find them.
