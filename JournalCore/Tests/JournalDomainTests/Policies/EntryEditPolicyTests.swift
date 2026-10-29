import Foundation
import Testing
@testable import JournalDomain

@Suite("EntryEditPolicy")
struct EntryEditPolicyTests {
    let tz = TimeZone.mexicoCity

    func editability(_ dayKey: String, hasEntry: Bool, at now: String) -> EntryEditability {
        EntryEditPolicy.editability(of: day(dayKey), hasEntry: hasEntry, now: instant(now, tz), timeZone: tz)
    }

    @Test func todayIsEditableUntilMidnight() {
        let expected = EntryEditability.editable(until: instant("2026-10-09 00:00"))
        #expect(editability("2026-10-08", hasEntry: false, at: "2026-10-08 09:00") == expected)
        #expect(editability("2026-10-08", hasEntry: true, at: "2026-10-08 23:59") == expected)
    }

    @Test func existingEntryLocksAtMidnight() {
        #expect(editability("2026-10-08", hasEntry: true, at: "2026-10-09 00:00") == .locked)
        #expect(editability("2026-10-08", hasEntry: true, at: "2026-10-09 09:00") == .locked)
    }

    @Test func missingYesterdayIsBackfillableUntilNoon() {
        let expected = EntryEditability.backfillable(until: instant("2026-10-09 12:00"))
        #expect(editability("2026-10-08", hasEntry: false, at: "2026-10-09 00:00") == expected)
        #expect(editability("2026-10-08", hasEntry: false, at: "2026-10-09 11:59") == expected)
        #expect(editability("2026-10-08", hasEntry: false, at: "2026-10-09 12:00") == .locked)
    }

    @Test func olderAndFutureDaysAreLocked() {
        #expect(editability("2026-10-07", hasEntry: false, at: "2026-10-09 09:00") == .locked)
        #expect(editability("2026-10-05", hasEntry: true, at: "2026-10-08 09:00") == .locked)
        #expect(editability("2026-10-09", hasEntry: true, at: "2026-10-08 09:00") == .locked)
    }

    @Test func backfillDeadlineIsLocalNoon() {
        #expect(EntryEditPolicy.backfillDeadline(today: day("2026-10-09"), timeZone: tz) == instant("2026-10-09 12:00"))
    }
}
