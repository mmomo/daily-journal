# Code Generation Plan: Unit 1 Domain (`JournalDomain`)

**This plan is the single source of truth for generating the Domain unit's code.** Steps run in order, and each checkbox is marked [x] as soon as its step is done.

## Unit Context

| Item | Value |
|---|---|
| Workspace root | `/Users/mmomo/Code/AIDLC/demo` |
| Project type | Greenfield, multi-unit, Tuist/SwiftPM layout (unit-of-work.md, Q2:A) |
| Code location | `JournalCore/` (Swift package). This unit creates the package with the **`JournalDomain`** target only. Unit 2 adds `JournalData` |
| Toolchain | Swift 6.2.3 / Xcode 26.2. `swift-tools-version: 6.0`, Swift 6 language mode (strict concurrency) |
| Platforms | iOS 17, macOS 14 (macOS only so `swift test` runs on the host) |
| Allowed imports | Foundation only (tests: Swift Testing `import Testing`) |
| Depends on | None |
| Consumed by | Data (ports, entities, storage contracts), App and Widget (use cases, TodayState, DeepLink, JournalError) |
| Database entities owned | None directly. Storage contracts (EntryRecord, prompts.json, App Group keys) are specified in functional design §9 and built in Unit 2 |
| Design inputs | `construction/domain/functional-design/*` (approved), `inception/application-design/*` with the refinements in business-logic-model §9.4 |

### Steps from the standard template that don't apply

| Template step | Status | Reason |
|---|---|---|
| API Layer (generation/tests/summary) | N/A | No network API. The "API" of this unit is the use cases, generated in Step 6 |
| Repository Layer | N/A here | Domain defines repository **ports** only (Step 4). Implementations are Unit 2 |
| Frontend Components | N/A | No UI in Domain |
| Database Migration Scripts | N/A | No database in Domain. SwiftData schema is Unit 2 (lightweight, no migrations at v1) |
| Deployment Artifacts | N/A | A library target ships inside the app bundle. Packaging is the App unit's Tuist project |

## Stories Implemented (primary in this unit)

- [x] US-1.1 See today's prompt
- [x] US-1.2 Same prompt everywhere
- [x] US-1.3 Refresh prompt (limited)
- [x] US-1.4 Choose categories
- [x] US-2.1 Write and save
- [x] US-2.2 Edit until midnight
- [x] US-2.3 Backfill yesterday
- [x] US-2.4 Read-only past entries
- [x] US-3.3 Export
- [x] US-4.1 Current streak
- [x] US-4.2 At risk during grace
- [x] US-4.3 Reset after grace
- [x] US-4.4 Longest streak
- [x] US-6.2 Skip reminder when done

Contributing logic delivered here for other units' stories: merge and reconcile (US-2.6), search matcher (US-3.2), reminder configuration (US-6.1), DeepLink (US-5.2, US-6.3), onboarding use case (US-7.1), TodayState (US-5.1).

---

## Generation Steps

### Step 1: Project structure setup
- [x] Create `JournalCore/Package.swift`: library product `JournalDomain`, target `JournalDomain`, test target `JournalDomainTests`, platforms iOS 17 / macOS 14
- [x] Create folders `JournalCore/Sources/JournalDomain/{Time,Entities,Policies,Ports,UseCases}` and `JournalCore/Tests/JournalDomainTests/{Support,Policies,UseCases}`
- [x] Create root `.gitignore` (`.build/`, `*.xcodeproj`, `*.xcworkspace`, `Derived/`, `.swiftpm/`, `xcuserdata/`, `.DS_Store`)

### Step 2: Time foundation (`Time/`)
- [x] `CalendarDay.swift`: Y/M/D, `dayNumber` (civil-date integer math), `key`, `init?(key:)`, `adding(days:)`, `init(containing:timeZone:)`, `start(in:)`, `noon(in:)`, Comparable (BR-T2–T4)
- [x] `DayMath.swift`: Gregorian calendar factory for a time zone, plus the DST-gap-safe "local time on day" resolver (BR-R3)
- [x] `StableHash.swift`: FNV-1a 64 and `gcd` helper (business-logic-model §1.1)

### Step 3: Entities and errors (`Entities/`)
- [x] `Prompt.swift` (Prompt, PromptCategory), `JournalEntry.swift`, `DailyPromptState.swift`
- [x] `EntryEditability.swift`, `BackfillOffer.swift`, `Streak.swift` (StreakStatus, StreakSummary), `TodayState.swift`
- [x] `Settings.swift` (AppSettings, ReminderSettings, defaults BR-G1), `Reminders.swift` (ScheduledReminder, ReminderAuthorization)
- [x] `Export.swift` (ExportFormat, ExportDocument), `DeepLink.swift`, `JournalError.swift`

### Step 4: Ports (`Ports/`)
- [x] `TimeSource`, `EntryRepository` (incl. `duplicateDays`, `entries(after:)`), `PromptLibrary`, `PromptStateStore`, `SettingsStore`, `ReminderScheduler` (`replacePending`), `WidgetRefresher` (refined signatures per business-logic-model §9.4)

### Step 5: Policies (`Policies/`)
- [x] `PromptSelector.swift`: pool, full-period stride daily pick, answered-30 skip, refresh sequence, BR-P9 fallbacks
- [x] `EntryEditPolicy.swift`: BR-E5, E6
- [x] `StreakCalculator.swift`: BR-S1–S8 incl. the Q4:B future-day rule
- [x] `DayEntryMerger.swift`: BR-M1–M6
- [x] `EntrySearchMatcher.swift`: BR-Q1–Q2
- [x] `JournalExporter.swift`: BR-X1–X4 layouts
- [x] `ReminderPlanner.swift`: pure 7-day window builder used by SyncReminderWithToday (BR-R2–R5)

### Step 6: Use cases (`UseCases/`)
- [x] Internal shared helper `PromptResolver` (business-logic-model §1.4)
- [x] `GetTodayStateUseCase`, `RefreshPromptUseCase`, `SaveTodayEntryUseCase`, `BackfillYesterdayUseCase`
- [x] `GetEntryUseCase`, `ListEntriesUseCase`, `SearchEntriesUseCase`, `ExportJournalUseCase`, `GetStreakUseCase`
- [x] `GetSettingsUseCase`, `UpdatePromptCategoriesUseCase`, `ConfigureReminderUseCase`, `SyncReminderWithTodayUseCase`, `CompleteOnboardingUseCase`
- [x] `ReconcileSyncedEntriesUseCase`
- [x] `JournalUseCases.swift`: a bag of all 15 plus a `make(...)` builder taking the ports (used by Data's factory)

### Step 7: Test support (`Tests/JournalDomainTests/Support/`)
- [x] `FixedTimeSource` (settable now and time zone), `InMemoryEntryRepository` (allows duplicates for merge tests), `InMemoryPromptLibrary` (generated fixture: 92 prompts per category), `InMemoryPromptStateStore`, `InMemorySettingsStore`, `FakeReminderScheduler`, `SpyWidgetRefresher`
- [x] Date helpers: `date("2026-10-08 09:00", tz: "America/Mexico_City")`

### Step 8: Policy unit tests (`Tests/JournalDomainTests/Policies/`)
- [x] `CalendarDayTests`: key round-trip, dayNumber continuity across years and leap days, time zone conversion, DST start/noon in America/New_York
- [x] `PromptSelectorTests`: determinism, no repeat within 30 days for every non-empty category combination (15 combinations × 400 days), answered-30 skip, refresh never repeats shown prompts, pool-of-1 fallback
- [x] `EntryEditPolicyTests`: today, midnight lock, backfill before and after noon, existing yesterday, two days ago, future day
- [x] `StreakCalculatorTests`: every BR-S example, US-4.1 to US-4.4 scenarios, DST 2026-11-01 New York, future-dated day (Q4:B), best streak
- [x] `DayEntryMergerTests`: order, divider, differing prompt quote, duplicate skip, determinism (shuffled input gives the same output), idempotence
- [x] `EntrySearchMatcherTests`, `JournalExporterTests` (exact expected strings), `ReminderPlannerTests` (window, skip today when done, past fire time, streak body), `DeepLinkTests`

### Step 9: Use case unit tests (`Tests/JournalDomainTests/UseCases/`)
- [x] One test suite per use case covering the scenarios in the business-rules.md "Acceptance Scenario → Test Mapping" table, including error cases, the widget reload spy, and reminder resync side effects

### Step 10: Business logic summary (documentation)
- [x] `aidlc-docs/construction/domain/code/code-summary.md`: file inventory, public API overview, refinements vs. design, story checklist, known limitations
- [x] `JournalCore/README.md` (short): what the package contains and how to run `swift test`

### Step 11: Verification
- [x] Run `swift build` and `swift test` in `JournalCore/`. Fix failures. Record the results in code-summary.md
  (Build & Test stage later produces the formal instructions. This is a smoke check that the generated code compiles and its tests pass.)

---

## Estimated Scope
- About 45 Swift source files (about 30 production, about 15 test)
- About 150+ test cases (Swift Testing, many parameterized)
- No external dependencies
