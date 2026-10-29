import Foundation
import JournalDomain
import SwiftData

/// `EntryRepository` backed by SwiftData. Runs on its own actor so database work stays off the main thread.
@ModelActor
public actor SwiftDataEntryRepository: EntryRepository {
    public func entry(for day: CalendarDay) async throws -> JournalEntry? {
        try records(dayKey: day.key)
            .compactMap { $0.toDomain() }
            .min { ($0.createdAt, $0.id.uuidString) < ($1.createdAt, $1.id.uuidString) }
    }

    public func entries(for day: CalendarDay) async throws -> [JournalEntry] {
        try records(dayKey: day.key).compactMap { $0.toDomain() }
    }

    public func entries(from: CalendarDay, through: CalendarDay) async throws -> [JournalEntry] {
        let lower = from.dayNumber
        let upper = through.dayNumber
        let descriptor = FetchDescriptor<EntryRecord>(
            predicate: #Predicate { $0.dayNumber >= lower && $0.dayNumber <= upper }
        )
        return try modelContext.fetch(descriptor).compactMap { $0.toDomain() }
    }

    public func entries(after day: CalendarDay) async throws -> [JournalEntry] {
        let number = day.dayNumber
        let descriptor = FetchDescriptor<EntryRecord>(predicate: #Predicate { $0.dayNumber > number })
        return try modelContext.fetch(descriptor).compactMap { $0.toDomain() }
    }

    public func allEntries() async throws -> [JournalEntry] {
        let descriptor = FetchDescriptor<EntryRecord>(
            sortBy: [SortDescriptor(\.dayNumber, order: .reverse), SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).compactMap { $0.toDomain() }
    }

    public func entryDays() async throws -> Set<CalendarDay> {
        Set(try dayKeys().compactMap(CalendarDay.init(key:)))
    }

    public func search(_ query: String) async throws -> [JournalEntry] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return try await allEntries() }
        let descriptor = FetchDescriptor<EntryRecord>(
            predicate: #Predicate {
                $0.text.localizedStandardContains(q) || $0.promptText.localizedStandardContains(q)
            },
            sortBy: [SortDescriptor(\.dayNumber, order: .reverse), SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).compactMap { $0.toDomain() }
    }

    public func duplicateDays() async throws -> [CalendarDay] {
        var counts: [String: Int] = [:]
        for key in try dayKeys() { counts[key, default: 0] += 1 }
        return counts.filter { $0.value > 1 }.keys.compactMap(CalendarDay.init(key:)).sorted()
    }

    public func save(_ entry: JournalEntry) async throws {
        let id = entry.id
        var descriptor = FetchDescriptor<EntryRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        if let existing = try modelContext.fetch(descriptor).first {
            existing.apply(entry)
        } else {
            modelContext.insert(EntryRecord(entry: entry))
        }
        try modelContext.save()
    }

    public func delete(ids: [UUID]) async throws {
        guard !ids.isEmpty else { return }
        for id in ids {
            let descriptor = FetchDescriptor<EntryRecord>(predicate: #Predicate { $0.id == id })
            for record in try modelContext.fetch(descriptor) {
                modelContext.delete(record)
            }
        }
        try modelContext.save()
    }

    // MARK: - Helpers

    private func records(dayKey key: String) throws -> [EntryRecord] {
        try modelContext.fetch(FetchDescriptor<EntryRecord>(predicate: #Predicate { $0.dayKey == key }))
    }

    private func dayKeys() throws -> [String] {
        var descriptor = FetchDescriptor<EntryRecord>()
        descriptor.propertiesToFetch = [\.dayKey]
        return try modelContext.fetch(descriptor).map(\.dayKey)
    }
}
