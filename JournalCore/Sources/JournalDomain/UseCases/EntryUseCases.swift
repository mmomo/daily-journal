import Foundation

/// Creates or updates today's entry (services.md S3, BR-E1–E4, BR-E7).
public struct SaveTodayEntryUseCase: Sendable {
    let time: any TimeSource
    let entries: any EntryRepository
    let widgets: any WidgetRefresher
    let resolver: PromptResolver
    let syncReminder: SyncReminderWithTodayUseCase

    /// - Parameter day: the day the editor was opened for. If it is no longer today
    ///   (the clock passed midnight), the save is rejected with `entryLocked` (US-2.2).
    @discardableResult
    public func execute(text: String, day: CalendarDay) async throws -> JournalEntry {
        guard JournalEntry.isValidText(text) else { throw JournalError.emptyText }
        let now = time.now
        let today = CalendarDay(containing: now, timeZone: time.timeZone)
        guard day == today else { throw JournalError.entryLocked }
        let futureEntries = try await withStorage { try await entries.entries(after: today) }
        guard futureEntries.isEmpty else { throw JournalError.entryLocked }

        let existing = try await withStorage { try await entries.entry(for: today) }
        guard EntryEditPolicy.editability(
            of: today, hasEntry: existing != nil, now: now, timeZone: time.timeZone
        ).isEditable else { throw JournalError.entryLocked }

        let entry: JournalEntry
        if var updated = existing {
            updated.text = text
            updated.updatedAt = now
            entry = updated
        } else {
            let prompt = try await resolver.resolve(today).prompt
            entry = JournalEntry(
                day: today,
                text: text,
                promptID: prompt.id,
                promptText: prompt.text,
                createdAt: now,
                updatedAt: now
            )
        }
        try await withStorage { try await entries.save(entry) }
        await syncReminder.execute()
        widgets.reloadAll()
        return entry
    }
}

/// Writes yesterday's missing entry before today's noon (services.md S4, BR-E8, BR-E9).
public struct BackfillYesterdayUseCase: Sendable {
    let time: any TimeSource
    let entries: any EntryRepository
    let widgets: any WidgetRefresher
    let resolver: PromptResolver
    let syncReminder: SyncReminderWithTodayUseCase

    @discardableResult
    public func execute(text: String, day: CalendarDay) async throws -> JournalEntry {
        guard JournalEntry.isValidText(text) else { throw JournalError.emptyText }
        let now = time.now
        let yesterday = CalendarDay(containing: now, timeZone: time.timeZone).adding(days: -1)
        guard day == yesterday else { throw JournalError.backfillNotAvailable }

        let existing = try await withStorage { try await entries.entry(for: yesterday) }
        guard EntryEditPolicy.editability(
            of: yesterday, hasEntry: existing != nil, now: now, timeZone: time.timeZone
        ).isBackfillable else { throw JournalError.backfillNotAvailable }

        let prompt = try await resolver.resolve(yesterday).prompt
        let entry = JournalEntry(
            day: yesterday,
            text: text,
            promptID: prompt.id,
            promptText: prompt.text,
            createdAt: now,
            updatedAt: now
        )
        try await withStorage { try await entries.save(entry) }
        await syncReminder.execute()
        widgets.reloadAll()
        return entry
    }
}

public struct EntryDetail: Equatable, Sendable {
    public let entry: JournalEntry
    public let editability: EntryEditability
}

/// Loads one entry with what may be done to it now (US-2.4).
public struct GetEntryUseCase: Sendable {
    let time: any TimeSource
    let entries: any EntryRepository

    public func execute(day: CalendarDay) async throws -> EntryDetail? {
        guard let entry = try await withStorage({ try await entries.entry(for: day) }) else { return nil }
        let editability = EntryEditPolicy.editability(of: day, hasEntry: true, now: time.now, timeZone: time.timeZone)
        return EntryDetail(entry: entry, editability: editability)
    }
}

/// History list, newest day first (US-3.1).
public struct ListEntriesUseCase: Sendable {
    let entries: any EntryRepository

    public func execute() async throws -> [JournalEntry] {
        try await withStorage { try await entries.allEntries() }.sortedNewestFirst()
    }
}

/// Search by whole-query substring (US-3.2, BR-Q1–Q3).
public struct SearchEntriesUseCase: Sendable {
    let entries: any EntryRepository

    public func execute(query: String) async throws -> [JournalEntry] {
        let q = EntrySearchMatcher.normalizedQuery(query)
        if q.isEmpty {
            return try await withStorage { try await entries.allEntries() }.sortedNewestFirst()
        }
        return try await withStorage { try await entries.search(q) }
            .filter { EntrySearchMatcher.matches($0, query: q) }
            .sortedNewestFirst()
    }
}

/// Export to Markdown or plain text (US-3.3, BR-X1–X4).
public struct ExportJournalUseCase: Sendable {
    let time: any TimeSource
    let entries: any EntryRepository

    public func execute(format: ExportFormat) async throws -> ExportDocument {
        let all = try await withStorage { try await entries.allEntries() }
        guard !all.isEmpty else { throw JournalError.nothingToExport }
        return JournalExporter.export(all, as: format, exportDay: time.today)
    }
}

/// Current and best streak (US-4.1–4.4).
public struct GetStreakUseCase: Sendable {
    let time: any TimeSource
    let entries: any EntryRepository

    public func execute() async throws -> StreakSummary {
        let days = try await withStorage { try await entries.entryDays() }
        return StreakCalculator.summary(entryDays: days, now: time.now, timeZone: time.timeZone)
    }
}

/// Merges same-day duplicates created by iCloud sync (services.md S5, BR-M1–M6).
public struct ReconcileSyncedEntriesUseCase: Sendable {
    let entries: any EntryRepository
    let widgets: any WidgetRefresher
    let syncReminder: SyncReminderWithTodayUseCase

    /// - Returns: `true` if anything was merged.
    @discardableResult
    public func execute() async throws -> Bool {
        let days = try await withStorage { try await entries.duplicateDays() }
        var merged = false
        for day in days {
            let group = try await withStorage { try await entries.entries(for: day) }
            guard group.count > 1 else { continue }
            let result = DayEntryMerger.merge(group)
            try await withStorage { try await entries.save(result) }
            let others = group.map(\.id).filter { $0 != result.id }
            try await withStorage { try await entries.delete(ids: others) }
            merged = true
        }
        if merged {
            await syncReminder.execute()
            widgets.reloadAll()
        }
        return merged
    }
}

extension Array where Element == JournalEntry {
    func sortedNewestFirst() -> [JournalEntry] {
        sorted { ($0.day, $0.createdAt) > ($1.day, $1.createdAt) }
    }
}
