# Business Rules: Unit 1 Domain

Notation: **today** = `CalendarDay(containing: now, timeZone)`; **yesterday** = today − 1; **midnight(d)** = `(d+1).start`; **noon(d)** = `d.noon`. All examples use America/Mexico_City (UTC−6, no DST) unless stated.

---

## Time (BR-T)

| ID | Rule | Example |
|---|---|---|
| BR-T1 | Every rule gets "now" and the time zone from `TimeSource`. No code reads the system clock directly | Tests inject a fixed instant |
| BR-T2 | Days are Gregorian civil dates in the device's **current** time zone, whatever the calendar setting | Device set to the Japanese calendar still journals on 2026-10-08 |
| BR-T3 | An entry's day is fixed when it's created and never recomputed from timestamps | Entry for 10-08 stays 10-08 after moving to Tokyo |
| BR-T4 | Day boundaries are computed by the calendar, never as "+86,400 s" | 2026-11-01 in New York is 25 h long; still one day |

## Prompts (BR-P)

| ID | Rule | Stories |
|---|---|---|
| BR-P1 | The eligible pool is every library prompt whose category is selected, sorted by `id` | US-1.4 |
| BR-P2 | Each day's prompt is a deterministic function of (day, selected categories, the prompt ids answered in the previous 30 days). Two devices with the same inputs show the same prompt | US-1.2 |
| BR-P3 | No prompt is the daily pick twice within any 30 consecutive days while the categories stay the same. A daily pick that matches a prompt answered in the previous 30 days is skipped | US-1.2 |
| BR-P4 | The first time a day's prompt is needed on a device, it's computed and saved in that device's `DailyPromptState`. After that it's read from the state, so changing categories mid-day doesn't change it | US-1.4 |
| BR-P5 | Up to **3** refreshes per day per device (`refreshesUsed` 0…3). The count resets with the new day's state | US-1.3 |
| BR-P6 | A refresh picks a prompt from the **current** selected categories that isn't in today's `shownPromptIDs` and wasn't answered in the previous 30 days. The result is deterministic for (day, categories, refresh number) | US-1.3, US-1.4 |
| BR-P7 | Refreshing is refused (`entryLocked`) once today is done (an entry exists for today, or a future-dated entry exists) | US-1.3 |
| BR-P8 | If the stored `promptID` no longer exists in the library (removed in an app update), the daily pick is recomputed and replaces it | n/a |
| BR-P9 | If every prompt in the pool is excluded (impossible with ≥ 90 per category, but defined anyway), exclusions are relaxed in this order: answered-in-30-days, then shown-today except the current prompt. A refresh with a pool of size 1 throws `noRefreshesLeft` | n/a |

## Entries (BR-E)

| ID | Rule | Stories |
|---|---|---|
| BR-E1 | At most one entry per day (domain view) | US-2.1 |
| BR-E2 | Text is valid if it has at least one non-whitespace character. It's stored exactly as typed. No maximum length (Q3:A) | US-2.1 |
| BR-E3 | Saving today: create if none exists (prompt = today's current prompt, frozen), or update text and `updatedAt` if one exists. Only while `now < midnight(today)` | US-2.1, US-2.2 |
| BR-E4 | Saves (including autosaves) after midnight to the previous day's existing entry are rejected (`entryLocked`) | US-2.2 |
| BR-E5 | Editability: day == today → `.editable(until: midnight(today))`. Day == yesterday, no entry, and `now < noon(today)` → `.backfillable(until: noon(today))`. Otherwise `.locked` | US-2.2–2.4 |
| BR-E6 | Future-dated days (day > today, after westward travel) are `.locked` (Q4:B) | Q4 |
| BR-E7 | While a future-dated entry exists, **today counts as done**. The Today screen shows that entry (read-only), and no new entry can be created for today (`entryLocked`) | Q4:B |
| BR-E8 | Backfill creates an entry for yesterday with yesterday's prompt: this device's `DailyPromptState` for yesterday if present, else the deterministic daily pick. **No refresh** (Q6:A) | US-2.3 |
| BR-E9 | Only yesterday can be backfilled, never earlier days | US-2.3 |
| BR-E10 | `createdAt` is the instant of the first save. `updatedAt` is the instant of the latest save | n/a |

## Streak (BR-S)

Let **D** = the set of entry days ≤ today, plus today if any entry day > today (Q4:B). `run(x)` = number of consecutive days in D ending at x (0 if x ∉ D).

| ID | Rule | Example (D, now) → result |
|---|---|---|
| BR-S1 | Today ∈ D and (yesterday ∈ D, or now ≥ noon(today), or run(today−2) = 0) → current = run(today), **active** | {10-06,07,08}, 10-08 21:00 → 3 active |
| BR-S2 | Today ∈ D, yesterday ∉ D, now < noon(today), run(today−2) > 0 → current = 1, **atRisk(restorable: run(today−2), until: noon(today))** | {10-05,06,07,09}, 10-09 09:00 → 1 atRisk(3) |
| BR-S3 | Today ∉ D, yesterday ∈ D → current = run(yesterday), **active** | {10-06,07}, 10-08 09:00 → 2 active |
| BR-S4 | Today ∉ D, yesterday ∉ D, now < noon(today), run(today−2) > 0 → current = run(today−2), **atRisk(restorable: same, until: noon(today))** | {10-05,06,07}, 10-09 09:00 → 3 atRisk(3) |
| BR-S5 | Otherwise current = 0, **none** | {10-05,06,07}, 10-09 12:00 → 0 none |
| BR-S6 | best = max(longest run in D, current) | Runs 12 and 4 → best 12 |
| BR-S7 | isTodayDone = today ∈ D | n/a |
| BR-S8 | The streak is always recalculated from current data, never stored | US-4.1 |

Backfilling in BR-S4 then gives run(yesterday) = 4 (active). Writing today too gives 5 (US-4.2).

## Merge (BR-M)

| ID | Rule |
|---|---|
| BR-M1 | When the store has two or more entries for the same day, they're merged into one |
| BR-M2 | Order the entries by `createdAt` ascending, ties broken by `id.uuidString` ascending. The first is the **base** |
| BR-M3 | The merged entry keeps the base's `id`, `day`, `promptID`, `promptText` and `createdAt`. `updatedAt` = max of all |
| BR-M4 | Merged text = base text, then for each later entry: `"\n\n---\n\n"` + (if its `promptID` ≠ base `promptID`: `"> " + its promptText + "\n\n"`) + its text (Q1:A) |
| BR-M5 | A later entry whose text and `promptID` exactly equal a part already included is skipped (no duplicated text) |
| BR-M6 | Merging is deterministic, so two devices merging the same set produce identical results. All non-base entries are deleted |

## Search (BR-Q)

| ID | Rule |
|---|---|
| BR-Q1 | The query is trimmed. Empty → all entries, newest first |
| BR-Q2 | An entry matches if its `text` or `promptText` contains the whole query as one substring, case- and diacritic-insensitive (Q5:A) |
| BR-Q3 | Results are newest day first |

## Export (BR-X)

| ID | Rule |
|---|---|
| BR-X1 | Throws `nothingToExport` when there are no entries |
| BR-X2 | Entries are oldest day first. Future-dated entries are included in date order |
| BR-X3 | File name: `daily-journal-YYYY-MM-DD.md` or `.txt` (export day) |
| BR-X4 | Layouts are defined in business-logic-model §6. Entry text is written exactly as stored |

## Reminders (BR-R)

| ID | Rule |
|---|---|
| BR-R1 | If reminders are disabled or permission isn't granted, all pending reminders are removed |
| BR-R2 | Otherwise the pending set is replaced with a **7-day window**. Day d is in the window if d ∈ [today, today+6], fire(d) > now, and d isn't done (only today can be done) |
| BR-R3 | fire(d) = d at the configured hour:minute in the current time zone. If a DST gap skips that time, use the next valid instant |
| BR-R4 | Title "Time to journal". Body "Your daily prompt is waiting." For **today's** reminder only, when the streak status at scheduling time is active with current ≥ 1, add " Keep your N-day streak going." (N = current, the run ending yesterday; e.g., 5 → "Keep your 5-day streak going."). Other days: the base body only (Q2:A) |
| BR-R5 | Every reminder carries `DeepLink.todayEditor` |
| BR-R6 | The window is recalculated on: app launch, foreground, day change, save, backfill, sync reconcile, and reminder setting changes |
| BR-R7 | Turning reminders on with authorization `notDetermined` requests permission. If denied, the setting is saved as **off** and `notificationsDenied` is thrown |

## Settings and Onboarding (BR-G)

| ID | Rule |
|---|---|
| BR-G1 | Defaults: all 4 categories, reminder off at 20:00, onboarding not completed |
| BR-G2 | The category set can never be empty (`categoriesEmpty`) |
| BR-G3 | Changing categories reloads the widget. It doesn't change today's already-chosen prompt (BR-P4) |
| BR-G4 | Completing onboarding saves categories, applies the reminder choice (BR-R7), sets `onboardingCompleted = true`, and reloads the widget. If reminder permission is denied, onboarding still completes with the reminder off, and the error is returned for display |
| BR-G5 | Before onboarding is complete, `TodayState.onboardingCompleted == false`. The widget shows a placeholder and deep links are deferred |

---

## Acceptance Scenario → Test Mapping (Step 6)

| Story scenario | Rule(s) | Test target |
|---|---|---|
| US-1.1 prompt on Today / offline / new day | BR-P1, P2, P4 | GetTodayStateUseCase |
| US-1.2 same after relaunch, app = widget, no 30-day repeats, cross-device | BR-P2, P3, P4 | PromptSelector (30-day sweep, all category combinations), GetTodayState |
| US-1.3 refresh, limit, reset, persists, none after save | BR-P5, P6, P7 | RefreshPromptUseCase |
| US-1.4 select categories, at least one, today stable | BR-G2, G3, P4 | UpdatePromptCategoriesUseCase, GetTodayState |
| US-2.1 save, empty rejected, one per day, prompt frozen | BR-E1, E2, E3 | SaveTodayEntryUseCase |
| US-2.2 edit same day, locked after midnight, typing across midnight | BR-E3, E4, E5 | SaveTodayEntryUseCase, EntryEditPolicy |
| US-2.3 backfill offered, saved, window closes, not if exists, only yesterday | BR-E5, E8, E9 | BackfillYesterdayUseCase, EntryEditPolicy |
| US-2.4 past entry locked, today editable | BR-E5 | GetEntryUseCase |
| US-2.6 merge two same-day entries | BR-M1–M6 | DayEntryMerger, ReconcileSyncedEntriesUseCase |
| US-3.1 time zone change keeps the day | BR-T3 | CalendarDay, GetTodayState with a changed time zone |
| US-3.2 match text, match prompt, accents, none | BR-Q1–Q3 | EntrySearchMatcher, SearchEntriesUseCase |
| US-3.3 Markdown, plain text, nothing to export | BR-X1–X4 | JournalExporter, ExportJournalUseCase |
| US-4.1 streak cases + DST (New York, 2026-11-01) | BR-S1, S3, S5, T4 | StreakCalculator |
| US-4.2 at risk, backfill restores, today written yesterday missing | BR-S2, S4 | StreakCalculator, BackfillYesterday |
| US-4.3 reset at cutoff, restart, two missed days | BR-S5, S1 | StreakCalculator |
| US-4.4 best, new record, calculated from synced entries | BR-S6, S8 | StreakCalculator |
| US-6.1 enable, change time, denied, turn off | BR-R1, R2, R7 | ConfigureReminderUseCase (fake scheduler) |
| US-6.2 skip when done, fires when not done | BR-R2, R4 | SyncReminderWithTodayUseCase |
| US-7.1 onboarding saves, optional reminder | BR-G4 | CompleteOnboardingUseCase |
| Q4:B future-dated entry | BR-E6, E7, S-definition of D | StreakCalculator, GetTodayState, SaveTodayEntry |
