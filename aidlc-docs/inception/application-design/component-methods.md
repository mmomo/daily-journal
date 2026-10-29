# Component Methods

These are the method signatures and input/output types for each component. They are illustrative Swift and may be adjusted during Code Generation. **Business rules are not defined here.** Functional Design (Core unit) specifies the algorithms behind `PromptSelector`, `EntryEditPolicy`, `StreakCalculator`, `DayEntryMerger` and the export format.

Conventions:
- Ports and use cases are `Sendable`. I/O methods are `async throws`.
- Policies are pure, synchronous `struct`s, which makes them easy to unit-test.
- Every time-dependent operation gets "now" from the injected `TimeSource` (named to avoid clashing with Swift's standard-library `Clock`), never from `Date()` directly.

---

## 1. Domain Value Types (shapes only)

```swift
public struct CalendarDay: Hashable, Comparable, Codable, Sendable {
    public let year: Int, month: Int, day: Int
    public init(year: Int, month: Int, day: Int)
    public init(containing instant: Date, in calendar: Calendar)
    public func adding(days: Int, in calendar: Calendar) -> CalendarDay
    public func startInstant(in calendar: Calendar) -> Date
}

public enum PromptCategory: String, CaseIterable, Codable, Sendable {
    case gratitude, reflection, goals, creativity
}

public struct Prompt: Hashable, Codable, Sendable {
    public let id: String
    public let category: PromptCategory
    public let text: String
}

public struct JournalEntry: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let day: CalendarDay
    public var text: String
    public let promptID: String
    public let promptText: String
    public let createdAt: Date
    public var updatedAt: Date
}

public struct DailyPromptState: Codable, Sendable {
    public let day: CalendarDay
    public var promptID: String
    public var refreshesUsed: Int
    public var recentPromptIDs: [String]      // used to avoid repeats
}

public enum StreakStatus: Equatable, Sendable {
    case none                                  // streak is 0
    case active                                // ends today or yesterday
    case atRisk(restorableCount: Int, until: Date)   // backfill can restore
}

public struct StreakSummary: Equatable, Sendable {
    public let current: Int
    public let best: Int
    public let status: StreakStatus
    public let isTodayDone: Bool
}

public enum EntryEditability: Equatable, Sendable {
    case editable(until: Date)                 // today, until midnight
    case backfillable(until: Date)             // missing yesterday, until 12:00
    case locked
}

public struct BackfillOffer: Equatable, Sendable {
    public let day: CalendarDay
    public let prompt: Prompt
    public let until: Date
}

public struct TodayState: Equatable, Sendable {
    public let day: CalendarDay
    public let prompt: Prompt                  // frozen prompt if today's entry exists
    public let entry: JournalEntry?
    public let refreshesRemaining: Int         // 0 when entry saved
    public let backfillOffer: BackfillOffer?
    public let streak: StreakSummary
    public let onboardingCompleted: Bool
}

public struct ReminderSettings: Equatable, Codable, Sendable {
    public var isEnabled: Bool
    public var hour: Int, minute: Int          // default 20:00
}

public struct AppSettings: Equatable, Codable, Sendable {
    public var categories: Set<PromptCategory> // never empty
    public var reminder: ReminderSettings
    public var onboardingCompleted: Bool
}

public enum ReminderAuthorization: Sendable { case notDetermined, authorized, denied }

public enum ExportFormat: Sendable { case markdown, plainText }

public struct ExportDocument: Sendable {
    public let fileName: String
    public let contents: String
}

public enum DeepLink: Equatable, Sendable {
    case todayEditor
    case backfillEditor
    public var url: URL { get }
    public init?(url: URL)
}

public enum JournalError: Error, Equatable, Sendable {
    case emptyText
    case entryLocked
    case backfillNotAvailable
    case noRefreshesLeft
    case categoriesEmpty
    case notificationsDenied
    case nothingToExport
}
```

---

## 2. Ports

```swift
public protocol TimeSource: Sendable {
    var now: Date { get }
    var calendar: Calendar { get }             // carries the current time zone
}

public protocol EntryRepository: Sendable {
    func entry(for day: CalendarDay) async throws -> JournalEntry?
    func entries(for day: CalendarDay) async throws -> [JournalEntry]   // >1 only after sync conflicts
    func allEntries() async throws -> [JournalEntry]                    // newest first
    func entryDays() async throws -> Set<CalendarDay>                   // for streaks
    func search(_ query: String) async throws -> [JournalEntry]
    func save(_ entry: JournalEntry) async throws                       // insert or update by id
    func delete(ids: [UUID]) async throws                               // used only by merge
}

public protocol PromptLibrary: Sendable {
    func allPrompts() -> [Prompt]
    func prompt(id: String) -> Prompt?
}

public protocol PromptStateStore: Sendable {
    func state(for day: CalendarDay) -> DailyPromptState?
    func save(_ state: DailyPromptState)
}

public protocol SettingsStore: Sendable {
    func load() -> AppSettings
    func save(_ settings: AppSettings)
}

public protocol ReminderScheduler: Sendable {
    func authorizationStatus() async -> ReminderAuthorization
    func requestAuthorization() async -> Bool
    func scheduleDaily(at hour: Int, minute: Int, skipping days: Set<CalendarDay>,
                       bodyFor: @Sendable (CalendarDay) -> String) async throws
    func cancelAll() async
}

public protocol WidgetRefresher: Sendable {
    func reloadAll()
}
```

---

## 3. Policies (pure)

```swift
public struct PromptSelector: Sendable {
    public init(library: [Prompt])
    /// Deterministic prompt for a day and category set (no refreshes applied).
    public func dailyPrompt(for day: CalendarDay, categories: Set<PromptCategory>,
                            excluding recent: [String]) -> Prompt
    /// Next prompt after `refreshIndex` refreshes, never equal to `current`.
    public func refreshedPrompt(for day: CalendarDay, categories: Set<PromptCategory>,
                                refreshIndex: Int, current: String,
                                excluding recent: [String]) -> Prompt
    public static let maxRefreshesPerDay = 3
}

public struct EntryEditPolicy: Sendable {
    public init(calendar: Calendar)
    public func editability(of day: CalendarDay, hasEntry: Bool, at instant: Date) -> EntryEditability
    public func backfillDeadline(for today: CalendarDay) -> Date          // 12:00 local
}

public struct StreakCalculator: Sendable {
    public init(calendar: Calendar)
    public func summary(entryDays: Set<CalendarDay>, at instant: Date) -> StreakSummary
}

public struct DayEntryMerger: Sendable {
    /// Merges same-day entries into one, keeping all text.
    public func merge(_ entries: [JournalEntry]) -> JournalEntry
}

public struct JournalExporter: Sendable {
    public func export(_ entries: [JournalEntry], as format: ExportFormat,
                       generatedAt: Date) -> ExportDocument
}

public struct EntrySearchMatcher: Sendable {
    public func matches(_ entry: JournalEntry, query: String) -> Bool
}
```

---

## 4. Use Cases (one per action, single `execute`)

| Use case | Signature | Errors |
|---|---|---|
| `GetTodayStateUseCase` | `func execute() async throws -> TodayState` | n/a |
| `RefreshPromptUseCase` | `func execute() async throws -> Prompt` | `noRefreshesLeft`, `entryLocked` (entry already saved) |
| `SaveTodayEntryUseCase` | `func execute(text: String) async throws -> JournalEntry` | `emptyText`, `entryLocked` |
| `BackfillYesterdayUseCase` | `func execute(text: String) async throws -> JournalEntry` | `emptyText`, `backfillNotAvailable` |
| `GetEntryUseCase` | `func execute(day: CalendarDay) async throws -> (JournalEntry, EntryEditability)?` | n/a |
| `ListEntriesUseCase` | `func execute() async throws -> [JournalEntry]` | n/a |
| `SearchEntriesUseCase` | `func execute(query: String) async throws -> [JournalEntry]` | n/a |
| `ExportJournalUseCase` | `func execute(format: ExportFormat) async throws -> ExportDocument` | `nothingToExport` |
| `GetStreakUseCase` | `func execute() async throws -> StreakSummary` | n/a |
| `GetSettingsUseCase` | `func execute() -> AppSettings` | n/a |
| `UpdatePromptCategoriesUseCase` | `func execute(_ categories: Set<PromptCategory>) throws` | `categoriesEmpty` |
| `ConfigureReminderUseCase` | `func execute(_ settings: ReminderSettings) async throws -> ReminderAuthorization` | `notificationsDenied` |
| `SyncReminderWithTodayUseCase` | `func execute() async` | n/a (best effort) |
| `CompleteOnboardingUseCase` | `func execute(categories: Set<PromptCategory>, reminder: ReminderSettings?) async throws` | `categoriesEmpty`, `notificationsDenied` |
| `ReconcileSyncedEntriesUseCase` | `func execute() async throws -> Bool` (true if anything merged) | n/a |

Each use case is a `struct` that receives only the ports and policies it needs, for example:

```swift
public struct SaveTodayEntryUseCase: Sendable {
    public init(time: TimeSource, entries: EntryRepository, prompts: PromptLibrary,
                promptState: PromptStateStore, settings: SettingsStore,
                editPolicy: EntryEditPolicy, reminders: SyncReminderWithTodayUseCase,
                widgets: WidgetRefresher)
    public func execute(text: String) async throws -> JournalEntry
}
```

---

## 5. Data Layer

```swift
public enum PersistenceContext: Sendable { case app, widget }

public enum PersistenceController {
    public static func makeContainer(for context: PersistenceContext) throws -> ModelContainer
    // app: App Group URL + CloudKit .private(containerID); widget: same URL + .none
}

@ModelActor
public actor SwiftDataEntryRepository: EntryRepository { /* maps EntryRecord <-> JournalEntry */ }

public final class BundledPromptLibrary: PromptLibrary {
    public init(bundle: Bundle = .module, resource: String = "prompts") throws
}

public final class AppGroupPromptStateStore: PromptStateStore { public init(defaults: UserDefaults) }
public final class AppGroupSettingsStore: SettingsStore { public init(defaults: UserDefaults) }
public final class UserNotificationReminderScheduler: ReminderScheduler { public init(center: UNUserNotificationCenter = .current()) }
public struct WidgetCenterRefresher: WidgetRefresher { public init() }
public struct SystemTimeSource: TimeSource { public init() }

@MainActor
public final class RemoteChangeObserver {
    public init(container: ModelContainer, onChange: @escaping @Sendable () async -> Void)
    public func start()
}

public struct JournalEnvironmentFactory {
    public static func make(for context: PersistenceContext) throws -> JournalUseCases
}

public struct JournalUseCases: Sendable {   // plain bag of the 15 use cases
    public let getTodayState: GetTodayStateUseCase
    public let refreshPrompt: RefreshPromptUseCase
    // ... one property per use case
}
```

---

## 6. Presentation Entry Points

```swift
// JournalApp
@MainActor @Observable final class AppEnvironment {
    let useCases: JournalUseCases
    var refreshToken: UUID                      // bumped on day change, sync, save
    var pendingDeepLink: DeepLink?
}

// JournalWidget
struct PromptStreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> PromptStreakEntry
    func getSnapshot(in context: Context, completion: @escaping (PromptStreakEntry) -> Void)
    func getTimeline(in context: Context, completion: @escaping (Timeline<PromptStreakEntry>) -> Void)
}
struct PromptStreakEntry: TimelineEntry { let date: Date; let state: TodayState? }
```
