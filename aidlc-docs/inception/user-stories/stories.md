# User Stories

**Source**: `aidlc-docs/inception/requirements/requirements.md` (approved)
**Plan**: `aidlc-docs/inception/plans/story-generation-plan.md` (approved)
**Personas**: `personas.md`. P1 Everyday Journaler, P2 Habit Builder, P3 Lapsed Journaler

## Conventions

- **Format**: "As a [persona], I want [capability], so that [benefit]", followed by Given / When / Then acceptance criteria (Q4:A).
- **Clock**: unless a scenario says otherwise, times are local to the device in **America/Mexico_City** (UTC−6, no daylight saving). The "today" used in examples is **Thursday 2026-10-08**. In tests these scenarios run against an injectable fixed clock (NFR-4.2).
- **Grace cutoff**: 12:00 local time the day after a missed day (FR-2.4).
- **Edge cases** (time zone, daylight saving, midnight, sync) are scenarios inside the relevant feature story (Q5:A).
- Stories are grouped into **feature epics** E1 to E7 (Q3:A). There are 25 stories.

---

## E1: Daily Prompt (FR-1)

### US-1.1: See today's prompt
**As** P1 Everyday Journaler, **I want** a journaling prompt waiting for me when I open the app, **so that** I never start from a blank page.

**Acceptance criteria**
- **Scenario: Prompt on Today screen.** **Given** the app is installed and onboarding is complete, **When** I open the app on 2026-10-08, **Then** the Today screen shows one prompt from the bundled library, with its category name.
- **Scenario: Works offline.** **Given** the device is in Airplane Mode, **When** I open the app, **Then** today's prompt still appears (no network needed).
- **Scenario: New day, new prompt.** **Given** the app was open showing the 2026-10-08 prompt, **When** the clock passes 00:00 on 2026-10-09 and I return to the app, **Then** the Today screen shows the 2026-10-09 prompt.

### US-1.2: Same prompt everywhere, all day
**As** P1 Everyday Journaler, **I want** today's prompt to stay the same across launches and in the widget, **so that** I'm not confused by a prompt that changes.

**Acceptance criteria**
- **Scenario: Same prompt after relaunch.** **Given** the Today screen showed prompt X at 08:00 on 2026-10-08, **When** I force-quit and reopen the app at 21:00, **Then** prompt X is still shown.
- **Scenario: App and widget agree.** **Given** today's prompt is X, **When** I look at the Home Screen widget, **Then** it shows prompt X.
- **Scenario: No recent repeats.** **Given** my selected categories contain at least 30 prompts, **When** daily prompts are picked for any 30 consecutive days, **Then** no prompt appears twice in that window.
- **Scenario: Same date and categories give the same prompt.** **Given** the same date, the same selected categories and no refreshes used, **When** the prompt is picked on the same device or on another device, **Then** the same prompt is chosen.

### US-1.3: Refresh today's prompt (limited)
**As** P3 Lapsed Journaler, **I want** to swap a prompt that doesn't speak to me, **so that** I'm more likely to write today.

**Acceptance criteria**
- **Scenario: Refresh shows a different prompt.** **Given** today's prompt is X and I have used 0 refreshes, **When** I tap Refresh, **Then** a different prompt Y from my selected categories is shown and the remaining count shows "2 left".
- **Scenario: Limit reached.** **Given** I have used 3 refreshes today, **When** I view the Today screen, **Then** the Refresh control is disabled and shows "No refreshes left today".
- **Scenario: Limit resets at midnight.** **Given** I used 3 refreshes on 2026-10-08, **When** it is 00:00 on 2026-10-09, **Then** I have 3 refreshes available again.
- **Scenario: Refreshed prompt persists.** **Given** I refreshed to prompt Y, **When** I relaunch the app or view the widget, **Then** prompt Y is shown (not X).
- **Scenario: No refresh after saving.** **Given** I have saved today's entry, **When** I view the Today screen, **Then** the Refresh control is hidden and the prompt saved with the entry is shown (FR-1.6).

### US-1.4: Choose prompt categories
**As** P1 Everyday Journaler, **I want** to choose which kinds of prompts I get, **so that** the prompts match what I want to reflect on.

**Acceptance criteria**
- **Scenario: Select categories.** **Given** I'm in Settings, Prompt Categories, **When** I deselect "Goals" and keep Gratitude, Reflection and Creativity, **Then** future daily prompts and refreshes come only from those three categories.
- **Scenario: At least one category.** **Given** only "Gratitude" is selected, **When** I try to deselect it, **Then** the app prevents it and explains that at least one category is required.
- **Scenario: Today's prompt is stable.** **Given** today's prompt X is already shown, **When** I change my categories, **Then** today's prompt stays X and the new selection applies from tomorrow's prompt and to any refresh today. *(Proposed rule, see Open Points.)*

---

## E2: Quick Entry (FR-2)

### US-2.1: Write and save today's entry
**As** P1 Everyday Journaler, **I want** to type a short answer to today's prompt and save it, **so that** journaling takes under a minute.

**Acceptance criteria**
- **Scenario: Save entry.** **Given** no entry exists for 2026-10-08, **When** I type "Grateful for a quiet morning." and tap Save at 21:00, **Then** an entry dated 2026-10-08 is stored with that text and today's prompt, and the Today screen shows it as done.
- **Scenario: Empty entry rejected.** **Given** the entry field contains only spaces or newlines, **When** I look at the Save button, **Then** it is disabled.
- **Scenario: One entry per day.** **Given** an entry for 2026-10-08 exists, **When** I open the Today screen, **Then** I see that entry to edit, not a new blank entry.
- **Scenario: Prompt frozen with entry.** **Given** I saved an entry while prompt Y was shown, **When** I view it later in History, **Then** prompt Y is shown with it.

### US-2.2: Edit today's entry until midnight
**As** P1 Everyday Journaler, **I want** to add to or fix today's entry later in the day, **so that** I can capture thoughts as they come.

**Acceptance criteria**
- **Scenario: Edit same day.** **Given** I saved an entry at 08:00 on 2026-10-08, **When** I change its text at 22:00 the same day, **Then** the updated text is stored and the entry is still dated 2026-10-08.
- **Scenario: Locked after midnight.** **Given** an entry for 2026-10-08 exists, **When** it is 00:00 or later on 2026-10-09, **Then** that entry is read-only, including during the grace window (FR-2.5).
- **Scenario: Typing across midnight.** **Given** I'm editing the existing 2026-10-08 entry at 23:59:30, **When** the clock passes 00:00, **Then** text typed before midnight is kept (autosaved), the editor becomes read-only, and a message explains the entry is locked. *(Autosave is a proposed mechanism, see Open Points.)*

### US-2.3: Backfill a missed yesterday until noon
**As** P3 Lapsed Journaler, **I want** to write yesterday's missing entry the next morning, **so that** one late night doesn't cost me my streak.

**Acceptance criteria**
- **Scenario: Backfill offered.** **Given** no entry exists for 2026-10-08, **When** I open the app at 09:00 on 2026-10-09, **Then** the Today screen offers "Write yesterday's entry (until 12:00)" in addition to today's prompt.
- **Scenario: Backfill saved.** **Given** the backfill option is shown, **When** I write and save an entry at 11:30 on 2026-10-09, **Then** it is stored with date 2026-10-08 and yesterday's prompt.
- **Scenario: Grace window closes.** **Given** no entry exists for 2026-10-08, **When** it is 12:00 or later on 2026-10-09, **Then** the backfill option is gone and 2026-10-08 can't be written.
- **Scenario: No backfill if yesterday exists.** **Given** an entry exists for 2026-10-08, **When** I open the app at 09:00 on 2026-10-09, **Then** no backfill option is offered.
- **Scenario: Only yesterday.** **Given** no entries exist for 2026-10-07 or 2026-10-08, **When** I open the app at 09:00 on 2026-10-09, **Then** only 2026-10-08 can be backfilled.

### US-2.4: Read-only past entries
**As** P1 Everyday Journaler, **I want** past entries to be read-only, **so that** my journal is an honest record.

**Acceptance criteria**
- **Scenario: Past entry locked.** **Given** an entry dated 2026-10-05, **When** I open it from History on 2026-10-08, **Then** it is shown read-only with no edit control.
- **Scenario: Today's entry editable from History.** **Given** today's entry exists, **When** I open it from History, **Then** I can edit it (same rules as US-2.2).

### US-2.5: Open the editor fast
**As** P1 Everyday Journaler, **I want** to start typing almost immediately, **so that** a quick entry really is quick.

**Acceptance criteria**
- **Scenario: Ready to type.** **Given** the app is not running, **When** I launch it (or tap the widget or reminder), **Then** within about 1 second on a supported device the editor shows today's prompt with the keyboard up and the cursor in the entry field (NFR-5.1).
- **Scenario: Done-today state.** **Given** today's entry is already saved, **When** I open the app, **Then** the keyboard is not raised automatically, and the saved entry is shown with an Edit option.

### US-2.6: My entries on all my devices
**As** P1 Everyday Journaler, **I want** my entries to sync through my iCloud, **so that** I can journal on any of my devices without accounts.

**Acceptance criteria**
- **Scenario: Sync between devices.** **Given** iPhone A and iPhone B are signed in to the same iCloud account, **When** I save an entry on A, **Then** it appears on B once B has synced, without any app login.
- **Scenario: Offline writing.** **Given** device A is offline, **When** I save an entry, **Then** it is stored locally and synced when connectivity returns.
- **Scenario: No iCloud.** **Given** I'm not signed in to iCloud (or iCloud is off for the app), **When** I use the app, **Then** every feature works locally and no error blocks writing.
- **Scenario: Same-day entries from two devices.** **Given** both devices were offline and each saved an entry for 2026-10-08, **When** they sync, **Then** exactly one 2026-10-08 entry remains, and it contains both texts (oldest first, separated by a divider), so no text is lost (NFR-2.4). *(Merge format is proposed, see Open Points.)*
- **Scenario: Private by design.** **Given** the app is running, **When** I save or sync entries, **Then** journal text goes only to my private iCloud database, never to any other service (NFR-2.5).

---

## E3: Past Entries (FR-3)

### US-3.1: Browse past entries
**As** P1 Everyday Journaler, **I want** to scroll back through my journal, **so that** I can reflect on how I've changed.

**Acceptance criteria**
- **Scenario: Reverse chronological list.** **Given** entries exist for 2026-10-01, 2026-10-05 and 2026-10-08, **When** I open History from the Today screen, **Then** they are listed 2026-10-08, 2026-10-05, 2026-10-01, each showing date, prompt and a text preview.
- **Scenario: Empty state.** **Given** no entries exist, **When** I open History, **Then** a friendly empty state invites me to write today's entry.
- **Scenario: Entry stays on its date after travel.** **Given** I wrote an entry at 22:00 on 2026-10-08 in America/Mexico_City, **When** I later change the device time zone to Asia/Tokyo, **Then** History still lists that entry under 2026-10-08 (NFR-3.2).

### US-3.2: Search entries
**As** P1 Everyday Journaler, **I want** to search my journal, **so that** I can find the time I wrote about something.

**Acceptance criteria**
- **Scenario: Match entry text.** **Given** one entry contains "beach", **When** I search "beach", **Then** that entry is listed.
- **Scenario: Match prompt text.** **Given** one entry answered a prompt containing "grateful", **When** I search "grateful", **Then** that entry is listed.
- **Scenario: Case and accent insensitive.** **Given** an entry contains "Café", **When** I search "cafe", **Then** that entry is listed.
- **Scenario: No results.** **Given** nothing matches "zebra", **When** I search "zebra", **Then** a "No entries match" message is shown.
- **Scenario: Large journal.** **Given** about 3,650 entries exist, **When** I type a search term, **Then** results update without noticeable lag (NFR-5.2).

### US-3.3: Export my journal
**As** P1 Everyday Journaler, **I want** to export my entries, **so that** I own a copy outside the app.

**Acceptance criteria**
- **Scenario: Markdown export.** **Given** entries exist, **When** I choose Export, then Markdown, **Then** the share sheet offers a `.md` file with one section per entry (date heading, prompt, text), oldest first.
- **Scenario: Plain-text export.** **Given** entries exist, **When** I choose Export, then Plain Text, **Then** the share sheet offers a `.txt` file with the same content without Markdown syntax.
- **Scenario: Nothing to export.** **Given** no entries exist, **When** I open Export, **Then** the export actions are disabled with an explanation.
- *(Stretch goal, not required: PDF format and date-range filter, per FR-3.3/FR-3.4.)*

---

## E4: Streak (FR-4)

### US-4.1: See my current streak
**As** P2 Habit Builder, **I want** to see how many days in a row I've journaled, **so that** I stay motivated.

**Acceptance criteria**
- **Scenario: Streak including today.** **Given** entries exist for 2026-10-06, 10-07 and 10-08, **When** I view the Today screen on 2026-10-08, **Then** the streak shows 3.
- **Scenario: Today not written yet.** **Given** entries exist for 2026-10-06 and 10-07 but not 10-08, **When** I view the Today screen at 09:00 on 2026-10-08, **Then** the streak shows 2 (ending yesterday) and is not marked at risk.
- **Scenario: No entries.** **Given** no entries exist, **When** I view the Today screen, **Then** the streak shows 0.
- **Scenario: Daylight-saving change.** **Given** the device is in America/New_York and entries exist for 2026-10-31, 2026-11-01 (the 25-hour day DST ends) and 2026-11-02, **When** I view the streak on 2026-11-02, **Then** it shows 3.
- **Scenario: Calculated from entries.** **Given** an entry for yesterday arrives via iCloud sync, **When** the Today screen refreshes, **Then** the streak is recalculated from stored entries and includes that day (FR-4.6).

### US-4.2: Streak at risk during grace
**As** P3 Lapsed Journaler, **I want** to be warned my streak is at risk instead of seeing it reset immediately, **so that** I can save it with a backfill.

**Acceptance criteria**
- **Scenario: At-risk shown.** **Given** entries exist for 2026-10-05, 10-06 and 10-07 and none for 10-08, **When** I view the Today screen at 09:00 on 2026-10-09, **Then** the streak shows 3 marked "At risk: write yesterday's entry by 12:00".
- **Scenario: Backfill restores.** **Given** the at-risk state above, **When** I backfill 2026-10-08 at 11:00 on 2026-10-09, **Then** the streak shows 4 and is no longer at risk.
- **Scenario: Backfill then today.** **Given** I backfilled 2026-10-08 as above, **When** I also save today's entry for 2026-10-09, **Then** the streak shows 5.
- **Scenario: Today written, yesterday missing, before noon.** **Given** entries exist for 10-05 to 10-07, none for 10-08, and I saved today's 10-09 entry at 08:00, **When** I view the streak at 09:00 on 2026-10-09, **Then** it shows 1 with the hint "Write yesterday's entry by 12:00 to restore your 3-day streak". If I then backfill 10-08, it shows 5.

### US-4.3: Streak resets after grace
**As** P2 Habit Builder, **I want** the streak to follow clear rules, **so that** I trust it.

**Acceptance criteria**
- **Scenario: Reset at cutoff.** **Given** entries exist for 10-05 to 10-07, none for 10-08, and no backfill, **When** it is 12:00 on 2026-10-09 and I haven't written today, **Then** the streak shows 0.
- **Scenario: Restart.** **Given** the streak was reset as above, **When** I save an entry for 2026-10-09 at 20:00, **Then** the streak shows 1.
- **Scenario: Two missed days.** **Given** the last entry is for 2026-10-06, **When** I open the app at 09:00 on 2026-10-09, **Then** the streak shows 0 (grace covers only yesterday).

### US-4.4: See my longest streak
**As** P2 Habit Builder, **I want** to see my best streak ever, **so that** I have something to beat.

**Acceptance criteria**
- **Scenario: Longest shown.** **Given** past entries contain a 12-day run and the current streak is 4, **When** I view the streak area, **Then** it shows "Current 4 · Best 12".
- **Scenario: New record.** **Given** the best streak is 12 and the current streak is 12, **When** I save today's entry making the current streak 13, **Then** the best streak shows 13.
- **Scenario: Calculated, not stored.** **Given** entries sync in from another device and fill gaps in an older run, **When** the streak is recalculated, **Then** the best streak reflects the combined entries.

---

## E5: Widget (FR-5)

### US-5.1: Prompt and streak on my Home Screen
**As** P1 Everyday Journaler, **I want** a small Home Screen widget showing today's prompt and my streak, **so that** I'm reminded to write without opening the app.

**Acceptance criteria**
- **Scenario: Widget content.** **Given** today's prompt is X and the streak is 5, **When** I add the small widget, **Then** it shows prompt X (truncated with an ellipsis if too long) and a corner badge showing 5.
- **Scenario: Done mark.** **Given** today's entry is saved, **When** I view the widget, **Then** the streak badge includes a checkmark (FR-5.6).
- **Scenario: At risk.** **Given** the streak is at risk (US-4.2), **When** I view the widget before 12:00, **Then** the badge shows the at-risk state.
- **Scenario: Before onboarding.** **Given** the app has been installed but never opened, **When** I add the widget, **Then** it shows a placeholder inviting me to open the app.

### US-5.2: Tap widget to write
**As** P1 Everyday Journaler, **I want** tapping the widget to open the editor directly, **so that** I can start writing in one tap.

**Acceptance criteria**
- **Scenario: Deep link to editor.** **Given** today's entry isn't written, **When** I tap the widget, **Then** the app opens on the Today screen with the editor focused, today's prompt loaded and the keyboard up.
- **Scenario: Already done.** **Given** today's entry is saved, **When** I tap the widget, **Then** the app opens showing today's saved entry with an Edit option.

### US-5.3: Widget stays current
**As** P2 Habit Builder, **I want** the widget to update by itself, **so that** it never shows a stale prompt or streak.

**Acceptance criteria**
- **Scenario: Midnight rollover.** **Given** the widget shows the 2026-10-08 prompt, **When** it is 00:00 on 2026-10-09, **Then** the widget shows the 2026-10-09 prompt and recalculated streak.
- **Scenario: Grace cutoff.** **Given** the widget shows the at-risk state, **When** it is 12:00 and no backfill happened, **Then** the widget shows the streak as 0.
- **Scenario: After save or refresh.** **Given** the widget is on the Home Screen, **When** I save an entry or refresh the prompt in the app, **Then** the widget updates to match when I return to the Home Screen.

---

## E6: Reminder Notifications (FR-6)

### US-6.1: Turn on a daily reminder
**As** P3 Lapsed Journaler, **I want** a daily reminder at a time I choose, **so that** I don't forget to write.

**Acceptance criteria**
- **Scenario: Enable with permission.** **Given** reminders are off and notification permission hasn't been asked, **When** I turn on the reminder (in onboarding or Settings), **Then** iOS asks for notification permission, and if I allow it, a daily reminder is scheduled for 20:00 by default.
- **Scenario: Change time.** **Given** the reminder is on at 20:00, **When** I change it to 07:30, **Then** future reminders fire at 07:30.
- **Scenario: Permission denied.** **Given** I denied notification permission, **When** I view the reminder setting, **Then** it is shown as unavailable with a button that opens iOS Settings.
- **Scenario: No early prompt.** **Given** a fresh install, **When** I go through onboarding without turning on the reminder, **Then** I'm never asked for notification permission (FR-6.3).
- **Scenario: Turn off.** **Given** the reminder is on, **When** I turn it off, **Then** no further reminders fire.

### US-6.2: No reminder once I've written
**As** P3 Lapsed Journaler, **I want** no reminder if I've already written today, **so that** notifications don't nag me.

**Acceptance criteria**
- **Scenario: Skip when done.** **Given** the reminder is set for 20:00, **When** I save today's entry at 08:00, **Then** no reminder fires today, and tomorrow's reminder is still scheduled.
- **Scenario: Fires when not done.** **Given** the reminder is set for 20:00 and no entry exists for today, **When** it is 20:00, **Then** the reminder fires showing today's prompt.
- **Scenario: Done on another device.** **Given** I saved today's entry on device B, **When** device A syncs before 20:00, **Then** device A cancels today's reminder. *(If sync hasn't happened by then, A may still fire; accepted limitation.)*

### US-6.3: Tap reminder to write
**As** P3 Lapsed Journaler, **I want** tapping the reminder to open the editor, **so that** I can write straight away.

**Acceptance criteria**
- **Scenario: Open editor.** **Given** the reminder notification is showing, **When** I tap it, **Then** the app opens the editor with today's prompt, as in US-5.2.

---

## E7: Settings and First Launch (FR-7, Q6:B)

### US-7.1: First-launch onboarding
**As** P1 Everyday Journaler, **I want** a short setup the first time I open the app, **so that** prompts and reminders fit me from day one.

**Acceptance criteria**
- **Scenario: Shown once.** **Given** a fresh install, **When** I open the app, **Then** a 1–2 screen onboarding appears. After finishing it, it never appears again on that device.
- **Scenario: Choose categories.** **Given** I'm on the onboarding categories step, **When** I continue, **Then** at least one category must be selected (all four are selected by default).
- **Scenario: Optional reminder.** **Given** I'm on the onboarding reminder step, **When** I tap "Not now", **Then** onboarding completes with the reminder off and no permission prompt. **When** I turn it on and pick a time, **Then** US-6.1 applies.
- **Scenario: Lands on Today.** **Given** I finish onboarding, **When** it closes, **Then** the Today screen appears with today's prompt and the editor ready.
- **Scenario: Second device.** **Given** I already use the app on another device with iCloud, **When** I install on a new device, **Then** onboarding still runs once there, and my synced entries appear afterward.

### US-7.2: Settings screen
**As** P1 Everyday Journaler, **I want** one place to change my preferences, **so that** I can adjust the app as my habits change.

**Acceptance criteria**
- **Scenario: Settings contents.** **Given** I'm on the Today screen, **When** I open Settings, **Then** I see Prompt Categories (US-1.4), Daily Reminder on/off and time (US-6.1), and Export (US-3.3).
- **Scenario: Changes persist.** **Given** I change any setting, **When** I relaunch the app, **Then** the change is kept.

---

## Persona-to-Story Map

| Story | P1 Everyday | P2 Habit Builder | P3 Lapsed |
|---|---|---|---|
| US-1.1 See today's prompt | Primary | | |
| US-1.2 Same prompt everywhere | Primary | Yes | |
| US-1.3 Refresh prompt | Yes | | Primary |
| US-1.4 Choose categories | Primary | | |
| US-2.1 Write and save | Primary | Yes | Yes |
| US-2.2 Edit until midnight | Primary | | |
| US-2.3 Backfill yesterday | | Yes | Primary |
| US-2.4 Read-only past entries | Primary | | |
| US-2.5 Open editor fast | Primary | | Yes |
| US-2.6 Sync across devices | Primary | Yes | |
| US-3.1 Browse | Primary | | |
| US-3.2 Search | Primary | | |
| US-3.3 Export | Primary | | |
| US-4.1 Current streak | Yes | Primary | |
| US-4.2 At risk during grace | | Yes | Primary |
| US-4.3 Reset after grace | | Primary | Yes |
| US-4.4 Longest streak | | Primary | |
| US-5.1 Widget content | Primary | Yes | |
| US-5.2 Tap widget to write | Primary | | Yes |
| US-5.3 Widget stays current | | Primary | |
| US-6.1 Turn on reminder | | | Primary |
| US-6.2 Skip when done | | | Primary |
| US-6.3 Tap reminder to write | | | Primary |
| US-7.1 Onboarding | Primary | | Yes |
| US-7.2 Settings | Primary | | |

---

## Requirements Traceability

| Requirement | Stories | Notes |
|---|---|---|
| FR-1.1 | US-1.1 | |
| FR-1.2, FR-1.3 | US-1.4, US-7.1 | |
| FR-1.4 | US-1.2 | |
| FR-1.5 | US-1.3 | |
| FR-1.6 | US-1.3, US-2.1 | |
| FR-2.1, FR-2.2, FR-2.7 | US-2.1 | |
| FR-2.3 | US-2.2 | |
| FR-2.4 | US-2.3 | |
| FR-2.5 | US-2.2, US-2.3 | |
| FR-2.6 | US-2.4 | |
| FR-2.8 | US-2.5 | |
| FR-3.1 | US-3.1 | |
| FR-3.2 | US-3.2 | |
| FR-3.3, FR-3.4 | US-3.3 | PDF and date range are stretch goals |
| FR-4.1, FR-4.2 | US-4.1 | |
| FR-4.3 | US-4.3 | |
| FR-4.4 | US-4.2 | |
| FR-4.5 | US-4.4 | |
| FR-4.6 | US-4.1, US-4.4 | |
| FR-5.1, FR-5.2, FR-5.6 | US-5.1 | |
| FR-5.3, FR-5.5 | US-5.3 | |
| FR-5.4 | US-5.2 | |
| FR-6.1, FR-6.3 | US-6.1 | |
| FR-6.2 | US-6.2 | |
| FR-6.4 | US-6.3 | |
| FR-7.1 | US-7.2 | |
| Q6:B onboarding (new scope) | US-7.1 | Added during User Stories planning |
| NFR-1.1 to NFR-1.3 | Technical only | Platform choices; covered in design and code |
| NFR-2.1 to NFR-2.5 | US-2.6 | |
| NFR-2.6 | Out of scope | No app lock |
| NFR-3.1, NFR-3.3 | US-1.1, US-2.2, US-2.3, US-4.1, US-4.2, US-4.3, US-5.3 | Midnight, 12:00 cutoff and DST scenarios |
| NFR-3.2 | US-3.1 | Time zone change scenario |
| NFR-4.1, NFR-4.2 | All E1, E2, E4 stories | The Given/When/Then scenarios are the unit test cases |
| NFR-4.3, NFR-4.4 | Technical only | Testing and quality scope |
| NFR-5.1 | US-2.5 | |
| NFR-5.2 | US-3.2 | |

---

## Open Points for Review

These are proposed rules that were added to make the stories testable. They go beyond what requirements.md says explicitly, so please accept or change them.

1. **Changing categories mid-day** (US-1.4): today's prompt stays the same, and new categories apply from tomorrow and to refreshes today.
2. **Autosave while typing** (US-2.2): text is saved as you type, so nothing typed before midnight is lost when today's entry locks.
3. **Merging same-day entries from two devices** (US-2.6): both texts are kept in one entry, oldest first, separated by a divider.
4. **No-repeat window** (US-1.2): no prompt repeats within 30 days.
5. **Reminder on a second device** (US-6.2): a device that hasn't synced yet may still fire today's reminder. This is accepted as a limitation.
6. **No entry deletion**: the requirements don't include deleting entries, so no story covers it. Say so if you want it added.
