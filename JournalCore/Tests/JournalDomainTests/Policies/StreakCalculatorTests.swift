import Foundation
import Testing
@testable import JournalDomain

@Suite("StreakCalculator")
struct StreakCalculatorTests {
    func summary(_ entryDays: Set<CalendarDay>, at now: String, _ tz: TimeZone = .mexicoCity) -> StreakSummary {
        StreakCalculator.summary(entryDays: entryDays, now: instant(now, tz), timeZone: tz)
    }

    @Test func streakIncludingToday() {  // US-4.1, BR-S1
        let s = summary(days("2026-10-06", "2026-10-07", "2026-10-08"), at: "2026-10-08 21:00")
        #expect(s == StreakSummary(current: 3, best: 3, status: .active, isTodayDone: true))
    }

    @Test func todayNotWrittenYet() {  // US-4.1, BR-S3
        let s = summary(days("2026-10-06", "2026-10-07"), at: "2026-10-08 09:00")
        #expect(s == StreakSummary(current: 2, best: 2, status: .active, isTodayDone: false))
    }

    @Test func noEntries() {
        #expect(summary([], at: "2026-10-08 09:00") == .empty)
    }

    @Test func atRiskBeforeNoon() {  // US-4.2, BR-S4
        let s = summary(days("2026-10-05", "2026-10-06", "2026-10-07"), at: "2026-10-09 09:00")
        #expect(s.current == 3)
        #expect(s.status == .atRisk(restorableCount: 3, until: instant("2026-10-09 12:00")))
        #expect(!s.isTodayDone)
    }

    @Test func backfillRestoresAndTodayExtends() {  // US-4.2
        let restored = summary(days("2026-10-05", "2026-10-06", "2026-10-07", "2026-10-08"), at: "2026-10-09 11:00")
        #expect(restored.current == 4)
        #expect(restored.status == .active)
        let extended = summary(days("2026-10-05", "2026-10-06", "2026-10-07", "2026-10-08", "2026-10-09"), at: "2026-10-09 11:30")
        #expect(extended.current == 5)
    }

    @Test func todayWrittenYesterdayMissingBeforeNoon() {  // US-4.2, BR-S2
        let entryDays = days("2026-10-05", "2026-10-06", "2026-10-07", "2026-10-09")
        let morning = summary(entryDays, at: "2026-10-09 09:00")
        #expect(morning.current == 1)
        #expect(morning.status == .atRisk(restorableCount: 3, until: instant("2026-10-09 12:00")))
        #expect(morning.isTodayDone)
        let afternoon = summary(entryDays, at: "2026-10-09 13:00")
        #expect(afternoon.current == 1)
        #expect(afternoon.status == .active)
    }

    @Test func resetsAtCutoff() {  // US-4.3, BR-S5
        let s = summary(days("2026-10-05", "2026-10-06", "2026-10-07"), at: "2026-10-09 12:00")
        #expect(s == StreakSummary(current: 0, best: 3, status: .none, isTodayDone: false))
    }

    @Test func restartAfterReset() {  // US-4.3
        let s = summary(days("2026-10-05", "2026-10-06", "2026-10-07", "2026-10-09"), at: "2026-10-09 20:00")
        #expect(s.current == 1)
        #expect(s.status == .active)
        #expect(s.best == 3)
    }

    @Test func twoMissedDays() {  // US-4.3
        let s = summary(days("2026-10-06"), at: "2026-10-09 09:00")
        #expect(s.current == 0)
        #expect(s.status == .none)
    }

    @Test func daylightSavingFallBack() {  // US-4.1 DST scenario
        let entryDays = days("2026-10-31", "2026-11-01", "2026-11-02")
        #expect(summary(entryDays, at: "2026-11-02 20:00", .newYork).current == 3)
        #expect(summary(entryDays, at: "2026-11-02 00:30", .newYork).current == 3)
    }

    @Test func bestStreak() {  // US-4.4
        var entryDays = Set((0..<12).map { day("2026-09-01").adding(days: $0) })
        entryDays.formUnion(days("2026-10-05", "2026-10-06", "2026-10-07", "2026-10-08"))
        let s = summary(entryDays, at: "2026-10-08 20:00")
        #expect(s.current == 4)
        #expect(s.best == 12)
    }

    @Test func newRecordRaisesBest() {  // US-4.4
        let thirteen = Set((0..<13).map { day("2026-09-26").adding(days: $0) })
        let s = summary(thirteen, at: "2026-10-08 20:00")
        #expect(s.current == 13)
        #expect(s.best == 13)
    }

    @Test func futureDatedEntryCountsAsToday() {  // Q4:B
        // Wrote 2026-10-08 in Mexico City, flew to Honolulu where it is still 2026-10-07.
        let s = summary(days("2026-10-06", "2026-10-08"), at: "2026-10-07 21:00", .honolulu)
        #expect(s.isTodayDone)
        #expect(s.current == 2)
        #expect(s.status == .active)
    }

    @Test func longestRun() {
        #expect(StreakCalculator.longestRun(in: []) == 0)
        #expect(StreakCalculator.longestRun(in: [1, 2, 3, 7, 8, 10]) == 3)
    }
}
