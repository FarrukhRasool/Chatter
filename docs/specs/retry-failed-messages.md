# Spec: Retry failed messages (README feature 1)

Status: implemented, not committed. Logic tested and app builds; UI checks in section 7 are pending.
Baseline: commit `5d2a35b` plus the uncommitted `[weak self]` fix in `ChatViewModel.swift`.

## 0. Remember: For this feature always check first if there is existed method can be used without any changes if not then add new functionality and do not change the exsiting running code and try to change the business logic, keep it simple, clean and minimilistic with no extra code.

## 1. Context

About 10% of sends fail in the mock backend. A failed message shows "Not delivered", but the user
can only retype it. This feature lets them resend or remove it.

README requirement: tapping a "Not delivered" message offers *Retry* and *Delete*. Retry resends
the same message (same bubble, no duplicates) and updates its status.

**Decisions made**
- A retried message keeps its position and original time.
- The send-completion status fix is included, as an agreed exception to section 0. Replies lost
  after leaving a chat are not; that is separate work.
- Retry and Delete use the standard system alert.
- `MessageBubble` is unchanged and no new files are added.
- The existing scroll trigger is unchanged, so deleting an older message may scroll to the bottom.

**Out of scope:** automatic retry, retry all, offline queue, editing before retry, undo delete,
persistence, replies lost after leaving a chat, a failure marker in the chat list, keeping the
scroll position on delete, `@Observable` migration.

## 2. Functional requirements

| ID | Requirement | Acceptance check |
|---|---|---|
| FR-1 | Tapping a failed bubble or its "Not delivered" label opens an alert with Retry, Delete and Cancel. | Both areas open the same alert. |
| FR-2 | Only failed messages are tappable. | Sending, sent, read and incoming bubbles do nothing on tap. |
| FR-3 | Retry resends the same message. | ID, text, time, position and message count are unchanged. |
| FR-4 | Retry shows `sending` at once, then `sent` (later `read`) or `failed`. | Status icon changes with each step. |
| FR-5 | A failed retry can be retried again, without limit. | "Not delivered" returns and is tappable. |
| FR-6 | Retry acts only on a `failed` message. | Two quick calls produce one service send. |
| FR-7 | Delete removes only the selected message and never calls the service. | Other messages are unchanged; grouping and date separators update. |
| FR-8 | Delete acts only on a `failed` message. | Calling it for any other status does nothing. |
| FR-9 | Deleting the only message shows the empty chat view. | Leaving then removes the empty chat (existing behaviour). |
| FR-10 | Cancel changes nothing. | Message is still failed. |
| FR-11 | Deleting a chat during a retry is safe. | No crash and no chat recreated. |
| FR-12 | Tapping Retry does not itself scroll the chat. | Scroll position is kept until the contact types or replies (existing behaviour). |

## 3. Non-functional requirements

| ID | Area | Requirement |
|---|---|---|
| NFR-1 | Compatibility | iOS 17+, iPhone and iPad, Swift 5 mode, no new dependencies. |
| NFR-2 | Architecture | `ChatStore` stays the only place that changes conversations. Rules live in `ChatViewModel`, not views. No `ChatService` protocol change. |
| NFR-3 | Threading | Store changes on the main queue only, relying on the existing `completion` contract. No new `DispatchQueue` use. |
| NFR-4 | Memory | No new retain cycles. The view model is released after leaving, even during a retry. |
| NFR-5 | Responsiveness | `sending` appears without waiting for the network. Message lookup is linear in one chat, as in `updateStatus`. |
| NFR-6 | Accessibility | Failed bubbles are VoiceOver buttons with a hint, at least 44 pt tall, and work with Dynamic Type. Failure is shown by text and icon, not colour alone. |
| NFR-7 | UI | Standard system alert, Delete marked destructive, correct in light and dark mode. |
| NFR-8 | Conventions | Follow `ChatApp/CLAUDE.md` for new code: `Button` rather than `onTapGesture`, separate views rather than new computed view properties, one type per file. Existing `ObservableObject` and `ScrollViewReader` code stays. |
| NFR-9 | Regression | Normal send, read receipts, typing, grouping and Copy are unchanged. No new build warnings. |

## 4. State rules

```
            send                success          read event
(new) ───────────▶ sending ───────────▶ sent ───────────▶ read
                     ▲  │ failure
               Retry │  ▼
                    failed ── Delete ──▶ (removed)
```

## 5. Implementation

1. **`Store/ChatStore.swift`**: added `deleteMessage(_ messageID: UUID, in conversationID: UUID)`,
   using `indexOfConversation` and `removeAll`. Retry reuses `updateStatus`.
   *(FR-7, FR-9, FR-11)*
2. **`ViewModels/ChatViewModel.swift`**: *(FR-3 to FR-9, FR-11, NFR-4)*
   - `send()`: the completion captures `[store]` instead of `[weak self]`, so a message always ends
     as `sent` or `failed`, even after leaving the chat.
   - Added `retry(messageID:)`: finds the failed message and recipient, sets `.sending`, then calls
     the existing `service.send` with a copy whose status is `.sending`. Its completion also
     captures `[store]`.
   - Added `delete(messageID:)`: checks the message is failed, then calls `store.deleteMessage`.
   - Both share the private `failedMessage(withID:)` check.
3. **`Views/Chat/ChatView.swift`**: *(FR-1, FR-2, FR-10, NFR-6, NFR-7)*
   - Added `@State private var failedMessageID: UUID?`.
   - Failed bubbles are wrapped in a plain-style `Button` with an accessibility hint. Other bubbles
     are shown as before.
   - Added one `alert` at chat level with Retry, Delete (destructive) and Cancel.
   - `.onChange(of: messages.count)` is unchanged.

Suggested commits: (a) send-completion status fix, (b) store and view model retry/delete, (c) UI.

## 6. Risks

| Risk | Handling |
|---|---|
| Button tap and long-press Copy conflict: the bubble's context menu is inside the button | Not yet checked. Test on a simulator. |
| Swapping Button and plain content may affect the status animation | Not yet checked. Test on a simulator. |
| Deleting an older failed message while scrolled up jumps to the bottom | Accepted; the scroll trigger was left unchanged. |
| Leaving during a successful retry leaves `sent`, and the reply is lost | Known limit; fixed separately by moving event handling into `ChatStore`. |

## 7. Verification

- **Logic harness: passed.** 15 checks on the real sources with a stub service, covering the logic
  of FR-3 to FR-9, FR-11 and NFR-4. The harness is temporary and is not in the repo.
- **Build: passed** with no errors, using Xcode MCP `BuildProject`.
- **Simulator: pending.** Run temporarily with `MockChatService(failureRate: 1)` and check FR-1,
  FR-2, FR-5, FR-9, FR-10, FR-12, NFR-6, NFR-7 and long-press Copy (NFR-9) on iPhone and iPad. Restore
  the default, then check that a retry ends as `sent`, then `read` (FR-4).
- **Unit tests:** there is no test target. Adding one is a separate decision.
