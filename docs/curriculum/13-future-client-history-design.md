# Exercise 13 — Future Client History Architecture (DESIGN ONLY)

## Why we're doing this

We want today's architecture to support tomorrow's high-value feature without prematurely building it.

## Codex skill

- future-compatible architecture
- resisting premature implementation
- modeling stable identity relationships

## Skills practiced

- `frame-work` — Frame a bounded task
- `plan` — Plan in proportion to risk
- `record-decisions` — Preserve durable technical judgment

## Future requirement

When programming for a client, surface prior exercise history:

- date
- sets
- reps
- load
- notes
- potentially recent trends or suggested working load

Example:

Front Squat — Whitney

Aug 14
3 x 5 @ 35 kg

Aug 7
3 x 5 @ 32.5 kg

Jul 31
3 x 6 @ 30 kg

## Task

Design only.

Propose entities such as:
- Client
- TrainingSession
- ExercisePerformance
- ExerciseSet or an appropriate alternative

Every performance record must reference canonical `Exercise.id`.

Discuss:
- sets with different loads/reps
- units
- unilateral exercises
- bodyweight exercises
- assisted exercises
- tempo/RPE/RIR
- correcting historical records
- migrations from existing data

### STOP / REVIEW

Inspect the proposed entities, relationships, examples, migration considerations, tradeoffs, and links to existing canonical exercise IDs. Confirm from the diff that there is no application code, migration, client record, performance record, or load recommendation implementation.

Verify that the existing exercise library and alias model can support this cleanly, then decide whether the design should become an ADR, remain a future plan, or be revised.

Teach back: How can architecture preserve a future option without prematurely implementing it?

## Final reflection

Before writing anything, answer in your own words:

1. What makes an effective Codex task?
2. What belongs in `AGENTS.md` rather than a prompt?
3. What is a verification harness?
4. Why do fixtures matter for the resolver?
5. Why should fuzzy matching suggest rather than define identity?
6. When would you use a worktree?
7. What architectural decisions proved most important?

Codex drafts a concise first-person retrospective that cites selected learning artifacts. The tutorial is complete only after the user approves that reflection, the ledger entry, justified skill-confidence changes, and the final progress update—and the project has a working Notes companion workflow. Then use a real, bounded next product increment as a springboard capstone: the user frames it and directs Codex through it, with evidence and a reflection rather than a grade.
