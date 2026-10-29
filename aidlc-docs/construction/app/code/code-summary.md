# Code Summary: Unit 3 App (`JournalApp`)

**Location**: `/Users/mmomo/Code/AIDLC/demo/` (Tuist manifests, `JournalApp/`)
**Tooling**: Tuist 4.148.1, Xcode 26.2, Swift 6 language mode, iOS 17.0+, iPhone

## Files Created

| Path | Purpose |
|---|---|
| `Tuist.swift` | Tuist configuration |
| `Tuist/ProjectDescriptionHelpers/AppIdentifiers.swift` | All identifiers, `developmentTeam`, derived Info.plist keys and signing settings |
| `Project.swift` | Project `DailyJournal`, local package `JournalCore`, target `JournalApp` (Info.plist: display name, launch screen, URL scheme `dailyjournal`, `Journal*` config keys; entitlements only when a team is set) |
| `JournalApp/JournalApp.entitlements` | App Group, iCloud/CloudKit, aps-environment (applied only with a Team ID) |
| `JournalApp/Resources/Assets.xcassets` | AccentColor (light/dark), AppIcon (generated 1024 px placeholder) |
| `JournalApp/Sources/App/JournalApp.swift` | `@main`, delegate adaptor, `onOpenURL`, scene-phase handling |
| `JournalApp/Sources/App/AppDelegate.swift` | Notification presentation; tap → deep link (buffered on cold launch) |
| `JournalApp/Sources/App/AppEnvironment.swift` | `@Observable` use cases, `refreshToken`, `pendingDeepLink`; launch/foreground/day-change/noon handling; remote-change observer; preview factory |
| `JournalApp/Sources/App/JournalError+Message.swift` | User-facing error text |
| `JournalApp/Sources/Components/` | `StreakView`, `PromptCard`, `EntryEditorView` (autosave, serialized saves, lock handling), `DayFormatting` |
| `JournalApp/Sources/Screens/` | `RootView`, `OnboardingView`, `TodayView` (+ backfill sheet), `HistoryView` + `EntryDetailView`, `SettingsView` + `ExportSection`, `PreviewSupport` |
| `README.md` (root) | Project overview, build/test commands, how to enable signing |

## Screens → Stories

| Screen | Stories |
|---|---|
| OnboardingView | US-7.1 (and US-1.4, US-6.1 choices) |
| TodayView / PromptCard / StreakView / EntryEditorView | US-1.1–1.3, US-2.1–2.3, US-2.5, US-4.1–4.4 |
| HistoryView / EntryDetailView | US-3.1, US-3.2, US-2.4 |
| SettingsView / ExportSection | US-7.2, US-1.4, US-6.1, US-3.3 |
| AppDelegate / AppEnvironment | US-6.3, US-2.6 (reconcile on remote change), day rollover |

Primary stories completed: **US-2.5, US-3.1, US-6.3, US-7.1, US-7.2**.

## Verification

| Check | Result |
|---|---|
| `tuist generate --no-open` | Success |
| `xcodebuild … -scheme JournalApp -destination 'platform=iOS Simulator,id=<iPhone 15 Pro, iOS 17.2>' build` | **BUILD SUCCEEDED**, 0 warnings |
| Simulator smoke run (iPhone 15 Pro, iOS 17.2) | Launched without a crash. Onboarding renders. After seeding `onboardingCompleted`, Today shows the streak, a prompt ("New prompt · 3 left") and a focused editor with the keyboard up. No backfill banner after 12:00, as expected |

Adjustment made after the smoke run: the zero-streak label now reads "Start your streak today" instead of "0 day streak".

## Notes and Limitations

- Tuist runs here with `XDG_STATE_HOME`/`XDG_CACHE_HOME`/`XDG_CONFIG_HOME` pointed at a writable folder because of this session's sandbox. On your machine, plain `tuist generate` works.
- Without a Team ID there are no entitlements: notifications work locally, but there's no CloudKit sync and no App Group, so the widget (Unit 4) won't see app data until signing is configured.
- UI has no automated tests (Q15:A). Accessibility identifiers are in place for future UI tests.
