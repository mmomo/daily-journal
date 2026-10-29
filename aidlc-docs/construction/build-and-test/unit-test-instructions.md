# Unit Test Execution

Unit tests cover the core logic (NFR-4.1). They run on the Mac host with Swift Testing and need no simulator.

## 1. Execute all unit tests
```bash
cd /Users/mmomo/Code/AIDLC/demo/JournalCore
swift test
# a single suite:
swift test --filter StreakCalculator
```

From Xcode: open the `JournalCore` package (or the generated workspace) and run the `JournalCore-Package` test plan (⌘U).

## 2. Review test results
- **Expected**: `Test run with 122 tests in 23 suites passed`. Several tests are parameterized, for example the 30-day no-repeat check runs for all 15 category combinations.
- **Breakdown**:

| Target | Suites | Tests | Focus |
|---|---|---|---|
| JournalDomainTests | 16 | 101 | CalendarDay/DST, PromptSelector, EntryEditPolicy, StreakCalculator, merge, search, export, reminder planner, DeepLink, all 15 use cases |
| JournalDataTests | 7 | 21 | SwiftData repository (in-memory), search parity, prompt library validation, App Group stores, notification requests, integration, performance smoke |

- **Coverage**: optional. Run `swift test --enable-code-coverage`, then `xcrun llvm-cov report .build/debug/JournalCorePackageTests.xctest/Contents/MacOS/JournalCorePackageTests -instr-profile .build/debug/codecov/default.profdata`
- **Reports**: console output. For CI, add `--xunit-output results.xml`

## 3. Fix failing tests
1. Re-run the failing suite with `--filter <SuiteName>`.
2. Time-based tests use fixed instants in `America/Mexico_City` (and New York/Honolulu/Tokyo for DST and travel). They don't depend on the machine's clock or time zone.
3. Fix the code, re-run `swift test` until everything passes.

## Not unit-tested (by design, Q15:A / FQ1:B)
SwiftUI screens and widget views (no view models). They're covered by builds, previews and the manual E2E checklist (`e2e-test-instructions.md`).
