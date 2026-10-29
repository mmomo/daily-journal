# Code Generation Plan: Unit 3 App (`JournalApp`)

**This plan is the single source of truth for generating the App unit's code.** Each checkbox is marked [x] as soon as its step is done.

## Per-Unit Stage Assessment

| Stage | Decision | Rationale |
|---|---|---|
| Functional Design | **SKIP** | All business rules live in the approved Domain use cases. Screen structure and responsibilities are in application design (components.md §3.1, services.md S7/S9). The UI specifics below (screens, states, interactions) are enough for a presentation-only unit |
| NFR / NFR Design / Infrastructure | SKIP | Per execution plan |

## Unit Context

| Item | Value |
|---|---|
| Workspace root | `/Users/mmomo/Code/AIDLC/demo` |
| Code location | `Project.swift`, `Tuist.swift`, `Tuist/ProjectDescriptionHelpers/`, `JournalApp/` |
| Tooling | Tuist **4.148.1** (installed via mise). Run as `~/.local/share/mise/installs/tuist/4.148.1/tuist` with `XDG_*` dirs pointed at a writable location because of this session's sandbox. Xcode 26.2 |
| Depends on | `JournalDomain`, `JournalData` (local package `JournalCore`) |
| Target | iOS application, iPhone, iOS 17.0+, bundle id `com.mmomo.dailyjournal`, URL scheme `dailyjournal` |
| Architecture | Plain SwiftUI with no view models (FQ1:B). Views call `JournalUseCases` from an `@Observable AppEnvironment` passed through `.environment` |

### Signing and Entitlements Approach (Q4:A)
`AppIdentifiers.developmentTeam` is empty by default. While it's empty, the project builds **without entitlements** (no App Group, no iCloud) and `JournalCloudKitEnabled = NO`, so simulator builds work unsigned. Setting the Team ID in that one file turns on `JournalApp.entitlements` (App Group, iCloud/CloudKit, push for CloudKit) and `JournalCloudKitEnabled = YES`. The Build and Test instructions will document this.

## Stories (primary in this unit)
- [x] US-2.5 Open editor fast (focused editor, keyboard up on launch, widget tap or notification)
- [x] US-3.1 Browse past entries
- [x] US-6.3 Tap reminder to write (notification delegate → deep link)
- [x] US-7.1 First-launch onboarding
- [x] US-7.2 Settings screen

Presentation for: US-1.1 to 1.4 (prompt card, refresh, categories), US-2.1 to 2.4 (editor, autosave, backfill sheet, read-only detail), US-3.2 (`.searchable`), US-3.3 (export via ShareLink), US-4.1 to 4.4 (streak view), US-6.1 (reminder settings, denied state), US-2.6 (remote-change wiring).

## UI Specification (replaces a separate frontend-components.md)

| Screen / component | Content and behavior | Use cases |
|---|---|---|
| `RootView` | Loading → `OnboardingView` if not onboarded, otherwise `NavigationStack { TodayView }`. A startup error shows a message with a retry button | getSettings |
| `OnboardingView` | Step 1: category toggles (all on, ≥ 1 required). Step 2: "Daily reminder" toggle + time picker (default 20:00), "Not now". Finish → `completeOnboarding`. A permission denial still finishes and shows a short note | completeOnboarding |
| `TodayView` | Date title, `StreakView`, prompt card (category, text, **Refresh (n left)**, hidden once done), backfill banner "Write yesterday's entry · until 12:00" → sheet, `EntryEditorView` (today) or the saved entry. Toolbar: History, Settings. Reloads on `refreshToken` | getTodayState, refreshPrompt |
| `EntryEditorView` | `TextEditor`, auto-focused (keyboard up) when today isn't done. **Autosave** (0.8 s debounce) in today mode. Done button. Backfill mode: explicit Save then dismiss. `entryLocked` makes it read-only with "This entry is locked." | saveTodayEntry, backfillYesterday |
| `StreakView` | "🔥 Current N · Best M", done checkmark, at-risk caption "Write yesterday's entry by 12:00 to keep your N-day streak" | (TodayState.streak) |
| `HistoryView` | List newest first (date, prompt, two-line preview). `.searchable` (debounced 250 ms). Empty states for no entries and no matches | listEntries, searchEntries |
| `EntryDetailView` | Date, prompt, text. Today's entry is editable through `EntryEditorView`, others are read-only | getEntry |
| `SettingsView` | Prompt categories (can't deselect the last), daily reminder toggle + time (denied → "Notifications are off" + Open Settings), Export section | getSettings, updatePromptCategories, configureReminder |
| `ExportSection` | Prepares Markdown and plain-text files in a temp directory; `ShareLink` per format. Disabled with an explanation when there are no entries | exportJournal |

**Accessibility identifiers** (automation-friendly rule, `{screen}-{element-role}`): `today-prompt-text`, `today-refresh-button`, `today-backfill-button`, `editor-text-field`, `editor-done-button`, `today-history-button`, `today-settings-button`, `history-list`, `settings-category-toggle-<category>`, `settings-reminder-toggle`, `settings-reminder-time`, `settings-export-markdown`, `settings-export-text`, `onboarding-next-button`, `onboarding-finish-button`, `onboarding-reminder-toggle`, `streak-label`.

**App lifecycle** (services.md S5, S7, S9):
- **On launch**: build the environment (`.app`). If the store fails, show the startup error. Then reconcile, sync reminders, and start `RemoteChangeObserver`.
- **Becoming active, or on `NSCalendarDayChanged`**: reconcile, sync reminders, bump `refreshToken`.
- **While the app is open**: a timer bumps `refreshToken` at the next 12:00 or midnight boundary.
- **Opening a URL** (`onOpenURL`) or **tapping a notification** (`UNUserNotificationCenterDelegate`): sets `pendingDeepLink`. TodayView consumes it by focusing the editor or opening the backfill sheet.

## Template Steps Not Applicable
| Step | Reason |
|---|---|
| Business logic / API / Repository layers | Already in Units 1–2 |
| Frontend unit tests | Q15:A limits unit tests to core logic and FQ1:B means there are no view models. Verified instead by build plus a simulator smoke launch (Step 9) |
| Database migrations | n/a |

---

## Generation Steps

### Step 1: Tuist project
- [x] `Tuist.swift` (Tuist 4 configuration)
- [x] `Tuist/ProjectDescriptionHelpers/AppIdentifiers.swift`: all identifiers, `developmentTeam`, derived flags
- [x] `Project.swift`: local package `JournalCore`; target `JournalApp` (iOS app, iPhone, iOS 17). Info.plist extensions: launch screen, URL scheme, `Journal*` config keys, portrait/landscape. Sources and resources. Conditional entitlements and team settings
- [x] `JournalApp/JournalApp.entitlements` (applied only when a team is set)
- [x] Update `.gitignore` if needed (Tuist `Derived/` already covered)

### Step 2: Resources
- [x] `JournalApp/Resources/Assets.xcassets` (AccentColor, AppIcon placeholder set)

### Step 3: App shell (`JournalApp/Sources/App/`)
- [x] `JournalApp.swift` (`@main`, `UIApplicationDelegateAdaptor`, scene phase, `onOpenURL`)
- [x] `AppEnvironment.swift` (`@Observable @MainActor`: use cases, `refreshToken`, `pendingDeepLink`, startup error, lifecycle handlers, boundary timer, day-change listener, remote-change observer)
- [x] `AppDelegate.swift` (`UNUserNotificationCenterDelegate`: foreground presentation, tap → deep link)
- [x] `JournalError+Message.swift` (user-facing messages)

### Step 4: Shared components (`JournalApp/Sources/Components/`)
- [x] `StreakView.swift`, `PromptCard.swift`, `EntryEditorView.swift`, `DayFormatting.swift`

### Step 5: Screens (`JournalApp/Sources/Screens/`)
- [x] `RootView.swift`, `OnboardingView.swift`, `TodayView.swift`
- [x] `HistoryView.swift`, `EntryDetailView.swift`
- [x] `SettingsView.swift`, `ExportSection.swift`

### Step 6: Previews
- [x] `#Preview` blocks using `JournalEnvironmentFactory.makeInMemory`, plus `AppEnvironment.preview`

### Step 7: Generate and build
- [x] `tuist generate --no-open` (or `tuist install` first if required); fix manifest errors
- [x] `xcodebuild -workspace … -scheme JournalApp -destination 'generic/platform=iOS Simulator' build`; fix compile errors and warnings

### Step 8: Documentation
- [x] `aidlc-docs/construction/app/code/code-summary.md` (files, screens → stories, lifecycle, identifiers, how to enable signing)
- [x] Root `README.md` (project overview, prerequisites, generate/build/test commands, how to set the Team ID)

### Step 9: Simulator smoke check
- [x] Build for an iOS Simulator (iPhone 15 Pro), install, launch, capture a screenshot of the first screen (onboarding) into the scratchpad, and confirm no crash at launch

## Estimated Scope
- About 16 Swift files, 3 Tuist manifest/helper files, 1 entitlements file, 1 asset catalog
