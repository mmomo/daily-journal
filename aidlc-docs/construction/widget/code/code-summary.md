# Code Summary: Unit 4 Widget (`JournalWidget`)

**Location**: `/Users/mmomo/Code/AIDLC/demo/JournalWidget/` plus `Project.swift`
**Target**: WidgetKit app extension `com.mmomo.dailyjournal.widget`, iOS 17.0+, embedded in `JournalApp`

## Files

| Path | Purpose |
|---|---|
| `Project.swift` (modified) | Adds the `JournalWidget` target (`.appExtension`, `NSExtensionPointIdentifier = com.apple.widgetkit-extension`, `Journal*` config keys, team-conditional entitlements); the App target now depends on (embeds) it |
| `JournalWidget/JournalWidget.entitlements` | App Group (applied only with a Team ID) |
| `JournalWidget/Resources/Assets.xcassets` | AccentColor, WidgetBackground (light and dark) |
| `JournalWidget/Sources/JournalWidgetBundle.swift` | `@main WidgetBundle` |
| `JournalWidget/Sources/PromptStreakWidget.swift` | `StaticConfiguration`, `.systemSmall`, "Daily Prompt" |
| `JournalWidget/Sources/PromptStreakProvider.swift` | Timeline entries (now, plus 12:00 when a backfill or at-risk state ends then), reload after midnight, `WidgetClock`, Ready / Needs-setup content, sample state |
| `JournalWidget/Sources/PromptStreakWidgetView.swift` | Streak badge (✓ done, ⚠︎ at risk), prompt (5 lines, scale-down), needs-setup view, `widgetURL`, accessibility label, 4 previews |
| `README.md` (modified) | Widget section and signing note |

## Stories

- [x] US-5.1: prompt + streak badge, done and at-risk states, setup placeholder
- [x] US-5.2: `widgetURL(dailyjournal://today)` → TodayView focuses the editor (Unit 3 routing)
- [x] US-5.3: noon entry, midnight reload policy, plus app-triggered `reloadAllTimelines()` after save, refresh, category change and sync (Units 1–2)

## Verification

| Check | Result |
|---|---|
| `tuist generate --no-open` | Success |
| `xcodebuild` `JournalApp` scheme, iPhone 15 Pro simulator (iOS 17.2) | **BUILD SUCCEEDED**, 0 warnings |
| Embedded extension | `JournalApp.app/PlugIns/JournalWidget.appex` present: bundle id `com.mmomo.dailyjournal.widget`, extension point `com.apple.widgetkit-extension`, `JournalAppGroupIdentifier` set |
| Launch + deep link | App launched; `simctl openurl dailyjournal://today` handled with no crash (same process kept running) |

## Notes and Limitations

- Placing the widget on the Home Screen and checking how it looks has to be done by hand. There's no automated widget UI test (Q15:A). The four previews cover each visual state.
- Without a Team ID the extension can't reach the App Group, so it always shows the needs-setup message. That's expected and documented.
- The midnight switch relies on WidgetKit honoring `.after(nextMidnight)`. The system may delay the reload by a few minutes. Opening the app reloads it immediately.
