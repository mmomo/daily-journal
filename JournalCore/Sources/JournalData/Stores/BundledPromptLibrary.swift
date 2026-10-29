import Foundation
import JournalDomain

/// The prompt library shipped in `prompts.json` (functional design §9.2).
public final class BundledPromptLibrary: PromptLibrary {
    private let prompts: [Prompt]
    private let byID: [String: Prompt]

    public init(prompts: [Prompt]) throws {
        try PromptLibraryValidator.validate(prompts)
        self.prompts = prompts
        byID = Dictionary(uniqueKeysWithValues: prompts.map { ($0.id, $0) })
    }

    /// Loads and validates the bundled `prompts.json`.
    public convenience init() throws {
        try self.init(bundle: .module)
    }

    public convenience init(bundle: Bundle, resource: String = "prompts") throws {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            throw PromptLibraryError.missingResource(resource)
        }
        try self.init(data: Data(contentsOf: url))
    }

    public convenience init(data: Data) throws {
        let file = try JSONDecoder().decode(PromptFile.self, from: data)
        guard file.version == 1 else { throw PromptLibraryError.unsupportedVersion(file.version) }
        try self.init(prompts: file.prompts)
    }

    public func allPrompts() -> [Prompt] { prompts }
    public func prompt(id: String) -> Prompt? { byID[id] }
}

struct PromptFile: Codable {
    let version: Int
    let prompts: [Prompt]
}

public enum PromptLibraryError: Error, Equatable {
    case missingResource(String)
    case unsupportedVersion(Int)
    case duplicateID(String)
    case malformedID(String)
    case categoryMismatch(String)
    case textLength(String)
    case duplicateText(String)
    case tooFewPrompts(category: String, count: Int)
    case tooFewTotal(Int)
}

public enum PromptLibraryValidator {
    public static let minimumPerCategory = 90
    public static let minimumTotal = 365

    public static func validate(
        _ prompts: [Prompt],
        minimumPerCategory: Int = minimumPerCategory,
        minimumTotal: Int = minimumTotal
    ) throws {
        var ids = Set<String>()
        var texts = Set<String>()
        for prompt in prompts {
            guard ids.insert(prompt.id).inserted else { throw PromptLibraryError.duplicateID(prompt.id) }
            let parts = prompt.id.split(separator: "-")
            guard parts.count == 2, let category = PromptCategory(rawValue: String(parts[0])),
                  parts[1].count == 3, parts[1].allSatisfy(\.isNumber)
            else { throw PromptLibraryError.malformedID(prompt.id) }
            guard category == prompt.category else { throw PromptLibraryError.categoryMismatch(prompt.id) }
            let trimmed = prompt.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard (10...200).contains(trimmed.count) else { throw PromptLibraryError.textLength(prompt.id) }
            guard texts.insert(trimmed.lowercased()).inserted else { throw PromptLibraryError.duplicateText(prompt.id) }
        }
        for category in PromptCategory.allCases {
            let count = prompts.filter { $0.category == category }.count
            if count < minimumPerCategory {
                throw PromptLibraryError.tooFewPrompts(category: category.rawValue, count: count)
            }
        }
        guard prompts.count >= minimumTotal else { throw PromptLibraryError.tooFewTotal(prompts.count) }
    }
}
