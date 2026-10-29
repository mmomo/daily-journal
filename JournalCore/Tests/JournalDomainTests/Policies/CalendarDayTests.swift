import Foundation
import Testing
@testable import JournalDomain

@Suite("CalendarDay")
struct CalendarDayTests {
    @Test func keyRoundTrip() {
        let d = CalendarDay(year: 2026, month: 10, day: 8)
        #expect(d.key == "2026-10-08")
        #expect(CalendarDay(key: "2026-10-08") == d)
    }

    @Test(arguments: ["2026-02-30", "2026-13-01", "26-10-08", "2026-1-08", "", "2026-10-08x", "abcd-ef-gh"])
    func rejectsMalformedKeys(_ key: String) {
        #expect(CalendarDay(key: key) == nil)
    }

    @Test func dayNumberEpoch() {
        #expect(day("2001-01-01").dayNumber == 0)
        #expect(day("2001-01-02").dayNumber == 1)
        #expect(day("2000-12-31").dayNumber == -1)
    }

    @Test func addingAcrossLeapDayAndYear() {
        #expect(day("2024-02-28").adding(days: 1) == day("2024-02-29"))
        #expect(day("2024-02-28").adding(days: 2) == day("2024-03-01"))
        #expect(day("2026-12-31").adding(days: 1) == day("2027-01-01"))
        #expect(day("2026-03-01").adding(days: -1) == day("2026-02-28"))
    }

    @Test func normalisesOutOfRangeComponents() {
        #expect(CalendarDay(year: 2026, month: 2, day: 30) == day("2026-03-02"))
        #expect(CalendarDay(year: 2026, month: 13, day: 1) == day("2027-01-01"))
    }

    @Test func dayNumberMatchesFoundationOver4000Days() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let startDate = calendar.date(from: DateComponents(year: 1999, month: 1, day: 1))!
        var current = day("1999-01-01")
        for offset in 0..<4000 {
            let date = calendar.date(byAdding: .day, value: offset, to: startDate)!
            let parts = calendar.dateComponents([.year, .month, .day], from: date)
            #expect(current == CalendarDay(year: parts.year!, month: parts.month!, day: parts.day!))
            let next = current.adding(days: 1)
            #expect(next.dayNumber == current.dayNumber + 1)
            current = next
        }
    }

    @Test func containingDependsOnTimeZone() {
        let moment = instant("2026-10-08 22:00", .mexicoCity)
        #expect(CalendarDay(containing: moment, timeZone: .mexicoCity) == day("2026-10-08"))
        #expect(CalendarDay(containing: moment, timeZone: .tokyo) == day("2026-10-09"))
    }

    @Test func ignoresNonGregorianUserCalendars() {
        // Day math always uses the Gregorian calendar (BR-T2), whatever Calendar.current is.
        let moment = instant("2026-10-08 09:00")
        #expect(CalendarDay(containing: moment, timeZone: .mexicoCity).year == 2026)
    }

    @Test func dstFallBackDayIs25Hours() {
        let d = day("2026-11-01")
        let length = d.adding(days: 1).start(in: .newYork).timeIntervalSince(d.start(in: .newYork))
        #expect(length == 25 * 3600)
        #expect(d.noon(in: .newYork) == instant("2026-11-01 12:00", .newYork))
    }

    @Test func dstSpringForwardDayIs23Hours() {
        let d = day("2026-03-08")
        let length = d.adding(days: 1).start(in: .newYork).timeIntervalSince(d.start(in: .newYork))
        #expect(length == 23 * 3600)
    }

    @Test func wallClockTimeInDstGapMovesForward() {
        let d = day("2026-03-08")
        let resolved = DayMath.instant(on: d, hour: 2, minute: 30, in: .newYork)
        #expect(resolved >= instant("2026-03-08 03:00", .newYork))
        #expect(resolved < instant("2026-03-08 04:00", .newYork))
        #expect(CalendarDay(containing: resolved, timeZone: .newYork) == d)
    }

    @Test func ordering() {
        #expect(day("2026-10-07") < day("2026-10-08"))
        #expect([day("2026-10-08"), day("2025-01-01")].sorted() == [day("2025-01-01"), day("2026-10-08")])
    }
}
