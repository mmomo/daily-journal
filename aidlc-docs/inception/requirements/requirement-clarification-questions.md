# Requirements Clarification Questions

Thanks for answering all 18 questions. I found one contradiction and three ambiguities. Please resolve them before I write the requirements document.

---

## Contradiction 1: On-device AI prompts vs. minimum iOS version
You chose "On-device AI generation using Apple Foundation Models" (Q1:B) and also "iOS 17+" (Q12:A).
The Apple Foundation Models framework exists only on iOS 26+ and only on Apple Intelligence-capable devices (iPhone 15 Pro and later). On iOS 17–25 the app cannot call it at all.

### Clarification Question 1
How should we resolve this?

A) Raise the minimum to iOS 26+. AI prompts on Apple Intelligence devices, curated library fallback on other iOS 26 devices

B) Keep iOS 17+. Use the curated library everywhere, and add AI-generated prompts on iOS 26+ Apple Intelligence devices only (two code paths gated by availability checks)

C) Keep iOS 17+ and drop AI generation. Curated library only (categories and limited refresh still apply)

X) Other (please describe after [Answer]: tag below)

[Answer]: C

---

## Ambiguity 1: Content of the single small widget
You chose "Home Screen small widget only (today's prompt or streak)" (Q9:A). A small widget has room for one main element, and the option didn't say which.

### Clarification Question 2
What should the small widget show?

A) Today's prompt (truncated if long), with a small streak badge in a corner

B) The streak count prominently, with a "done / not done today" indicator

C) Two separate small widgets the user can choose between: one for the prompt, one for the streak

X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Ambiguity 2: Entry editing window vs. streak grace period
You chose "One entry per day, editable during that day" (Q5:A) and a grace period that lets the user "backfill yesterday's entry until midday today" (Q8:B). It isn't clear what is allowed during the grace window.

### Clarification Question 3
What is allowed for yesterday's entry before midday today?

A) Only create a missing entry for yesterday. An existing entry from yesterday is locked at midnight

B) Create a missing entry or edit an existing one for yesterday until midday; locked after that

C) Grace only protects the streak (it doesn't break until midday); the user cannot write a backdated entry at all

X) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Ambiguity 3: Extension scope vs. personal/demo project
You chose "Personal / demo project" (Q14:A) and also chose to enforce the full Security Baseline (Q16:A) and Resiliency Baseline (Q17:A) as blocking constraints. Both are allowed, but they pull in different directions. The Resiliency Baseline is based on the AWS Well-Architected Reliability Pillar and mostly targets server and cloud workloads. Since this app has no backend (on-device plus iCloud sync), many of its rules will be N/A, and the rest will add design and documentation overhead.

### Clarification Question 4
How should the extensions apply?

A) Keep both enforced as chosen. Rules that don't fit an on-device app are marked N/A with a reason

B) Keep Security enforced, and skip Resiliency

C) Skip both for this demo

X) Other (please describe after [Answer]: tag below)

[Answer]: C
