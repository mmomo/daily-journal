/// Per-device prompt state for one day (Q4:B). Only today's and yesterday's states are kept.
public struct DailyPromptState: Codable, Equatable, Sendable {
    public let day: CalendarDay
    public var promptID: String
    public var refreshesUsed: Int
    /// Every prompt shown that day, in order (daily pick first, then refreshes).
    public var shownPromptIDs: [String]
    /// Category selection in effect when the daily pick was made (diagnostics only).
    public var categoriesKey: String

    public init(day: CalendarDay, promptID: String, refreshesUsed: Int, shownPromptIDs: [String], categoriesKey: String) {
        self.day = day
        self.promptID = promptID
        self.refreshesUsed = refreshesUsed
        self.shownPromptIDs = shownPromptIDs
        self.categoriesKey = categoriesKey
    }
}
