import Foundation
import Testing
@testable import JournalData
import JournalDomain

@Suite("EntryRecord mapping")
struct EntryRecordMappingTests {
    @Test func roundTrip() {
        let original = entry("2026-10-08", text: "Hello", created: "2026-10-08 08:00")
        #expect(EntryRecord(entry: original).toDomain() == original)
    }

    @Test func storesDayKeyAndNumber() {
        let record = EntryRecord(entry: entry("2026-10-08"))
        #expect(record.dayKey == "2026-10-08")
        #expect(record.dayNumber == day("2026-10-08").dayNumber)
    }

    @Test func invalidDayKeyIsSkipped() {
        let record = EntryRecord(entry: entry("2026-10-08"))
        record.dayKey = ""
        #expect(record.toDomain() == nil)
        record.dayKey = "2026-02-30"
        #expect(record.toDomain() == nil)
    }
}

@Suite("SwiftDataEntryRepository")
struct SwiftDataEntryRepositoryTests {
    @Test func saveInsertsThenUpdatesById() async throws {
        let repo = try makeRepository()
        var e = entry("2026-10-08", text: "First")
        try await repo.save(e)
        e.text = "Second"
        e.updatedAt = instant("2026-10-08 22:00")
        try await repo.save(e)
        let all = try await repo.allEntries()
        #expect(all.count == 1)
        #expect(all.first == e)
    }

    @Test func entryForDayReturnsEarliestDuplicate() async throws {
        let repo = try makeRepository()
        let late = entry("2026-10-08", text: "B", created: "2026-10-08 20:00")
        let early = entry("2026-10-08", text: "A", created: "2026-10-08 08:00")
        try await repo.save(late)
        try await repo.save(early)
        #expect(try await repo.entry(for: day("2026-10-08")) == early)
        #expect(try await repo.entries(for: day("2026-10-08")).count == 2)
        #expect(try await repo.duplicateDays() == [day("2026-10-08")])
        #expect(try await repo.entry(for: day("2026-10-07")) == nil)
    }

    @Test func rangesAndOrdering() async throws {
        let repo = try makeRepository()
        for key in ["2026-09-01", "2026-10-01", "2026-10-05", "2026-10-08", "2026-10-09"] {
            try await repo.save(entry(key))
        }
        let range = try await repo.entries(from: day("2026-10-01"), through: day("2026-10-08"))
        #expect(Set(range.map(\.day.key)) == ["2026-10-01", "2026-10-05", "2026-10-08"])
        #expect(try await repo.entries(after: day("2026-10-08")).map(\.day.key) == ["2026-10-09"])
        #expect(try await repo.allEntries().map(\.day.key) == ["2026-10-09", "2026-10-08", "2026-10-05", "2026-10-01", "2026-09-01"])
        #expect(try await repo.entryDays().count == 5)
        #expect(try await repo.duplicateDays().isEmpty)
    }

    @Test func deleteByIds() async throws {
        let repo = try makeRepository()
        let a = entry("2026-10-07")
        let b = entry("2026-10-08")
        try await repo.save(a)
        try await repo.save(b)
        try await repo.delete(ids: [a.id])
        #expect(try await repo.allEntries() == [b])
        try await repo.delete(ids: [])
        #expect(try await repo.allEntries() == [b])
    }

    static let searchFixture = [
        entry("2026-10-01", text: "A quiet morning at the beach café."),
        entry("2026-10-02", text: "Long walk in the park", promptText: "What made you feel GRATEFUL today?"),
        entry("2026-10-03", text: "Résumé finally done"),
        entry("2026-10-04", text: "Nothing special"),
    ]

    @Test(arguments: ["beach", "BEACH", "cafe", "café", "quiet morning", "morning quiet", "grateful", "resume", "zebra", ""])
    func searchMatchesDomainMatcher(_ query: String) async throws {
        let repo = try makeRepository()
        for e in Self.searchFixture { try await repo.save(e) }
        let fromRepository = try await repo.search(query).map(\.id)
        let expected = Self.searchFixture
            .filter { EntrySearchMatcher.matches($0, query: query) }
            .sorted { $0.day > $1.day }
            .map(\.id)
        #expect(fromRepository == expected)
    }
}
