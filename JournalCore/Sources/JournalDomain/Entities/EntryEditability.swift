import Foundation

public enum EntryEditability: Equatable, Sendable {
    /// The day is today; an entry may be created or edited until `until` (next local midnight).
    case editable(until: Date)
    /// The day is yesterday, has no entry, and today's noon deadline has not passed.
    case backfillable(until: Date)
    /// Past days with entries, missed days after the deadline, and future-dated days.
    case locked

    public var isEditable: Bool {
        if case .editable = self { return true }
        return false
    }

    public var isBackfillable: Bool {
        if case .backfillable = self { return true }
        return false
    }
}

public struct BackfillOffer: Equatable, Sendable {
    public let day: CalendarDay
    public let prompt: Prompt
    public let until: Date

    public init(day: CalendarDay, prompt: Prompt, until: Date) {
        self.day = day
        self.prompt = prompt
        self.until = until
    }
}
