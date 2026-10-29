import Foundation

/// Whole-query substring match on entry text or prompt text, case- and diacritic-insensitive (BR-Q1–Q2, Q5:A).
public enum EntrySearchMatcher {
    public static func normalizedQuery(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func matches(_ entry: JournalEntry, query: String) -> Bool {
        let q = normalizedQuery(query)
        guard !q.isEmpty else { return true }
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        return entry.text.range(of: q, options: options) != nil
            || entry.promptText.range(of: q, options: options) != nil
    }
}
