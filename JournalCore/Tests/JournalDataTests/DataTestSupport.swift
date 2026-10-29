import Foundation
@testable import JournalData
import JournalDomain

let mexicoCity = TimeZone(identifier: "America/Mexico_City")!

func instant(_ text: String, _ timeZone: TimeZone = mexicoCity) -> Date {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = timeZone
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    return formatter.date(from: text)!
}

func day(_ key: String) -> CalendarDay { CalendarDay(key: key)! }

func entry(
    _ dayKey: String,
    text: String = "Some thoughts",
    promptID: String = "gratitude-001",
    promptText: String = "What small thing made today better?",
    created: String? = nil,
    id: UUID = UUID()
) -> JournalEntry {
    let createdAt = instant(created ?? "\(dayKey) 21:00")
    return JournalEntry(id: id, day: day(dayKey), text: text, promptID: promptID,
                        promptText: promptText, createdAt: createdAt, updatedAt: createdAt)
}

final class TestClock: TimeSource, @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date
    let timeZone: TimeZone
    init(_ now: Date, timeZone: TimeZone = mexicoCity) { current = now; self.timeZone = timeZone }
    var now: Date { lock.withLock { current } }
    func set(_ date: Date) { lock.withLock { current = date } }
}

final class RecordingScheduler: ReminderScheduler, @unchecked Sendable {
    private let lock = NSLock()
    private var _pending: [ScheduledReminder] = []
    var pending: [ScheduledReminder] { lock.withLock { _pending } }
    func authorizationStatus() async -> ReminderAuthorization { .authorized }
    func requestAuthorization() async -> Bool { true }
    func replacePending(with reminders: [ScheduledReminder]) async { lock.withLock { _pending = reminders } }
}

final class CountingRefresher: WidgetRefresher, @unchecked Sendable {
    private let lock = NSLock()
    private var _count = 0
    var count: Int { lock.withLock { _count } }
    func reloadAll() { lock.withLock { _count += 1 } }
}

/// A fresh in-memory repository per test.
func makeRepository() throws -> SwiftDataEntryRepository {
    let container = try PersistenceController.makeContainer(for: .app, configuration: AppConfiguration(), inMemory: true)
    return SwiftDataEntryRepository(modelContainer: container)
}

/// A throwaway UserDefaults suite, removed when `body` finishes.
func withTemporaryDefaults(_ body: (UserDefaults) throws -> Void) rethrows {
    let name = "journal.tests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defer { defaults.removePersistentDomain(forName: name) }
    try body(defaults)
}
