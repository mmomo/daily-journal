# Personas

The app has one kind of user: someone journaling privately on their own iPhone. Following plan decision Q1:B, it is modeled as **one primary persona** plus **two behavioral variants**. The variants share the primary persona's context but stress different requirements, so acceptance criteria cover both habits.

---

## P1: Sam, the Everyday Journaler (Primary)

| Attribute | Description |
|---|---|
| **Context** | Adult with a busy routine who wants a few minutes of reflection a day. Uses an iPhone (iOS 17+), sometimes has a second Apple device signed in to the same iCloud account |
| **Goal** | Write a short, honest entry most days without having to think of what to write |
| **Motivations** | Less mental clutter, noticing patterns over time, a calm daily ritual |
| **Frustrations** | Staring at a blank page; apps with accounts, ads or social features; slow, multi-tap flows |
| **Journaling habit** | 2–5 sentences, usually in the evening, sometimes from the Home Screen widget |
| **Tech comfort** | Comfortable with iOS basics (widgets, notifications, share sheet). Doesn't want to configure much |
| **Key requirements** | FR-1 (prompt), FR-2 (quick entry), FR-3 (history), FR-5 (widget), NFR-2 (privacy, offline, sync), NFR-5 (speed) |

---

## P2: Habit Builder (Variant of P1)

| Attribute | Description |
|---|---|
| **Context** | Same as Sam, but driven mostly by keeping the streak going |
| **Goal** | Never break the streak, and beat their longest streak |
| **Motivations** | Visible progress; the satisfaction of a "done today" checkmark |
| **Frustrations** | A streak that resets unfairly: travel across time zones, daylight-saving changes, or an entry written on another device not being counted |
| **Behavior** | Checks the streak badge on the widget daily. Writes early in the day to "lock in" the streak |
| **Key requirements** | FR-4 (streak, longest streak), FR-5.2/FR-5.6 (widget badge and done mark), NFR-3 (date/time correctness), FR-4.6 (streak calculated from synced entries) |

---

## P3: Lapsed Journaler (Variant of P1)

| Attribute | Description |
|---|---|
| **Context** | Same as Sam, but with an irregular schedule; often forgets or falls asleep before writing |
| **Goal** | Get back into the habit without feeling punished for missing a day |
| **Motivations** | Gentle nudges; a second chance the next morning |
| **Frustrations** | Losing a long streak over one late night; reminders that fire after they've already written |
| **Behavior** | Relies on the daily reminder. Often writes yesterday's entry the next morning |
| **Key requirements** | FR-2.4/FR-2.5 (grace backfill until 12:00), FR-4.3/FR-4.4 (at-risk state and reset), FR-6 (configurable reminder, skipped once done), FR-1.5 (refresh when a prompt doesn't fit) |

---

## Persona Summary

| Persona | Primary concern | Most-used touchpoints |
|---|---|---|
| P1 Everyday Journaler | Easy, private, quick writing | Today screen, widget, history |
| P2 Habit Builder | Streak correctness and visibility | Widget badge, Today screen streak |
| P3 Lapsed Journaler | Forgiveness and reminders | Notification, grace backfill, Today screen at-risk message |

Persona-to-story mapping is in `stories.md`.
