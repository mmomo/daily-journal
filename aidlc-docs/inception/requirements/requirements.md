# Requirements: Daily Journaling Prompt iOS App

## Intent Analysis Summary

| Item | Value |
|---|---|
| **User Request** | "I want to build an iOS that generates a prompt for journaling. A daily journaling prompt and a quick entry, with a streak counter and a widget." |
| **Request Type** | New Project (Greenfield) |
| **Scope Estimate** | Multiple Components: iOS app target, WidgetKit extension, shared data/logic module |
| **Complexity Estimate** | Moderate |
| **Requirements Depth** | Standard |
| **Distribution** | Personal / demo project (not shipped to the App Store) |

**Sources**: `requirement-verification-questions.md` (Q1–Q18) and `requirement-clarification-questions.md` (CQ1–CQ4). Each requirement lists the answers it comes from.

---

## 1. Functional Requirements

### FR-1 Daily Prompt

| ID | Requirement | Source |
|---|---|---|
| FR-1.1 | The app shows one journaling prompt per calendar day, chosen from a curated prompt library bundled with the app. No AI or network generation. | Q1, CQ1:C |
| FR-1.2 | The prompt library is organized into categories, at minimum: Gratitude, Reflection, Goals, Creativity. | Q2:B |
| FR-1.3 | The user can choose which categories they want prompts from in Settings. At least one category must stay selected. | Q2:B |
| FR-1.4 | The daily prompt is picked deterministically from the user's selected categories, so the same day gives the same prompt on every app launch and in the widget. It also avoids repeating recent prompts. | Q1, Q9 |
| FR-1.5 | The user can refresh today's prompt a limited number of times per day (default **3**). The refreshed prompt becomes today's prompt everywhere, including the widget. | Q3:C |
| FR-1.6 | Once today's entry is saved, the prompt it answered is stored with the entry and no longer changes. | Q4, Q5 |

### FR-2 Quick Entry

| ID | Requirement | Source |
|---|---|---|
| FR-2.1 | The user writes a text-only entry in response to today's prompt. | Q4:A |
| FR-2.2 | Only one entry is allowed per calendar day. | Q5:A |
| FR-2.3 | Today's entry can be edited until the end of that calendar day (local midnight). | Q5:A |
| FR-2.4 | **Grace backfill**: if yesterday has no entry, the user can create one for yesterday until 12:00 local time today. | Q8:B, CQ3:A |
| FR-2.5 | An entry that already exists for yesterday is locked at midnight. The grace window does not allow editing it. | CQ3:A |
| FR-2.6 | Entries from earlier days can be read but not edited. | Q5:A |
| FR-2.7 | Empty or whitespace-only entries cannot be saved. | Q7 |
| FR-2.8 | Opening the editor should feel quick: the editor shows with today's prompt and the keyboard already up. | Request ("quick entry") |

### FR-3 Past Entries

| ID | Requirement | Source |
|---|---|---|
| FR-3.1 | The user can browse past entries in reverse chronological order, each showing its date, prompt and text. | Q6:D |
| FR-3.2 | The user can search entries by text, matching both entry text and prompt text. | Q6:D |
| FR-3.3 | The user can export entries through the iOS share sheet. Markdown and plain text are required. PDF is a stretch goal. | Q6:D |
| FR-3.4 | Export covers all entries, with a date-range filter as an optional enhancement. | Q6:D |

### FR-4 Streak

| ID | Requirement | Source |
|---|---|---|
| FR-4.1 | A day counts toward the streak if it has a saved entry, using the user's current local time zone. | Q7:A |
| FR-4.2 | The current streak is the number of days in a row that have entries, ending today, or ending yesterday if today has no entry yet. | Q7, Q8 |
| FR-4.3 | Missing a whole day resets the streak to 0 after the grace window (12:00 the next day) passes without a backfill. | Q8:B |
| FR-4.4 | Before the grace window closes, a streak that ended the day before yesterday is shown as **at risk**, not reset. A backfill for yesterday restores it. | Q8:B, CQ3:A |
| FR-4.5 | The app also shows the longest streak ever reached. | Assumption |
| FR-4.6 | The streak is always calculated from stored entries and never kept as a separate counter, so it stays correct after iCloud sync. | Q13:B |

### FR-5 Widget

| ID | Requirement | Source |
|---|---|---|
| FR-5.1 | Provide a **Home Screen small widget** only. | Q9:A |
| FR-5.2 | The widget shows today's prompt, cut short if needed, with a small streak badge in a corner. | CQ2:A |
| FR-5.3 | The widget shows the same prompt as the app, including after a refresh (FR-1.4, FR-1.5). | FR-1 |
| FR-5.4 | Tapping the widget opens the app straight to the entry editor with today's prompt loaded. | Q10:B |
| FR-5.5 | The widget updates at local midnight, after the 12:00 grace cutoff, and right after an entry is saved or the prompt is refreshed. | FR-4 |
| FR-5.6 | The widget shows when today's entry is done, for example with a checkmark on the streak badge. | Assumption |

### FR-6 Reminder Notifications

| ID | Requirement | Source |
|---|---|---|
| FR-6.1 | The user can turn on a daily reminder and set its time. The default is 8:00 PM. | Q11:C |
| FR-6.2 | If today's entry is already saved, there is no reminder for today. | Q11:C |
| FR-6.3 | Notification permission is requested only when the user turns reminders on, not on first launch. | Assumption |
| FR-6.4 | Tapping the notification opens the entry editor, the same way the widget does. | Q10:B |

### FR-7 Settings

| ID | Requirement | Source |
|---|---|---|
| FR-7.1 | Settings has: prompt categories, the reminder switch and time, and export. | FR-1, FR-3, FR-6 |

---

## 2. Non-Functional Requirements

### NFR-1 Platform and Technology

| ID | Requirement | Source |
|---|---|---|
| NFR-1.1 | Minimum version is **iOS 17.0**. iPhone only; iPad layout is not required. | Q12:A, CQ1:C |
| NFR-1.2 | Built with **SwiftUI** for the UI, **SwiftData** for storage and **WidgetKit** for the widget. | Q12:A |
| NFR-1.3 | The app and widget share data and logic through an **App Group** container and a shared Swift package or framework. | Q9, Q13 |

### NFR-2 Data, Sync and Privacy

| ID | Requirement | Source |
|---|---|---|
| NFR-2.1 | Entries are stored on the device and synced through the user's private **iCloud (CloudKit)** database. There are no app accounts and no custom backend. | Q13:B |
| NFR-2.2 | The app works fully offline. Sync happens whenever iCloud is available. | Q13:B |
| NFR-2.3 | If the user isn't signed in to iCloud or has turned off iCloud for the app, it still works as a local-only app. | Q13:B |
| NFR-2.4 | If two devices create entries for the same day, they must be merged so that one entry per day still holds and no text is silently lost. CloudKit-backed SwiftData does not support unique constraints, so the app must handle this itself. | Q5:A, Q13:B |
| NFR-2.5 | No analytics or third-party SDKs, and journal text never leaves the user's devices or their iCloud account. | Q13:B (implied) |
| NFR-2.6 | No Face ID or passcode lock is in scope. | Q13:B (C not chosen) |

### NFR-3 Date and Time Correctness

| ID | Requirement | Source |
|---|---|---|
| NFR-3.1 | All day boundaries use the device's current calendar and time zone. | Q7:A |
| NFR-3.2 | Each entry stores its own calendar day as year, month and day, separate from the creation time, so that changing time zones doesn't move an entry to a different day. | Q7:A |
| NFR-3.3 | Streak and prompt logic must be correct across daylight-saving changes, midnight, the 12:00 grace cutoff and time zone changes. | Q7, Q8 |

### NFR-4 Quality and Testing

| ID | Requirement | Source |
|---|---|---|
| NFR-4.1 | Unit tests cover the core logic: streak calculation, including grace and at-risk states; picking the daily prompt; the refresh limit; and the rules for when an entry can be edited or backfilled. | Q15:A |
| NFR-4.2 | Core logic depends on an injectable clock or calendar so the tests are deterministic. | Q15:A |
| NFR-4.3 | Property-based testing is **not** required. | Q18:C |
| NFR-4.4 | Accessibility features (Dynamic Type, VoiceOver) and localization are not formally in scope. Standard SwiftUI controls give basic support and Dark Mode for free. | Q15:A |

### NFR-5 Performance and Usability

| ID | Requirement | Source |
|---|---|---|
| NFR-5.1 | From launch or a widget tap, the editor is ready to type in about 1 second or less on a supported device. | Request ("quick entry") |
| NFR-5.2 | Search stays responsive with a few thousand entries, roughly 10 years of daily use. | Q6:D |

---

## 3. Out of Scope

- AI-generated or personalized prompts (CQ1:C)
- Mood, photos or other attachments (Q4:A)
- Medium, Lock Screen, interactive or Control Center widgets (Q9:A)
- App lock (Face ID or passcode), user accounts, custom backend (Q13:B)
- App Store release, monetization, localization (Q14:A, Q15:A)
- iPad, Mac, watchOS

## 4. Extension Configuration

| Extension | Enabled | Decision |
|---|---|---|
| Security Baseline | No | Q16:A, overridden by CQ4:C ("Skip both for this demo") |
| Resiliency Baseline | No | Q17:A, overridden by CQ4:C |
| Property-Based Testing | No | Q18:C |

## 5. Assumptions to Confirm During Review

1. The refresh limit is **3 per day** (Q3:C gave 3 as an example).
2. Showing the longest streak (FR-4.5) and a "done today" mark on the widget (FR-5.6) are welcome additions.
3. The default reminder time is 8:00 PM.
4. PDF export is a stretch goal; Markdown and plain text are required.
5. The prompt library ships with at least 365 prompts spread across the four categories, written for this project.

## 6. Key Requirements Summary

- One curated prompt per day, filtered by the user's chosen categories, with up to 3 refreshes
- One text entry per day, editable until midnight. A missed yesterday can be backfilled until 12:00 today
- The streak counts calendar days, has a grace and "at risk" state, and is always calculated from stored entries
- Small Home Screen widget showing the prompt and a streak badge, which opens straight to the editor
- Optional daily reminder at a time the user sets, skipped once today's entry is done
- Browse, search and export past entries
- iOS 17+, SwiftUI, SwiftData, CloudKit sync, App Group shared with the widget, and unit tests for core logic
