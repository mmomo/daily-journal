import Foundation

/// One day's journal entry. The prompt is frozen at creation (FR-1.6).
public struct JournalEntry: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let day: CalendarDay
    /// Stored exactly as typed; validity only requires a non-whitespace character (BR-E2).
    public var text: String
    public let promptID: String
    public let promptText: String
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        day: CalendarDay,
        text: String,
        promptID: String,
        promptText: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.day = day
        self.text = text
        self.promptID = promptID
        self.promptText = promptText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// BR-E2: at least one non-whitespace character.
    public static func isValidText(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
