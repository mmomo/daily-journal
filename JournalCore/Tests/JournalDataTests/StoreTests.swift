import Foundation
import Testing
@testable import JournalData
import JournalDomain
import UserNotifications

@Suite("BundledPromptLibrary")
struct BundledPromptLibraryTests {
    @Test func bundledLibraryLoadsAndIsValid() throws {
        let library = try BundledPromptLibrary()
        let prompts = library.allPrompts()
        #expect(prompts.count == 600)
        for category in PromptCategory.allCases {
            #expect(prompts.filter { $0.category == category }.count == 150)
        }
        #expect(library.prompt(id: "gratitude-001")?.text == "What small thing made today better?")
        #expect(library.prompt(id: "creativity-150") != nil)
        #expect(library.prompt(id: "missing-001") == nil)
    }

    @Test func bundledLibraryGivesNoRepeatsForEveryCategoryAlone() throws {
        let selector = PromptSelector(library: try BundledPromptLibrary().allPrompts())
        for category in PromptCategory.allCases {
            let ids = (0..<150).map { selector.dailyPrompt(for: day("2026-01-01").adding(days: $0), categories: [category]).id }
            #expect(Set(ids).count == 150)
        }
    }

    func prompts(_ count: Int, category: PromptCategory = .goals) -> [Prompt] {
        (1...count).map { Prompt(id: String(format: "%@-%03d", category.rawValue, $0), category: category, text: "Prompt text number \($0)") }
    }

    @Test func validatorRejectsBadData() {
        let ok = prompts(3)
        func validate(_ list: [Prompt]) throws {
            try PromptLibraryValidator.validate(list, minimumPerCategory: 0, minimumTotal: 0)
        }
        #expect(throws: Never.self) { try validate(ok) }
        #expect(throws: PromptLibraryError.duplicateID("goals-001")) { try validate(ok + [ok[0]]) }
        #expect(throws: PromptLibraryError.malformedID("goals-1")) {
            try validate([Prompt(id: "goals-1", category: .goals, text: "Long enough text")])
        }
        #expect(throws: PromptLibraryError.categoryMismatch("goals-001")) {
            try validate([Prompt(id: "goals-001", category: .gratitude, text: "Long enough text")])
        }
        #expect(throws: PromptLibraryError.textLength("goals-001")) {
            try validate([Prompt(id: "goals-001", category: .goals, text: "Short")])
        }
        #expect(throws: PromptLibraryError.duplicateText("goals-002")) {
            try validate([ok[0], Prompt(id: "goals-002", category: .goals, text: ok[0].text.uppercased())])
        }
        #expect(throws: PromptLibraryError.tooFewPrompts(category: "gratitude", count: 0)) {
            try PromptLibraryValidator.validate(ok)
        }
    }

    @Test func rejectsUnsupportedVersion() {
        let data = Data(#"{"version": 2, "prompts": []}"#.utf8)
        #expect(throws: PromptLibraryError.unsupportedVersion(2)) { try BundledPromptLibrary(data: data) }
    }
}

@Suite("App Group stores")
struct AppGroupStoresTests {
    @Test func settingsDefaultRoundTripAndCorruptFallback() {
        withTemporaryDefaults { defaults in
            let store = AppGroupSettingsStore(defaults: defaults)
            #expect(store.load() == .default)
            let custom = AppSettings(categories: [.goals], reminder: ReminderSettings(isEnabled: true, hour: 7, minute: 30), onboardingCompleted: true)
            store.save(custom)
            #expect(AppGroupSettingsStore(defaults: defaults).load() == custom)
            defaults.set(Data("not json".utf8), forKey: AppGroupSettingsStore.key)
            #expect(store.load() == .default)
        }
    }

    @Test func promptStateRoundTripAndPruning() {
        withTemporaryDefaults { defaults in
            let store = AppGroupPromptStateStore(defaults: defaults)
            func state(_ key: String) -> DailyPromptState {
                DailyPromptState(day: day(key), promptID: "goals-001", refreshesUsed: 1,
                                 shownPromptIDs: ["goals-002", "goals-001"], categoriesKey: "goals")
            }
            store.save(state("2026-10-07"), keepingFrom: day("2026-10-06"))
            store.save(state("2026-10-08"), keepingFrom: day("2026-10-07"))
            #expect(store.state(for: day("2026-10-07")) == state("2026-10-07"))
            store.save(state("2026-10-09"), keepingFrom: day("2026-10-08"))
            #expect(store.state(for: day("2026-10-07")) == nil)
            #expect(store.state(for: day("2026-10-08")) == state("2026-10-08"))
            #expect(AppGroupPromptStateStore(defaults: defaults).state(for: day("2026-10-09")) == state("2026-10-09"))
        }
    }

    @Test func configurationDefaults() {
        let config = AppConfiguration.fromBundle(Bundle(for: CountingRefresher.self))
        #expect(config == AppConfiguration())
        #expect(!config.cloudKitEnabled)
    }
}

@Suite("ReminderRequestBuilder")
struct ReminderRequestBuilderTests {
    @Test func buildsCalendarRequestWithDeepLink() throws {
        let reminder = ScheduledReminder(
            identifier: "reminder-2026-10-08", day: day("2026-10-08"), fireDate: instant("2026-10-08 20:00"),
            title: "Time to journal", body: "Your daily prompt is waiting.", deepLink: .todayEditor
        )
        let request = ReminderRequestBuilder.request(for: reminder, timeZone: mexicoCity)
        #expect(request.identifier == "reminder-2026-10-08")
        #expect(request.content.title == "Time to journal")
        #expect(request.content.body == "Your daily prompt is waiting.")
        #expect(ReminderRequestBuilder.deepLink(from: request.content.userInfo) == .todayEditor)
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(!trigger.repeats)
        #expect(trigger.dateComponents.year == 2026)
        #expect(trigger.dateComponents.month == 10)
        #expect(trigger.dateComponents.day == 8)
        #expect(trigger.dateComponents.hour == 20)
        #expect(trigger.dateComponents.minute == 0)
    }

    @Test func authorizationMapping() {
        #expect(ReminderRequestBuilder.authorization(from: .notDetermined) == .notDetermined)
        #expect(ReminderRequestBuilder.authorization(from: .denied) == .denied)
        #expect(ReminderRequestBuilder.authorization(from: .authorized) == .authorized)
        #expect(ReminderRequestBuilder.authorization(from: .provisional) == .authorized)
    }

    @Test func ignoresForeignUserInfo() {
        #expect(ReminderRequestBuilder.deepLink(from: [:]) == nil)
        #expect(ReminderRequestBuilder.deepLink(from: ["deepLink": "https://example.com"]) == nil)
    }
}
