# Unit of Work Plan

**Stage**: INCEPTION - Units Generation (Part 1: Planning)
**Inputs**: requirements.md, stories.md, application-design.md (all approved)

## Context

This is **one iOS app**: a single App Store bundle containing the app and its widget extension. There are no separately deployable services. "Units" here are **modules built in order**, each finished (design and code) before the next starts. Application Design already fixed the module boundaries: `JournalDomain`, `JournalData` (one `JournalCore` Swift package), `JournalApp`, `JournalWidget`. What's left to decide is how these group into units, the folder layout, and project configuration values.

### Category Evaluation

| Category | Applies? | Notes |
|---|---|---|
| Story Grouping | Yes | Question 1 |
| Dependencies | Yes | Fixed by the design (App and Widget depend on Core). Build order follows from it |
| Team Alignment | No | One developer (personal/demo project, Q14:A), so there are no ownership boundaries to plan |
| Technical / Deployment | Partly | Everything ships in one bundle, but signing and identifiers affect all units. Questions 3 and 4 |
| Business Domain | No | One small domain (journaling). Application Design already split it by capability inside Domain |
| Code Organization | Yes | Question 2 |
| Content | Yes | The prompt library is a sizeable piece of work inside Core. Question 5 |

---

## Questions

Please fill in the letter after each `[Answer]:` tag. If no option fits, choose the last option (Other) and describe what you want.

## Question 1
How should the modules be grouped into units of work? (Each unit goes through its own design and code cycle with approval gates.)

A) **3 units**: (1) Core = JournalDomain + JournalData, (2) App, (3) Widget. Core is built and unit-tested first; App and Widget then build on it

B) **4 units**: (1) Domain, (2) Data, (3) App, (4) Widget. Smaller review steps, one extra cycle of gates

C) **2 units**: (1) Core, (2) App + Widget together (the widget is small and shares the "today" presentation)

D) **1 unit**: everything in one pass, with the fewest approval gates and the largest single review

X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 2
What directory layout should the workspace root use?

A) **iOS/Tuist conventional**:
`Project.swift` and `Tuist/` at the root, `JournalCore/` (Swift package: `Sources/JournalDomain`, `Sources/JournalData`, `Tests/...`), `JournalApp/` (`Sources/`, `Resources/`), `JournalWidget/` (`Sources/`)

B) **AI-DLC generic monolith pattern**: `src/{unit-name}/` and `tests/{unit-name}/` (less familiar to iOS tools; Tuist and SwiftPM paths would need custom configuration)

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 3
Which identifiers should the project use (bundle ID, App Group, iCloud container, URL scheme)?

A) Placeholders based on `com.example.dailyjournal` (App Group `group.com.example.dailyjournal`, iCloud `iCloud.com.example.dailyjournal`, scheme `dailyjournal://`), kept in one Tuist config file so you can change them later

B) Use my own reverse-DNS prefix (write it after the [Answer]: tag, e.g., `B: com.janedoe`)

X) Other (please describe after [Answer]: tag below)

[Answer]: B com.mmomo

## Question 4
App Groups and iCloud/CloudKit need code signing with an Apple Developer Team to run on a real device. iCloud sync also only works on a signed build. How should signing be handled?

A) Leave the Team ID empty for now: builds and tests run in the **simulator**, and I document how to add your Team ID to run on a device and test iCloud sync

B) Use my Team ID (write it after the [Answer]: tag, e.g., `B: ABCDE12345`)

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 5
The requirements call for 365+ original prompts across 4 categories (assumption 5). How should the prompt library be produced?

A) I write all 365+ prompts (about 92 per category) in `prompts.json` during Core code generation

B) I write a smaller starter set (e.g., 40 per category = 160) now, and the library grows later. With fewer than 30 prompts in a single selected category, the no-repeat window is affected (handled in Functional Design)

X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Approved Decisions

| # | Decision |
|---|---|
| Q1:B | **4 units**, built in order: (1) **Domain** (`JournalDomain`), (2) **Data** (`JournalData`), (3) **App** (`JournalApp`), (4) **Widget** (`JournalWidget`). Domain and Data are separate targets of the one `JournalCore` package |
| Q2:A | iOS/Tuist conventional layout: `Project.swift`, `Tuist/`, `JournalCore/`, `JournalApp/`, `JournalWidget/` at the workspace root |
| Q3:B | Prefix `com.mmomo`. Derived identifiers: app `com.mmomo.dailyjournal`, widget `com.mmomo.dailyjournal.widget`, App Group `group.com.mmomo.dailyjournal`, iCloud `iCloud.com.mmomo.dailyjournal`, URL scheme `dailyjournal://`. All kept in one Tuist config file |
| Q4:A | No Team ID yet. Builds and tests target the simulator. Steps to add a Team ID for device and iCloud testing go in the build instructions |
| Q5:A | All 365+ prompts (about 92 per category) written in `prompts.json` during the Data unit, where the JSON resource lives |

Answer analysis: no contradictions. Splitting Core into Domain and Data (Q1:B) changes the execution plan's "Functional Design for the Core unit" to **Functional Design for the Domain unit**. That design will cover all business rules plus the storage schema (`EntryRecord`, `prompts.json`). Data, App and Widget are expected to skip Functional Design, which will be confirmed per unit.

## Execution Checklist (Part 2: Generation, run after approval)

- [x] Step 1: Re-read the approved answers and the application design
- [x] Step 2: Generate `aidlc-docs/inception/application-design/unit-of-work.md`
  - [x] Unit definitions, responsibilities, included modules and components
  - [x] Code organization strategy (greenfield): directory tree, Tuist and SwiftPM layout, config file for identifiers
  - [x] Per-unit design stages to run (Functional Design: Core only) and definition of done
- [x] Step 3: Generate `aidlc-docs/inception/application-design/unit-of-work-dependency.md`
  - [x] Dependency matrix and build order
  - [x] Interfaces each unit consumes and provides
- [x] Step 4: Generate `aidlc-docs/inception/application-design/unit-of-work-story-map.md`
  - [x] Assign every story US-1.1 to US-7.2 to a primary unit (and any contributing units)
- [x] Step 5: Validate unit boundaries and dependencies (no cycles; every story assigned)
- [x] Step 6: Validate Markdown and diagrams; update aidlc-state.md

## Mandatory Artifacts
- [x] `unit-of-work.md` with unit definitions and responsibilities
- [x] `unit-of-work-dependency.md` with dependency matrix
- [x] `unit-of-work-story-map.md` mapping stories to units
- [x] Greenfield only: code organization strategy documented in `unit-of-work.md`
- [x] Validate unit boundaries and dependencies
- [x] Ensure all stories are assigned to units
