import Foundation
import Testing
@testable import JournalDomain

@Suite("DayEntryMerger")
struct DayEntryMergerTests {
    let first = entry("2026-10-08", text: "Morning on phone A.", promptID: "gratitude-001",
                      promptText: "What are you grateful for?", created: instant("2026-10-08 08:00"))
    let second = entry("2026-10-08", text: "Evening on phone B.", promptID: "gratitude-001",
                       promptText: "What are you grateful for?", created: instant("2026-10-08 20:00"))

    @Test func keepsBaseAndAppendsWithDivider() {
        let merged = DayEntryMerger.merge([second, first])
        #expect(merged.id == first.id)
        #expect(merged.text == "Morning on phone A.\n\n---\n\nEvening on phone B.")
        #expect(merged.promptID == first.promptID)
        #expect(merged.createdAt == first.createdAt)
        #expect(merged.updatedAt == second.updatedAt)
    }

    @Test func quotesDifferingPrompt() {  // Q1:A
        let other = entry("2026-10-08", text: "Planning the week.", promptID: "goals-004",
                          promptText: "What is one goal for this week?", created: instant("2026-10-08 20:00"))
        let merged = DayEntryMerger.merge([first, other])
        #expect(merged.text == "Morning on phone A.\n\n---\n\n> What is one goal for this week?\n\nPlanning the week.")
    }

    @Test func skipsExactDuplicates() {
        let copy = entry("2026-10-08", text: first.text, promptID: first.promptID,
                         promptText: first.promptText, created: instant("2026-10-08 09:00"))
        #expect(DayEntryMerger.merge([first, copy]).text == first.text)
    }

    @Test func deterministicForAnyOrder() {
        let third = entry("2026-10-08", text: "Third.", created: instant("2026-10-08 12:00"))
        let expected = DayEntryMerger.merge([first, second, third])
        for permutation in [[second, third, first], [third, first, second], [third, second, first]] {
            #expect(DayEntryMerger.merge(permutation) == expected)
        }
    }

    @Test func tieOnCreatedAtBrokenById() {
        let a = entry("2026-10-08", text: "A", created: instant("2026-10-08 08:00"),
                      id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        let b = entry("2026-10-08", text: "B", created: instant("2026-10-08 08:00"),
                      id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!)
        #expect(DayEntryMerger.merge([b, a]).id == a.id)
        #expect(DayEntryMerger.merge([b, a]).text.hasPrefix("A"))
    }

    @Test func idempotent() {
        let merged = DayEntryMerger.merge([first, second])
        #expect(DayEntryMerger.merge([merged]) == merged)
    }
}

@Suite("EntrySearchMatcher")
struct EntrySearchMatcherTests {
    let sample = entry("2026-10-08", text: "A quiet morning at the beach café.",
                       promptText: "What made you feel grateful today?")

    @Test(arguments: ["beach", "BEACH", "cafe", "Café", "quiet morning", "grateful", "  beach  "])
    func matches(_ query: String) {
        #expect(EntrySearchMatcher.matches(sample, query: query))
    }

    @Test(arguments: ["zebra", "morning quiet", "beaches"])
    func doesNotMatch(_ query: String) {
        #expect(!EntrySearchMatcher.matches(sample, query: query))
    }

    @Test func emptyQueryMatchesEverything() {
        #expect(EntrySearchMatcher.matches(sample, query: "   "))
    }
}

@Suite("JournalExporter")
struct JournalExporterTests {
    let entries = [
        entry("2026-10-05", text: "B text", promptText: "P2"),
        entry("2026-10-01", text: "A text", promptText: "P1"),
    ]

    @Test func markdown() {
        let doc = JournalExporter.export(entries, as: .markdown, exportDay: day("2026-10-08"))
        #expect(doc.fileName == "daily-journal-2026-10-08.md")
        #expect(doc.contents == """
        # Daily Journal

        Exported 2026-10-08 · 2 entries

        ## 2026-10-01

        > P1

        A text

        ## 2026-10-05

        > P2

        B text

        """)
    }

    @Test func plainText() {
        let doc = JournalExporter.export(entries, as: .plainText, exportDay: day("2026-10-08"))
        #expect(doc.fileName == "daily-journal-2026-10-08.txt")
        #expect(doc.contents == """
        DAILY JOURNAL
        Exported 2026-10-08 - 2 entries

        2026-10-01
        Prompt: P1

        A text

        ----------------------------------------

        2026-10-05
        Prompt: P2

        B text

        """)
    }

    @Test func singularCount() {
        let doc = JournalExporter.export([entries[0]], as: .markdown, exportDay: day("2026-10-08"))
        #expect(doc.contents.contains("Exported 2026-10-08 · 1 entry\n"))
    }
}

@Suite("ReminderPlanner")
struct ReminderPlannerTests {
    let enabled = ReminderSettings(isEnabled: true, hour: 20, minute: 0)
    let active5 = StreakSummary(current: 5, best: 5, status: .active, isTodayDone: false)

    func plan(_ settings: ReminderSettings, authorized: Bool = true, streak: StreakSummary, at now: String) -> [ScheduledReminder] {
        ReminderPlanner.plan(settings: settings, isAuthorized: authorized, streak: streak,
                             now: instant(now), timeZone: .mexicoCity)
    }

    @Test func disabledOrUnauthorizedClearsAll() {  // BR-R1
        #expect(plan(ReminderSettings(isEnabled: false), streak: active5, at: "2026-10-08 09:00").isEmpty)
        #expect(plan(enabled, authorized: false, streak: active5, at: "2026-10-08 09:00").isEmpty)
    }

    @Test func sevenDayWindowWithStreakTextToday() {  // BR-R2, BR-R4
        let reminders = plan(enabled, streak: active5, at: "2026-10-08 09:00")
        #expect(reminders.count == 7)
        #expect(reminders.first?.identifier == "reminder-2026-10-08")
        #expect(reminders.first?.fireDate == instant("2026-10-08 20:00"))
        #expect(reminders.first?.body == "Your daily prompt is waiting. Keep your 5-day streak going.")
        #expect(reminders.dropFirst().allSatisfy { $0.body == "Your daily prompt is waiting." })
        #expect(reminders.last?.day == day("2026-10-14"))
        #expect(reminders.allSatisfy { $0.deepLink == .todayEditor && $0.title == "Time to journal" })
    }

    @Test func skipsTodayWhenDone() {  // US-6.2
        let done = StreakSummary(current: 6, best: 6, status: .active, isTodayDone: true)
        let reminders = plan(enabled, streak: done, at: "2026-10-08 08:00")
        #expect(reminders.count == 6)
        #expect(reminders.first?.day == day("2026-10-09"))
    }

    @Test func skipsTodayAfterFireTime() {
        let reminders = plan(enabled, streak: active5, at: "2026-10-08 21:00")
        #expect(reminders.count == 6)
        #expect(reminders.first?.day == day("2026-10-09"))
    }

    @Test func noStreakTextWhenAtRiskOrNone() {
        let atRisk = StreakSummary(current: 3, best: 3, status: .atRisk(restorableCount: 3, until: instant("2026-10-08 12:00")), isTodayDone: false)
        #expect(plan(enabled, streak: atRisk, at: "2026-10-08 09:00").first?.body == "Your daily prompt is waiting.")
        #expect(plan(enabled, streak: .empty, at: "2026-10-08 09:00").first?.body == "Your daily prompt is waiting.")
    }
}

@Suite("DeepLink")
struct DeepLinkTests {
    @Test func urls() {
        #expect(DeepLink.todayEditor.url.absoluteString == "dailyjournal://today")
        #expect(DeepLink.backfillEditor.url.absoluteString == "dailyjournal://backfill")
    }

    @Test(arguments: DeepLink.allCases)
    func roundTrip(_ link: DeepLink) {
        #expect(DeepLink(url: link.url) == link)
    }

    @Test func parsing() {
        #expect(DeepLink(url: URL(string: "DailyJournal://TODAY?x=1#y")!) == .todayEditor)
        #expect(DeepLink(url: URL(string: "https://today")!) == nil)
        #expect(DeepLink(url: URL(string: "dailyjournal://settings")!) == nil)
    }
}
