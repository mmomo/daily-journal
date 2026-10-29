import Foundation
@testable import JournalDomain

/// Small lock-protected box so fakes can be `Sendable` on macOS 14.
final class Locked<Value>: @unchecked Sendable {
    private var value: Value
    private let lock = NSLock()
    init(_ value: Value) { self.value = value }
    func get() -> Value { lock.withLock { value } }
    func set(_ newValue: Value) { lock.withLock { value = newValue } }
    func mutate<R>(_ body: (inout Value) -> R) -> R { lock.withLock { body(&value) } }
}

final class FixedTimeSource: TimeSource, @unchecked Sendable {
    private let state: Locked<(Date, TimeZone)>
    init(_ now: Date, timeZone: TimeZone = .mexicoCity) { state = Locked((now, timeZone)) }
    var now: Date { state.get().0 }
    var timeZone: TimeZone { state.get().1 }
    func set(_ now: Date) { state.mutate { $0.0 = now } }
    func set(timeZone: TimeZone) { state.mutate { $0.1 = timeZone } }
}

final class InMemoryEntryRepository: EntryRepository, @unchecked Sendable {
    private let store = Locked<[JournalEntry]>([])
    var failNextCall = Locked(false)

    init(_ entries: [JournalEntry] = []) { store.set(entries) }

    var all: [JournalEntry] { store.get() }

    private func check() throws {
        if failNextCall.mutate({ let f = $0; $0 = false; return f }) {
            throw NSError(domain: "test", code: 1)
        }
    }

    func entry(for day: CalendarDay) async throws -> JournalEntry? {
        try check()
        return store.get().filter { $0.day == day }.min { ($0.createdAt, $0.id.uuidString) < ($1.createdAt, $1.id.uuidString) }
    }
    func entries(for day: CalendarDay) async throws -> [JournalEntry] {
        try check(); return store.get().filter { $0.day == day }
    }
    func entries(from: CalendarDay, through: CalendarDay) async throws -> [JournalEntry] {
        try check(); return store.get().filter { $0.day >= from && $0.day <= through }
    }
    func entries(after day: CalendarDay) async throws -> [JournalEntry] {
        try check(); return store.get().filter { $0.day > day }
    }
    func allEntries() async throws -> [JournalEntry] {
        try check(); return store.get().sorted { ($0.day, $0.createdAt) > ($1.day, $1.createdAt) }
    }
    func entryDays() async throws -> Set<CalendarDay> {
        try check(); return Set(store.get().map(\.day))
    }
    func search(_ query: String) async throws -> [JournalEntry] {
        try check(); return store.get().filter { EntrySearchMatcher.matches($0, query: query) }
    }
    func duplicateDays() async throws -> [CalendarDay] {
        try check()
        let counts = Dictionary(grouping: store.get(), by: \.day).filter { $0.value.count > 1 }
        return counts.keys.sorted()
    }
    func save(_ entry: JournalEntry) async throws {
        try check()
        store.mutate { list in
            if let i = list.firstIndex(where: { $0.id == entry.id }) { list[i] = entry } else { list.append(entry) }
        }
    }
    func delete(ids: [UUID]) async throws {
        try check(); store.mutate { $0.removeAll { ids.contains($0.id) } }
    }
}

struct InMemoryPromptLibrary: PromptLibrary {
    let prompts: [Prompt]
    init(prompts: [Prompt] = InMemoryPromptLibrary.fixture()) { self.prompts = prompts }

    func allPrompts() -> [Prompt] { prompts }
    func prompt(id: String) -> Prompt? { prompts.first { $0.id == id } }

    /// `perCategory` prompts in each category, ids `<category>-NNN`.
    static func fixture(perCategory: Int = 92) -> [Prompt] {
        PromptCategory.allCases.flatMap { category in
            (1...perCategory).map { i in
                Prompt(
                    id: String(format: "%@-%03d", category.rawValue, i),
                    category: category,
                    text: "\(category.rawValue.capitalized) prompt number \(i)?"
                )
            }
        }
    }
}

final class InMemoryPromptStateStore: PromptStateStore, @unchecked Sendable {
    private let states = Locked<[String: DailyPromptState]>([:])
    func state(for day: CalendarDay) -> DailyPromptState? { states.get()[day.key] }
    func save(_ state: DailyPromptState, keepingFrom: CalendarDay) {
        states.mutate { dict in
            dict[state.day.key] = state
            dict = dict.filter { CalendarDay(key: $0.key).map { $0 >= keepingFrom } ?? false }
        }
    }
    var storedDays: [String] { states.get().keys.sorted() }
}

final class InMemorySettingsStore: SettingsStore, @unchecked Sendable {
    private let settings: Locked<AppSettings>
    init(_ settings: AppSettings = .default) { self.settings = Locked(settings) }
    func load() -> AppSettings { settings.get() }
    func save(_ settings: AppSettings) { self.settings.set(settings) }
}

final class FakeReminderScheduler: ReminderScheduler, @unchecked Sendable {
    let status: Locked<ReminderAuthorization>
    let grantOnRequest: Bool
    let requestCount = Locked(0)
    let pending = Locked<[ScheduledReminder]>([])

    init(status: ReminderAuthorization = .authorized, grantOnRequest: Bool = true) {
        self.status = Locked(status)
        self.grantOnRequest = grantOnRequest
    }
    func authorizationStatus() async -> ReminderAuthorization { status.get() }
    func requestAuthorization() async -> Bool {
        requestCount.mutate { $0 += 1 }
        status.set(grantOnRequest ? .authorized : .denied)
        return grantOnRequest
    }
    func replacePending(with reminders: [ScheduledReminder]) async { pending.set(reminders) }
}

final class SpyWidgetRefresher: WidgetRefresher, @unchecked Sendable {
    let count = Locked(0)
    func reloadAll() { count.mutate { $0 += 1 } }
}
