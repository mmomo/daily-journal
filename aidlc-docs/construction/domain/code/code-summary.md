# Code Summary: Unit 1 Domain (`JournalDomain`)

**Location**: `/Users/mmomo/Code/AIDLC/demo/JournalCore/` (Swift package)
**Toolchain**: Swift 6.2.3, `swift-tools-version: 6.0`, Swift 6 language mode, platforms iOS 17 / macOS 14
**Imports**: Foundation only (tests: Swift Testing)

## File Inventory

| Path (under `JournalCore/`) | Purpose |
|---|---|
| `Package.swift` | Package `JournalCore`, product and target `JournalDomain`, test target |
| `README.md` | Package overview, how to run the tests |
| `Sources/JournalDomain/Time/CalendarDay.swift` | Civil date value; dayNumber, key, adding, start and noon in a time zone |
| `Sources/JournalDomain/Time/DayMath.swift` | Gregorian calendar per time zone; DST-gap-safe local time resolution |
| `Sources/JournalDomain/Time/StableHash.swift` | FNV-1a 64, gcd |
| `Sources/JournalDomain/Entities/*.swift` (11 files) | Prompt/PromptCategory, JournalEntry, DailyPromptState, EntryEditability/BackfillOffer, StreakStatus/StreakSummary, TodayState, AppSettings/ReminderSettings, ScheduledReminder/ReminderAuthorization, ExportFormat/ExportDocument, DeepLink, JournalError |
| `Sources/JournalDomain/Ports/Ports.swift` | TimeSource, EntryRepository, PromptLibrary, PromptStateStore, SettingsStore, ReminderScheduler, WidgetRefresher |
| `Sources/JournalDomain/Policies/*.swift` (7 files) | PromptSelector, EntryEditPolicy, StreakCalculator, DayEntryMerger, EntrySearchMatcher, JournalExporter, ReminderPlanner |
| `Sources/JournalDomain/UseCases/Support.swift` | `withStorage` error mapping, PromptResolver, prompt snapshot helper |
| `Sources/JournalDomain/UseCases/TodayUseCases.swift` | GetTodayState, RefreshPrompt |
| `Sources/JournalDomain/UseCases/EntryUseCases.swift` | SaveTodayEntry, BackfillYesterday, GetEntry, ListEntries, SearchEntries, ExportJournal, GetStreak, ReconcileSyncedEntries |
| `Sources/JournalDomain/UseCases/SettingsUseCases.swift` | GetSettings, UpdatePromptCategories, SyncReminderWithToday, ConfigureReminder, CompleteOnboarding |
| `Sources/JournalDomain/UseCases/JournalUseCases.swift` | Wires all 15 use cases from the 7 ports |
| `Tests/JournalDomainTests/Support/*` | Fakes (fixed clock, in-memory stores, fake scheduler, widget spy), date helpers, `TestHarness` |
| `Tests/JournalDomainTests/Policies/*` | CalendarDay, PromptSelector, EntryEditPolicy, StreakCalculator, merger, search, exporter, reminder planner, DeepLink |
| `Tests/JournalDomainTests/UseCases/*` | All 15 use cases, using the acceptance scenarios |
| `/.gitignore` (workspace root) | Ignores SwiftPM, Tuist and Xcode build output |

Size: 27 production files (about 1,370 lines), 10 test files (about 1,160 lines).

## Public API Overview

- **Entry point for other units**: `JournalUseCases(time:entries:prompts:promptState:settings:reminders:widgets:)`. It exposes `getTodayState`, `refreshPrompt`, `saveTodayEntry`, `backfillYesterday`, `getEntry`, `listEntries`, `searchEntries`, `exportJournal`, `getStreak`, `getSettings`, `updatePromptCategories`, `configureReminder`, `syncReminderWithToday`, `completeOnboarding`, `reconcileSyncedEntries`.
- **Ports to implement in Unit 2 (Data)**: see `Ports.swift`. `EntryRepository` must tolerate duplicate days until reconciled. `PromptStateStore.save(_:keepingFrom:)` prunes older states.
- **Errors**: every use case throws `JournalError`. Unexpected repository errors are wrapped as `.storageFailure(message)`.

## Refinements vs. Design Documents

| Change | Reason |
|---|---|
| `SaveTodayEntryUseCase.execute(text:day:)` and `BackfillYesterdayUseCase.execute(text:day:)` take the editor's day | Without it, an autosave just after midnight would silently write into the *new* day. Now it's rejected with `entryLocked` (US-2.2) |
| `EntryRepository.entries(from:through:)` added | Efficient "answered in the previous 30 days" lookup for prompt selection (BR-P3) |
| `PromptStateStore.save(_:keepingFrom:)` | Makes the "keep only today and yesterday" pruning explicit |
| `GetEntryUseCase` returns `EntryDetail` (entry + editability) | Named type instead of a tuple |
| `ExportDocument.format` instead of a UT type string | Presentation derives the UT type from `ExportFormat.utTypeIdentifier` |

## Story Checklist (primary in this unit)

All 14 are implemented and covered by tests: US-1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 2.4, 3.3, 4.1, 4.2, 4.3, 4.4, 6.2.
Logic used by other units' stories: merge and reconcile (US-2.6), search (US-3.2), reminder configuration (US-6.1), DeepLink (US-5.2, US-6.3), onboarding (US-7.1), TodayState (US-5.1).

## Verification (Step 11)

| Command (in `JournalCore/`) | Result |
|---|---|
| `swift build --build-tests` (clean `.build`) | Succeeded, 0 warnings, 0 errors |
| `swift test` | **101 tests in 16 suites passed** (several are parameterized, e.g. the 30-day no-repeat check runs for all 15 category combinations × 400 days) |

## Known Limitations

- `PromptResolver` rebuilds a `PromptSelector` (sorting about 370 prompts) on each call. This is negligible at this size, and could be cached in Unit 2 if profiling shows a need.
- After a category change, the new daily sequence may repeat a prompt that was *shown but not answered* within the last 30 days. Answered prompts are still excluded. This was accepted in functional design §1.2.
- `SyncReminderWithTodayUseCase` is best effort. If the repository fails, it schedules as if today were not done.
