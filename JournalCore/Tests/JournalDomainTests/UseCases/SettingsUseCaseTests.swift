import Foundation
import Testing
@testable import JournalDomain

@Suite("Settings and reminder use cases")
struct SettingsUseCaseTests {
    @Test func categoriesMustNotBeEmpty() async {  // US-1.4
        let h = TestHarness(now: instant("2026-10-08 09:00"))
        #expect(throws: JournalError.categoriesEmpty) { try h.useCases.updatePromptCategories.execute([]) }
        #expect(h.useCases.getSettings.execute().categories == Set(PromptCategory.allCases))
    }

    @Test func savesCategoriesAndReloadsWidget() throws {
        let h = TestHarness(now: instant("2026-10-08 09:00"))
        try h.useCases.updatePromptCategories.execute([.gratitude, .reflection])
        #expect(h.useCases.getSettings.execute().categories == [.gratitude, .reflection])
        #expect(h.widgets.count.get() == 1)
    }

    @Test func enablingRequestsPermissionAndSchedules() async throws {  // US-6.1
        let scheduler = FakeReminderScheduler(status: .notDetermined, grantOnRequest: true)
        let h = TestHarness(now: instant("2026-10-08 09:00"), scheduler: scheduler)
        let status = try await h.useCases.configureReminder.execute(ReminderSettings(isEnabled: true, hour: 20, minute: 0))
        #expect(status == .authorized)
        #expect(scheduler.requestCount.get() == 1)
        #expect(h.useCases.getSettings.execute().reminder.isEnabled)
        #expect(scheduler.pending.get().count == 7)
    }

    @Test func deniedPermissionTurnsReminderOff() async {  // US-6.1
        let scheduler = FakeReminderScheduler(status: .notDetermined, grantOnRequest: false)
        let h = TestHarness(now: instant("2026-10-08 09:00"), scheduler: scheduler)
        await #expect(throws: JournalError.notificationsDenied) {
            try await h.useCases.configureReminder.execute(ReminderSettings(isEnabled: true, hour: 20, minute: 0))
        }
        #expect(!h.useCases.getSettings.execute().reminder.isEnabled)
        #expect(scheduler.pending.get().isEmpty)
    }

    @Test func changingTimeAndTurningOff() async throws {  // US-6.1
        let h = TestHarness(now: instant("2026-10-08 06:00"))
        try await h.useCases.configureReminder.execute(ReminderSettings(isEnabled: true, hour: 7, minute: 30))
        #expect(h.scheduler.pending.get().first?.fireDate == instant("2026-10-08 07:30"))
        try await h.useCases.configureReminder.execute(ReminderSettings(isEnabled: false, hour: 7, minute: 30))
        #expect(h.scheduler.pending.get().isEmpty)
    }

    @Test func reminderSkipsTodayOnceDone() async throws {  // US-6.2
        let h = TestHarness(now: instant("2026-10-08 08:00"))
        try await h.useCases.configureReminder.execute(ReminderSettings(isEnabled: true, hour: 20, minute: 0))
        #expect(h.scheduler.pending.get().first?.day == day("2026-10-08"))
        try await h.useCases.saveTodayEntry.execute(text: "Done early", day: day("2026-10-08"))
        #expect(h.scheduler.pending.get().first?.day == day("2026-10-09"))
        #expect(h.scheduler.pending.get().count == 6)
    }

    @Test func onboardingWithoutReminderNeverAsksPermission() async throws {  // US-7.1, FR-6.3
        let scheduler = FakeReminderScheduler(status: .notDetermined)
        let h = TestHarness(now: instant("2026-10-08 09:00"), settings: .default, scheduler: scheduler)
        try await h.useCases.completeOnboarding.execute(categories: [.goals], reminder: nil)
        let settings = h.useCases.getSettings.execute()
        #expect(settings.onboardingCompleted)
        #expect(settings.categories == [.goals])
        #expect(scheduler.requestCount.get() == 0)
        #expect(h.widgets.count.get() == 1)
    }

    @Test func onboardingCompletesEvenIfPermissionDenied() async {  // BR-G4
        let scheduler = FakeReminderScheduler(status: .notDetermined, grantOnRequest: false)
        let h = TestHarness(now: instant("2026-10-08 09:00"), settings: .default, scheduler: scheduler)
        await #expect(throws: JournalError.notificationsDenied) {
            try await h.useCases.completeOnboarding.execute(
                categories: [.goals], reminder: ReminderSettings(isEnabled: true, hour: 21, minute: 0))
        }
        #expect(h.useCases.getSettings.execute().onboardingCompleted)
        #expect(!h.useCases.getSettings.execute().reminder.isEnabled)
    }

    @Test func onboardingRequiresCategories() async {
        let h = TestHarness(now: instant("2026-10-08 09:00"), settings: .default)
        await #expect(throws: JournalError.categoriesEmpty) {
            try await h.useCases.completeOnboarding.execute(categories: [], reminder: nil)
        }
        #expect(!h.useCases.getSettings.execute().onboardingCompleted)
    }
}
