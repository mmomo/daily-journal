import Foundation
import Testing
@testable import JournalDomain

private let enabledReminder = AppSettings(reminder: ReminderSettings(isEnabled: true, hour: 20, minute: 0), onboardingCompleted: true)

@Suite("SaveTodayEntryUseCase")
struct SaveTodayEntryUseCaseTests {
    @Test func savesWithTodaysPromptAndSideEffects() async throws {  // US-2.1, US-6.2
        let h = TestHarness(now: instant("2026-10-08 08:00"), settings: enabledReminder)
        let prompt = try await h.useCases.getTodayState.execute().prompt
        let saved = try await h.useCases.saveTodayEntry.execute(text: "Grateful for a quiet morning.", day: day("2026-10-08"))
        #expect(saved.day == day("2026-10-08"))
        #expect(saved.promptID == prompt.id)
        #expect(saved.promptText == prompt.text)
        #expect(h.entries.all == [saved])
        #expect(h.widgets.count.get() == 1)
        #expect(h.scheduler.pending.get().first?.day == day("2026-10-09"))
        #expect(try await h.useCases.getTodayState.execute().isTodayDone)
    }

    @Test(arguments: ["", "   ", "\n\t "])
    func rejectsEmptyText(_ text: String) async {  // US-2.1
        let h = TestHarness(now: instant("2026-10-08 08:00"))
        await #expect(throws: JournalError.emptyText) {
            try await h.useCases.saveTodayEntry.execute(text: text, day: day("2026-10-08"))
        }
    }

    @Test func updatesSameEntryDuringTheDay() async throws {  // US-2.2
        let h = TestHarness(now: instant("2026-10-08 08:00"))
        let first = try await h.useCases.saveTodayEntry.execute(text: "Morning.", day: day("2026-10-08"))
        h.time.set(instant("2026-10-08 22:00"))
        let second = try await h.useCases.saveTodayEntry.execute(text: "Morning. And evening.", day: day("2026-10-08"))
        #expect(second.id == first.id)
        #expect(second.createdAt == first.createdAt)
        #expect(second.updatedAt == instant("2026-10-08 22:00"))
        #expect(h.entries.all.count == 1)
        #expect(h.entries.all.first?.text == "Morning. And evening.")
    }

    @Test func rejectsSaveAfterMidnight() async throws {  // US-2.2 typing across midnight
        let h = TestHarness(now: instant("2026-10-08 23:59:30"))
        try await h.useCases.saveTodayEntry.execute(text: "Before midnight", day: day("2026-10-08"))
        h.time.set(instant("2026-10-09 00:00:10"))
        await #expect(throws: JournalError.entryLocked) {
            try await h.useCases.saveTodayEntry.execute(text: "After midnight", day: day("2026-10-08"))
        }
        #expect(h.entries.all.first?.text == "Before midnight")
        #expect(h.entries.all.count == 1)
    }

    @Test func savesRefreshedPrompt() async throws {  // US-2.1 prompt frozen
        let h = TestHarness(now: instant("2026-10-08 08:00"))
        let refreshed = try await h.useCases.refreshPrompt.execute()
        let saved = try await h.useCases.saveTodayEntry.execute(text: "Answer", day: day("2026-10-08"))
        #expect(saved.promptID == refreshed.id)
    }

    @Test func blockedByFutureDatedEntry() async {  // Q4:B
        let h = TestHarness(now: instant("2026-10-07 21:00", .honolulu), timeZone: .honolulu,
                            entries: [entry("2026-10-08", created: instant("2026-10-08 01:00"))])
        await #expect(throws: JournalError.entryLocked) {
            try await h.useCases.saveTodayEntry.execute(text: "New", day: day("2026-10-07"))
        }
    }
}

@Suite("BackfillYesterdayUseCase")
struct BackfillYesterdayUseCaseTests {
    @Test func backfillsWithYesterdaysShownPrompt() async throws {  // US-2.3, Q6:A
        let h = TestHarness(now: instant("2026-10-08 10:00"))
        let shownYesterday = try await h.useCases.refreshPrompt.execute()
        h.time.set(instant("2026-10-09 11:30"))
        let saved = try await h.useCases.backfillYesterday.execute(text: "Late thoughts", day: day("2026-10-08"))
        #expect(saved.day == day("2026-10-08"))
        #expect(saved.promptID == shownYesterday.id)
        #expect(saved.createdAt == instant("2026-10-09 11:30"))
        #expect(h.widgets.count.get() == 2)
    }

    @Test func usesDeterministicPromptWhenNeverShown() async throws {
        let h = TestHarness(now: instant("2026-10-09 09:00"))
        let saved = try await h.useCases.backfillYesterday.execute(text: "Late", day: day("2026-10-08"))
        let expected = PromptSelector(library: h.library.prompts)
            .dailyPrompt(for: day("2026-10-08"), categories: Set(PromptCategory.allCases))
        #expect(saved.promptID == expected.id)
    }

    @Test func windowClosesAtNoon() async {  // US-2.3
        let h = TestHarness(now: instant("2026-10-09 12:00"))
        await #expect(throws: JournalError.backfillNotAvailable) {
            try await h.useCases.backfillYesterday.execute(text: "Too late", day: day("2026-10-08"))
        }
    }

    @Test func notAllowedWhenYesterdayExistsOrForOlderDays() async {  // US-2.3, BR-E9
        let h = TestHarness(now: instant("2026-10-09 09:00"), entries: [entry("2026-10-08")])
        await #expect(throws: JournalError.backfillNotAvailable) {
            try await h.useCases.backfillYesterday.execute(text: "Again", day: day("2026-10-08"))
        }
        await #expect(throws: JournalError.backfillNotAvailable) {
            try await h.useCases.backfillYesterday.execute(text: "Older", day: day("2026-10-07"))
        }
    }

    @Test func restoresAtRiskStreak() async throws {  // US-4.2
        let h = TestHarness(now: instant("2026-10-09 09:00"),
                            entries: [entry("2026-10-05"), entry("2026-10-06"), entry("2026-10-07")])
        #expect(try await h.useCases.getStreak.execute().status
                == .atRisk(restorableCount: 3, until: instant("2026-10-09 12:00")))
        try await h.useCases.backfillYesterday.execute(text: "Saved it", day: day("2026-10-08"))
        #expect(try await h.useCases.getStreak.execute().current == 4)
        try await h.useCases.saveTodayEntry.execute(text: "And today", day: day("2026-10-09"))
        #expect(try await h.useCases.getStreak.execute().current == 5)
    }
}

@Suite("History use cases")
struct HistoryUseCaseTests {
    let samples = [
        entry("2026-10-01", text: "A day at the beach"),
        entry("2026-10-08", text: "Coffee at a café", promptText: "What made you feel grateful?"),
        entry("2026-10-05", text: "Long walk"),
    ]

    @Test func getEntryEditability() async throws {  // US-2.4
        let h = TestHarness(now: instant("2026-10-08 09:00"), entries: samples)
        #expect(try await h.useCases.getEntry.execute(day: day("2026-10-05"))?.editability == .locked)
        #expect(try await h.useCases.getEntry.execute(day: day("2026-10-08"))?.editability.isEditable == true)
        #expect(try await h.useCases.getEntry.execute(day: day("2026-10-03")) == nil)
    }

    @Test func listNewestFirstAndStableAcrossTimeZones() async throws {  // US-3.1
        let h = TestHarness(now: instant("2026-10-08 22:00"), entries: samples)
        let list = try await h.useCases.listEntries.execute()
        #expect(list.map(\.day.key) == ["2026-10-08", "2026-10-05", "2026-10-01"])
        h.time.set(timeZone: .tokyo)
        #expect(try await h.useCases.listEntries.execute().map(\.day.key) == ["2026-10-08", "2026-10-05", "2026-10-01"])
    }

    @Test func search() async throws {  // US-3.2
        let h = TestHarness(now: instant("2026-10-08 22:00"), entries: samples)
        #expect(try await h.useCases.searchEntries.execute(query: "beach").map(\.day.key) == ["2026-10-01"])
        #expect(try await h.useCases.searchEntries.execute(query: "grateful").map(\.day.key) == ["2026-10-08"])
        #expect(try await h.useCases.searchEntries.execute(query: "cafe").map(\.day.key) == ["2026-10-08"])
        #expect(try await h.useCases.searchEntries.execute(query: "zebra").isEmpty)
        #expect(try await h.useCases.searchEntries.execute(query: "  ").count == 3)
    }

    @Test func export() async throws {  // US-3.3
        let empty = TestHarness(now: instant("2026-10-08 22:00"))
        await #expect(throws: JournalError.nothingToExport) { try await empty.useCases.exportJournal.execute(format: .markdown) }
        let h = TestHarness(now: instant("2026-10-08 22:00"), entries: samples)
        let doc = try await h.useCases.exportJournal.execute(format: .plainText)
        #expect(doc.fileName == "daily-journal-2026-10-08.txt")
        #expect(doc.contents.hasPrefix("DAILY JOURNAL\nExported 2026-10-08 - 3 entries\n\n2026-10-01\n"))
    }
}

@Suite("ReconcileSyncedEntriesUseCase")
struct ReconcileSyncedEntriesUseCaseTests {
    @Test func mergesDuplicatesOnce() async throws {  // US-2.6
        let a = entry("2026-10-08", text: "From phone A", created: instant("2026-10-08 08:00"))
        let b = entry("2026-10-08", text: "From phone B", created: instant("2026-10-08 20:00"))
        let h = TestHarness(now: instant("2026-10-08 21:00"), entries: [b, a, entry("2026-10-07")])
        #expect(try await h.useCases.reconcileSyncedEntries.execute())
        let today = h.entries.all.filter { $0.day == day("2026-10-08") }
        #expect(today.count == 1)
        #expect(today.first?.id == a.id)
        #expect(today.first?.text == "From phone A\n\n---\n\nFrom phone B")
        #expect(h.entries.all.count == 2)
        #expect(h.widgets.count.get() == 1)
        #expect(try await !h.useCases.reconcileSyncedEntries.execute())
        #expect(h.widgets.count.get() == 1)
    }
}
