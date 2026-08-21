# Tutorial Progress

Current exercise: 04
Current task: Task B — Implement the approved persistence model
Current task state: not started
Task completion condition: pass Exercise 04 Task B `STOP / REVIEW — Persistence verification`
Completed tasks: Exercise 01 — Tasks A–E; Exercise 02 — Tasks A–C; Exercise 03 — architecture decision; Exercise 04 — Task A: Design only
Remaining tasks: Exercise 04 — Task B: Implement the approved persistence model
Most recent checkpoint: Exercise 04 Task A `STOP / REVIEW` (passed)
Relevant skills: orient, frame-work, plan

## Completed

- [x] 01 — Repository, Git/GitHub, and specification
- [x] 02 — Apple Notes Service architecture spike
- [x] 03 — Review and commit the architecture decision
- [ ] 04 — Exercise library data model
- [ ] 05 — Resolver fixtures before resolver code
- [ ] 06 — Deterministic normalization and alias lookup
- [ ] 07 — Fuzzy candidate generation and human confirmation
- [ ] 08 — Frictionless new-exercise workflow
- [ ] 09 — Exercise blocks and insertion
- [ ] 10 — Programming-history tendencies
- [ ] 11 — Verification harness and agentic manual testing
- [ ] 12 — Independent review and worktrees
- [ ] 13 — Future client-history architecture (design only)

## Current notes

- The repository is initialized locally with repository-local author `Dan Goldburt <8260344+DGoldburt@users.noreply.github.com>`.
- Private SSH remote `origin` is `git@github.com:DGoldburt/gym-assistant.git`; GitHub CLI remains uninstalled.
- Local and remote `main` contain learner-free reusable history through branch-model update `2b4dbe1`. The immutable tag `tutorial-start-v1` still resolves to the original clean root `4161f6f`.
- Local and remote `learner/main` contain merged pull-request commit `feb2e0c` and are the persistent integration target for personal tutorial progress.
- Pull request #1 merged the reviewed `tutorial/exercise-01` state into `learner/main`; local synchronization was verified with a clean working tree.
- `tutorial/exercise-02` was pushed and merged into `learner/main` as `968f6c7`; local and remote `learner/main` were synchronized before creating local `tutorial/exercise-03` from that exact commit. Reusable `main` remains learner-free at `2b4dbe1`.
- Exercise 02 Task A verified macOS 26.6, Xcode 26.6, Swift 6.3.3, the selected full-Xcode developer directory, and the macOS SDK without installing or creating anything.
- Task A approved an Automator Quick Action as the first and smallest mechanism to test on macOS 26.6. A minimal AppKit Service provider is the only fallback if Notes-specific replacement, cancellation, focus, or latency fails.
- The approved Quick Action will offer Front Squat, Single-Leg Romanian Deadlift, and Aussie Pull-up; the selected choice replaces the selected Notes text, while cancellation must leave it unchanged.
- Exercise 02 Task B reverified the environment, aligned `PLAN-001` with the approved mechanism and three-choice contract, and passed implementation readiness without adding tools.
- Exercise 02 Task C preserved the failed Automator attempt and proved the AppKit Service-provider fallback through the real Notes shortcut, three-choice keyboard interaction, exact replacement, cancellation, and focus restoration.
- The AppKit fallback passed 5/5 cold trials with a 480.0 ms maximum, 20/20 warm trials with a 130.5 ms median and 192.9 ms nearest-rank p95, and 2/2 unchanged cancellation checks with zero integrity or focus failures.
- The Exercise 02 architecture gate passed. The learner would use the interaction repeatedly and chose to retain the Notes-adapter hypothesis while carrying forward the awkward shortcut and identical-text replacement ambiguity as limitations.
- Exercise 03 accepted ADR 001: retain Notes through an AppKit Service adapter, keep domain/resolver logic independent, reject Automator for the initial mechanism, and revisit or abandon the approach using explicit quantitative and human triggers.
- `docs/ARCHITECTURE.md` now identifies the Notes adapter direction as validated while leaving downstream domain boundaries as tutorial hypotheses.
- Exercise 04 Task A approved a minimal `Exercise` identity with an opaque UUID and required owned `preferredNameID`, plus durable `ExerciseName` records with globally unique normalized keys and workflow-supplied provenance.
- The approved deferred composite foreign key rejects orphan exercises, nonexistent preferred names, and preferred names owned by another exercise. A separate canonical-name role, contextual ownership, variants, program/client context, taxonomy, and history remain explicitly outside Task B.
- A read-only review of all 57 Notes in the Strength Training folder informed evidence-backed future directions without adding required fields to the initial model.
- Local reusable `main` includes approved success-criteria review guidance at `64bfe51`; local `learner/main` and the current exercise branch are synchronized with it. Nothing from that reusable update was pushed.
- Exercise 01 Tasks A–E evidence and approved reflections are recorded in `LEARNING_LOG.md`.
- Task C selected a deliberate hybrid from a regular-prompt plan, a Plan-mode plan, and an isolated regular-prompt control without `PLANS.md`. The approved plan requires a lightweight keyboard interaction, separate cold/warm gates, system-latency measurement excluding human decision time, and a stop before product implementation.
- The temporary post–Task-A root and backup branch were deleted after restoration; obsolete commit `68ecdb2` was pruned and never pushed.

## Relevant durable context

- Skill confidence: `docs/curriculum/SKILLS.md`
- Agentic-AI context and outside ideas: `docs/curriculum/AGENTIC_AI_MAP.md`
- Approved learning evidence: `LEARNING_LOG.md` — 2026-08-18, Exercise 01, Task A; 2026-08-19, Exercise 01, Tasks B–E and Exercise 02, Tasks A–B
- Completed durable plan: `docs/exec-plans/PLAN-001-notes-interaction-spike.md`; evidence is under `spikes/notes-interaction/`
- Accepted architecture decision: `docs/decisions/001-notes-integration.md`

## Next action

Begin Exercise 04 Task B by inspecting the approved model and existing project structure, then create only the persistence layer, migration, and tests for exercise creation, adding a confirmed name, exact normalized-name lookup, conflicting ownership, and the approved no-orphan invariant. Stop at the persistence-verification checkpoint before adding resolver or history behavior.
