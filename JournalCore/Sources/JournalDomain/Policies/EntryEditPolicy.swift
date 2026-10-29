import Foundation

/// Decides what may be done with a day's entry at a given instant (BR-E5, BR-E6).
public enum EntryEditPolicy {
    public static func editability(
        of day: CalendarDay,
        hasEntry: Bool,
        now: Date,
        timeZone: TimeZone
    ) -> EntryEditability {
        let today = CalendarDay(containing: now, timeZone: timeZone)
        if day == today {
            return .editable(until: today.adding(days: 1).start(in: timeZone))
        }
        if day == today.adding(days: -1), !hasEntry {
            let deadline = backfillDeadline(today: today, timeZone: timeZone)
            if now < deadline { return .backfillable(until: deadline) }
        }
        return .locked
    }

    /// 12:00 local on `today` (BR-E5 / FR-2.4).
    public static func backfillDeadline(today: CalendarDay, timeZone: TimeZone) -> Date {
        today.noon(in: timeZone)
    }
}
