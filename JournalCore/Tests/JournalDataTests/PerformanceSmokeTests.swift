import Foundation
import Testing
@testable import JournalData
import JournalDomain

/// NFR-5.2: search and streak stay responsive with ~10 years of daily entries (3,650).
@Suite("Performance smoke", .serialized)
struct PerformanceSmokeTests {
    static let entryCount = 3_650

    static func seeded() async throws -> SwiftDataEntryRepository {
        let repo = try makeRepository()
        let start = day("2016-10-09")
        let words = ["quiet", "beach", "coffee", "family", "work", "walk", "café", "rain", "book", "music"]
        for i in 0..<entryCount {
            let d = start.adding(days: i)
            try await repo.save(JournalEntry(
                day: d,
                text: "Day \(i): a note about \(words[i % words.count]) and \(words[(i * 7) % words.count]).",
                promptID: "gratitude-001", promptText: "What small thing made today better?",
                createdAt: d.start(in: mexicoCity), updatedAt: d.start(in: mexicoCity)
            ))
        }
        return repo
    }

    @Test func searchAndStreakAreFast() async throws {
        let repo = try await Self.seeded()
        let clock = ContinuousClock()

        var results: [JournalEntry] = []
        let searchTime = try await clock.measure { results = try await repo.search("cafe") }
        #expect(!results.isEmpty)
        #expect(searchTime < .milliseconds(500), "search took \(searchTime)")

        var days: Set<CalendarDay> = []
        let streakTime = try await clock.measure {
            days = try await repo.entryDays()
            _ = StreakCalculator.summary(entryDays: days, now: instant("2026-10-08 09:00"), timeZone: mexicoCity)
        }
        #expect(days.count == Self.entryCount)
        #expect(streakTime < .milliseconds(500), "entryDays + streak took \(streakTime)")
        print("PERF search=\(searchTime) entryDays+streak=\(streakTime) n=\(Self.entryCount)")
    }
}
