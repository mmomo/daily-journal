# End-to-End (Manual) Test Checklist

Run on the iOS 17+ simulator (unsigned build) unless noted. Change the simulator clock with macOS System Settings → Date & Time, or test the boundary cases on a device. The Domain unit tests already cover them precisely with a fixed clock.

| # | Story | Steps | Expected | Pass |
|---|---|---|---|---|
| E-1 | US-7.1 | Fresh install, launch | 2-step onboarding; can't continue with 0 categories; "Not now" finishes without a permission prompt | ☐ |
| E-2 | US-1.1, US-2.5 | After onboarding | Today: date title, streak card "Start your streak today", prompt card, editor focused with keyboard | ☐ |
| E-3 | US-1.3 | Tap "New prompt" 3 times | Different prompt each time; counter 2 → 1 → 0; then "No refreshes left today" | ☐ |
| E-4 | US-2.1 | Type an entry, wait 1 s | "Saved"; streak 1 ✓; refresh button hidden | ☐ |
| E-5 | US-2.1 | Clear the text | Done disabled; nothing saved as empty | ☐ |
| E-6 | US-2.2 | Tap Edit on the saved entry, change text, Done | Updated text persists after relaunch | ☐ |
| E-7 | US-1.4, US-7.2 | Settings → turn off all but one category | The last one can't be turned off (message shown); today's prompt unchanged | ☐ |
| E-8 | US-6.1 | Settings → Daily reminder on | Permission prompt; allow → time picker shown. Deny → "Notifications are off…" + Open Settings | ☐ |
| E-9 | US-3.1, US-3.2 | History; search for a word in an entry and for "cafe" vs "café" | Newest first; matches ignore case and accents; empty search → all; nonsense → "No Results" | ☐ |
| E-10 | US-2.4 | Open an older entry from History | Read-only, "Past entries are read-only." | ☐ |
| E-11 | US-3.3 | Settings → Export as Markdown / plain text | Share sheet with `daily-journal-YYYY-MM-DD.md/.txt`; contents oldest first | ☐ |
| E-12 | US-2.3, US-4.2 | Device clock: skip a day, open before 12:00 | Backfill banner "until 12:00"; streak at-risk caption; backfill → streak restored | ☐ |
| E-13 | US-4.3 | Same, open after 12:00 | No banner; streak reset to 0 ("Start your streak today") | ☐ |
| E-14 | US-5.1–5.3 | (Team ID) Add the widget; save; refresh; cross midnight | Widget mirrors the prompt and streak; ✓ after saving; new prompt after midnight | ☐ |
| E-15 | US-2.6 | (Team ID, 2 devices) offline entries on both, then online | One merged entry on both | ☐ |
| E-16 | Accessibility | Turn on larger Dynamic Type and VoiceOver | Text scales; controls are labeled (basic support, NFR-4.4) | ☐ |
