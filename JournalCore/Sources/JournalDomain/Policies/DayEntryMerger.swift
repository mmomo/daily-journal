/// Combines several entries for the same day into one without losing text (BR-M1–M6).
public enum DayEntryMerger {
    public static let divider = "\n\n---\n\n"

    /// Deterministic: the same set of entries gives the same result in any input order.
    public static func merge(_ entries: [JournalEntry]) -> JournalEntry {
        precondition(!entries.isEmpty, "merge requires at least one entry")
        let sorted = entries.sorted {
            ($0.createdAt, $0.id.uuidString) < ($1.createdAt, $1.id.uuidString)
        }
        let base = sorted[0]
        var included: [(promptID: String, text: String)] = [(base.promptID, base.text)]
        var body = base.text

        for entry in sorted.dropFirst() {
            if included.contains(where: { $0.promptID == entry.promptID && $0.text == entry.text }) { continue }
            body += divider
            if entry.promptID != base.promptID {
                body += "> " + entry.promptText + "\n\n"
            }
            body += entry.text
            included.append((entry.promptID, entry.text))
        }

        return JournalEntry(
            id: base.id,
            day: base.day,
            text: body,
            promptID: base.promptID,
            promptText: base.promptText,
            createdAt: base.createdAt,
            updatedAt: sorted.map(\.updatedAt).max() ?? base.updatedAt
        )
    }
}
