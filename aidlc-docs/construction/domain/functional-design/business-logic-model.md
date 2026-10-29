# Business Logic Model: Unit 1 Domain

These are the algorithms behind the policies and the flow of each use case. Rule IDs (BR-xx) refer to `business-rules.md`. The pseudocode shows intent; Swift details are settled in Code Generation.

---

## 1. PromptSelector

### 1.1 Stable hash
`stableHash(s: String) -> UInt64` = **FNV-1a 64-bit** over the UTF-8 bytes of `s` (offset basis `0xcbf29ce484222325`, prime `0x100000001b3`). It's deterministic across launches, devices and OS versions. Swift's `hashValue` is never used (BR-P2).

### 1.2 Daily sequence (stateless, no-repeat by construction)
The 30-day no-repeat guarantee (BR-P3) comes from a **full-period stride** over the pool instead of from stored history:

```
pool      = library.filter { categories.contains($0.category) }.sorted(by: id)   // BR-P1
n         = pool.count                        // >= 90 with one category, ~368 with all four
catKey    = categories.map(rawValue).sorted().joined(",")
offset    = stableHash("offset|" + catKey) % n
step      = stableHash("step|"   + catKey) % n, forced into 1...n-1,
            then incremented until gcd(step, n) == 1          // full period
index(d)  = (offset + d.dayNumber * step) mod n
```

Because `gcd(step, n) = 1`, `index(d)` visits every prompt exactly once in any n consecutive days, so there are no repeats for n ≥ 90 > 30 days.

**Skipping recently answered prompts.** Prompts answered through refreshes or backfills can still collide with the daily sequence, so the pick walks forward until it finds a prompt not answered in the previous 30 days:

```
answered30 = Set(promptIDs of entries with day in [d-30, d-1])
for k in 0..<n:
    candidate = pool[(index(d) + k * step) mod n]
    if candidate.id ∉ answered30: return candidate
return pool[index(d)]                                // BR-P9 fallback
```

`answered30` comes from synced entries, so devices agree once they've synced.

Note: after a **category change**, a new sequence starts, and repeats within 30 days of the old sequence are possible. `answered30` still prevents repeating a prompt you actually *answered*. This is accepted (open point 1 keeps today's prompt unchanged).

### 1.3 Refresh sequence
```
refreshedPrompt(day d, categories, refreshNumber r in 1...3, shownToday, answered30):
    excluded = Set(shownToday) ∪ answered30
    start    = stableHash("refresh|" + d.key + "|" + catKey + "|" + r) % n
    for k in 0..<n:
        candidate = pool[(start + k) mod n]
        if candidate.id ∉ excluded: return candidate
    relax: excluded = Set(shownToday)             // BR-P9
    ...same scan...
    if n == 1 → throw noRefreshesLeft
```

The result is deterministic for (day, categories, r, exclusions).

### 1.4 Resolving "the prompt for day d on this device"
```
resolvePrompt(d):
    if let s = promptState.state(for: d), let p = library.prompt(id: s.promptID): return (p, s)
    p = dailyPick(d)                              // 1.2
    s = DailyPromptState(day: d, promptID: p.id, refreshesUsed: 0,
                         shownPromptIDs: [p.id], categoriesKey: catKey)
    promptState.save(s); prune states older than d-1
    return (p, s)
```

---

## 2. EntryEditPolicy

```
editability(of day, hasEntry, now, tz):
    today = CalendarDay(containing: now, tz)
    if day == today:                          return .editable(until: (today+1).start(tz))
    if day == today-1 && !hasEntry && now < today.noon(tz):
                                              return .backfillable(until: today.noon(tz))
    return .locked                            // past, missed after deadline, future (BR-E6)
```

**DST**: `start` and `noon` are computed by the Gregorian calendar in `tz`, so a 23- or 25-hour day keeps correct boundaries (BR-T4).
**Time zone change**: `today` is recomputed from `now` in the *current* `tz`, and entry days never move (BR-T3).

---

## 3. StreakCalculator

```
summary(entryDays, now, tz):
    today = CalendarDay(now, tz); y = today-1; y2 = today-2
    D = { d ∈ entryDays | d <= today } ∪ ({today} if any d > today)    // Q4:B
    run(x) = x ∉ D ? 0 : 1 + run(x-1)          (iterative)
    noon = today.noon(tz)

    if today ∈ D:
        if y ∉ D && now < noon && run(y2) > 0:  current = 1;          status = .atRisk(run(y2), noon)   // BR-S2
        else:                                   current = run(today); status = .active             // BR-S1
    else if y ∈ D:                              current = run(y);     status = .active             // BR-S3
    else if now < noon && run(y2) > 0:          current = run(y2);    status = .atRisk(run(y2), noon) // BR-S4
    else:                                       current = 0;          status = .none               // BR-S5

    best = max(longestRun(D), current)          // BR-S6; one pass over sorted dayNumbers
    return StreakSummary(current, best, status, isTodayDone: today ∈ D)
```

Cost: O(k log k) for k entry days (k ≈ 3,650 after 10 years). Negligible.

---

## 4. DayEntryMerger

```
merge(entries):                                   // precondition: count >= 2, same day
    sorted = entries.sorted { ($0.createdAt, $0.id.uuidString) < ($1.createdAt, $1.id.uuidString) }
    base   = sorted[0]
    parts  = [(base.promptID, base.text)]
    body   = base.text
    for e in sorted.dropFirst():
        if parts.contains((e.promptID, e.text)): continue                 // BR-M5
        body += "\n\n---\n\n"
        if e.promptID != base.promptID: body += "> " + e.promptText + "\n\n" // Q1:A
        body += e.text
        parts.append((e.promptID, e.text))
    return JournalEntry(id: base.id, day: base.day, text: body,
                        promptID: base.promptID, promptText: base.promptText,
                        createdAt: base.createdAt,
                        updatedAt: sorted.map(\.updatedAt).max())
```

Deterministic: the same inputs produce the same output on every device. After a merge only `base.id` remains. If another device merges the same set, it writes the identical record and deletes the same ids, so the state settles.

---

## 5. EntrySearchMatcher

```
matches(entry, query):
    q = query.trimmingCharacters(in: .whitespacesAndNewlines)
    if q.isEmpty: return true
    opts = [.caseInsensitive, .diacriticInsensitive]
    return entry.text.range(of: q, options: opts) != nil
        || entry.promptText.range(of: q, options: opts) != nil
```

The Data unit may push this into a SwiftData predicate for speed, but it must give the same results as this matcher. A shared test fixture checks both.

---

## 6. JournalExporter

**Markdown** (`daily-journal-2026-10-08.md`):
```
# Daily Journal

Exported 2026-10-08 · 3 entries

## 2026-10-01

> What small thing made today better?

Grateful for a quiet morning.

## 2026-10-05
...
```

**Plain text** (`daily-journal-2026-10-08.txt`):
```
DAILY JOURNAL
Exported 2026-10-08 - 3 entries

2026-10-01
Prompt: What small thing made today better?

Grateful for a quiet morning.

----------------------------------------

2026-10-05
...
```

Rules: oldest first (BR-X2). Entry text is written exactly as stored. A merged entry's `---` divider stays as is. Line endings are `\n`.

---

## 7. Reminder Window (SyncReminderWithTodayUseCase)

```
execute():
    s = settings.load().reminder
    if !s.isEnabled || scheduler.authorizationStatus() != .authorized:
        scheduler.replacePending(with: []); return                        // BR-R1
    today = CalendarDay(now, tz)
    streak = StreakCalculator.summary(entryRepo.entryDays(), now, tz)
    reminders = []
    for i in 0...6:
        d = today + i
        fire = d at s.hour:s.minute in tz (next valid instant if in a DST gap)
        if fire <= now: continue
        if i == 0 && streak.isTodayDone: continue                        // BR-R2
        body = "Your daily prompt is waiting."
        if i == 0, case .active = streak.status, streak.current >= 1:
            body += " Keep your \(streak.current)-day streak going."     // BR-R4
        reminders.append(ScheduledReminder("reminder-" + d.key, d, fire,
                         "Time to journal", body, .todayEditor))
    scheduler.replacePending(with: reminders)
```

It's best effort: errors are swallowed. Running it repeatedly gives the same result.

---

## 8. Use Case Flows

| # | Use case | Flow | Errors |
|---|---|---|---|
| 1 | GetTodayState | today. Settings. `entries(for: today)` and any entry with day > today (Q4:B) → `shownEntry`. Prompt = the shown entry's frozen prompt, or `resolvePrompt(today)`. refreshesRemaining = done ? 0 : 3 − used. Editability via policy (a future entry is locked). backfillOffer if yesterday is `.backfillable`: prompt = `resolvePrompt(yesterday)` (Q6:A). Streak via calculator | `storageFailure` |
| 2 | RefreshPrompt | Load today. If done → `entryLocked`. `(p, s) = resolvePrompt(today)`. If `s.refreshesUsed >= 3` → `noRefreshesLeft`. `next = refreshedPrompt(r: used+1)`. Save state (promptID, used+1, shown + next). Widget reload | `entryLocked`, `noRefreshesLeft` |
| 3 | SaveTodayEntry(text) | Validate (BR-E2). If a future-dated entry exists → `entryLocked` (BR-E7). Existing = entry(today). Editability must be `.editable`, else `entryLocked`. Create with `resolvePrompt(today)` or update text/updatedAt. Save. Reminder sync. Widget reload | `emptyText`, `entryLocked`, `storageFailure` |
| 4 | BackfillYesterday(text) | Validate. Editability(yesterday, hasEntry) must be `.backfillable`, else `backfillNotAvailable`. Create with `resolvePrompt(yesterday)`. Save. Widget reload. Reminder sync (streak text) | `emptyText`, `backfillNotAvailable`, `storageFailure` |
| 5 | GetEntry(day) | entry(for: day), editability | n/a |
| 6 | ListEntries | allEntries, newest first | `storageFailure` |
| 7 | SearchEntries(q) | BR-Q1–Q3 | `storageFailure` |
| 8 | ExportJournal(format) | allEntries. Empty → `nothingToExport`. Exporter (oldest first) | `nothingToExport` |
| 9 | GetStreak | calculator(entryDays) | `storageFailure` |
| 10 | GetSettings | settings.load() | n/a |
| 11 | UpdatePromptCategories(set) | Empty → `categoriesEmpty`. Save. Widget reload | `categoriesEmpty` |
| 12 | ConfigureReminder(r) | If enabling: status `.notDetermined` → request. Not granted → save with reminder off, throw `notificationsDenied`. Else save, then SyncReminderWithToday | `notificationsDenied` |
| 13 | SyncReminderWithToday | §7 | none (best effort) |
| 14 | CompleteOnboarding(categories, reminder?) | Empty → `categoriesEmpty`. Save categories. If a reminder is given → ConfigureReminder (catch `notificationsDenied`, remember it). Set onboardingCompleted. Widget reload. Rethrow a remembered denial *after* completion (BR-G4) | `categoriesEmpty`, `notificationsDenied` (non-blocking) |
| 15 | ReconcileSyncedEntries | Days with count > 1 (repository `duplicateDays()` **(refined: new port method)**). For each: merge, save, delete the others. If any: reminder sync, widget reload, return true | `storageFailure` |

---

## 9. Storage Contracts for the Data Unit

### 9.1 `EntryRecord` (SwiftData `@Model`, CloudKit-compatible)
| Attribute | Type | Default | Notes |
|---|---|---|---|
| `id` | UUID | `UUID()` | Domain identity. **Not** `@Attribute(.unique)` (CloudKit forbids unique) |
| `dayKey` | String | `""` | `CalendarDay.key`, used for lookup and duplicate detection |
| `dayNumber` | Int | `0` | For sorting and range queries |
| `text` | String | `""` | n/a |
| `promptID` | String | `""` | n/a |
| `promptText` | String | `""` | n/a |
| `createdAt` | Date | `.distantPast` | n/a |
| `updatedAt` | Date | `.distantPast` | n/a |

No relationships, every attribute defaulted, no unique constraints (CloudKit rules). Records with an empty `dayKey` or an unparseable day are ignored by mapping and logged.

### 9.2 `prompts.json`
```json
{
  "version": 1,
  "prompts": [
    { "id": "gratitude-001", "category": "gratitude", "text": "What small thing made today better?" }
  ]
}
```
Validation (loader and test): `version == 1`; ids unique and matching `^(gratitude|reflection|goals|creativity)-\d{3}$`; the id prefix equals `category`; text trimmed to 10–200 characters; no duplicate texts (case-insensitive); **≥ 90 prompts per category**, ≥ 365 total.

### 9.3 App Group `UserDefaults` keys
| Key | Value |
|---|---|
| `settings.v1` | JSON-encoded `AppSettings` |
| `promptState.v1` | JSON-encoded `[String: DailyPromptState]` keyed by `day.key`. Only today and yesterday are kept |

### 9.4 Port refinements (vs. component-methods.md)
- `TimeSource`: `now` plus `timeZone` (no `Calendar`)
- `EntryRepository`: add `duplicateDays() -> [CalendarDay]` and `entries(after day:) -> [JournalEntry]` (future-dated lookup). `entryDays()` stays
- `ReminderScheduler`: `authorizationStatus()`, `requestAuthorization()`, `replacePending(with:)`
- `DailyPromptState.recentPromptIDs` replaced by `shownPromptIDs` + `categoriesKey`
