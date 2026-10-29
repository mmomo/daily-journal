# Story Generation Plan

**Stage**: INCEPTION - User Stories (Part 1: Planning)
**Input**: `aidlc-docs/inception/requirements/requirements.md` (approved)
**Assessment**: `aidlc-docs/inception/plans/user-stories-assessment.md`

---

## Breakdown Approaches Considered

| Approach | How stories are organized | Fit for this app |
|---|---|---|
| **User Journey-Based** | Follows a day in the user's life: reminder, widget tap, write, see streak, browse | Good for the main daily loop. Edge cases like grace and sync get scattered across journeys |
| **Feature-Based** | One group per feature: Prompt, Entry, Streak, Widget, Reminder, History, Settings | Lines up 1:1 with FR-1 to FR-7, so tracing is easy. Can hide the overall daily flow |
| **Persona-Based** | Grouped by user type | Weak fit, since there is only one kind of user |
| **Domain-Based** | Grouped by business domain | Not much different from feature-based in an app this small |
| **Epic-Based** | Epics with sub-stories | Useful for big products. Too much structure for about 20 stories |

**Suggestion**: a hybrid, with feature-based epics (one per FR group) plus a short "daily loop" journey at the top that links to them. You decide in Question 3.

---

## Questions

Please fill in the letter after each `[Answer]:` tag. If no option fits, choose the last option (Other) and describe what you want.

## Question 1
How should personas be modeled? (The app has one user type, but different motivations can change the acceptance criteria.)

A) A single persona: you, the project owner, as a daily journaler

B) One primary persona plus 1–2 behavioral variants (e.g., "habit builder" focused on streaks, "lapsed journaler" who often misses days and relies on grace)

C) Three or more distinct personas with full profiles

X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 2
How fine-grained should stories be?

A) Coarse: about 1 story per requirement group (about 7 stories)

B) Medium: one story per user-visible behavior (about 15–25 stories), each small enough to implement and test on its own

C) Fine: separate stories for each edge case (30+ stories)

X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 3
Which breakdown approach should be used?

A) Feature-based (epics = FR-1 Prompt, FR-2 Entry, FR-3 History, FR-4 Streak, FR-5 Widget, FR-6 Reminder, FR-7 Settings)

B) User journey-based

C) Hybrid: feature-based epics plus a "daily loop" journey overview that references the stories

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 4
What format should acceptance criteria use?

A) Given / When / Then scenarios (lines up directly with unit tests that use a fixed test clock)

B) Bulleted checklist of conditions

C) Given / When / Then for time-sensitive logic (streak, grace, refresh, editing window), bulleted checklist for everything else

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 5
How should time and sync edge cases be covered?

A) Inside the acceptance criteria of the relevant feature stories (e.g., DST and time zone change scenarios inside the streak story)

B) As separate dedicated stories (e.g., "Travel across time zones", "Same-day entries from two devices")

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 6
The requirements don't define a first-launch experience. What should happen the first time the app opens?

A) No onboarding. Open on today's prompt with all categories selected by default

B) A short 1–2 screen onboarding: choose prompt categories, and optionally turn on the reminder

C) No onboarding, but show a one-time tip about adding the widget

X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 7
What should the main screen show? (This affects how the Entry, Streak and Prompt stories are framed.)

A) A single "Today" screen: prompt, entry field and streak together, with History and Settings reachable from it

B) Tab bar with Today, History and Settings tabs

X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Approved Decisions (from answers)

| # | Decision |
|---|---|
| Q1:B | One primary persona plus 2 behavioral variants: **Habit Builder** (motivated by the streak) and **Lapsed Journaler** (often misses days, relies on grace backfill and reminders) |
| Q2:B | Medium granularity: one story per user-visible behavior, about 15–25 stories |
| Q3:A | Feature-based epics, one per FR group (FR-1 to FR-7). No separate journey overview |
| Q4:A | Given / When / Then acceptance criteria for **every** story. Time-based scenarios state the fixed clock time and time zone |
| Q5:A | Time zone, DST, midnight, 12:00 cutoff and two-device sync edge cases go inside the acceptance criteria of the relevant feature stories |
| Q6:B | New first-launch onboarding (1–2 screens): choose prompt categories, optionally turn on the reminder. Belongs to the Settings / First Launch epic. **New scope beyond requirements.md** |
| Q7:A | A single **Today** screen (prompt, entry field, streak) is the home screen. History and Settings are reached from it |

Answer analysis: no contradictions or vague answers found. Q6:B fits FR-6.3, because notification permission is still requested only when the user turns the reminder on, which can now happen during onboarding.

## Execution Checklist (Part 2: Generation)

This is run only after the answers are checked and the plan is approved.

- [x] Step 1: Re-read requirements.md and the approved answers above
- [x] Step 2: Generate `aidlc-docs/inception/user-stories/personas.md`
  - [x] Write each persona's goals, motivations, frustrations and journaling habits
  - [x] Note which requirements matter most to each persona
- [x] Step 3: Generate `aidlc-docs/inception/user-stories/stories.md` using the chosen breakdown approach
  - [x] Epic / group: Daily Prompt (FR-1)
  - [x] Epic / group: Quick Entry, including the grace backfill (FR-2)
  - [x] Epic / group: Past Entries (browse, search, export) (FR-3)
  - [x] Epic / group: Streak (FR-4)
  - [x] Epic / group: Widget (FR-5)
  - [x] Epic / group: Reminder Notifications (FR-6)
  - [x] Epic / group: Settings (FR-7), plus first launch per Question 6
  - [x] Daily loop journey overview: N/A (Question 3 = A)
  - [x] Time and sync edge cases, handled as Question 5 decides
- [x] Step 4: Write acceptance criteria for every story in the format from Question 4
- [x] Step 5: Check each story against INVEST (Independent, Negotiable, Valuable, Estimable, Small, Testable) and split or merge as needed
- [x] Step 6: Map personas to stories (table in stories.md)
- [x] Step 7: Build a traceability table: every FR and NFR in requirements.md maps to one or more stories, or is marked as technical-only with a reason
- [x] Step 8: Validate Markdown and any diagrams per content-validation rules
- [x] Step 9: Update aidlc-state.md and present the completion message

## Mandatory Artifacts
- [x] stories.md with user stories following INVEST criteria
- [x] personas.md with user archetypes and characteristics
- [x] Stories are Independent, Negotiable, Valuable, Estimable, Small, Testable
- [x] Acceptance criteria included for each story
- [x] Personas mapped to relevant user stories
