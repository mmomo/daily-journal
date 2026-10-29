/// Everything the Today screen and the widget need (services.md S1).
public struct TodayState: Equatable, Sendable {
    public let day: CalendarDay
    /// The entry's frozen prompt when today is done, otherwise this device's current prompt.
    public let prompt: Prompt
    /// Today's entry, or a future-dated entry that counts as today (Q4:B).
    public let entry: JournalEntry?
    public let entryEditability: EntryEditability
    public let refreshesRemaining: Int
    public let backfillOffer: BackfillOffer?
    public let streak: StreakSummary
    public let onboardingCompleted: Bool

    public init(
        day: CalendarDay,
        prompt: Prompt,
        entry: JournalEntry?,
        entryEditability: EntryEditability,
        refreshesRemaining: Int,
        backfillOffer: BackfillOffer?,
        streak: StreakSummary,
        onboardingCompleted: Bool
    ) {
        self.day = day
        self.prompt = prompt
        self.entry = entry
        self.entryEditability = entryEditability
        self.refreshesRemaining = refreshesRemaining
        self.backfillOffer = backfillOffer
        self.streak = streak
        self.onboardingCompleted = onboardingCompleted
    }

    public var isTodayDone: Bool { streak.isTodayDone }
}
