# Requirements Clarification Questions

**Project**: iOS Daily Journaling Prompt App
**Request**: "I want to build an iOS that generates a prompt for journaling. A daily journaling prompt and a quick entry, with a streak counter and a widget."

Please answer each question by filling in the letter after the `[Answer]:` tag. If no option fits, choose the last option (Other) and describe what you want after the tag.

---

## Section 1: Prompt Generation

## Question 1
How should the daily journaling prompts be generated?

A) Curated library bundled in the app (e.g., 365+ handwritten prompts, picked deterministically per day). Works offline, no cost, fully private

B) On-device AI generation using Apple Foundation Models (iOS 26+, Apple Intelligence devices only), with the curated library as fallback

C) Cloud LLM API (e.g., Claude API) via a small backend. Requires network, an API key and a server, and has ongoing cost

D) Hybrid: curated library by default, with optional AI-generated prompts

X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 2
Should prompts adapt to the user in any way?

A) No, everyone sees the same kind of prompt; just one per day

B) User picks preferred categories/themes (e.g., gratitude, reflection, goals, creativity)

C) Prompts adapt based on the user's previous entries or mood (requires AI)

X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 3
Can the user skip or refresh the day's prompt?

A) No, one fixed prompt per day

B) Yes, the user can shuffle to get a new prompt (unlimited)

C) Yes, but limited (e.g., up to 3 refreshes per day)

X) Other (please describe after [Answer]: tag below)

[Answer]: C

---

## Section 2: Journal Entry

## Question 4
What should a "quick entry" contain?

A) Text only

B) Text plus a mood rating (e.g., 5 emoji/levels)

C) Text, mood, and optional photo

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 5
How many entries can a user make per day?

A) One entry per day (editable during that day)

B) One entry per day, editable any time afterward

C) Multiple entries per day

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 6
What should users be able to do with past entries?

A) Nothing beyond the current day (write-only journal)

B) Browse a chronological list / calendar of past entries

C) Browse plus search by text

D) Browse, search, and export (e.g., Markdown/PDF/text share)

X) Other (please describe after [Answer]: tag below)

[Answer]: D

---

## Section 3: Streak

## Question 7
What counts toward the streak?

A) At least one saved entry on a calendar day (in the user's local time zone)

B) Answering that day's prompt specifically (free-form entries don't count)

C) An entry with a minimum length (e.g., 20+ characters)

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 8
How forgiving should the streak be?

A) Strict: missing a day resets the streak to 0

B) Grace period: e.g., can backfill yesterday's entry until midday today

C) Streak freezes: user earns/has a limited number of "skip days"

X) Other (please describe after [Answer]: tag below)

[Answer]: B

---

## Section 4: Widget and Notifications

## Question 9
Which widget types do you want?

A) Home Screen small widget only (today's prompt or streak)

B) Home Screen small + medium (prompt and streak together on medium)

C) Home Screen small + medium plus Lock Screen widgets (streak count / prompt)

D) All of C plus interactive elements (e.g., refresh prompt button) and Control Center/StandBy support

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 10
Tapping the widget should:

A) Open the app on the home screen

B) Deep-link straight to the entry editor with today's prompt pre-loaded

X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 11
Should the app send a daily reminder notification?

A) No notifications

B) Yes, at a fixed default time (e.g., 8 PM)

C) Yes, at a user-configurable time, and skipped if today's entry is already done

X) Other (please describe after [Answer]: tag below)

[Answer]: C

---

## Section 5: Platform, Data, and Privacy

## Question 12
What is the minimum iOS version and UI approach?

A) iOS 17+ with SwiftUI and SwiftData (interactive widgets available, broad device coverage)

B) iOS 18+ with SwiftUI and SwiftData (adds Control Center widgets)

C) iOS 26+ with SwiftUI and SwiftData (required if you choose on-device Apple Foundation Models)

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 13
Where should journal data be stored, and how private should it be?

A) On-device only, no accounts, no sync

B) On-device plus iCloud sync (CloudKit) across the user's devices, no accounts

C) Either A or B, plus an optional Face ID / passcode lock for the app

D) Custom backend with user accounts

X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 14
What is the intended distribution and scope of this build?

A) Personal / demo project (not shipped to the App Store yet)

B) MVP intended for App Store release (free)

C) App Store release with monetization (e.g., subscription unlocking premium prompts/themes)

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 15
Which quality attributes should be explicitly in scope?

A) Basics only: unit tests for core logic (streak calculation, prompt selection)

B) A plus Dynamic Type, VoiceOver, and Dark Mode support

C) B plus localization (more than one language; please list them)

X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Section 6: Extensions

## Question 16: Security Extensions
Should security extension rules be enforced for this project?

A) Yes — enforce all SECURITY rules as blocking constraints (recommended for production-grade applications)

B) No — skip all SECURITY rules (suitable for PoCs, prototypes, and experimental projects)

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 17: Resiliency Extensions
Should the resiliency baseline be applied to this project?

**What this extension is.** Enabling it applies a set of **directional, design-time best practices** for building resilient systems, derived from the **AWS Well-Architected Framework (Reliability Pillar)** and resilience-review guidance. It steers requirements, design, and code toward fault tolerance, high availability, observability, and recoverability — covering 15 practice areas across business goals, change management, observability, high availability, disaster recovery, and continuous improvement.

**What this extension is NOT.** Enabling it does **not** make your workload production-ready, nor does it certify or guarantee any availability, RTO, or RPO target. It is a **starting point** that scaffolds good resiliency decisions early — it is not a substitute for a formal **AWS Well-Architected Review** of the built system.

Treat the output as a well-grounded **first draft of your resiliency posture** to build on and validate — not a finished, production-certified result.

A) Yes — apply the resiliency baseline as directional best practices and design-time guidance (recommended for business-critical workloads, as an informed starting point that you can validate and harden before go-live)

B) No — skip the resiliency baseline (suitable for PoCs, prototypes, and experimental projects where rapid iteration matters more than reliability)

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 18: Property-Based Testing Extension
Should property-based testing (PBT) rules be enforced for this project?

A) Yes — enforce all PBT rules as blocking constraints (recommended for projects with business logic, data transformations, serialization, or stateful components)

B) Partial — enforce PBT rules only for pure functions and serialization round-trips (suitable for projects with limited algorithmic complexity)

C) No — skip all PBT rules (suitable for simple CRUD applications, UI-only projects, or thin integration layers with no significant business logic)

X) Other (please describe after [Answer]: tag below)

[Answer]: C
