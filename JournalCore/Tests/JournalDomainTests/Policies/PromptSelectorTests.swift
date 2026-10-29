import Foundation
import Testing
@testable import JournalDomain

@Suite("PromptSelector")
struct PromptSelectorTests {
    let library = InMemoryPromptLibrary.fixture()
    var selector: PromptSelector { PromptSelector(library: library) }
    let all = Set(PromptCategory.allCases)

    static let categoryCombinations: [Set<PromptCategory>] = {
        let cases = PromptCategory.allCases
        return (1..<(1 << cases.count)).map { mask in
            Set(cases.enumerated().filter { mask & (1 << $0.offset) != 0 }.map(\.element))
        }
    }()

    @Test func dailyPickIsDeterministicAndOrderIndependent() {
        let shuffled = PromptSelector(library: library.shuffled())
        for offset in 0..<50 {
            let d = day("2026-10-08").adding(days: offset)
            #expect(selector.dailyPrompt(for: d, categories: all) == shuffled.dailyPrompt(for: d, categories: all))
        }
    }

    @Test(arguments: categoryCombinations)
    func noRepeatWithin30DaysAndStaysInCategories(_ categories: Set<PromptCategory>) {
        let start = day("2026-01-01")
        let picks = (0..<400).map { selector.dailyPrompt(for: start.adding(days: $0), categories: categories) }
        #expect(picks.allSatisfy { categories.contains($0.category) })
        for windowStart in 0...(picks.count - 30) {
            let window = picks[windowStart..<(windowStart + 30)].map(\.id)
            #expect(Set(window).count == 30)
        }
    }

    @Test func consecutiveDaysVaryAcrossCategories() {
        let picks = (0..<8).map { selector.dailyPrompt(for: day("2026-10-01").adding(days: $0), categories: all) }
        #expect(Set(picks.map(\.category)).count > 1)
    }

    @Test func skipsPromptsAnsweredRecently() {
        let d = day("2026-10-08")
        let usual = selector.dailyPrompt(for: d, categories: all)
        let alternative = selector.dailyPrompt(for: d, categories: all, answeredRecently: [usual.id])
        #expect(alternative != usual)
    }

    @Test func fallsBackWhenEverythingWasAnswered() {
        let d = day("2026-10-08")
        let usual = selector.dailyPrompt(for: d, categories: [.goals])
        let everything = Set(library.map(\.id))
        #expect(selector.dailyPrompt(for: d, categories: [.goals], answeredRecently: everything) == usual)
    }

    @Test func strideIsAlwaysCoprime() {
        for n in 2...400 {
            for categories in Self.categoryCombinations.prefix(3) {
                let stride = PromptSelector.stride(for: categories, count: n)
                #expect(StableHash.gcd(stride.step, n) == 1)
                #expect((0..<n).contains(stride.offset))
            }
        }
    }

    @Test func refreshNeverRepeatsShownPromptsAndIsDeterministic() throws {
        let d = day("2026-10-08")
        var shown = [selector.dailyPrompt(for: d, categories: all).id]
        for number in 1...3 {
            let next = try selector.refreshedPrompt(for: d, categories: all, refreshNumber: number, shownToday: shown)
            let again = try selector.refreshedPrompt(for: d, categories: all, refreshNumber: number, shownToday: shown)
            #expect(next == again)
            #expect(!shown.contains(next.id))
            shown.append(next.id)
        }
    }

    @Test func refreshUsesCurrentCategories() throws {
        let d = day("2026-10-08")
        let current = selector.dailyPrompt(for: d, categories: [.gratitude])
        let next = try selector.refreshedPrompt(for: d, categories: [.creativity], refreshNumber: 1, shownToday: [current.id])
        #expect(next.category == .creativity)
    }

    @Test func refreshRelaxesExclusionsWhenPoolIsTiny() throws {
        let tiny = [
            Prompt(id: "goals-001", category: .goals, text: "A goal?"),
            Prompt(id: "goals-002", category: .goals, text: "Another goal?"),
            Prompt(id: "goals-003", category: .goals, text: "A third goal?"),
        ]
        let small = PromptSelector(library: tiny)
        let d = day("2026-10-08")
        let relaxed = try small.refreshedPrompt(
            for: d, categories: [.goals], refreshNumber: 1,
            shownToday: ["goals-001", "goals-002"], answeredRecently: ["goals-003"]
        )
        #expect(relaxed.id == "goals-003")
        let lastResort = try small.refreshedPrompt(
            for: d, categories: [.goals], refreshNumber: 3,
            shownToday: ["goals-001", "goals-002", "goals-003"]
        )
        #expect(lastResort.id != "goals-003")
    }

    @Test func singlePromptPool() {
        let one = PromptSelector(library: [Prompt(id: "goals-001", category: .goals, text: "Only goal?")])
        #expect(one.dailyPrompt(for: day("2026-10-08"), categories: [.goals]).id == "goals-001")
        #expect(throws: JournalError.noRefreshesLeft) {
            try one.refreshedPrompt(for: day("2026-10-08"), categories: [.goals], refreshNumber: 1, shownToday: ["goals-001"])
        }
    }

    @Test func stableHashIsFixed() {
        // FNV-1a 64 reference values; guards against accidental algorithm changes.
        #expect(StableHash.fnv1a64("") == 0xcbf2_9ce4_8422_2325)
        #expect(StableHash.fnv1a64("a") == 0xaf63_dc4c_8601_ec8c)
    }
}
