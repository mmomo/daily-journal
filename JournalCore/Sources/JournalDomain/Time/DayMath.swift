import Foundation

/// Calendar helpers. All day arithmetic uses the Gregorian calendar in the device's
/// current time zone, regardless of the user's preferred calendar system (BR-T2).
enum DayMath {
    static func calendar(for timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    static func startOfDay(_ day: CalendarDay, in timeZone: TimeZone) -> Date {
        let calendar = calendar(for: timeZone)
        // Build a mid-day instant (always valid) and let the calendar find the day's first instant.
        let midday = calendar.date(from: DateComponents(year: day.year, month: day.month, day: day.day, hour: 12))!
        return calendar.startOfDay(for: midday)
    }

    /// The instant of `hour:minute` local time on `day`. If a DST gap removes that wall-clock time,
    /// returns the next valid instant (BR-R3).
    static func instant(on day: CalendarDay, hour: Int, minute: Int, in timeZone: TimeZone) -> Date {
        let calendar = calendar(for: timeZone)
        let start = startOfDay(day, in: timeZone)
        if hour == 0 && minute == 0 { return start }
        let match = DateComponents(hour: hour, minute: minute, second: 0)
        guard let found = calendar.nextDate(
            after: start.addingTimeInterval(-1),
            matching: match,
            matchingPolicy: .nextTime,
            direction: .forward
        ) else { return start }
        // A wall-clock time before the day's (late) first instant does not exist on that day;
        // the next valid instant is the start of the day itself.
        let nextStart = startOfDay(day.adding(days: 1), in: timeZone)
        return found < nextStart ? found : start
    }
}
