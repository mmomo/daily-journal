# Functional Design Plan: Unit 1 Domain (`JournalDomain`)

**Stage**: CONSTRUCTION - Functional Design
**Inputs**: unit-of-work.md (Unit 1), unit-of-work-story-map.md (14 primary stories), application-design.md §6, stories.md (approved open points)

## Already Decided (no question needed)

These come from approved artifacts and are applied directly:

| Topic | Rule | Source |
|---|---|---|
| Refresh limit | 3 per day, resets at local midnight, none after today's entry is saved | FR-1.5, US-1.3 |
| Prompt on category change | Today's prompt stays; new categories apply to refreshes today and to prompts from tomorrow | Open point 1 |
| No-repeat window | 30 days | Open point 4 |
| Edit window | Today's entry editable until local midnight; existing entries lock at midnight | FR-2.3, FR-2.5 |
| Backfill | Only a *missing* yesterday, until 12:00 local today | FR-2.4, CQ3:A |
| Streak | Calculated from the set of entry days; grace and at-risk until 12:00; best streak shown | FR-4 |
| Merge | Both texts kept, oldest first, with a divider; deterministic and idempotent | Open point 3, services.md S5 |
| Reminders | Rolling window of one-off notifications, today skipped once done | services.md S6 |
| Determinism | Prompt choice uses a stable hash (never Swift's per-launch randomized `hashValue`) so devices agree | US-1.2 |

## Category Evaluation

| Category | Applies | Covered by |
|---|---|---|
| Business Logic Modeling | Yes | Plan steps 2–4 |
| Domain Model | Yes | Step 2; Q4 (future-dated entries) |
| Business Rules | Yes | Q1, Q3, Q5, Q6 |
| Data Flow | Yes | Step 5 (storage contracts for Data unit) |
| Integration Points | Limited | Ports only; there are no external systems. Notification content in Q2 |
| Error Handling | Yes | Step 6 (`JournalError` mapping); Q3 |
| Business Scenarios | Yes | Q4, Q6 |
| Frontend Components | No | Domain has no UI. `frontend-components.md` is not produced for this unit |

---

## Questions

Please fill in the letter after each `[Answer]:` tag. If no option fits, choose the last option (Other) and describe what you want.

## Question 1
When two same-day entries from different devices are merged, they may have answered **different prompts** (prompt state is per device). How should the merged entry handle that?

A) Keep the prompt of the oldest entry as the entry's prompt. If the second entry answered a different prompt, insert that prompt as a quoted line above its text inside the merged body

B) Keep only the oldest entry's prompt and just join the texts (the second prompt is lost)

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 2
Reminder notifications are scheduled up to 7 days ahead, but a future day's prompt can still change (a refresh, a category change). What should the notification say?

A) Generic text that never goes stale, e.g., title "Time to journal", body "Your daily prompt is waiting. Keep your N-day streak going." (streak number only when known at scheduling time, otherwise omitted)

B) The predicted prompt text for that day, re-scheduled whenever the prompt changes. It may occasionally differ from what the app shows if a change happens on another device

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 3
Should entries have a maximum length?

A) No limit (validation is only "not empty after trimming whitespace")

B) Soft limit: maximum 5,000 characters, with a counter shown near the limit and further input blocked beyond it

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 4
**Travel edge case:** if you write the Oct 8 entry in Mexico City, then fly west (e.g., to Hawaii) where it is still Oct 7, the Oct 8 entry is now "in the future" relative to the device's today. How should that be handled?

A) Future-dated entries are shown in History, are read-only, and don't count toward the streak until their date arrives locally. Today (Oct 7) behaves normally: if it has no entry, you can write one

B) Treat any future-dated entry as belonging to today for streak and "done today" purposes (no new entry can be written for today while it exists)

X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 5
How should search match the query?

A) The whole query as one substring (e.g., "quiet morning" matches only that exact phrase), case- and accent-insensitive

B) All words in the query must appear somewhere in the entry or prompt text, in any order (e.g., "morning quiet" matches "a quiet, slow morning"), case- and accent-insensitive

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 6
When backfilling yesterday's missing entry, which prompt is used, and can it be refreshed?

A) Yesterday's prompt as this device last showed it (including any refreshes made yesterday), or the deterministic choice if this device never showed one. **No refresh** for backfill

B) Same as A, but the backfill prompt can also be refreshed, sharing yesterday's remaining refresh count

C) No prompt for backfill entries: a free-form entry with a fixed label like "Catching up on yesterday"

X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Approved Answers

| # | Decision |
|---|---|
| Q1:A | Merged entry keeps the oldest entry's prompt. A later entry with a different prompt gets that prompt as a quoted line above its text |
| Q2:A | Generic reminder text ("Time to journal" / "Your daily prompt is waiting."), plus the streak count when it's known at scheduling time |
| Q3:A | No length limit. The only validation is "not empty after trimming whitespace" |
| Q4:B | A future-dated entry (after westward travel) counts as today for streak and "done today". No new entry can be written for today while one exists |
| Q5:A | Search matches the whole query as one substring, case- and accent-insensitive |
| Q6:A | Backfill uses yesterday's prompt as this device last showed it (or the deterministic choice). No refresh for backfill |

Answer analysis: no contradictions or vague answers. One derived detail, Q4:B: a future-dated entry stays **read-only** (EntryEditPolicy locks any day after today). It becomes editable as "today" once that date arrives locally.

## Execution Checklist (run after answers are checked)

- [x] Step 1: Re-read Unit 1 context, stories and approved answers
- [x] Step 2: Generate `domain-entities.md`: every value type with fields, invariants and relationships; `CalendarDay` rules; `JournalError` catalogue
- [x] Step 3: Generate `business-rules.md`: numbered rules (BR-xx) for prompts, entries, backfill, streak, merge, search, export, reminders, settings and onboarding, each traced to stories and with example cases
- [x] Step 4: Generate `business-logic-model.md`: algorithms and use case flows
  - [x] PromptSelector: stable hash, pool ordering, recent-exclusion, refresh sequence, fallbacks
  - [x] EntryEditPolicy: instants for midnight and 12:00 under DST and time zone changes
  - [x] StreakCalculator: current, best, at-risk, future-dated days
  - [x] DayEntryMerger: ordering, divider, prompt handling, id selection, idempotence
  - [x] Reminder window computation and notification content
  - [x] JournalExporter: Markdown and plain-text layouts
  - [x] EntrySearchMatcher: normalization and matching
  - [x] All 15 use case flows with error outcomes
- [x] Step 5: Define storage contracts for the Data unit: `EntryRecord` fields (CloudKit-compatible), `prompts.json` schema and validation rules, App Group keys for settings and prompt state
- [x] Step 6: Map acceptance scenarios to planned test cases (scenario → policy or use case)
- [x] Step 7: Validate Markdown and diagrams; update state
