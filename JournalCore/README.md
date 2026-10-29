# JournalCore

Shared Swift package for the Daily Journal app (iOS 17+).

| Target | Layer | Contents |
|---|---|---|
| `JournalDomain` | Domain | Entities, business-rule policies, ports (protocols) and the 15 use cases. Foundation only |
| `JournalData` | Data | SwiftData/CloudKit repository, App Group stores, notification scheduler, widget refresher, bundled `prompts.json` (600 prompts), and the `JournalEnvironmentFactory` composition root |

## Running the tests

```sh
cd JournalCore
swift test
```

Tests use Swift Testing and run on the Mac host (no simulator needed). Time-dependent logic is driven by an injected `TimeSource`, so every scenario uses a fixed clock and time zone.

## Host app configuration (Info.plist keys read by `AppConfiguration`)

| Key | Default | Meaning |
|---|---|---|
| `JournalAppGroupIdentifier` | `group.com.mmomo.dailyjournal` | Shared container for the store and settings |
| `JournalICloudContainerIdentifier` | `iCloud.com.mmomo.dailyjournal` | CloudKit container for sync |
| `JournalCloudKitEnabled` | `NO` | Turn on only in signed builds with the iCloud entitlement |

Without the App Group entitlement (unsigned simulator builds), data falls back to the app's own Application Support directory and `UserDefaults.standard`. The widget can't see app data in that mode.
