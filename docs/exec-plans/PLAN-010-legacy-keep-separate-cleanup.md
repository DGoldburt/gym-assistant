# Remove unused Keep Separate behavior while preserving existing records

This ExecPlan is a living document maintained according to `PLANS.md`. Keep its
Progress, Surprises & Discoveries, Decision Log, and Outcomes & Retrospective current.

## Purpose / Big Picture

Remove an unused identity-review API that no longer belongs to library editing.
The resulting core has no Keep Separate operation or result, and new databases
need no separate-exercise pair table. Existing databases keep any historical table
and records intact. The user can review this as one focused cleanup PR later.

## Plan Status

Approved on 2026-10-06 as a later follow-up. Defer implementation until PLAN-009
settles or is explicitly paused. PR publication remains a separate release action.

## Progress

- [x] (2026-10-06) Locate API, result/error cases, SQL methods, schema creation, test, and historical documentation.
- [x] (2026-10-06) Record the bounded later cleanup requested by the user.
- [x] (2026-10-06) Obtain approval of the bounded cleanup plan; retain its later sequencing.
- [ ] Inspect the then-current base after PLAN-009 settles; obtain publication authorization before a PR.
- [ ] Remove the unused API and fresh-schema creation; preserve existing persisted rows.
- [ ] Verify fresh/reopened databases and full regression; prepare one focused PR.

## Surprises & Discoveries

Keep Separate exists only as a core precursor and synthetic test, not a routine
product UI action. Its table can remain inert on existing databases without a
destructive migration. Removing the API and deleting historical decisions are
different changes; this plan covers only the former.

## Decision Log

Decision: retain cleanup as a separate later workstream.
Rationale: library editing does not need it, but concurrent edits would overlap
the library, identity-review, and test files. Date/Author: 2026-10-06 / Learner.

Decision: leave existing tables and records intact.
Rationale: removing dead behavior does not require erasing previous decisions or
adding a table-drop migration. Date/Author: 2026-10-06 / Learner approval of Codex proposal.

## Outcomes & Retrospective

The cleanup is recorded and unimplemented. A later focused PR is sufficient;
no tutorial reflection cycle or broad refactor is required. PR publication still
requires the user's authorization under repository rules.

## Context and Orientation

`Sources/GymAssistantCore/ExerciseIdentityReview.swift` exposes `keepSeparate`,
`keptSeparate`, and `sameExerciseCannotRemainSeparate`.
`Sources/GymAssistantCore/ExerciseLibrary.swift` contains `recordSeparateExercises`,
`separateExerciseDecisionCount`, and creation of `separate_exercise_decision`.
`Tests/GymAssistantCoreTests/ExerciseIdentityReviewTests.swift` has the corresponding
idempotency test. Completed PLAN-005/006 and LEARNING_LOG describe the earlier
approved work and must retain that historical evidence.

## Plan of Work

### Milestone 1: Remove unused behavior and prove compatibility

From the then-current approved integration base, inspect all Keep Separate callers
with `rg`. Remove the API and exclusive result/error cases, private SQL writer and
count helper, and fresh-database table creation. Remove only the dedicated test
because the product explicitly retired its behavior; do not rewrite remaining
tests to bypass failures. Add a compatibility test opening a synthetic old database
containing a pair decision, then verify that the row survives and ordinary identity
review still works. A fresh database must not create the unused table. Adjust
current architecture prose to describe completed cleanup, preserving historical
plans and learning evidence. Run full verification and inspect the complete diff.

### Milestone 2: Present a focused PR when publication is authorized

Use a separate managed worktree if the library-edit worktree is still in use;
otherwise reuse a suitable free checkout after accounting for all changes.
Target the approved learner integration branch, not reusable documentation-only
main. Record tests, explain preserved legacy data, and attach the PR to its chat.
Do not merge it without review. Apply the repository source-branch closeout rule
after merge and target synchronization.

## Concrete Steps

From the cleanup repository root run `git status --short` and
`rg -n 'keepSeparate|keptSeparate|sameExerciseCannotRemainSeparate|recordSeparateExercises|separateExerciseDecisionCount|separate_exercise_decision' Sources Tests docs`.
Inspect the implementation before editing because PLAN-009 may have changed
migration structure. Run `./scripts/verify` and `git diff --check` after changes.
Expect all five verification stages to pass; record the actual test total and
fresh/legacy schema outcomes. Do not install the app for this core-only cleanup.

## Validation and Acceptance

No production callable Keep Separate operation remains. A fresh database lacks
the pair table; a legacy database retains its table, exact pair IDs, and timestamp.
Create, Link, Skip, Back, merge, split, migration, and resolver fixtures continue
to pass where implemented on the approved base. The diff contains no learner
progress edits, source-data deletion, unrelated refactor, or new UI.

## Idempotence and Recovery

The cleanup drops no existing table and changes no persisted pair row. Reopening
old databases remains safe. Retain synthetic compatibility fixtures only. If an
unexpected caller or migration dependency exists, stop and revise this plan rather
than deleting it mechanically. Normal Git reversal of the code change restores
API availability without requiring recovery of discarded data.

## Artifacts and Notes

Keep this work excluded from PLAN-009 implementation. Preserve LEARNING_LOG and
completed ExecPlans. A physical drop of legacy tables is separate future scope
requiring explicit approval and recovery design.

## Interfaces and Dependencies

Use existing Swift/SQLite test infrastructure; add no dependency or new public
API. The resulting identity-review service exposes its supported observation
decisions only, with persisted library corrections supplied by the separate edit
service from PLAN-009.

Revision note — 2026-10-06: Initial proposed cleanup plan records the user-requested
follow-up and narrows it to retiring unused behavior without deleting history.

Revision note — 2026-10-06: Recorded user approval after quick review. The cleanup
remains sequenced after PLAN-009; existing pair decisions are preserved.
