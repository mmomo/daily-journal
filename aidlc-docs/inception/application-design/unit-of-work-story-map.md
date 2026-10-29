# Unit of Work: Story Map

Each story has one **primary** unit, where most of the behavior is implemented and tested, and may have **contributing** units. Stories touch several layers because of Clean Architecture: Domain holds the rule, Data the storage, App and Widget the screens.

Legend: **P** = primary, C = contributes

| Story | Domain | Data | App | Widget | Domain test coverage |
|---|---|---|---|---|---|
| US-1.1 See today's prompt | **P** | C (prompt library) | C (TodayView) | | Yes |
| US-1.2 Same prompt everywhere | **P** | C (App Group state) | C | C | Yes |
| US-1.3 Refresh prompt (limited) | **P** | C | C (refresh control) | | Yes |
| US-1.4 Choose categories | **P** | C (settings store) | C (picker) | | Yes |
| US-2.1 Write and save | **P** | C (repository) | C (editor) | | Yes |
| US-2.2 Edit until midnight | **P** | | C (autosave, lock UI) | | Yes |
| US-2.3 Backfill yesterday | **P** | | C (backfill offer) | | Yes |
| US-2.4 Read-only past entries | **P** | | C (detail view) | | Yes |
| US-2.5 Open editor fast | | | **P** | | Manual |
| US-2.6 Sync across devices | C (merger, reconcile) | **P** (CloudKit store, remote change) | C (observer wiring) | | Merge logic yes; device sync manual |
| US-3.1 Browse | C | C (sorted query) | **P** (HistoryView) | | Partly |
| US-3.2 Search | C (matcher) | **P** (search query) | C (`.searchable`) | | Yes (Domain + Data) |
| US-3.3 Export | **P** (exporter) | | C (ShareLink) | | Yes |
| US-4.1 Current streak | **P** | | C (StreakView) | C (badge) | Yes |
| US-4.2 At risk during grace | **P** | | C | C | Yes |
| US-4.3 Reset after grace | **P** | | C | C | Yes |
| US-4.4 Longest streak | **P** | | C | | Yes |
| US-5.1 Widget content | C (TodayState) | C | | **P** | Partly (TodayState) |
| US-5.2 Tap widget to write | C (DeepLink) | | C (routing) | **P** (`widgetURL`) | DeepLink round-trip |
| US-5.3 Widget stays current | C (deadlines) | C (WidgetRefresher) | | **P** (timeline) | Deadline math yes |
| US-6.1 Turn on reminder | C | **P** (UN scheduler) | C (settings UI) | | Use case with fake scheduler |
| US-6.2 Skip when done | **P** (reminder window rule) | C | | | Yes |
| US-6.3 Tap reminder to write | C (DeepLink) | C (notification payload) | **P** (delegate routing) | | DeepLink round-trip |
| US-7.1 Onboarding | C (CompleteOnboarding) | C | **P** (OnboardingView) | | Use case yes |
| US-7.2 Settings | C | C | **P** (SettingsView) | | n/a |

## Summary per Unit

| Unit | Primary stories | Count |
|---|---|---|
| Domain | US-1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 2.4, 3.3, 4.1, 4.2, 4.3, 4.4, 6.2 | 14 |
| Data | US-2.6, 3.2, 6.1 | 3 |
| App | US-2.5, 3.1, 6.3, 7.1, 7.2 | 5 |
| Widget | US-5.1, 5.2, 5.3 | 3 |
| **Total** | | **25** |

## Validation

- All 25 stories (US-1.1 to US-7.2) have exactly one primary unit.
- No story's primary unit depends on a unit built later. For example, Domain-primary stories can be tested before Data exists by using in-memory fakes.
- Most of the logic (14 of 25 primary stories) is in Domain, so most acceptance scenarios become fast, host-run unit tests (NFR-4.1).
