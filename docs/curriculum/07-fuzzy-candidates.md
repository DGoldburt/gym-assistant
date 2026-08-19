# Exercise 07 — Fuzzy Candidate Generation + Human Confirmation

## Why we're doing this

Similarity should help the user decide, not silently rewrite exercise identity.

## Codex skill

- ranking systems
- confidence thresholds
- human-in-the-loop design
- measuring false-positive cost

## Skills practiced

- `verify` — Build an evidence-producing delivery loop

## Desired behavior

Input:

`1 leg romanian deadlift`

Possible ranked candidates:

1. Single-Leg Romanian Deadlift
2. Romanian Deadlift
3. B-Stance Romanian Deadlift

The resolver may:
- auto-resolve only when durable alias knowledge makes identity explicit
- suggest candidates when similarity is uncertain
- require human confirmation before creating a new alias relationship

## Task A — Propose scoring

Ask Codex to propose:
- features used for ranking
- treatment of meaningful modifiers
- threshold behavior
- false-positive protections

Do not implement yet.

### STOP / REVIEW

Inspect the proposed features, thresholds, tradeoffs, and false-positive protections. Challenge the proposal with:
- incline vs flat press
- single-leg vs bilateral RDL
- half-kneeling vs standing press
- paused vs normal squat
- front squat vs goblet squat

Decide whether automatic resolution is limited to durable identity knowledge and whether ambiguous similarity always remains reviewable.

Teach back: Why should a similarity score rank candidates but not create canonical identity?

## Task B — Implement candidate generation

Implement and evaluate against fixtures.

Report:
- precision on automatic resolutions
- quality of top suggestions
- false merges
- unresolved cases

### STOP / REVIEW — Candidate-generation evidence

Inspect the fixture metrics, false-merge report, representative rankings, and unresolved cases. Decide whether the candidate generator ranks useful alternatives without silently establishing identity.

Teach back: What evidence would show that a candidate generator is unsafe even if its top suggestion is often correct?

## Task C — Persist user confirmation

When a user confirms a suggestion:
- persist the entered term as an alias
- future lookup should use the durable alias path rather than fuzzy inference

### STOP / REVIEW — Confirmation evidence

Inspect the persisted alias record and the next lookup of that alias. Test at least one accepted suggestion and one rejected suggestion; decide whether confirmation—not similarity—created the durable relationship.

Teach back: What changed between the first fuzzy lookup and the next exact alias lookup?

After the user approves the reflection and checkpoint, append learning evidence, update justified skill confidence and progress, and advance to Exercise 08.

## Optional map check-in

After this exercise is recorded, offer a brief, non-blocking map check-in: How did fixtures, uncertainty, and human confirmation change the learner's view of what an agent should automate versus leave reviewable? Preserve a summary in `LEARNING_LOG.md` only if the user asks or approves.
