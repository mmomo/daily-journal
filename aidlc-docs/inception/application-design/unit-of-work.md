# Units of Work

**Deployment model**: one iOS app bundle (the app plus an embedded WidgetKit extension). Nothing is deployed separately. Each **unit of work** is one module, designed, built and tested in order before the next starts (Q1:B).

| # | Unit | Module | Kind | Built on |
|---|---|---|---|---|
| 1 | **Domain** | `JournalDomain` | SwiftPM library target in `JournalCore` | none |
| 2 | **Data** | `JournalData` | SwiftPM library target in `JournalCore` | Domain |
| 3 | **App** | `JournalApp` | iOS application target (Tuist) | Domain, Data |
| 4 | **Widget** | `JournalWidget` | WidgetKit app extension target (Tuist), embedded in App | Domain, Data (+ App for embedding) |

---

## Unit 1: Domain (`JournalDomain`)

**Purpose**: All business rules and use cases, in pure Swift with only Foundation, fully unit-testable with a fixed `TimeSource`.

**Responsibilities**
- Value types: CalendarDay, JournalEntry, Prompt, PromptCategory, DailyPromptState, StreakSummary/StreakStatus, EntryEditability, BackfillOffer, TodayState, AppSettings, ReminderSettings, ReminderAuthorization, ExportFormat, ExportDocument, DeepLink, JournalError
- Policies: PromptSelector, EntryEditPolicy, StreakCalculator, DayEntryMerger, JournalExporter, EntrySearchMatcher
- Ports (protocols): TimeSource, EntryRepository, PromptLibrary, PromptStateStore, SettingsStore, ReminderScheduler, WidgetRefresher
- The 15 use cases
- In-memory test doubles for every port, in the test target. These are also reusable as SwiftUI preview fakes if exposed through a small `JournalDomainTesting` target, decided in Code Generation

**Design stages**: **Functional Design: EXECUTE.** It covers every business rule listed in application-design.md §6, *including* the storage schema contracts that Data must implement (`EntryRecord` fields, `prompts.json` schema). NFR, NFR Design and Infrastructure: SKIP (per execution plan).

**Definition of done**
- `swift test` passes for `JournalDomainTests` on macOS. There are no iOS-only APIs in Domain, so it can be tested on the host
- Every Given/When/Then scenario in E1, E2 and E4 (and the logic parts of E3 and E6) has a matching test
- Zero imports other than Foundation

---

## Unit 2: Data (`JournalData`)

**Purpose**: Implement the Domain ports with Apple frameworks and provide the composition root.

**Responsibilities**
- `EntryRecord` SwiftData model (CloudKit-compatible) and mapping to and from `JournalEntry`
- `PersistenceController` (App Group store URL; CloudKit private DB for `.app`, none for `.widget`)
- `SwiftDataEntryRepository` (`@ModelActor`)
- `BundledPromptLibrary` + **`prompts.json` with 365+ original prompts, about 92 per category** (Q5:A)
- `AppGroupPromptStateStore`, `AppGroupSettingsStore`
- `UserNotificationReminderScheduler`, `WidgetCenterRefresher`, `SystemTimeSource`
- `RemoteChangeObserver`
- `JournalEnvironmentFactory` + `JournalUseCases`
- `AppConfiguration` constants (App Group id, iCloud container id), read from the Info.plist values set by Tuist so identifiers live in one place

**Design stages**: Functional Design is expected to be **SKIPPED** because Domain FD defines the schemas. This will be confirmed at the start of the unit. NFR, NFR Design and Infrastructure: SKIP.

**Definition of done**
- `swift test` passes for `JournalDataTests`: repository round-trip and queries on an in-memory `ModelContainer`, prompt JSON loads and validates (count, unique ids, all categories ≥ 90), stores round-trip through a throwaway `UserDefaults` suite
- `prompts.json` reviewed for originality, tone and category fit

---

## Unit 3: App (`JournalApp`)

**Purpose**: The SwiftUI app: Presentation layer, entitlements and app lifecycle.

**Responsibilities**
- `JournalApp` (`@main`), `AppEnvironment`, `RootView`, `OnboardingView`, `TodayView`, `EntryEditorView` (autosave, focus), `StreakView`, `HistoryView` (+ `.searchable`), `EntryDetailView`, `SettingsView`, `ExportView` (`ShareLink`)
- Deep link handling (`onOpenURL`, notification delegate), day-rollover and 12:00 timer, scene-phase reconcile
- Accessibility identifiers on interactive elements, following the `{screen}-{element-role}` convention (e.g., `today-refresh-button`, `editor-text-field`). This is the SwiftUI equivalent of the `data-testid` rule
- Tuist project setup: `Project.swift`, `Tuist/Config` or `Tuist.swift`, entitlements (App Group, iCloud/CloudKit, push for CloudKit, background remote notifications), Info.plist URL scheme, local package dependency on `JournalCore`

**Design stages**: Functional Design is expected to be **SKIPPED** (presentation over Domain use cases). Confirmed at the start of the unit. Others: SKIP.

**Definition of done**
- `tuist generate` then `xcodebuild build` succeeds for an iOS 17+ simulator
- Manual checks of the app stories (listed in build-and-test instructions)

---

## Unit 4: Widget (`JournalWidget`)

**Purpose**: The small Home Screen widget.

**Responsibilities**
- `JournalWidgetBundle`, `PromptStreakWidget` (`.systemSmall`), `PromptStreakProvider` (timeline: now, next 12:00 cutoff, next midnight), `PromptStreakWidgetView` (prompt, streak badge with done and at-risk states, placeholder before onboarding, `widgetURL`)
- Tuist extension target embedded in the App, with the App Group entitlement

**Design stages**: Functional Design is expected to be **SKIPPED**. Others: SKIP.

**Definition of done**
- Widget target builds and is embedded. The widget renders in the simulator and in Xcode previews for each state (not done, done, at risk, before onboarding)
- Tapping it opens the editor (manual check)

---

## Code Organization Strategy (Greenfield, Q2:A)

Workspace root: `/Users/mmomo/Code/AIDLC/demo`. Application code never goes in `aidlc-docs/`.

```
demo/
+-- Project.swift                   Tuist project: JournalApp + JournalWidget targets
+-- Tuist.swift                     Tuist configuration (or Tuist/Config.swift, per installed version)
+-- Tuist/
|   +-- ProjectDescriptionHelpers/
|       +-- AppIdentifiers.swift    single source of all identifiers (Q3:B)
+-- JournalCore/                    local Swift package
|   +-- Package.swift               products: JournalDomain, JournalData
|   +-- Sources/
|   |   +-- JournalDomain/          Unit 1
|   |   |   +-- Entities/
|   |   |   +-- Policies/
|   |   |   +-- Ports/
|   |   |   +-- UseCases/
|   |   +-- JournalData/            Unit 2
|   |       +-- Persistence/
|   |       +-- Stores/
|   |       +-- System/
|   |       +-- Composition/
|   |       +-- Resources/prompts.json
|   +-- Tests/
|       +-- JournalDomainTests/
|       +-- JournalDataTests/
+-- JournalApp/                     Unit 3
|   +-- Sources/
|   |   +-- App/
|   |   +-- Screens/
|   |   +-- Components/
|   +-- Resources/                  asset catalog, Info.plist additions
|   +-- JournalApp.entitlements
+-- JournalWidget/                  Unit 4
|   +-- Sources/
|   +-- Resources/
|   +-- JournalWidget.entitlements
+-- .gitignore                      ignores *.xcodeproj, *.xcworkspace, Derived/, .build/
+-- README.md
```

Text summary: Tuist manifests at the root. One Swift package, `JournalCore/`, holds the Domain and Data targets and their tests. `JournalApp/` and `JournalWidget/` hold the presentation targets and their entitlements. The generated Xcode project is not committed.

### Identifiers (Q3:B, single source in `AppIdentifiers.swift`)

| Item | Value |
|---|---|
| App bundle ID | `com.mmomo.dailyjournal` |
| Widget bundle ID | `com.mmomo.dailyjournal.widget` |
| App Group | `group.com.mmomo.dailyjournal` |
| iCloud container | `iCloud.com.mmomo.dailyjournal` |
| URL scheme | `dailyjournal` |
| Deployment target | iOS 17.0, iPhone |
| Signing | No Team ID (simulator only, Q4:A) |

### Toolchain

- Xcode 26.2 (installed), Swift Package Manager, Tuist (installed by the user before the App unit, FQ4:B). The Domain and Data units need only SwiftPM, so Tuist isn't required until Unit 3.
- Tests: Swift Testing (`import Testing`), with XCTest only if needed.
