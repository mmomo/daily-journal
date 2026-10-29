import Foundation

/// Computes the streak from the set of entry days (BR-S1–S8). Pure; never stored.
public enum StreakCalculator {
    public static func summary(entryDays: Set<CalendarDay>, now: Date, timeZone: TimeZone) -> StreakSummary {
        let today = CalendarDay(containing: now, timeZone: timeZone)
        let yesterday = today.adding(days: -1)
        let dayBefore = today.adding(days: -2)
        let noon = today.noon(in: timeZone)
        let beforeNoon = now < noon

        // Q4:B: future-dated entries count as today.
        var days = Set(entryDays.lazy.filter { $0 <= today }.map(\.dayNumber))
        if entryDays.contains(where: { $0 > today }) { days.insert(today.dayNumber) }

        func run(endingAt day: CalendarDay) -> Int {
            var count = 0
            var cursor = day.dayNumber
            while days.contains(cursor) {
                count += 1
                cursor -= 1
            }
            return count
        }

        let todayDone = days.contains(today.dayNumber)
        let yesterdayDone = days.contains(yesterday.dayNumber)
        let current: Int
        let status: StreakStatus

        if todayDone {
            let restorable = run(endingAt: dayBefore)
            if !yesterdayDone, beforeNoon, restorable > 0 {
                current = 1                                                        // BR-S2
                status = .atRisk(restorableCount: restorable, until: noon)
            } else {
                current = run(endingAt: today)                                     // BR-S1
                status = .active
            }
        } else if yesterdayDone {
            current = run(endingAt: yesterday)                                     // BR-S3
            status = .active
        } else if beforeNoon, case let restorable = run(endingAt: dayBefore), restorable > 0 {
            current = restorable                                                   // BR-S4
            status = .atRisk(restorableCount: restorable, until: noon)
        } else {
            current = 0                                                            // BR-S5
            status = .none
        }

        let best = max(longestRun(in: days), current)                             // BR-S6
        return StreakSummary(current: current, best: best, status: status, isTodayDone: todayDone)
    }

    static func longestRun(in dayNumbers: Set<Int>) -> Int {
        var best = 0
        var length = 0
        var previous: Int?
        for number in dayNumbers.sorted() {
            length = (previous.map { number == $0 + 1 } ?? false) ? length + 1 : 1
            best = max(best, length)
            previous = number
        }
        return best
    }
}
