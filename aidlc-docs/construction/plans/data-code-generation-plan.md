# Code Generation Plan: Unit 2 Data (`JournalData`)

**This plan is the single source of truth for generating the Data unit's code.** Each checkbox is marked [x] as soon as its step is done.

## Per-Unit Stage Assessment

| Stage | Decision | Rationale |
|---|---|---|
| Functional Design | **SKIP** | Data adds no business rules. Its contracts (EntryRecord schema, prompts.json schema and validation, App Group keys, port semantics) are already specified in Domain functional design `business-logic-model.md` §9 and `Ports.swift` |
| NFR Requirements / NFR Design | SKIP | Per execution plan (stack fixed, extensions disabled) |
| Infrastructure Design | SKIP | No cloud infrastructure. The CloudKit container and App Group are entitlements configured in Unit 3 |

## Unit Context

| Item | Value |
|---|---|
| Workspace root | `/Users/mmomo/Code/AIDLC/demo` |
| Code location | `JournalCore/Sources/JournalData/`, `JournalCore/Tests/JournalDataTests/` (new target in the existing package) |
| Depends on | `JournalDomain` (ports, entities, use cases) |
| Consumed by | App (factory `.app`, `RemoteChangeObserver`), Widget (factory `.widget`) |
| Frameworks | Foundation, SwiftData, CoreData (only for the remote-change notification name), UserNotifications, WidgetKit |
| Database entities owned | `EntryRecord` (SwiftData `@Model`, CloudKit-compatible) |
| Shared resources owned | SwiftData store file in the App Group, App Group `UserDefaults` (`settings.v1`, `promptState.v1`), `prompts.json` |

### Configuration and Signing Approach (Q4:A, simulator without a Team ID)
- `AppConfiguration` reads `JournalAppGroupIdentifier`, `JournalICloudContainerIdentifier` and `JournalCloudKitEnabled` from the host bundle's Info.plist. Tuist sets them in Unit 3 from `AppIdentifiers.swift`. Defaults: `group.com.mmomo.dailyjournal`, `iCloud.com.mmomo.dailyjournal`, CloudKit **off**.
- CloudKit sync is used only when `JournalCloudKitEnabled` is true (set it once a Team ID is added). Otherwise the app context uses a local store. This prevents a crash when entitlements aren't present.
- If the App Group container isn't available (unsigned or unconfigured build), the store and defaults fall back to the app's own Application Support and `UserDefaults.standard`. The widget then can't see app data until signing is configured. This will be documented in the Build and Test instructions.

## Stories (primary in this unit)
- [x] US-2.6 Sync across devices (CloudKit store configuration, remote-change observer, reconcile trigger)
- [x] US-3.2 Search (repository search query consistent with `EntrySearchMatcher`)
- [x] US-6.1 Turn on reminder (UserNotifications scheduler)

Contributing: the prompt library for US-1.1 to US-1.4, and the persistence used by every entry and streak story.

### Template Steps Not Applicable

| Template step | Reason |
|---|---|
| API layer | No network API |
| Frontend components | No UI in this unit |
| Database migration scripts | First schema version. SwiftData/CloudKit add-only evolution; no migration plan needed at v1 |
| Deployment artifacts | Library target; packaging is in Unit 3 |

---

## Generation Steps

### Step 1: Package update
- [x] Add library product and target `JournalData` (depends on `JournalDomain`, resources `.process("Resources")`) and test target `JournalDataTests` to `JournalCore/Package.swift`
- [x] Create folders `Sources/JournalData/{Configuration,Persistence,Stores,System,Composition,Resources}` and `Tests/JournalDataTests`

### Step 2: Configuration
- [x] `Configuration/AppConfiguration.swift`: identifiers from Info.plist with defaults, App Group container URL lookup, `UserDefaults` suite resolution with fallback

### Step 3: Persistence (repository layer)
- [x] `Persistence/EntryRecord.swift`: `@Model` with defaulted attributes (id, dayKey, dayNumber, text, promptID, promptText, createdAt, updatedAt); mapping to and from `JournalEntry` (invalid dayKey → skipped)
- [x] `Persistence/PersistenceController.swift`: `makeContainer(for: .app/.widget, inMemory:)`. Store URL in the App Group; CloudKit `.private(id)` only for `.app` when enabled, otherwise `.none`
- [x] `Persistence/SwiftDataEntryRepository.swift`: `@ModelActor` implementing every `EntryRepository` method (dayKey and dayNumber predicates, `localizedStandardContains` search, duplicate-day detection)

### Step 4: Stores
- [x] `Stores/BundledPromptLibrary.swift` + `PromptLibraryValidator`: decode `prompts.json`; validate per functional design §9.2; index by id
- [x] `Stores/AppGroupPromptStateStore.swift`: `promptState.v1` JSON dictionary, prune before `keepingFrom`
- [x] `Stores/AppGroupSettingsStore.swift`: `settings.v1` JSON, defaults when missing or corrupt

### Step 5: System adapters
- [x] `System/SystemTimeSource.swift`: `Date()`, `TimeZone.autoupdatingCurrent`
- [x] `System/UserNotificationReminderScheduler.swift`: authorization; `replacePending` removes this app's `reminder-*` requests and adds calendar-trigger requests with the deep link in `userInfo`. Request building is a pure function so it can be tested
- [x] `System/WidgetCenterRefresher.swift`: `WidgetCenter.shared.reloadAllTimelines()`
- [x] `System/RemoteChangeObserver.swift`: observes `.NSPersistentStoreRemoteChange`, debounces (1 s), invokes the callback (app process only)

### Step 6: Composition root
- [x] `Composition/JournalEnvironmentFactory.swift`: `make(for:)` → `JournalEnvironment` (`useCases`, `modelContainer`), plus `makeInMemory(...)` for previews and tests

### Step 7: Prompt library content (Q5:A)
- [x] `Resources/prompts.json`: **368 original prompts, 92 per category** (gratitude, reflection, goals, creativity), ids `<category>-001…092`, 10–200 characters, no duplicates, written in a warm, non-judgmental tone

### Step 8: Unit tests (`Tests/JournalDataTests/`)
- [x] `EntryRecordMappingTests`: round-trip and invalid dayKey skipping
- [x] `SwiftDataEntryRepositoryTests` (in-memory container): save/update by id, entry(for:) earliest-of-duplicates, ranges, entries(after:), entryDays, duplicateDays, delete, newest-first ordering, search parity with `EntrySearchMatcher` on a shared fixture (case, accents, prompt text)
- [x] `BundledPromptLibraryTests`: the real `prompts.json` loads and passes validation (≥ 90 per category, ≥ 365 total, unique ids and texts, id-category match, length); the validator rejects bad fixtures
- [x] `AppGroupStoresTests`: settings round-trip, defaults, corrupt-data fallback; prompt state round-trip and pruning (throwaway `UserDefaults` suite)
- [x] `ReminderRequestBuilderTests`: identifier, title, body, trigger date components, deep link `userInfo`
- [x] `DataIntegrationTests`: `JournalUseCases` wired with the real in-memory repository, real stores and the bundled library. Save, backfill, streak, reconcile duplicates, export, end to end

### Step 9: Documentation
- [x] `aidlc-docs/construction/data/code/code-summary.md`: inventory, configuration keys, store layout, test results, limitations
- [x] Update `JournalCore/README.md` (JournalData section, Info.plist keys)

### Step 10: Verification
- [x] Clean `swift build --build-tests` (0 warnings) and `swift test` (Domain + Data suites all passing); record the results

## Estimated Scope
- About 12 production Swift files, 1 JSON resource (368 prompts), about 7 test files
- No third-party dependencies
