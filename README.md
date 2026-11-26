# Chatter

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
