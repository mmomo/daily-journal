# Code Generation Plan: Unit 4 Widget (`JournalWidget`)

**This plan is the single source of truth for generating the Widget unit's code.** Each checkbox is marked [x] as soon as its step is done.

## Per-Unit Stage Assessment

| Stage | Decision | Rationale |
|---|---|---|
| Functional Design | **SKIP** | The widget presents `GetTodayStateUseCase` output. Its timeline rules are in services.md S7 and its content in US-5.1–5.3. No new business rules |
| NFR / NFR Design / Infrastructure | SKIP | Per execution plan |

## Unit Context

| Item | Value |
|---|---|
| Code location | `JournalWidget/` plus updates to `Project.swift` |
| Target | WidgetKit app extension, bundle id `com.mmomo.dailyjournal.widget`, iOS 17.0+, embedded in `JournalApp` |
| Depends on | `JournalDomain`, `JournalData` (`JournalEnvironmentFactory.make(for: .widget)`: read-only store, no CloudKit, no-op reminders and widget refresher) |
| Signing | Same rule as the App: the `JournalWidget.entitlements` App Group is applied only when `AppIdentifiers.developmentTeam` is set |

## Stories (primary in this unit)
- [x] US-5.1 Prompt and streak on my Home Screen (small widget: prompt + streak badge, done check, at-risk state, placeholder before setup)
- [x] US-5.2 Tap widget to write (`widgetURL(dailyjournal://today)`)
- [x] US-5.3 Widget stays current (timeline boundaries + app-triggered reloads already in Domain/Data)

## Widget Behavior

| Aspect | Design |
|---|---|
| Family | `.systemSmall` only (Q9:A) |
| Content | Top: streak badge (flame + count, ✓ when done, ⚠︎ when at risk). Body: today's prompt, up to 5 lines with slight scale-down. Uses the app's accent color |
| States | **Ready**: TodayState. **Needs setup**: onboarding not completed, or the store can't be opened. In that state it shows "Open Daily Journal to get your first prompt" (US-5.1 "before onboarding"). **Placeholder** (gallery): a sample prompt, redacted |
| Timeline | Entry for **now**. An extra entry at **today's 12:00** if a backfill offer or at-risk state ends then, computed with the clock set to noon (same day, so no new prompt state is written). Reload policy `.after(next midnight)` so the new day's prompt is computed on the new day. The app also reloads the widget after save, refresh, category change and sync (Data `WidgetCenterRefresher`) |
| Tap | `widgetURL(DeepLink.todayEditor.url)` → app opens with the editor focused, or the saved entry if done (US-5.2) |
| Clock | A small `WidgetClock: TimeSource` with an adjustable `now`, so the noon entry is computed with the Domain's own rules |

Known limitation (documented): without a Team ID there's no App Group, so the extension can't read the app's store and always shows **Needs setup**. With signing configured, it shows live data.

## Template Steps Not Applicable
| Step | Reason |
|---|---|
| Business logic / repository / API | In Units 1–2 |
| Unit tests | Q15:A. The widget is presentation only. Its logic (TodayState, streak, deadlines) is already covered by the Domain tests |
| Migrations / deployment | n/a. The extension is embedded in the app |

---

## Generation Steps

### Step 1: Project update
- [x] `Project.swift`: add target `JournalWidget` (`.appExtension`, Info.plist `NSExtension` → `com.apple.widgetkit-extension`, `Journal*` config keys, display name); add `.target(name: "JournalWidget")` to `JournalApp`'s dependencies (embeds the extension)
- [x] `JournalWidget/JournalWidget.entitlements` (App Group; applied only with a team)
- [x] `JournalWidget/Resources/Assets.xcassets` (AccentColor and WidgetBackground)

### Step 2: Widget sources (`JournalWidget/Sources/`)
- [x] `JournalWidgetBundle.swift` (`@main WidgetBundle`)
- [x] `PromptStreakWidget.swift` (`StaticConfiguration`, kind `PromptStreakWidget`, `.systemSmall`, name and description, content-margin-aware background)
- [x] `PromptStreakProvider.swift` (`TimelineProvider`: placeholder, snapshot, timeline; `WidgetClock`; Ready / Needs setup content)
- [x] `PromptStreakWidgetView.swift` (badge, prompt, needs-setup view, accessibility label, `widgetURL`, previews for ready / done / at risk / needs setup)

### Step 3: Generate and build
- [x] `tuist generate --no-open`; `xcodebuild` the `JournalApp` scheme for the iOS 17.2 simulator; 0 errors, 0 warnings

### Step 4: Smoke check
- [x] Install on the simulator and confirm `JournalApp.app/PlugIns/JournalWidget.appex` is embedded with the correct bundle id and extension point; launch the app with no crash

### Step 5: Documentation
- [x] `aidlc-docs/construction/widget/code/code-summary.md`
- [x] Update the root `README.md` (widget section, signing note)

## Estimated Scope
- 4 Swift files, 1 entitlements file, 1 asset catalog, and a `Project.swift` update
