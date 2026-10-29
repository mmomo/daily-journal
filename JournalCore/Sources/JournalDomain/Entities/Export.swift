public enum ExportFormat: String, CaseIterable, Sendable {
    case markdown
    case plainText

    public var fileExtension: String {
        switch self {
        case .markdown: "md"
        case .plainText: "txt"
        }
    }

    /// Uniform Type Identifier hint for the share sheet.
    public var utTypeIdentifier: String {
        switch self {
        case .markdown: "net.daringfireball.markdown"
        case .plainText: "public.plain-text"
        }
    }
}

public struct ExportDocument: Equatable, Sendable {
    public let fileName: String
    public let contents: String
    public let format: ExportFormat

    public init(fileName: String, contents: String, format: ExportFormat) {
        self.fileName = fileName
        self.contents = contents
        self.format = format
    }
}
