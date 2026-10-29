# Application Design Plan

**Stage**: INCEPTION - Application Design
**Inputs**: `requirements.md`, `stories.md`, `personas.md`, `execution-plan.md` (all approved)

## Capabilities Identified (from requirements and stories)

| Capability | Stories | Likely home |
|---|---|---|
| Prompt library and daily selection, refresh limit | US-1.1 to US-1.4 | Core |
| Entry rules (one per day, edit window, backfill, lock) | US-2.1 to US-2.4 | Core |
| Persistence, iCloud sync, same-day merge | US-2.6 | Core |
| Streak (current, at risk, reset, best) | US-4.1 to US-4.4 | Core |
| Search and export | US-3.2, US-3.3 | Core (logic) + App (UI and share sheet) |
| Reminder scheduling | US-6.1 to US-6.3 | Core (scheduling logic) + App (permission, settings UI) |
| Today, History, Settings, onboarding UI | US-2.5, US-3.1, US-7.1, US-7.2 | App |
| Widget timeline and view | US-5.1 to US-5.3 | Widget |
| Deep links (widget and notification to editor) | US-5.2, US-6.3 | Core (URL definition) + App (routing) |

---

## Questions

Please fill in the letter after each `[Answer]:` tag. If no option fits, choose the last option (Other) and describe what you want.

## Question 1
Which UI architecture pattern should the app use?

A) MVVM: SwiftUI views backed by `@Observable` view models, which call Core services. Views stay thin, and view models can be unit-tested

B) "Plain SwiftUI": views use SwiftData `@Query` and call Core services directly, with no view-model layer. Less code, but more logic sits in views

C) The Composable Architecture (TCA), a third-party framework. Very testable, but a heavy dependency and steep learning curve for a small app

X) Other (please describe after [Answer]: tag below)

[Answer]: Clean Architecture

## Question 2
How should Core access the database?

A) Behind a repository protocol (e.g., `EntryRepository`) with a SwiftData implementation. Tests use an in-memory SwiftData store or a fake, and business rules never touch SwiftData types directly

B) Core services use SwiftData `ModelContext` directly. Tests use an in-memory `ModelContainer`

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 3
How should dependencies (clock, repository, services) be provided?

A) Constructor injection, plus one `AppEnvironment` container created at app or widget launch and passed down through SwiftUI `.environment`

B) A third-party DI library (e.g., Factory)

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 4
Where should the day's prompt state (chosen prompt, refreshes used) live?

A) Synced through iCloud with the entries, so a refresh on one device also changes the prompt on your other devices

B) Per device (App Group storage, not synced). Each device works out the same prompt for the date, but refreshes on one device don't affect another. Simpler, with no sync conflicts over prompt state

X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 5
How should the widget get its data?

A) The widget opens the same SwiftData store in the App Group container (read-only) and uses Core to work out the prompt and streak itself

B) The app writes a small "widget snapshot" (prompt text, streak, done/at-risk state, next refresh times) to the App Group, and the widget only reads it. The widget stays lightweight, but the snapshot can go stale if the app hasn't run

C) Hybrid: the widget works things out from the shared store (A) and uses the snapshot only as a fallback if the store can't be opened

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 6
How should the prompt library be stored?

A) A JSON file bundled in the Core package (id, category, text). Easy to edit and grow without touching code

B) Swift source (a static array in code). Checked at compile time, but awkward to edit with 365+ entries

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 7
What is the policy on third-party dependencies?

A) None. Apple frameworks only (SwiftUI, SwiftData, WidgetKit, UserNotifications, XCTest/Swift Testing)

B) Allowed when they save significant effort (please name any you want)

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 8
How should the Xcode project be created? (Code is generated in a terminal, so the project file has to come from a text definition or a tool.)

A) XcodeGen: a readable `project.yml` generates the `.xcodeproj` (requires `brew install xcodegen`). Core is a local Swift package

B) Tuist: Swift-based project definition (requires installing Tuist)

C) A hand-written `.xcodeproj`. No extra tools, but the project file is hard to read and review

D) Only the Core Swift package plus app and widget source files; you create the Xcode project yourself and add them

X) Other (please describe after [Answer]: tag below)

[Answer]: B

---

## Follow-up Questions

Your answers to Q2–Q8 are clear. Q1 needs more detail. A note on Q8 follows.

**Q1 "Clean Architecture"** describes how code is layered (Domain, Data, Presentation, with dependencies pointing inward). It doesn't say which UI pattern the Presentation layer uses, or how finely the business logic is split. Your answers to Q2 (repository protocol) and Q3 (constructor injection) fit it well.

## Follow-up Question 1
Which pattern should the Presentation layer (App and Widget UI) use?

A) MVVM: `@Observable` view models call use cases; views only render view-model state

B) Views call use cases directly, with no view models

X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Follow-up Question 2
How fine-grained should the Domain use cases be?

A) One use case per user action (e.g., `SaveTodayEntryUseCase`, `BackfillYesterdayUseCase`, `RefreshPromptUseCase`, `GetStreakUseCase`), each with a single `execute` method. About 15 small types, which is the most "by the book" option

B) A few domain services grouped by capability (e.g., `PromptService`, `EntryService`, `StreakService`, `ReminderService`, `ExportService`), each with several methods. Fewer types, still separated by layer

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Follow-up Question 3
How should the Clean Architecture layers map to code modules?

A) A single Core Swift package with separate targets per layer: `JournalDomain` (entities, use cases, repository protocols, no Apple storage frameworks), `JournalData` (SwiftData/CloudKit, App Group, notifications, prompt JSON). App and Widget hold the Presentation layer. The compiler enforces the layer rules

B) A single `JournalCore` target with Domain/Data folders. The layer rules are followed by convention only

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Follow-up Question 4 (Q8 Tuist, tooling)
Tuist isn't installed on this machine (`tuist` isn't on your PATH), but `mise` is, and it's Tuist's recommended installer. How should Tuist be set up?

A) I add a `.mise.toml` that pins a Tuist version in the repo, and run `mise install` during Code Generation (installs Tuist for this project only)

B) You install Tuist yourself before Code Generation (e.g., `mise use -g tuist` or Homebrew)

X) Other (please describe after [Answer]: tag below)

[Answer]: B

Note: Q7:A (Apple frameworks only) applies to code that ships in the app. Tuist is a build-time tool and doesn't ship, so the two answers are consistent.

---

## Approved Design Decisions

| # | Decision |
|---|---|
| Q1 + FQ1:B | **Clean Architecture**. Presentation is plain SwiftUI: views call use cases directly, with **no view models** |
| FQ2:A | **One use case per user action**, each with a single `execute` method |
| FQ3:A | One local Swift package `JournalCore` with layer targets: **JournalDomain** (pure Swift; entities, use cases, policies, ports) and **JournalData** (SwiftData/CloudKit, App Group, UserNotifications, WidgetKit reload, prompt JSON). App and Widget are the Presentation layer |
| Q2:A | Repository protocols (ports) in Domain, implemented with SwiftData in Data. Domain never imports SwiftData |
| Q3:A | Constructor injection. A composition root builds an `AppEnvironment` of use cases, passed through SwiftUI `.environment` |
| Q4:B | Daily prompt state (chosen prompt, refreshes used, recent history) is **per device** in App Group storage, not synced |
| Q5:A | Widget opens the shared SwiftData store in the App Group (CloudKit sync disabled in the widget process) and computes state with the same use cases |
| Q6:A | Prompt library is a bundled JSON resource in JournalData |
| Q7:A | Apple frameworks only, no third-party runtime dependencies |
| Q8:B + FQ4:B | Xcode project defined with **Tuist**. The user installs Tuist before Code Generation |

Answer analysis: no contradictions. FQ1:B (no view models) means Presentation logic isn't unit-tested, which matches Q15:A (unit tests cover core logic only).

## Execution Checklist (run after answers are checked and approved)

- [x] Step 1: Re-read requirements, stories and the approved answers
- [x] Step 2: Identify components and group them by unit (Core / App / Widget)
- [x] Step 3: Generate `aidlc-docs/inception/application-design/components.md`: name, purpose, responsibilities and interface for each component
- [x] Step 4: Generate `component-methods.md`: method signatures and input/output types (business rules left for Functional Design)
- [x] Step 5: Generate `services.md`: service definitions and how they coordinate (save entry, day rollover, sync merge, widget reload, reminder rescheduling)
- [x] Step 6: Generate `component-dependency.md`: dependency matrix, communication patterns, data flow diagram (Mermaid plus a text alternative)
- [x] Step 7: Generate `application-design.md` combining all of the above
- [x] Step 8: Check the design is complete: every story maps to at least one component, no dependency cycles, and App and Widget depend only on Core
- [x] Step 9: Validate Markdown and diagrams per content-validation rules

## Mandatory Artifacts
- [x] components.md with component definitions and high-level responsibilities
- [x] component-methods.md with method signatures (business rules detailed later in Functional Design)
- [x] services.md with service definitions and orchestration patterns
- [x] component-dependency.md with dependency relationships and communication patterns
- [x] Validate design completeness and consistency
