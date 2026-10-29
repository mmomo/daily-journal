# Code Summary: Unit 2 Data (`JournalData`)

**Location**: `/Users/mmomo/Code/AIDLC/demo/JournalCore/Sources/JournalData/` (new target in the `JournalCore` package)
**Frameworks**: Foundation, SwiftData, CoreData (remote-change notification name only), UserNotifications, WidgetKit

## File Inventory

| Path (under `JournalCore/`) | Purpose |
|---|---|
| `Package.swift` (modified) | Adds the `JournalData` product and target (with resources) and the `JournalDataTests` test target |
| `README.md` (modified) | JournalData description and Info.plist configuration keys |
| `Sources/JournalData/Configuration/AppConfiguration.swift` | App Group, iCloud container and CloudKit flag from Info.plist. Store directory and `UserDefaults` with fallbacks |
| `Sources/JournalData/Persistence/EntryRecord.swift` | `@Model` (CloudKit-compatible: defaults, no unique constraints, no relationships) and domain mapping |
| `Sources/JournalData/Persistence/PersistenceController.swift` | `ModelContainer` for `.app` (read/write, CloudKit when enabled) and `.widget` (read-only, no CloudKit), plus an in-memory variant |
| `Sources/JournalData/Persistence/SwiftDataEntryRepository.swift` | `@ModelActor` implementing every `EntryRepository` method |
| `Sources/JournalData/Stores/BundledPromptLibrary.swift` | JSON loader, `PromptLibraryValidator`, `PromptLibraryError` |
| `Sources/JournalData/Stores/AppGroupStores.swift` | `AppGroupPromptStateStore` (`promptState.v1`, pruning) and `AppGroupSettingsStore` (`settings.v1`, defaults on corruption) |
| `Sources/JournalData/System/SystemTimeSource.swift` | `Date()` and `TimeZone.autoupdatingCurrent` |
| `Sources/JournalData/System/UserNotificationReminderScheduler.swift` | `UNUserNotificationCenter` adapter. `ReminderRequestBuilder` turns a reminder into a calendar-trigger request carrying the deep link |
| `Sources/JournalData/System/WidgetCenterRefresher.swift` | `WidgetCenter` reload, plus no-op refresher and scheduler for the widget process and previews |
| `Sources/JournalData/System/RemoteChangeObserver.swift` | `@MainActor` debounced listener for `.NSPersistentStoreRemoteChange` |
| `Sources/JournalData/Composition/JournalEnvironmentFactory.swift` | `make(for: .app/.widget)` and `makeInMemory(...)` return `JournalEnvironment` (use cases, container, configuration) |
| `Sources/JournalData/Resources/prompts.json` | **368 original prompts**, 92 each for gratitude, reflection, goals and creativity |
| `Tests/JournalDataTests/*` (5 files) | Support, repository, stores and builder, integration |

## Configuration and Store Layout

| Item | Location |
|---|---|
| SwiftData store | `<App Group>/Library/Application Support/Journal.store`. Falls back to the app's Application Support directory |
| Settings | App Group `UserDefaults`, key `settings.v1` (JSON `AppSettings`) |
| Prompt state | App Group `UserDefaults`, key `promptState.v1` (JSON, today and yesterday only) |
| CloudKit | `.private(iCloud.com.mmomo.dailyjournal)`, only for `.app` and only when `JournalCloudKitEnabled = YES` |

## Story Checklist

- [x] US-2.6: CloudKit-capable store, remote-change observer, and reconcile verified against real SwiftData
- [x] US-3.2: repository search (`localizedStandardContains`) checked against `EntrySearchMatcher` on 10 queries
- [x] US-6.1: notification scheduler and request builder (calendar trigger, deep link)

## Verification

| Command | Result |
|---|---|
| `swift build --build-tests` (clean) | Succeeded, 0 warnings |
| `swift test` | **121 tests in 22 suites passed** (Domain 101 + Data 20, several parameterized) |
| `xcodebuild -scheme JournalCore-Package -destination 'generic/platform=iOS Simulator' build` | **BUILD SUCCEEDED** (checks iOS-only code paths such as `.ephemeral`) |

## Known Limitations

- `UserNotificationReminderScheduler.replacePending` and `WidgetCenterRefresher` aren't unit-tested against the real system centers, which need a host app. Their pure parts are tested (`ReminderRequestBuilder`), and the rest gets manual checks in Build and Test.
- The widget opens the store read-only. If the app has never created the store, the widget's container creation fails, and the Widget unit must show its placeholder in that case.
- CloudKit sync can't be exercised until a Team ID and the iCloud entitlement are configured (Q4:A).
