import Foundation

/// A civil (Gregorian) date that identifies a journal day independently of any time zone.
///
/// Entries keep the `CalendarDay` they were written on; it is never recomputed from timestamps,
/// so travelling across time zones does not move an entry to another day (BR-T3).
public struct CalendarDay: Hashable, Comparable, Codable, Sendable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    /// Creates a day from its components. Out-of-range components are normalised
    /// (e.g. 2026-02-30 becomes 2026-03-02), so the value is always a valid date.
    public init(year: Int, month: Int, day: Int) {
        let normalised = CalendarDay.civil(fromDayNumber: CalendarDay.dayNumber(year: year, month: month, day: day))
        self.year = normalised.year
        self.month = normalised.month
        self.day = normalised.day
    }

    private init(validYear: Int, month: Int, day: Int) {
        self.year = validYear
        self.month = month
        self.day = day
    }

    /// The Gregorian day containing `instant` in `timeZone` (BR-T2).
    public init(containing instant: Date, timeZone: TimeZone) {
        let parts = DayMath.calendar(for: timeZone).dateComponents([.year, .month, .day], from: instant)
        self.init(validYear: parts.year!, month: parts.month!, day: parts.day!)
    }

    /// Parses a `YYYY-MM-DD` key. Returns `nil` for anything malformed or not a real date.
    public init?(key: String) {
        let pieces = key.split(separator: "-", omittingEmptySubsequences: false)
        guard pieces.count == 3,
              pieces[0].count == 4, pieces[1].count == 2, pieces[2].count == 2,
              let y = Int(pieces[0]), let m = Int(pieces[1]), let d = Int(pieces[2]),
              (1...12).contains(m), d >= 1, d <= CalendarDay.daysInMonth(year: y, month: m)
        else { return nil }
        self.init(validYear: y, month: m, day: d)
    }

    /// Days since 2001-01-01 (which is day 0). Pure integer arithmetic; no time zones involved.
    public var dayNumber: Int {
        CalendarDay.dayNumber(year: year, month: month, day: day)
    }

    /// Stable storage key, e.g. `2026-10-08`.
    public var key: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    public var description: String { key }

    /// Moves by whole calendar days; never uses time intervals, so DST cannot shift it (BR-T4).
    public func adding(days: Int) -> CalendarDay {
        let c = CalendarDay.civil(fromDayNumber: dayNumber + days)
        return CalendarDay(validYear: c.year, month: c.month, day: c.day)
    }

    /// First instant of this day in `timeZone` (handles days that do not start at 00:00).
    public func start(in timeZone: TimeZone) -> Date {
        DayMath.startOfDay(self, in: timeZone)
    }

    /// 12:00 local on this day, or the next valid instant if a DST gap removes it.
    public func noon(in timeZone: TimeZone) -> Date {
        DayMath.instant(on: self, hour: 12, minute: 0, in: timeZone)
    }

    public static func < (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        lhs.dayNumber < rhs.dayNumber
    }

    // MARK: - Civil date arithmetic (H. Hinnant's days_from_civil / civil_from_days)

    private static let epochOffset = daysFromCivil(year: 2001, month: 1, day: 1)

    static func dayNumber(year: Int, month: Int, day: Int) -> Int {
        // Normalise month overflow before converting.
        let monthIndex = month - 1
        let y = year + Int((Double(monthIndex) / 12).rounded(.down))
        let m = ((monthIndex % 12) + 12) % 12 + 1
        return daysFromCivil(year: y, month: m, day: 1) + (day - 1) - epochOffset
    }

    static func civil(fromDayNumber number: Int) -> (year: Int, month: Int, day: Int) {
        civilFromDays(number + epochOffset)
    }

    /// Days since 1970-01-01 for a proleptic Gregorian date.
    private static func daysFromCivil(year: Int, month: Int, day: Int) -> Int {
        let y = month <= 2 ? year - 1 : year
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let mp = (month + 9) % 12
        let doy = (153 * mp + 2) / 5 + day - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146_097 + doe - 719_468
    }

    private static func civilFromDays(_ days: Int) -> (year: Int, month: Int, day: Int) {
        let z = days + 719_468
        let era = (z >= 0 ? z : z - 146_096) / 146_097
        let doe = z - era * 146_097
        let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365
        let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
        let mp = (5 * doy + 2) / 153
        let d = doy - (153 * mp + 2) / 5 + 1
        let m = mp < 10 ? mp + 3 : mp - 9
        let y = yoe + era * 400 + (m <= 2 ? 1 : 0)
        return (y, m, d)
    }

    static func daysInMonth(year: Int, month: Int) -> Int {
        dayNumber(year: year, month: month + 1, day: 1) - dayNumber(year: year, month: month, day: 1)
    }
}
