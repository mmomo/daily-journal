import Foundation
import Testing
@testable import JournalDomain

@Suite("GetTodayStateUseCase")
struct GetTodayStateUseCaseTests {
    @Test func showsPromptWithRefreshesAndBackfillOffer() async throws {  // US-1.1, US-2.3
        let h = TestHarness(now: instant("2026-10-08 09:00"))
        let state = try await h.useCases.getTodayState.execute()
        #expect(state.day == day("2026-10-08"))
        #expect(state.entry == nil)
        #expect(state.refreshesRemaining == 3)
        #expect(state.entryEditability == .editable(until: instant("2026-10-09 00:00")))
        #expect(state.backfillOffer?.day == day("2026-10-07"))
        #expect(state.backfillOffer?.until == instant("2026-10-08 12:00"))
        #expect(state.onboardingCompleted)
    }

    @Test func samePromptOnRelaunchAndInWidget() async throws {  // US-1.2
        let h = TestHarness(now: instant("2026-10-08 08:00"))
        let first = try await h.useCases.getTodayState.execute().prompt
        h.time.set(instant("2026-10-08 21:00"))
        // A second process (the widget) sharing the same App Group stores.
        let widget = JournalUseCases(
            time: h.time, entries: h.entries, prompts: h.library, promptState: h.promptState,
            settings: h.settings, reminders: h.scheduler, widgets: h.widgets
        )
        #expect(try await h.useCases.getTodayState.execute().prompt == first)
        #expect(try await widget.getTodayState.execute().prompt == first)
    }

    @Test func sameInputsGiveSamePromptOnAnotherDevice() async throws {  // US-1.2
        let a = TestHarness(now: instant("2026-10-08 08:00"))
        let b = TestHarness(now: instant("2026-10-08 19:00"))
        #expect(try await a.useCases.getTodayState.execute().prompt == b.useCases.getTodayState.execute().prompt)
    }

    @Test func categoryChangeKeepsTodaysPrompt() async throws {  // US-1.4
        let h = TestHarness(now: instant("2026-10-08 08:00"))
        let before = try await h.useCases.getTodayState.execute().prompt
        let other = PromptCategory.allCases.first { $0 != before.category }!
        try h.useCases.updatePromptCategories.execute([other])
        #expect(try await h.useCases.getTodayState.execute().prompt == before)
        h.time.set(instant("2026-10-09 08:00"))
        #expect(try await h.useCases.getTodayState.execute().prompt.category == other)
    }

    @Test func newDayNewPrompt() async throws {  // US-1.1
        let h = TestHarness(now: instant("2026-10-08 23:00"))
        let before = try await h.useCases.getTodayState.execute()
        h.time.set(instant("2026-10-09 00:01"))
        let after = try await h.useCases.getTodayState.execute()
        #expect(after.day == day("2026-10-09"))
        #expect(after.prompt != before.prompt)
    }

    @Test func doneTodayShowsFrozenPrompt() async throws {  // US-2.1, FR-1.6
        let saved = entry("2026-10-08", promptID: "goals-010", promptText: "Goals prompt number 10?",
                          created: instant("2026-10-08 07:00"))
        let h = TestHarness(now: instant("2026-10-08 09:00"), entries: [saved])
        let state = try await h.useCases.getTodayState.execute()
        #expect(state.entry == saved)
        #expect(state.prompt.id == "goals-010")
        #expect(state.refreshesRemaining == 0)
        #expect(state.isTodayDone)
    }

    @Test func futureDatedEntryCountsAsToday() async throws {  // Q4:B
        let written = entry("2026-10-08", created: instant("2026-10-08 01:00"))
        let h = TestHarness(now: instant("2026-10-07 21:00", .honolulu), timeZone: .honolulu, entries: [written])
        let state = try await h.useCases.getTodayState.execute()
        #expect(state.day == day("2026-10-07"))
        #expect(state.entry == written)
        #expect(state.entryEditability == .locked)
        #expect(state.isTodayDone)
    }

    @Test func noBackfillOfferAfterNoonOrWhenYesterdayExists() async throws {
        let late = TestHarness(now: instant("2026-10-09 12:00"))
        #expect(try await late.useCases.getTodayState.execute().backfillOffer == nil)
        let filled = TestHarness(now: instant("2026-10-09 09:00"), entries: [entry("2026-10-08")])
        #expect(try await filled.useCases.getTodayState.execute().backfillOffer == nil)
    }

    @Test func reportsOnboardingState() async throws {
        let h = TestHarness(now: instant("2026-10-08 09:00"), settings: .default)
        #expect(try await !h.useCases.getTodayState.execute().onboardingCompleted)
    }

    @Test func storageErrorsAreWrapped() async throws {
        let h = TestHarness(now: instant("2026-10-08 09:00"))
        h.entries.failNextCall.set(true)
        await #expect(throws: JournalError.self) { try await h.useCases.getTodayState.execute() }
        h.entries.failNextCall.set(true)
        do {
            _ = try await h.useCases.getTodayState.execute()
            Issue.record("expected failure")
        } catch let error as JournalError {
            guard case .storageFailure = error else { Issue.record("wrong error \(error)"); return }
        }
    }
}

@Suite("RefreshPromptUseCase")
struct RefreshPromptUseCaseTests {
    @Test func refreshShowsDifferentPromptAndPersists() async throws {  // US-1.3
        let h = TestHarness(now: instant("2026-10-08 09:00"))
        let original = try await h.useCases.getTodayState.execute().prompt
        let next = try await h.useCases.refreshPrompt.execute()
        #expect(next != original)
        let state = try await h.useCases.getTodayState.execute()
        #expect(state.prompt == next)
        #expect(state.refreshesRemaining == 2)
        #expect(h.widgets.count.get() == 1)
    }

    @Test func limitOfThreeThenResetsAtMidnight() async throws {  // US-1.3
        let h = TestHarness(now: instant("2026-10-08 09:00"))
        var seen: Set<String> = [try await h.useCases.getTodayState.execute().prompt.id]
        for _ in 1...3 { seen.insert(try await h.useCases.refreshPrompt.execute().id) }
        #expect(seen.count == 4)
        #expect(try await h.useCases.getTodayState.execute().refreshesRemaining == 0)
        await #expect(throws: JournalError.noRefreshesLeft) { try await h.useCases.refreshPrompt.execute() }

        h.time.set(instant("2026-10-09 00:00"))
        #expect(try await h.useCases.getTodayState.execute().refreshesRemaining == 3)
        _ = try await h.useCases.refreshPrompt.execute()
    }

    @Test func noRefreshAfterSaving() async throws {  // US-1.3, BR-P7
        let h = TestHarness(now: instant("2026-10-08 09:00"))
        try await h.useCases.saveTodayEntry.execute(text: "Done", day: day("2026-10-08"))
        await #expect(throws: JournalError.entryLocked) { try await h.useCases.refreshPrompt.execute() }
    }

    @Test func refreshUsesNewCategories() async throws {  // US-1.4
        let h = TestHarness(now: instant("2026-10-08 09:00"))
        _ = try await h.useCases.getTodayState.execute()
        try h.useCases.updatePromptCategories.execute([.creativity])
        #expect(try await h.useCases.refreshPrompt.execute().category == .creativity)
    }
}
