import Foundation

/// Supplies "now" and the device's current time zone. Injected everywhere so tests are deterministic (BR-T1).
public protocol TimeSource: Sendable {
    var now: Date { get }
    var timeZone: TimeZone { get }
}

/// Persistence for journal entries. Implementations must tolerate several entries for one day
/// (possible after iCloud sync) until `ReconcileSyncedEntriesUseCase` merges them.
public protocol EntryRepository: Sendable {
    /// The entry for `day`. If duplicates exist, returns the one with the earliest `createdAt`.
    func entry(for day: CalendarDay) async throws -> JournalEntry?
    /// All entries stored for `day` (more than one only after a sync conflict).
    func entries(for day: CalendarDay) async throws -> [JournalEntry]
    /// Entries with `from <= day <= through`, any order.
    func entries(from: CalendarDay, through: CalendarDay) async throws -> [JournalEntry]
    /// Entries dated after `day` (future-dated entries after westward travel, Q4:B).
    func entries(after day: CalendarDay) async throws -> [JournalEntry]
    /// All entries, newest day first.
    func allEntries() async throws -> [JournalEntry]
    /// The set of days that have at least one entry.
    func entryDays() async throws -> Set<CalendarDay>
    /// Entries whose text or prompt text contains `query` (case- and diacritic-insensitive), newest first.
    func search(_ query: String) async throws -> [JournalEntry]
    /// Days that currently hold more than one entry.
    func duplicateDays() async throws -> [CalendarDay]
    /// Inserts or updates by `id`.
    func save(_ entry: JournalEntry) async throws
    /// Deletes by `id` (used only by merge).
    func delete(ids: [UUID]) async throws
}

/// Read-only access to the bundled prompt library.
public protocol PromptLibrary: Sendable {
    func allPrompts() -> [Prompt]
    func prompt(id: String) -> Prompt?
}

/// Per-device daily prompt state (Q4:B). Implementations keep only today's and yesterday's states.
public protocol PromptStateStore: Sendable {
    func state(for day: CalendarDay) -> DailyPromptState?
    /// Saves `state` and discards states for days before `keepingFrom`.
    func save(_ state: DailyPromptState, keepingFrom: CalendarDay)
}

public protocol SettingsStore: Sendable {
    func load() -> AppSettings
    func save(_ settings: AppSettings)
}

public protocol ReminderScheduler: Sendable {
    func authorizationStatus() async -> ReminderAuthorization
    /// Shows the system permission prompt; returns whether notifications are now allowed.
    func requestAuthorization() async -> Bool
    /// Replaces every pending reminder this app scheduled with `reminders`.
    func replacePending(with reminders: [ScheduledReminder]) async
}

public protocol WidgetRefresher: Sendable {
    func reloadAll()
}
