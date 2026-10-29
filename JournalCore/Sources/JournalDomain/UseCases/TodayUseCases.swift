import Foundation

/// Builds everything the Today screen and widget show (services.md S1).
public struct GetTodayStateUseCase: Sendable {
    let time: any TimeSource
    let entries: any EntryRepository
    let library: any PromptLibrary
    let settings: any SettingsStore
    let resolver: PromptResolver

    public func execute() async throws -> TodayState {
        let now = time.now
        let timeZone = time.timeZone
        let today = CalendarDay(containing: now, timeZone: timeZone)
        let yesterday = today.adding(days: -1)
        let appSettings = settings.load()

        let todayEntry = try await withStorage { try await entries.entry(for: today) }
        let futureEntry = todayEntry == nil
            ? try await withStorage { try await entries.entries(after: today) }.min { $0.day < $1.day }
            : nil
        let shownEntry = todayEntry ?? futureEntry

        let prompt: Prompt
        let refreshesRemaining: Int
        if let entry = shownEntry {
            prompt = Prompt.answered(by: entry, library: library)
            refreshesRemaining = 0
        } else {
            let resolved = try await resolver.resolve(today)
            prompt = resolved.prompt
            refreshesRemaining = max(0, PromptSelector.maxRefreshesPerDay - resolved.state.refreshesUsed)
        }

        let editability: EntryEditability = futureEntry != nil
            ? .locked
            : EntryEditPolicy.editability(of: today, hasEntry: todayEntry != nil, now: now, timeZone: timeZone)

        let hasYesterday = try await withStorage { try await entries.entry(for: yesterday) } != nil
        var backfillOffer: BackfillOffer?
        if case let .backfillable(until) = EntryEditPolicy.editability(
            of: yesterday, hasEntry: hasYesterday, now: now, timeZone: timeZone
        ) {
            let yesterdayPrompt = try await resolver.resolve(yesterday).prompt
            backfillOffer = BackfillOffer(day: yesterday, prompt: yesterdayPrompt, until: until)
        }

        let entryDays = try await withStorage { try await entries.entryDays() }
        let streak = StreakCalculator.summary(entryDays: entryDays, now: now, timeZone: timeZone)

        return TodayState(
            day: today,
            prompt: prompt,
            entry: shownEntry,
            entryEditability: editability,
            refreshesRemaining: refreshesRemaining,
            backfillOffer: backfillOffer,
            streak: streak,
            onboardingCompleted: appSettings.onboardingCompleted
        )
    }
}

/// Swaps today's prompt, at most 3 times a day (services.md S2, BR-P5–P7).
public struct RefreshPromptUseCase: Sendable {
    let time: any TimeSource
    let entries: any EntryRepository
    let settings: any SettingsStore
    let promptState: any PromptStateStore
    let widgets: any WidgetRefresher
    let resolver: PromptResolver

    @discardableResult
    public func execute() async throws -> Prompt {
        let today = time.today
        let todayEntry = try await withStorage { try await entries.entry(for: today) }
        let futureEntries = try await withStorage { try await entries.entries(after: today) }
        guard todayEntry == nil, futureEntries.isEmpty else { throw JournalError.entryLocked }

        var state = try await resolver.resolve(today).state
        guard state.refreshesUsed < PromptSelector.maxRefreshesPerDay else { throw JournalError.noRefreshesLeft }

        let next = try resolver.selector().refreshedPrompt(
            for: today,
            categories: settings.load().categories,
            refreshNumber: state.refreshesUsed + 1,
            shownToday: state.shownPromptIDs,
            answeredRecently: try await resolver.answeredRecently(before: today)
        )
        state.promptID = next.id
        state.refreshesUsed += 1
        state.shownPromptIDs.append(next.id)
        promptState.save(state, keepingFrom: today.adding(days: -1))
        widgets.reloadAll()
        return next
    }
}
