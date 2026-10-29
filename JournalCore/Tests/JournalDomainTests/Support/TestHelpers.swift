import Foundation
@testable import JournalDomain

extension TimeZone {
    static let mexicoCity = TimeZone(identifier: "America/Mexico_City")!
    static let newYork = TimeZone(identifier: "America/New_York")!
    static let tokyo = TimeZone(identifier: "Asia/Tokyo")!
    static let honolulu = TimeZone(identifier: "Pacific/Honolulu")!
}

/// `"2026-10-08 09:00"` (optionally with seconds) in `timeZone`.
func instant(_ text: String, _ timeZone: TimeZone = .mexicoCity) -> Date {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = timeZone
    formatter.dateFormat = text.count > 16 ? "yyyy-MM-dd HH:mm:ss" : "yyyy-MM-dd HH:mm"
    guard let date = formatter.date(from: text) else { fatalError("Bad test date \(text)") }
    return date
}

/// `"2026-10-08"` as a CalendarDay.
func day(_ key: String) -> CalendarDay {
    guard let day = CalendarDay(key: key) else { fatalError("Bad test day \(key)") }
    return day
}

func days(_ keys: String...) -> Set<CalendarDay> { Set(keys.map(day)) }

func entry(
    _ dayKey: String,
    text: String = "Some thoughts",
    promptID: String = "gratitude-001",
    promptText: String = "Gratitude prompt number 1?",
    created: Date? = nil,
    id: UUID = UUID()
) -> JournalEntry {
    let createdAt = created ?? instant("\(dayKey) 21:00")
    return JournalEntry(
        id: id, day: day(dayKey), text: text, promptID: promptID, promptText: promptText,
        createdAt: createdAt, updatedAt: createdAt
    )
}

/// Everything a use case test needs, wired like production.
struct TestHarness {
    let time: FixedTimeSource
    let entries: InMemoryEntryRepository
    let library: InMemoryPromptLibrary
    let promptState: InMemoryPromptStateStore
    let settings: InMemorySettingsStore
    let scheduler: FakeReminderScheduler
    let widgets: SpyWidgetRefresher
    let useCases: JournalUseCases

    init(
        now: Date,
        timeZone: TimeZone = .mexicoCity,
        entries: [JournalEntry] = [],
        settings: AppSettings = AppSettings(onboardingCompleted: true),
        scheduler: FakeReminderScheduler = FakeReminderScheduler()
    ) {
        time = FixedTimeSource(now, timeZone: timeZone)
        self.entries = InMemoryEntryRepository(entries)
        library = InMemoryPromptLibrary()
        promptState = InMemoryPromptStateStore()
        self.settings = InMemorySettingsStore(settings)
        self.scheduler = scheduler
        widgets = SpyWidgetRefresher()
        useCases = JournalUseCases(
            time: time, entries: self.entries, prompts: library, promptState: promptState,
            settings: self.settings, reminders: scheduler, widgets: widgets
        )
    }
}
