import Foundation
import JournalDomain
import SwiftData

/// SwiftData storage model for a journal entry.
///
/// CloudKit-compatible: every attribute has a default, there are no unique constraints and
/// no relationships (functional design §9.1). Duplicate days are reconciled in the Domain.
@Model
final class EntryRecord {
    var id: UUID = UUID()
    var dayKey: String = ""
    var dayNumber: Int = 0
    var text: String = ""
    var promptID: String = ""
    var promptText: String = ""
    var createdAt: Date = Date.distantPast
    var updatedAt: Date = Date.distantPast

    init(entry: JournalEntry) {
        id = entry.id
        apply(entry)
    }

    func apply(_ entry: JournalEntry) {
        dayKey = entry.day.key
        dayNumber = entry.day.dayNumber
        text = entry.text
        promptID = entry.promptID
        promptText = entry.promptText
        createdAt = entry.createdAt
        updatedAt = entry.updatedAt
    }

    /// `nil` for records whose `dayKey` is empty or malformed (e.g. a half-synced record).
    func toDomain() -> JournalEntry? {
        guard let day = CalendarDay(key: dayKey) else { return nil }
        return JournalEntry(
            id: id,
            day: day,
            text: text,
            promptID: promptID,
            promptText: promptText,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
