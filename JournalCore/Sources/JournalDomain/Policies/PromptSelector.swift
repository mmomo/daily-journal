/// Deterministic prompt selection (business-logic-model §1).
///
/// The daily pick walks the category pool with a full-period stride, so no prompt is picked twice
/// within `pool.count` (≥ 90) consecutive days for a given category selection, without any stored history.
public struct PromptSelector: Sendable {
    public static let maxRefreshesPerDay = 3
    public static let noRepeatWindowDays = 30

    private let library: [Prompt]

    public init(library: [Prompt]) {
        precondition(!library.isEmpty, "The prompt library must not be empty")
        self.library = library.sorted { $0.id < $1.id }
    }

    /// BR-P1: prompts in the selected categories, sorted by id.
    /// Falls back to the whole library if no prompt matches (e.g. an empty selection).
    public func pool(for categories: Set<PromptCategory>) -> [Prompt] {
        let filtered = library.filter { categories.contains($0.category) }
        return filtered.isEmpty ? library : filtered
    }

    /// BR-P2/BR-P3: the day's prompt, skipping prompts answered in the previous 30 days.
    public func dailyPrompt(
        for day: CalendarDay,
        categories: Set<PromptCategory>,
        answeredRecently: Set<String> = []
    ) -> Prompt {
        let pool = pool(for: categories)
        let n = pool.count
        guard n > 1 else { return pool[0] }
        let stride = Self.stride(for: categories, count: n)
        let base = Self.mod(stride.offset + Self.mod(day.dayNumber, n) * stride.step, n)
        for k in 0..<n {
            let candidate = pool[(base + k * stride.step) % n]
            if !answeredRecently.contains(candidate.id) { return candidate }
        }
        return pool[base] // BR-P9: everything excluded
    }

    /// BR-P6: the prompt for refresh number `refreshNumber` (1-based) on `day`.
    /// Never returns a prompt already shown today; avoids prompts answered in the previous 30 days.
    public func refreshedPrompt(
        for day: CalendarDay,
        categories: Set<PromptCategory>,
        refreshNumber: Int,
        shownToday: [String],
        answeredRecently: Set<String> = []
    ) throws(JournalError) -> Prompt {
        let pool = pool(for: categories)
        let n = pool.count
        guard n > 1 else { throw .noRefreshesLeft }
        let seed = "refresh|\(day.key)|\(PromptCategory.key(for: categories))|\(refreshNumber)"
        let start = Int(StableHash.fnv1a64(seed) % UInt64(n))
        let shown = Set(shownToday)

        func scan(excluding excluded: Set<String>) -> Prompt? {
            for k in 0..<n {
                let candidate = pool[(start + k) % n]
                if !excluded.contains(candidate.id) { return candidate }
            }
            return nil
        }

        if let prompt = scan(excluding: shown.union(answeredRecently)) { return prompt }
        // BR-P9: relax the answered-recently exclusion, then keep only "not the current prompt".
        if let prompt = scan(excluding: shown) { return prompt }
        if let current = shownToday.last, let prompt = scan(excluding: [current]) { return prompt }
        throw .noRefreshesLeft
    }

    // MARK: - Stride

    struct Stride: Equatable {
        let offset: Int
        let step: Int
    }

    /// Offset and a step coprime with `count`, derived from the category selection.
    static func stride(for categories: Set<PromptCategory>, count n: Int) -> Stride {
        let key = PromptCategory.key(for: categories)
        let offset = Int(StableHash.fnv1a64("offset|" + key) % UInt64(n))
        var step = Int(StableHash.fnv1a64("step|" + key) % UInt64(n))
        if step == 0 { step = 1 }
        while StableHash.gcd(step, n) != 1 {
            step = step % (n - 1) + 1
        }
        return Stride(offset: offset, step: step)
    }

    static func mod(_ value: Int, _ n: Int) -> Int {
        ((value % n) + n) % n
    }
}
