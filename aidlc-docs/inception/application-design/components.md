# Components

**Architecture**: Clean Architecture with three layers. Dependencies point inward only: Presentation → Data → Domain, and Presentation → Domain.

| Layer | Module | Frameworks allowed |
|---|---|---|
| Domain | `JournalDomain` (target in the `JournalCore` Swift package) | Foundation only |
| Data | `JournalData` (target in `JournalCore`) | Foundation, SwiftData, CloudKit (via SwiftData), UserNotifications, WidgetKit (reload API only) |
| Presentation | `JournalApp` (iOS app target), `JournalWidget` (WidgetKit extension), both defined in Tuist | SwiftUI, WidgetKit, plus JournalDomain and JournalData |

Detailed business rules (prompt selection algorithm, streak math, edit and backfill windows, merge format) are left for **Functional Design (Core unit)**. This document defines boundaries and responsibilities only.

---

## 1. Domain Layer (`JournalDomain`)

### 1.1 Entities and Value Types

| Component | Purpose |
|---|---|
| `CalendarDay` | Year, month and day value that identifies a journal day independently of time zone (NFR-3.2). Comparable, Hashable, Codable |
| `JournalEntry` | One day's entry: id, day, text, the prompt it answered (id and text snapshot), created and updated timestamps |
| `Prompt` / `PromptCategory` | Library prompt (id, category, text) and the four categories: gratitude, reflection, goals, creativity |
| `DailyPromptState` | Per-device state for a day: chosen prompt id, refreshes used, recently shown prompt ids |
| `StreakSummary` | Current streak, best streak, status (active / at risk with restorable count / broken), whether today is done |
| `EntryEditability` | What can be done to a given day's entry right now: editable, can be backfilled until a time, or locked |
| `TodayState` | Everything the Today screen and widget need: day, prompt, today's entry, refreshes left, backfill offer, streak |
| `AppSettings` / `ReminderSettings` | Selected categories, reminder on/off and time, onboarding completed flag |
| `ExportFormat` / `ExportDocument` | Markdown or plain text; resulting file name and contents |
| `DeepLink` | Typed app routes shared by the widget, notifications and the app (e.g., today's editor, backfill editor) with a URL encode/decode |

### 1.2 Policies (pure business rules, no I/O)

| Component | Responsibility | Stories |
|---|---|---|
| `PromptSelector` | Picks the deterministic daily prompt and refresh candidates from the selected categories, avoiding recent repeats | US-1.1 to US-1.4 |
| `EntryEditPolicy` | Decides editability for a day at a given instant (today until midnight, yesterday backfill until 12:00 if missing, otherwise locked) | US-2.2 to US-2.4 |
| `StreakCalculator` | Computes current and best streak and at-risk status from the set of days that have entries | US-4.1 to US-4.4 |
| `DayEntryMerger` | Combines two or more entries for the same day into one without losing text | US-2.6 |
| `JournalExporter` | Turns entries into Markdown or plain text | US-3.3 |
| `EntrySearchMatcher` | Case- and accent-insensitive matching on entry and prompt text | US-3.2 |

### 1.3 Ports (protocols implemented in Data)

| Port | Responsibility |
|---|---|
| `TimeSource` | Supplies the current instant, calendar and time zone. Injectable so tests use a fixed clock (NFR-4.2) |
| `EntryRepository` | Load, save, list, search and delete-for-merge of entries. Hides SwiftData |
| `PromptLibrary` | Read-only access to all bundled prompts |
| `PromptStateStore` | Per-device daily prompt state (Q4:B) |
| `SettingsStore` | Read and write `AppSettings` |
| `ReminderScheduler` | Request notification permission, schedule, cancel and query pending reminders |
| `WidgetRefresher` | Ask the system to reload widget timelines |

### 1.4 Use Cases (one per user action, FQ2:A)

| Use case | Triggered by | Stories |
|---|---|---|
| `GetTodayStateUseCase` | Today screen appears, widget timeline, day rollover | US-1.1, US-2.5, US-4.1, US-5.1 |
| `RefreshPromptUseCase` | Refresh button | US-1.3 |
| `SaveTodayEntryUseCase` | Save or autosave in today's editor | US-2.1, US-2.2 |
| `BackfillYesterdayUseCase` | Save in the backfill editor | US-2.3 |
| `GetEntryUseCase` | Opening an entry from History | US-2.4 |
| `ListEntriesUseCase` | History screen | US-3.1 |
| `SearchEntriesUseCase` | History search field | US-3.2 |
| `ExportJournalUseCase` | Export action | US-3.3 |
| `GetStreakUseCase` | Streak display (also used inside GetTodayState) | US-4.1 to US-4.4 |
| `GetSettingsUseCase` | Settings and onboarding screens | US-7.2 |
| `UpdatePromptCategoriesUseCase` | Category picker | US-1.4 |
| `ConfigureReminderUseCase` | Reminder toggle or time change | US-6.1 |
| `SyncReminderWithTodayUseCase` | After save, sync, app foreground | US-6.2 |
| `CompleteOnboardingUseCase` | Finishing onboarding | US-7.1 |
| `ReconcileSyncedEntriesUseCase` | Remote iCloud changes arrive | US-2.6, US-4.1 |

---

## 2. Data Layer (`JournalData`)

| Component | Implements | Responsibility |
|---|---|---|
| `EntryRecord` | (SwiftData `@Model`) | Storage model for entries. CloudKit-compatible: every attribute optional or defaulted, no unique constraints |
| `PersistenceController` | n/a | Builds the `ModelContainer` in the App Group container. App: CloudKit private database. Widget: same store file, CloudKit off |
| `SwiftDataEntryRepository` | `EntryRepository` | Maps `EntryRecord` to and from `JournalEntry` and runs queries on a background `ModelActor` |
| `BundledPromptLibrary` | `PromptLibrary` | Loads and validates `prompts.json` from the package bundle once |
| `AppGroupPromptStateStore` | `PromptStateStore` | Stores per-device prompt state in App Group `UserDefaults` |
| `AppGroupSettingsStore` | `SettingsStore` | Stores settings in App Group `UserDefaults`, so the widget can read categories |
| `UserNotificationReminderScheduler` | `ReminderScheduler` | Wraps `UNUserNotificationCenter`; sets the notification's deep link and prompt text |
| `WidgetCenterRefresher` | `WidgetRefresher` | Calls `WidgetCenter.shared.reloadAllTimelines()` |
| `SystemTimeSource` | `TimeSource` | Uses `Date.now`, `Calendar.current` and `TimeZone.current` |
| `RemoteChangeObserver` | n/a | Listens for persistent-store remote-change notifications in the app process and triggers `ReconcileSyncedEntriesUseCase` |
| `JournalEnvironmentFactory` | n/a | Composition root helper: wires ports to implementations and builds the use cases for the `.app` or `.widget` context |

---

## 3. Presentation Layer

### 3.1 `JournalApp` (iOS app target)

| Component | Responsibility | Stories |
|---|---|---|
| `JournalApp` (`@main`) | Builds `AppEnvironment` through `JournalEnvironmentFactory`, injects it with `.environment`, handles `onOpenURL` deep links and scene-phase changes | All |
| `AppEnvironment` | `@Observable` container holding the use cases and an app-wide refresh signal (day changed, data synced) | All |
| `RootView` | Shows onboarding or the Today screen; routes deep links to the editor | US-7.1, US-5.2, US-6.3 |
| `OnboardingView` | Category selection, optional reminder setup | US-7.1 |
| `TodayView` | Prompt, refresh control, streak, entry editor or saved entry, backfill offer; toolbar links to History and Settings | US-1.x, US-2.x, US-4.x |
| `EntryEditorView` | Text editor with autosave, focused on appear; today mode and backfill mode | US-2.1 to US-2.3, US-2.5 |
| `StreakView` | Current and best streak, at-risk message | US-4.1 to US-4.4 |
| `HistoryView` / `EntryDetailView` | Reverse-chronological list with search; read-only or editable detail | US-3.1, US-3.2, US-2.4 |
| `SettingsView` | Categories, reminder, export | US-7.2, US-1.4, US-6.1, US-3.3 |
| `ExportView` | Chooses the format and presents `ShareLink` | US-3.3 |

Per FQ1:B there are no view models. Views keep only UI state (`@State`) and call use cases from `AppEnvironment`.

### 3.2 `JournalWidget` (WidgetKit extension)

| Component | Responsibility | Stories |
|---|---|---|
| `JournalWidgetBundle` | Declares the widget | US-5.1 |
| `PromptStreakWidget` | Small-family static configuration | US-5.1 |
| `PromptStreakProvider` | `TimelineProvider`. Builds its use cases through `JournalEnvironmentFactory(.widget)`, calls `GetTodayStateUseCase`, and emits entries for now, the next 12:00 cutoff and the next midnight | US-5.1, US-5.3 |
| `PromptStreakWidgetView` | Prompt text (truncated), streak badge with done and at-risk states, placeholder before onboarding, `widgetURL` deep link | US-5.1, US-5.2 |

---

## 4. Story Coverage Check

Every story US-1.1 to US-7.2 maps to at least one use case and one presentation component above. Technical-only requirements (NFR-1 platform, Tuist project, entitlements) are handled in Units Generation and Code Generation.
