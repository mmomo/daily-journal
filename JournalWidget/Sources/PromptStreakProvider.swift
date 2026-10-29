import Foundation
import JournalData
import JournalDomain
import WidgetKit

struct PromptStreakEntry: TimelineEntry {
    enum Content {
        case ready(TodayState)
        /// Onboarding not finished, or the shared store isn't reachable (e.g. no App Group yet).
        case needsSetup
    }

    let date: Date
    let content: Content
}

/// Clock whose "now" the provider moves to compute future entries with the Domain's own rules.
final class WidgetClock: TimeSource, @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date
    init(_ now: Date) { current = now }
    var now: Date { lock.withLock { current } }
    var timeZone: TimeZone { .autoupdatingCurrent }
    func set(_ date: Date) { lock.withLock { current = date } }
}

/// Timeline: now, plus today's 12:00 cutoff when a backfill offer or at-risk state ends then.
/// Reloads after the next midnight so the new day's prompt is chosen on that day (services.md S7).
struct PromptStreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> PromptStreakEntry {
        PromptStreakEntry(date: .now, content: .ready(.sample))
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (PromptStreakEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        Task {
            let clock = WidgetClock(.now)
            completion(PromptStreakEntry(date: clock.now, content: await Self.content(clock: clock)))
        }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<PromptStreakEntry>) -> Void) {
        Task {
            completion(await Self.timeline(now: .now))
        }
    }

    static func timeline(now: Date) async -> Timeline<PromptStreakEntry> {
        let timeZone = TimeZone.autoupdatingCurrent
        let today = CalendarDay(containing: now, timeZone: timeZone)
        let noon = today.noon(in: timeZone)
        let nextMidnight = today.adding(days: 1).start(in: timeZone)

        let clock = WidgetClock(now)
        guard let useCases = try? JournalEnvironmentFactory.make(for: .widget, time: clock).useCases else {
            return Timeline(entries: [PromptStreakEntry(date: now, content: .needsSetup)], policy: .after(nextMidnight))
        }

        let first = await content(useCases: useCases)
        var entries = [PromptStreakEntry(date: now, content: first)]
        if now < noon, case let .ready(state) = first, state.backfillOffer != nil || isAtRisk(state) {
            clock.set(noon)
            entries.append(PromptStreakEntry(date: noon, content: await content(useCases: useCases)))
        }
        return Timeline(entries: entries, policy: .after(nextMidnight.addingTimeInterval(1)))
    }

    private static func content(clock: WidgetClock) async -> PromptStreakEntry.Content {
        guard let useCases = try? JournalEnvironmentFactory.make(for: .widget, time: clock).useCases else {
            return .needsSetup
        }
        return await content(useCases: useCases)
    }

    private static func content(useCases: JournalUseCases) async -> PromptStreakEntry.Content {
        guard let state = try? await useCases.getTodayState.execute(), state.onboardingCompleted else {
            return .needsSetup
        }
        return .ready(state)
    }

    private static func isAtRisk(_ state: TodayState) -> Bool {
        if case .atRisk = state.streak.status { return true }
        return false
    }
}

extension TodayState {
    /// Gallery placeholder and previews.
    static let sample = TodayState(
        day: CalendarDay(containing: .now, timeZone: .autoupdatingCurrent),
        prompt: Prompt(id: "gratitude-001", category: .gratitude, text: "What small thing made today better?"),
        entry: nil,
        entryEditability: .locked,
        refreshesRemaining: 3,
        backfillOffer: nil,
        streak: StreakSummary(current: 5, best: 12, status: .active, isTodayDone: false),
        onboardingCompleted: true
    )
}
