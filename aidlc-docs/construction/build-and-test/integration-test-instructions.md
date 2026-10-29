# Integration Test Instructions

## Purpose
Check that the units work together: Domain ↔ Data (automated), App ↔ Data/Domain and Widget ↔ App (simulator/manual).

## Automated Integration Scenarios (part of `swift test`)

### Scenario 1: Domain use cases → Data implementations
- **Test**: `DataIntegrationTests.dailyFlowEndToEnd`
- **Setup**: `JournalEnvironmentFactory.makeInMemory` (in-memory SwiftData, throwaway UserDefaults suite, bundled prompts.json), fixed clock, recording scheduler
- **Steps**: onboarding with reminder → today's prompt → refresh → save → next-next day morning at-risk → backfill → save today → streak → export → search
- **Expected**: streak 3; reminders skip done days; export contains the entries; search is case-insensitive

### Scenario 2: Sync reconciliation through SwiftData
- **Test**: `DataIntegrationTests.reconcilesDuplicatesInSwiftData`
- **Expected**: two same-day records become one merged record (oldest id, divider), and a second run is a no-op

### Scenario 3: Repository search matches the Domain matcher
- **Test**: `SwiftDataEntryRepositoryTests.searchMatchesDomainMatcher` (10 queries)

Run them all with `cd JournalCore && swift test --filter "Data integration|SwiftDataEntryRepository"`.

## Simulator Integration Scenarios (manual)

Setup: build and install as in `build-instructions.md`. Use a fresh simulator (`xcrun simctl erase <UDID>`) for first-launch checks.

| # | Units | Steps | Expected |
|---|---|---|---|
| I-1 | App → Data | Fresh install, launch | Onboarding appears. No crash; store created |
| I-2 | App → Domain | Finish onboarding, type an entry, wait 1 s, relaunch | Entry persists; streak shows 1 with ✓ |
| I-3 | URL → App | `xcrun simctl openurl booted dailyjournal://today` | App opens Today with the editor focused (or the saved entry if done) |
| I-4 | Notification → App | Turn on the reminder 1–2 minutes from now, background the app, wait, tap the notification | Today opens with the editor (US-6.3). If you already wrote today, no notification fires (US-6.2) |
| I-5 | App → Widget (**requires Team ID**) | Add the "Daily Prompt" widget, save an entry in the app, go Home | Widget shows the same prompt and an updated streak with ✓ |
| I-6 | Widget → App | Tap the widget | App opens on the editor (US-5.2) |
| I-7 | Without Team ID | Add the widget | Shows "Open Daily Journal to get your first prompt" (expected limitation) |

## Two-Device Sync (requires Team ID + iCloud account)
1. Set `developmentTeam`, run `tuist generate`, and install on two devices or simulators signed in to the same iCloud account.
2. Put both offline, write an entry for today on each, then go online.
3. **Expected**: both devices end up with one entry for today containing both texts separated by `---` (US-2.6).

## Cleanup
```bash
xcrun simctl uninstall booted com.mmomo.dailyjournal
xcrun simctl shutdown all
```
