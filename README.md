# Chatter – iOS Take-Home Exercise

Chatter is a small messaging app built with **SwiftUI**. It has no real backend: a
`MockChatService` simulates network latency, occasional send failures, read receipts,
typing indicators and automatic replies from your contacts.

![platform](https://img.shields.io/badge/iOS-17%2B-blue) ![swift](https://img.shields.io/badge/Swift-5-orange) ![ui](https://img.shields.io/badge/UI-SwiftUI-purple)

## Getting started

1. Open `ChatApp.xcodeproj` in **Xcode 16 or newer**.
2. Choose an iPhone simulator (iOS 17+).
3. Build & run (`⌘R`). No signing or extra setup is needed for the simulator.

## What the app does

- A chat list with avatars, online status, last message preview, timestamps and unread badges
- Swipe actions: delete a conversation, mark it read or unread
- Start a new chat from the compose button (with contact search)
- A chat screen with grouped bubbles, day separators, delivery status (sending → sent → read),
  a typing indicator and auto-scroll
- Simulated replies from contacts, each with their own "personality"

## Project structure

```
ChatApp/
├── App/                ChatAppApp.swift – entry point, wires up store + service
├── Models/             User, Message, Conversation
├── Services/           ChatService protocol, MockChatService, ReplyGenerator, MockData
├── Store/              ChatStore – single source of truth for conversations
├── ViewModels/         ChatViewModel – logic for a single chat screen
├── Views/
│   ├── Chats/          Conversation list, row, new chat sheet
│   ├── Chat/           Chat screen, bubbles, input bar, typing indicator
│   └── Components/     Avatar, unread badge
└── Utilities/          Theme, date formatting, message grouping
```

**Data flow:** `ChatStore` (an `ObservableObject`) holds all conversations. Each chat
screen gets its own `ChatViewModel`, which sends messages through `ChatService` and
listens to its `events` publisher for typing, read receipts and incoming messages.

---

## Your task

### Part 1 – Find and fix bugs

QA says the app "mostly works", but users have reported crashes and odd behaviour.
The codebase has **several real bugs** of different severity.

1. Find as many as you can: run the app, read the code, use Xcode's tools.
2. **Prioritise them.** For each bug, write down:
   - what the user sees (symptom / steps to reproduce)
   - the root cause
   - severity and why you ranked it that way
3. Fix them, starting with the most critical. Keep each fix small and focused,
   ideally one commit per bug.

### Part 2 – Build features (AI tools encouraged)

Pick **at least two** features from the list below and build them. You may use any AI
assistant you like. We are interested in *how* you work with it, so be ready to show
your prompts, what you accepted, what you changed and why.

| # | Feature | Description | Size |
|---|---------|-------------|------|
| 1 | **Retry failed messages** | Tapping a "Not delivered" message offers *Retry* and *Delete*. Retry resends the same message (same bubble, no duplicates) and updates its status. | S |
| 2 | **Message reactions** | Long-press a bubble to pick an emoji reaction (❤️ 😂 👍 😮 😢). Show reactions as a small chip on the bubble. Tapping your own reaction removes it. | M |
| 3 | **Search** | A search bar in the chat list that filters by contact name *and* message content. Matching messages show a snippet with the match highlighted, and tapping one opens the chat. | M |
| 4 | **Reply / quote** | Swipe a bubble to reply. A preview of the quoted message appears above the input bar (can be dismissed). Sent replies show the quoted text inside the bubble. | M–L |
| 5 | **Persistence** | Conversations and messages survive an app restart (SwiftData, Core Data or Codable + file storage). Messages still in "sending" on launch should be marked as failed. | M–L |

Bonus: unit tests for the store, the view model or your new features.

### What to send back

- Your code (git repo or zip) with a readable commit history
- A short `NOTES.md` with your bug list and priorities, decisions you made, and what you
  would do next with more time

Good luck, and have fun! 🚀
