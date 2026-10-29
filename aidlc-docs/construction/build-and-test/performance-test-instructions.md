# Performance Test Instructions

## Purpose
This is an on-device app with no server, so load and stress testing don't apply. The performance requirements are:

| ID | Requirement | Target |
|---|---|---|
| NFR-5.1 | Editor ready to type after launch or widget tap | ≈ 1 s or less on a supported device |
| NFR-5.2 | Search stays responsive with ~10 years of entries (3,650) | No noticeable lag (< 500 ms per query) |

## Automated: data-layer smoke test (NFR-5.2)
```bash
cd JournalCore
swift test --filter "Performance smoke"
```
- Seeds 3,650 entries in an in-memory SwiftData store, then times a search and an `entryDays` + streak calculation.
- **Assertion**: each is under 500 ms.
- **Measured (2026-10-08, Apple Silicon Mac, debug build)**: search **26 ms**, entryDays + streak **127 ms**.

## Manual: launch-to-editor time (NFR-5.1)
1. Build **Release**, install on a physical iPhone (preferred) or the simulator.
2. Force-quit the app. Tap the icon (or the widget) and start a stopwatch, or use Instruments → **App Launch** template.
3. **Expected**: the Today screen shows with the keyboard up in about 1 second.
4. Repeat 5 times and record the median.

## If targets are missed
1. Profile with Instruments (Time Profiler, SwiftData template).
2. Likely hot spots: `GetTodayStateUseCase` (several repository calls), `PromptSelector` construction (sorts about 370 prompts per call; can be cached), `entryDays()` on very large stores.
3. Optimize, then re-run the smoke test and the manual launch check.
