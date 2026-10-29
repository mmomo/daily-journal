import Foundation

/// Runs a storage operation, converting unexpected errors into `JournalError.storageFailure`.
func withStorage<T>(_ operation: () async throws -> T) async throws -> T {
    do {
        return try await operation()
    } catch let error as JournalError {
        throw error
    } catch {
        throw JournalError.storageFailure(String(describing: error))
    }
}

extension TimeSource {
    var today: CalendarDay { CalendarDay(containing: now, timeZone: timeZone) }
}

extension Prompt {
    /// The prompt an entry answered: the library version if it still exists, otherwise the snapshot.
    static func answered(by entry: JournalEntry, library: any PromptLibrary) -> Prompt {
        if let prompt = library.prompt(id: entry.promptID) { return prompt }
        let prefix = entry.promptID.split(separator: "-").first.map(String.init) ?? ""
        return Prompt(id: entry.promptID, category: PromptCategory(rawValue: prefix) ?? .reflection, text: entry.promptText)
    }
}

/// Resolves "the prompt for day d on this device" (business-logic-model §1.4).
struct PromptResolver: Sendable {
    let time: any TimeSource
    let entries: any EntryRepository
    let library: any PromptLibrary
    let promptState: any PromptStateStore
    let settings: any SettingsStore

    func selector() -> PromptSelector {
        PromptSelector(library: library.allPrompts())
    }

    /// Prompt ids answered in the 30 days before `day` (BR-P3).
    func answeredRecently(before day: CalendarDay) async throws -> Set<String> {
        let recent = try await withStorage {
            try await entries.entries(
                from: day.adding(days: -PromptSelector.noRepeatWindowDays),
                through: day.adding(days: -1)
            )
        }
        return Set(recent.map(\.promptID))
    }

    /// BR-P4/BR-P8: the stored prompt for `day`, or a fresh deterministic pick that is then stored.
    func resolve(_ day: CalendarDay) async throws -> (prompt: Prompt, state: DailyPromptState) {
        if let state = promptState.state(for: day), let prompt = library.prompt(id: state.promptID) {
            return (prompt, state)
        }
        let categories = settings.load().categories
        let prompt = selector().dailyPrompt(
            for: day,
            categories: categories,
            answeredRecently: try await answeredRecently(before: day)
        )
        let state = DailyPromptState(
            day: day,
            promptID: prompt.id,
            refreshesUsed: 0,
            shownPromptIDs: [prompt.id],
            categoriesKey: PromptCategory.key(for: categories)
        )
        promptState.save(state, keepingFrom: time.today.adding(days: -1))
        return (prompt, state)
    }
}
