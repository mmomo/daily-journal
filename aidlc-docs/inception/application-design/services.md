# Services and Orchestration

In this design the **use cases are the service layer**. Each one coordinates ports (repositories, stores, scheduler, widget refresher) and pure policies for a single user action. Presentation calls use cases. Use cases never call Presentation.

Three cross-cutting **side effects** follow any change to entries or the day:
1. **Reminder sync**: make sure today's reminder is cancelled if today is done, and scheduled otherwise (`SyncReminderWithTodayUseCase`).
2. **Widget reload**: `WidgetRefresher.reloadAll()`.
3. **UI refresh**: Presentation bumps `AppEnvironment.refreshToken` so visible screens reload `TodayState`.

Side effects 1 and 2 happen inside the use cases that change data (save, backfill, refresh, reconcile, category or reminder changes), so every entry point (app, notification, future intents) gets them. Side effect 3 belongs to Presentation.

---

## S1: Load Today (`GetTodayStateUseCase`)

**Used by**: TodayView on appear and on `refreshToken` change, PromptStreakProvider (widget).

1. `day = CalendarDay(containing: time.now, in: time.calendar)`
2. `settings = SettingsStore.load()`
3. `entry = EntryRepository.entry(for: day)`
4. Prompt:
   - If an entry exists, use its frozen prompt (FR-1.6).
   - Else, read `PromptStateStore.state(for: day)`. If missing, pick one with `PromptSelector.dailyPrompt(...)` and save the new state (per device, Q4:B).
5. `entryDays = EntryRepository.entryDays()`, then `streak = StreakCalculator.summary(entryDays, at: now)`
6. Backfill offer: `EntryEditPolicy.editability(of: yesterday, hasEntry:)`. If `.backfillable`, build a `BackfillOffer` with yesterday's prompt (from saved state or deterministic selection).
7. Return `TodayState`.

The widget calls the same use case. Step 4 may write prompt state from the widget process. App and widget share the App Group `UserDefaults`, so both see the same choice.

## S2: Refresh Prompt (`RefreshPromptUseCase`)

1. Load today's state. Fail with `entryLocked` if today's entry exists, or `noRefreshesLeft` if `refreshesUsed >= 3`.
2. `PromptSelector.refreshedPrompt(...)`, increment `refreshesUsed`, append to `recentPromptIDs`, then `PromptStateStore.save`.
3. Side effect: widget reload.

## S3: Save Today's Entry (`SaveTodayEntryUseCase`)

**Used by**: the editor's explicit Save and debounced autosave.

1. Reject empty or whitespace-only text (`emptyText`).
2. `day = today`. Check `EntryEditPolicy.editability(of: day, hasEntry:)` is `.editable`, otherwise `entryLocked` (covers typing across midnight, US-2.2).
3. Insert a new `JournalEntry` with the current prompt id and text snapshot, or update the existing entry's text and `updatedAt`.
4. `EntryRepository.save`
5. Side effects: reminder sync (today is done, so cancel today's reminder), widget reload.

## S4: Backfill Yesterday (`BackfillYesterdayUseCase`)

1. Reject empty text.
2. `yesterday = today - 1`. Editability must be `.backfillable`, otherwise `backfillNotAvailable` (this also covers yesterday already having an entry: FR-2.5).
3. Create the entry for `yesterday` with yesterday's prompt.
4. Save, then side effect: widget reload (the streak changes).

## S5: Sync Reconciliation (`ReconcileSyncedEntriesUseCase`)

**Trigger**: `RemoteChangeObserver` in the app process when CloudKit imports changes. It also runs once on app launch and foreground.

1. Find days with more than one entry (`EntryRepository.entries(for:)` over recently changed days, or all days on launch).
2. For each such day: `DayEntryMerger.merge(entries)`, then save the merged entry and delete the others.
3. If anything changed: reminder sync (today may now be done on this device), widget reload, and return `true` so Presentation bumps `refreshToken`.

Two devices may merge the same conflict at once. The merge must be **deterministic and idempotent**, so both devices produce the same result and the final state settles. This is a requirement for Functional Design.

## S6: Reminder Lifecycle

| Use case | Flow |
|---|---|
| `ConfigureReminderUseCase` | If enabling and authorization is `.notDetermined`, request it. If denied, save settings with reminder off and throw `notificationsDenied`. Otherwise save settings, then reminder sync |
| `SyncReminderWithTodayUseCase` | If the reminder is off, `cancelAll`. Otherwise reschedule the next 7 days at the configured time, skipping today if it has an entry. Each notification body shows that day's prompt and carries `DeepLink.todayEditor` |
| `CompleteOnboardingUseCase` | Save categories. If a reminder was chosen, delegate to `ConfigureReminderUseCase`. Set `onboardingCompleted = true`, then widget reload |

Why schedule individual days instead of a repeating trigger: a repeating notification can't skip a day that's already done (FR-6.2). Scheduling a rolling 7-day window of one-off notifications lets "today" be cancelled on its own. The window is topped up on every launch, foreground, save and sync. The detailed rule is set in Functional Design.

## S7: Day Rollover

| Where | Mechanism |
|---|---|
| App | Observe `NSCalendarDayChanged` and `scenePhase == .active`, then run reconcile and reminder sync, and bump `refreshToken`. A timer fires at the next 12:00 cutoff while the app is open so the at-risk state updates |
| Widget | `PromptStreakProvider.getTimeline` returns entries for **now**, the **next 12:00 cutoff** (if a backfill or at-risk state applies) and the **next midnight**, with policy `.after(nextMidnight)` |

## S8: History, Search, Export

| Use case | Flow |
|---|---|
| `ListEntriesUseCase` | `EntryRepository.allEntries()` (newest first) |
| `SearchEntriesUseCase` | Empty query returns all entries. Otherwise `EntryRepository.search(query)`, using `EntrySearchMatcher` semantics: case- and accent-insensitive, matching entry text or prompt text |
| `GetEntryUseCase` | Load the entry and work out its editability with `EntryEditPolicy` |
| `ExportJournalUseCase` | Load all entries, throw `nothingToExport` if there are none, then `JournalExporter.export(..., format)` (oldest first) and return an `ExportDocument`. Presentation passes it to `ShareLink` |

## S9: Deep Link Routing (Presentation)

1. The widget sets `.widgetURL(DeepLink.todayEditor.url)`, and notifications carry the same URL in `userInfo`.
2. `JournalApp.onOpenURL`, or the notification delegate, decodes `DeepLink(url:)` and sets `AppEnvironment.pendingDeepLink`.
3. `RootView` shows TodayView with the editor focused, or the saved entry if today is done (US-5.2). If onboarding isn't complete, the link is ignored until it is.

---

## Orchestration Summary

| Use case | Ports used | Policies used | Side effects |
|---|---|---|---|
| GetTodayState | TimeSource, Entry, PromptLibrary, PromptState, Settings | PromptSelector, StreakCalculator, EntryEditPolicy | (may write prompt state) |
| RefreshPrompt | TimeSource, Entry, PromptLibrary, PromptState, Settings, Widget | PromptSelector | widget |
| SaveTodayEntry | TimeSource, Entry, PromptLibrary, PromptState, Settings, Widget | EntryEditPolicy | reminder, widget |
| BackfillYesterday | TimeSource, Entry, PromptLibrary, PromptState, Settings, Widget | EntryEditPolicy, PromptSelector | widget |
| GetEntry | TimeSource, Entry | EntryEditPolicy | n/a |
| ListEntries / SearchEntries | Entry | EntrySearchMatcher | n/a |
| ExportJournal | TimeSource, Entry | JournalExporter | n/a |
| GetStreak | TimeSource, Entry | StreakCalculator | n/a |
| GetSettings / UpdatePromptCategories | Settings, Widget | n/a | widget (categories) |
| ConfigureReminder / SyncReminderWithToday | TimeSource, Settings, Entry, Reminder, PromptLibrary, PromptState | PromptSelector | n/a |
| CompleteOnboarding | Settings, Reminder, Widget | n/a | reminder, widget |
| ReconcileSyncedEntries | TimeSource, Entry, Widget | DayEntryMerger | reminder, widget |
