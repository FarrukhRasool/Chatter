# Chatter – Bug Report

Findings from a full read of `ChatApp/` (27 files, all layers) plus static analysis of the
concurrency and state-mutation paths. Ordered by severity, most critical first.

**Severity scale**

| Level | Meaning |
|---|---|
| **P0 – Critical** | Crash, data race, or data corruption. Ships broken. Fix before anything else. |
| **P1 – High** | Core advertised feature produces wrong state or silently loses data. No crash. |
| **P2 – Medium** | Incorrect/sloppy behaviour a user will notice but can work around. |
| **P3 – Low** | Cosmetic, latent, or code-quality issue with no current user impact. |

**Summary**

| # | Bug | Severity | File |
|---|---|---|---|
| 1 | Force-unwrap crash on any conversation with no messages | **P0** | `Views/Chats/ConversationRow.swift:7` |
| 2 | Service events published from a background thread | **P0** | `Services/MockChatService.swift:56–72` |
| 3 | `updateStatus` stamps the *last* message, not the one that was sent | **P1** | `Store/ChatStore.swift:42–48` |
| 4 | Incoming replies are dropped unless that chat is on screen | **P1** | `ViewModels/ChatViewModel.swift:24–27` |
| 5 | Whitespace-only messages can be sent | **P2** | `ViewModels/ChatViewModel.swift:49–51` |
| 6 | `ChatViewModel` rebuilt (and re-subscribed) on every `ChatView` init | **P2** | `Views/Chat/ChatView.swift:8–12` |
| 7 | `MockData.conversations` is a computed `var` — new UUIDs every access | **P3** | `Services/MockData.swift:20` |
| 8 | `.messagesRead` emitted twice per reply cycle | **P3** | `Services/MockChatService.swift:56, 63` |
| 9 | Weekday timestamps are ambiguous at the 7-day boundary | **P3** | `Utilities/Date+Formatting.swift:14–16` |

---

## Bug 1 — Force-unwrap crash on any conversation with no messages

**Severity: P0 – Critical**

**File:** `ChatApp/Views/Chats/ConversationRow.swift:6-8`

```swift
private var lastMessage: Message {
    conversation.messages.last!     // crash
}
```

### What the user sees
The app crashes instantly — hard termination, no alert — when starting a chat with a contact
they haven't messaged before.

### Steps to reproduce
1. Launch the app.
2. Tap the compose button (top-right).
3. Pick **Lucas Berg** or **Maya Patel** — the two seeded contacts with no existing conversation.
4. Crash: `Fatal error: Unexpectedly found nil while unwrapping an Optional value`.

(The other five contacts — Emma, Noah, Liam, Sofia, Olivia — already have seeded message
history, so they mask the bug. Anyone testing with those five will report "works fine".)

### Root cause
`ChatStore.startConversation(with:)` (`ChatStore.swift:79-87`) appends a `Conversation`
built with the default `messages: []`:

```swift
let conversation = Conversation(participant: user)
conversations.append(conversation)
```

That mutation of the `@Published conversations` array re-renders `ConversationListView`, whose
`ForEach` builds a `ConversationRow` for the new, empty conversation. `ConversationRow.body`
reads `lastMessage` for both the timestamp (line 26) and the preview text (line 32), and the
force-unwrap traps on the empty array.

Note the codebase already *anticipates* empty conversations — `EmptyChatView` exists
specifically for "a brand-new conversation without messages"
(`ChatSupportingViews.swift:45-63`). The row simply never got the same treatment.

### Why this severity
Highest possible. It is a 100%-reproducible crash, reachable in three taps, on a flow the
README lists as a headline feature ("Start a new chat from the compose button"). There is no
workaround and no recovery — the process dies. A crash on a primary path outranks every
other class of defect here.

### Suggested fix
Make `lastMessage` optional and render a placeholder preview (e.g. *"No messages yet"*) with
`conversation.createdAt` as the timestamp fallback. `Conversation.lastActivity` already uses
exactly that fallback, so the pattern is established.

---

## Bug 2 — Service events published from a background thread

**Severity: P0 – Critical**

**File:** `ChatApp/Services/MockChatService.swift:54-74`

```swift
networkQueue.asyncAfter(deadline: .now() + readDelay) { [weak self] in
    guard let self else { return }
    self.subject.send(.messagesRead(conversationID: conversationID))   // on networkQueue
    self.subject.send(.typing(conversationID: conversationID, isTyping: true))
    ...
}
```

### What the user sees
Intermittent and hard to pin down — which is what makes it dangerous:

- Purple runtime issues in Xcode: *"Publishing changes from background threads is not
  allowed; make sure to publish values from the main thread."*
- Random crashes in Swift array internals (`_ArrayBuffer`, retain/release) when a reply lands
  at the same moment the chat list is scrolling or re-rendering.
- Occasional UI that doesn't update until the next unrelated touch, or a typing indicator
  that renders in a half-updated state.

Frequency scales with device load and message volume, so it will look like "flaky" or
"works on my machine" in QA.

### Steps to reproduce
1. Run on a simulator with Xcode's Main Thread Checker enabled (on by default).
2. Open any chat, send a message.
3. When the auto-reply arrives (~2–4s later), the purple warning fires on
   `ChatViewModel.handle`.
4. For the crash: send messages rapidly while scrolling the chat list. May take several attempts.

### Root cause
`MockChatService` dispatches all of its simulation work onto `networkQueue`, a private serial
`DispatchQueue`, and calls `subject.send(...)` from inside those blocks. `PassthroughSubject`
delivers synchronously on the calling thread, and nothing in the chain hops back to main —
`ChatViewModel` subscribes with no `.receive(on:)`:

```swift
service.events
    .filter { $0.conversationID == conversationID }
    .sink(receiveValue: handle)     // runs on networkQueue
```

So `handle` executes on the background queue and from there:

- writes `@Published private(set) var isPartnerTyping` → fires `objectWillChange` off-main,
  straight into SwiftUI's render machinery;
- calls `store.append(...)` / `store.markOutgoingAsRead(...)`, which mutate
  `ChatStore.conversations` — a `@Published` array that the main thread is concurrently
  reading in `sortedConversations` and every `ConversationRow`. That is an unsynchronised
  read/write on a copy-on-write buffer: a genuine data race, not just a warning.

The `send(_:to:completion:)` path *does* get this right — it wraps the completion in
`DispatchQueue.main.async` (line 34) and `ChatService`'s own documentation promises
*"`completion` is called on the main queue"* (`ChatService.swift:37`). The `events`
publisher carries no such guarantee and no such hop. The contract is simply missing for
half the API.

A grep confirms there is exactly one main-thread hop in the entire codebase, and it is that
completion handler.

### Why this severity
P0 alongside Bug 1. A data race on the single source of truth is worse than a deterministic
crash in one respect — it is unpredictable, can corrupt state silently, and will not
reproduce reliably in testing. It affects every incoming message, read receipt, and typing
event, i.e. the entire real-time half of the app.

### Suggested fix
Two defensible options:

1. **Fix it at the source** — make `MockChatService` publish on main:
   `subject.receive(on: DispatchQueue.main).eraseToAnyPublisher()` in the `events` getter.
   This makes the guarantee uniform across the whole `ChatService` protocol and documents it
   there, matching the existing promise on `completion`.
2. **Fix it at the consumer** — add `.receive(on: DispatchQueue.main)` in `ChatViewModel`.
   Protects this one subscriber but leaves the trap armed for the next.

Option 1 is preferable: the protocol should state its threading contract once, and a real
WebSocket implementation would have the identical obligation. Annotating `ChatStore` and
`ChatViewModel` as `@MainActor` would then enforce it at compile time.

---

## Bug 3 — `updateStatus` stamps the last message, not the one that was sent

**Severity: P1 – High**

**File:** `ChatApp/Store/ChatStore.swift:42-48`

```swift
func updateStatus(_ status: Message.Status, in conversationID: UUID) {
    guard let index = indexOfConversation(conversationID),
          let lastIndex = conversations[index].messages.indices.last
    else { return }

    conversations[index].messages[lastIndex].status = status   // positional, not identity
}
```

### What the user sees
Delivery ticks attach to the wrong bubble.

- **Two messages in quick succession:** send "A", then "B" within a second. A's network
  call completes and marks **B** as sent. "A" keeps its clock icon permanently — it looks
  like it never sent, even though it did.
- **"Not delivered" on the wrong bubble:** if "A" fails, **B** gets the red *Not delivered*
  label while "A" looks normal. The user retries the wrong message.
- **"Not delivered" on a message they received:** if the contact's reply lands before the
  send completes, the *incoming* bubble gets stamped `.sent` or `.failed` — a received
  message displaying the sender's own delivery status.

### Steps to reproduce
1. Open any chat.
2. Type "first", send, and immediately type "second" and send (within ~1s — latency is
   randomised 0.4–1.0s).
3. Watch the status icons: the first bubble stays on the clock icon indefinitely.
4. Repeat a few times; with `failureRate = 0.1` you will see the mislabelled
   *Not delivered* case within ~10 attempts.

### Root cause
The API identifies the target message by **position** (`messages.indices.last`) rather than
by **identity**. `ChatViewModel.send()` captures the `conversationID` but discards the
`message.id` it just created:

```swift
service.send(message, to: recipient) { result in
    switch result {
    case .success: store.updateStatus(.sent, in: conversationID)
    case .failure: store.updateStatus(.failed, in: conversationID)
    }
}
```

Between `store.append(message)` and the completion firing there is a 0.4–1.0s window in
which the array can grow — from a second outgoing send, or from an incoming reply appended by
`handle(_:)`. Whatever occupies the last slot at that moment absorbs the status.

**This compounds Bug 4's visible symptom.** `markOutgoingAsRead` only promotes messages whose
status is exactly `.sent` (`ChatStore.swift:56`). A message orphaned at `.sending` by this bug
is therefore skipped by the read receipt too, so it is stuck on the clock icon forever with no
path out.

### Why this severity
High rather than critical: no crash and no unrecoverable state, but it corrupts the model and
is plainly visible on an advertised feature ("delivery status (sending → sent → read)"). It
also actively misleads — telling a user a delivered message failed, or that a received
message wasn't delivered. Any "Retry failed messages" feature (Part 2, #1) built on top of
this positional API would inherit the defect and retry the wrong message.

### Suggested fix
Key the update on message identity:

```swift
func updateStatus(_ status: Message.Status, messageID: UUID, in conversationID: UUID)
```

resolving via `firstIndex(where: { $0.id == messageID })`, and pass `message.id` from
`ChatViewModel.send()`. This is also the prerequisite for Part 2 feature #1.

---

## Bug 4 — Incoming replies are dropped unless that chat is on screen

**Severity: P1 – High**

**File:** `ChatApp/ViewModels/ChatViewModel.swift:24-27` (architectural)

### What the user sees
Replies vanish. Send a message, navigate back to the chat list before the reply arrives
(a 2–4s window), and the reply never appears — no unread badge, no change to the list preview,
and it is absent when the chat is reopened. The contact simply never answered.

Unread badges therefore only ever show the hardcoded seed values (Noah 2, Sofia 1). No live
message can ever produce one.

### Steps to reproduce
1. Open the chat with Emma.
2. Send "hey".
3. Immediately tap back to the chat list.
4. Wait 10s. No badge appears, the row preview still shows your own message.
5. Reopen the chat — the reply is not there and never arrives.

### Root cause
The *only* subscriber to `service.events` is `ChatViewModel`, and a `ChatViewModel` exists
only while its `ChatView` is on screen (`@StateObject`, created in
`navigationDestination`). Pop the view and the view model — and its subscription — are
deallocated. `MockChatService` continues emitting on schedule, but nothing is listening, so
the event is discarded and `ChatStore` is never told.

The store's own code proves this is unintended. `ChatStore.append` contains:

```swift
if !message.isOutgoing && activeConversationID != message.conversationID {
    conversations[index].unreadCount += 1
}
```

That branch is **unreachable**. The only code path that appends an incoming message is
`ChatViewModel.handle`, which by construction runs only for the conversation that *is*
active and filters on its own `conversationID` (line 25). So `activeConversationID` always
equals `message.conversationID` at that point. The `activeConversationID` property,
`markAsUnread`'s counterpart logic, and this whole branch only make sense if something
store-level were subscribed to the event stream.

### Why this severity
High. Silent data loss on the feature the README calls out as the core of the simulation
("Simulated replies from contacts, each with their own personality") plus a headline list
feature (unread badges) that can never fire. Not P0 only because nothing crashes and the
loss is bounded to messages in flight.

### Suggested fix
Move the event subscription up to `ChatStore` (or an owner that lives as long as the app) so
it is always listening, and let `ChatViewModel` read derived state from the store. The
existing `activeConversationID` check then starts working as written, and badges increment
correctly for background conversations. `isPartnerTyping` would move to per-conversation
state on the store, keyed by conversation ID.

---

## Bug 5 — Whitespace-only messages can be sent

**Severity: P2 – Medium**

**File:** `ChatApp/ViewModels/ChatViewModel.swift:49-51`

```swift
var canSend: Bool {
    !draft.isEmpty
}
```

### What the user sees
Typing a few spaces or newlines activates the send button, and sending produces an empty
bubble — a coloured rectangle with no text, a timestamp, and a delivery tick. It persists in
the history and becomes the chat list's last-message preview, so the row reads `"You: "`.

### Steps to reproduce
1. Open any chat, press the spacebar three times.
2. The send button activates (it also scales up and gains a shadow, confirming `canSend`).
3. Tap send. An empty bubble appears and the contact replies to it.

### Root cause
`canSend` tests `isEmpty` rather than trimming whitespace, and `send()` passes `draft`
through untrimmed. `ReplyGenerator.reply(to:from:)` handles the blank string without
complaint (falls through to `genericReplies`), so nothing downstream catches it either.

### Why this severity
Medium. Cosmetically bad and trivially reachable, but it is user-initiated, harmless to app
state, and self-inflicted. Below the state-corruption bugs; above the latent ones.

### Suggested fix
Trim once and use the trimmed value for both the guard and the message:

```swift
var trimmedDraft: String { draft.trimmingCharacters(in: .whitespacesAndNewlines) }
var canSend: Bool { !trimmedDraft.isEmpty }
```

---

## Bug 6 — `ChatViewModel` is rebuilt, and re-subscribed, on every `ChatView` init

**Severity: P2 – Medium**

**File:** `ChatApp/Views/Chat/ChatView.swift:8-12`

```swift
init(conversationID: UUID, store: ChatStore, service: any ChatService) {
    _viewModel = StateObject(
        wrappedValue: ChatViewModel(conversationID: conversationID, store: store, service: service)
    )
}
```

### What the user sees
No direct symptom, which is why this is P2 rather than higher — but it wastes work on every
render pass and is a latent correctness trap.

### Root cause
`StateObject(wrappedValue:)` evaluates its argument eagerly on *every* `init`, while SwiftUI
keeps only the instance from the first one. `ChatView` is re-initialised on each re-render of
its parent — and because `ChatViewModel` forwards every `store.objectWillChange`
(lines 20-22), that happens on every store mutation, including each keystroke-driven status
change elsewhere.

Each discarded instance runs its full `init`: two Combine subscriptions into
`store.objectWillChange` and `service.events`. They are torn down when the throwaway object
deallocates, so there's no unbounded leak — but it means short-lived subscribers are
repeatedly attached to the shared service. Combined with Bug 2's background delivery, an
event can be dispatched to an instance mid-teardown.

### Why this severity
Medium. Currently invisible to users, but it allocates and subscribes on the hot path and is
the kind of thing that turns into a real bug the moment `init` gains a side effect (a fetch,
an analytics event, a "mark as delivered" call).

### Suggested fix
Construct the view model once in the parent and pass it in, or move creation into
`.task`/`onAppear` where lifetime is explicit. A `StateObject` whose init has side effects
should never be built inline in a view initialiser.

---

## Bug 7 — `MockData.conversations` is a computed `var`: new UUIDs on every access

**Severity: P3 – Low**

**File:** `ChatApp/Services/MockData.swift:20`

```swift
static var conversations: [Conversation] {   // computed — rebuilt every call
```

`makeConversation` calls `UUID()` per invocation, so every read of
`MockData.conversations` yields conversations with brand-new IDs and `Date()`-relative
timestamps.

Harmless today — `ChatStore.init`'s default argument reads it exactly once per store. But any
second reader gets a disjoint set of IDs that will not match the store's. `ConversationRow`'s
own `#Preview` (line 53) already does this, and anything comparing IDs across two reads would
fail in a thoroughly confusing way.

**Severity rationale:** no user-visible impact in the shipping path; purely a latent trap for
the next developer (and for the unit tests the README asks for as a bonus).

**Fix:** make it a `static let`, or an explicit `makeSeedData()` function so the
rebuild-per-call behaviour is obvious at the call site.

---

## Bug 8 — `.messagesRead` emitted twice per reply cycle

**Severity: P3 – Low**

**File:** `ChatApp/Services/MockChatService.swift:56` and `:63`

The same `.messagesRead(conversationID:)` event is sent once before the typing indicator
starts and again when it stops. `ChatStore.markOutgoingAsRead` is idempotent, so the second
is a no-op in practice.

**Severity rationale:** no behavioural impact; it's redundant work and misleading signal. A
real client with read-receipt analytics or animations keyed to the event would double-count.

**Fix:** drop the duplicate on line 63.

---

## Bug 9 — Weekday timestamps are ambiguous at the 7-day boundary

**Severity: P3 – Low**

**File:** `ChatApp/Utilities/Date+Formatting.swift:14-16`

```swift
if let days = calendar.dateComponents([.day], from: self, to: Date()).day, days < 7 {
    return formatted(.dateTime.weekday(.wide))
}
```

`dateComponents` truncates toward zero, so a message 6 days and 23 hours old returns `6` and
renders as a bare weekday — the *same* weekday name as today. A row reading "Monday" on a
Monday is indistinguishable from today's messages at a glance.

**Severity rationale:** cosmetic, affects a narrow time window, and the information is still
recoverable by opening the chat. Correct behaviour would compare calendar days (via
`startOfDay`) and use a `< 7` *day* boundary rather than a 7×24h one.

---

## What I'd fix first

1. **Bug 1** — one-line crash fix, unblocks all testing of the compose flow.
2. **Bug 2** — adopt a main-thread guarantee on the `events` publisher; without it every
   other fix is being tested against racy state.
3. **Bug 3** — change `updateStatus` to be identity-based. Also a prerequisite for the
   "Retry failed messages" feature.
4. **Bug 4** — move the event subscription to the store. The largest change of the four and
   the one that makes `activeConversationID` and unread badges mean something.

Bugs 5–9 are small, independent, and suitable for a single cleanup commit each.

### Notes on verification

These findings come from a complete read of the source plus targeted greps (one force-unwrap
in the codebase, one main-thread hop). I have **not** yet built and run the app in a
simulator, so the repro steps are derived from the code paths rather than observed. Bugs 1,
3, 5, 7, 8 and 9 are deterministic from the source. Bugs 2, 4 and 6 are concurrency- and
lifecycle-dependent — the mechanism is unambiguous in the code, but the exact crash signature
for Bug 2 will vary per run. Worth confirming each against a running build (Bug 2 in
particular with Thread Sanitizer enabled) before fixing.
