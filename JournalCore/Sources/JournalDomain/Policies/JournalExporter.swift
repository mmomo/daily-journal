/// Markdown and plain-text export (BR-X1–X4, business-logic-model §6).
public enum JournalExporter {
    public static let plainTextSeparator = String(repeating: "-", count: 40)

    public static func export(_ entries: [JournalEntry], as format: ExportFormat, exportDay: CalendarDay) -> ExportDocument {
        let ordered = entries.sorted { ($0.day, $0.createdAt) < ($1.day, $1.createdAt) }
        let countText = ordered.count == 1 ? "1 entry" : "\(ordered.count) entries"
        let contents: String
        switch format {
        case .markdown:
            var blocks = ["# Daily Journal", "Exported \(exportDay.key) · \(countText)"]
            for entry in ordered {
                blocks.append("## \(entry.day.key)")
                blocks.append("> \(entry.promptText)")
                blocks.append(entry.text)
            }
            contents = blocks.joined(separator: "\n\n") + "\n"
        case .plainText:
            let header = "DAILY JOURNAL\nExported \(exportDay.key) - \(countText)"
            let bodies = ordered.map { entry in
                "\(entry.day.key)\nPrompt: \(entry.promptText)\n\n\(entry.text)"
            }
            contents = ([header] + [bodies.joined(separator: "\n\n\(plainTextSeparator)\n\n")])
                .filter { !$0.isEmpty }
                .joined(separator: "\n\n") + "\n"
        }
        return ExportDocument(
            fileName: "daily-journal-\(exportDay.key).\(format.fileExtension)",
            contents: contents,
            format: format
        )
    }
}
