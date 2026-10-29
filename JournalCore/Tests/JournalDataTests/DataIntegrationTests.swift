import Foundation
import Testing
@testable import JournalData
import JournalDomain

/// Real Data components (in-memory SwiftData, UserDefaults stores, bundled prompts) behind the Domain use cases.
@Suite("Data integration")
struct DataIntegrationTests {
    @Test func dailyFlowEndToEnd() async throws {
        let clock = TestClock(instant("2026-10-08 08:00"))
        let scheduler = RecordingScheduler()
        let widgets = CountingRefresher()
        let env = try JournalEnvironmentFactory.makeInMemory(time: clock, reminders: scheduler, widgets: widgets)
        let useCases = env.useCases

        try await useCases.completeOnboarding.execute(
            categories: [.gratitude, .reflection],
            reminder: ReminderSettings(isEnabled: true, hour: 20, minute: 0)
        )
        #expect(scheduler.pending.first?.day == day("2026-10-08"))

        let today = try await useCases.getTodayState.execute()
        #expect([.gratitude, .reflection].contains(today.prompt.category))
        #expect(today.refreshesRemaining == 3)

        let refreshed = try await useCases.refreshPrompt.execute()
        let saved = try await useCases.saveTodayEntry.execute(text: "Grateful for coffee.", day: today.day)
        #expect(saved.promptID == refreshed.id)
        #expect(scheduler.pending.first?.day == day("2026-10-09"))

        // Next day, morning: streak continues; a missed day later puts it at risk.
        clock.set(instant("2026-10-10 09:00"))
        let atRisk = try await useCases.getTodayState.execute()
        #expect(atRisk.backfillOffer?.day == day("2026-10-09"))
        #expect(atRisk.streak.status == .atRisk(restorableCount: 1, until: instant("2026-10-10 12:00")))

        try await useCases.backfillYesterday.execute(text: "Catching up.", day: day("2026-10-09"))
        try await useCases.saveTodayEntry.execute(text: "Today too.", day: day("2026-10-10"))
        #expect(try await useCases.getStreak.execute().current == 3)

        let export = try await useCases.exportJournal.execute(format: .markdown)
        #expect(export.contents.contains("## 2026-10-08"))
        #expect(export.contents.contains("Catching up."))
        #expect(try await useCases.searchEntries.execute(query: "COFFEE").count == 1)
        #expect(widgets.count > 0)
    }

    @Test func reconcilesDuplicatesInSwiftData() async throws {
        let clock = TestClock(instant("2026-10-08 21:00"))
        let env = try JournalEnvironmentFactory.makeInMemory(time: clock)
        let repo = SwiftDataEntryRepository(modelContainer: env.modelContainer)
        let a = entry("2026-10-08", text: "From phone A", created: "2026-10-08 08:00")
        let b = entry("2026-10-08", text: "From phone B", created: "2026-10-08 20:00")
        try await repo.save(b)
        try await repo.save(a)

        #expect(try await env.useCases.reconcileSyncedEntries.execute())
        let remaining = try await repo.entries(for: day("2026-10-08"))
        #expect(remaining.count == 1)
        #expect(remaining.first?.id == a.id)
        #expect(remaining.first?.text == "From phone A\n\n---\n\nFrom phone B")
        #expect(try await !env.useCases.reconcileSyncedEntries.execute())
    }
}
