public enum PromptCategory: String, CaseIterable, Codable, Sendable, Comparable {
    case gratitude
    case reflection
    case goals
    case creativity

    public static func < (lhs: PromptCategory, rhs: PromptCategory) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Sorted, comma-joined raw values; identifies a category selection deterministically.
    static func key(for categories: Set<PromptCategory>) -> String {
        categories.map(\.rawValue).sorted().joined(separator: ",")
    }
}

public struct Prompt: Hashable, Codable, Sendable, Identifiable {
    public let id: String
    public let category: PromptCategory
    public let text: String

    public init(id: String, category: PromptCategory, text: String) {
        self.id = id
        self.category = category
        self.text = text
    }
}
