# Exercise 05 — Write the Resolver Exam Before the Resolver

## Why we're doing this

"Make duplicate detection smart" is not testable.

We first define examples of correct and incorrect behavior.

## Codex skill

- fixture-driven development
- acceptance criteria
- building objective feedback before implementation

## Skills practiced

- `frame-work` — Frame a bounded task
- `verify` — Build an evidence-producing delivery loop

## Task A — Create fixture categories

Create a machine-readable resolver fixture set with at least:

### MUST_MATCH
Examples that should resolve automatically when an alias is already known or normalization is deterministic.

Examples:
- `SL RDL` ↔ `Single-Leg Romanian Deadlift`
- `single leg rdl` ↔ `Single-Leg Romanian Deadlift`
- `1-leg RDL` ↔ `Single-Leg Romanian Deadlift`

### MUST_NOT_MATCH
Examples that must remain distinct.

Examples:
- `RDL` ≠ `Single-Leg Romanian Deadlift`
- `B-Stance RDL` ≠ `Single-Leg Romanian Deadlift`
- `Single-Leg Squat` ≠ `Single-Leg Romanian Deadlift`

### SUGGEST_REVIEW
Examples where candidate generation is useful but automatic identity is unsafe.

Examples:
- `Kickstand RDL` → perhaps `B-Stance RDL`
- `Australian Row` → perhaps `Aussie Pull-up`

Include additional realistic strength-training names.

### STOP / REVIEW

Inspect the machine-readable fixture diff and the human-readable cases. The user should inspect the fixture set rather than accepting Codex's labels.

Ask:
- Which cases would be dangerous to auto-merge?
- Are abbreviations being confused with movement identity?
- Are meaningful modifiers preserved? Examples: single-leg, deficit, paused, incline, half-kneeling.

Do not write fuzzy-matching code yet.

Decide whether each category expresses safe product behavior and whether important real-world modifiers are represented.

Teach back: Why is a dangerous expected false merge more valuable to define before writing the matcher?

## Task B — Add a fixture runner

Create a test runner capable of reporting:
- passes
- false merges
- missed expected matches
- candidate ranking failures

The runner can initially fail because the resolver is not implemented.

That is acceptable.

### STOP / REVIEW — Fixture runner

Inspect the runner command, failure output, category totals, and diff. Verify that failures distinguish false merges, missed matches, and ranking failures; decide whether the output will help both a human and Codex correct behavior.

Teach back: How can a deliberately failing harness still be useful evidence at this stage?

After the user approves the reflection and checkpoint, append learning evidence, update justified skill confidence and progress, and advance to Exercise 06.
