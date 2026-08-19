# Exercise 03 — Commit the Architecture Decision

## Why we're doing this

Agentic projects need durable decisions. A long chat transcript is not an architecture record.

## Codex skill

- architecture decision records
- turning experimental evidence into durable context
- updating project instructions after learning

## Skills practiced

- `frame-work` — Frame a bounded task
- `collaborate` — Work through reviewable Git collaboration
- `verify` — Build an evidence-producing delivery loop
- `record-decisions` — Preserve durable technical judgment

## Task

Review the result of Exercise 02 and create/update:

`docs/decisions/001-notes-integration.md`

Use this structure:

- Context
- Decision
- Evidence
- Alternatives considered
- Consequences
- Known limitations
- Revisit triggers

Update `docs/ARCHITECTURE.md` if the experiment changed the design.

### STOP / REVIEW

Inspect the ADR diff against the Exercise 02 logs, screenshots, measurements, and approved reflection. The decision must be grounded in what actually happened during the spike, not what Codex assumes should happen.

You should be able to answer:

> What evidence would cause us to abandon the Notes companion approach later?

Decide whether the ADR accurately records alternatives, consequences, limitations, and a falsifiable revisit trigger.

Teach back: Why does an architecture decision belong in an ADR while the experimental procedure belongs in the plan and evidence log?

## Completion

After the user approves the reflection and checkpoint, append the learning evidence, update justified skill confidence and progress, and commit the architecture decision separately from later feature work. Then advance to Exercise 04.
