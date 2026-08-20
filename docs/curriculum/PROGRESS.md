# Tutorial Progress

Current exercise: 01
Current task: Task D — Prepare the first pull request
Current task state: in progress — `learner/main` established, approved `PLAN-001` recorded, and exercise branch pushed; pull-request creation and review remain
Task completion condition: pass `STOP / REVIEW — First pull request`
Completed tasks: Task A — Repository, Git, and product orientation; Task B — Create the local and remote repository; Task C — Initial architecture-spike plan
Remaining tasks: Task D — Prepare the first pull request; Task E — Merge and synchronize
Most recent checkpoint: `STOP / REVIEW — Spike plan` (passed)
Relevant skills: collaborate, record-decisions, verify

## Completed

- [ ] 01 — Repository, Git/GitHub, and specification
- [ ] 02 — Apple Notes Service architecture spike
- [ ] 03 — Review and commit the architecture decision
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
- Local and remote `learner/main` start at reusable commit `2b4dbe1` and are the persistent integration target for personal tutorial progress.
- The current local branch is `tutorial/exercise-01`; its learner-specific Task A–C evidence, progress, skills, map orientation, and approved `PLAN-001` are committed and pushed. No pull request has been opened yet; its base must be `learner/main`, not reusable `main`.
- Full Xcode 26.6 is now installed and selected as the active developer directory. This happened after Task A and does not advance the tutorial; Exercise 02 still owns verification of the toolchain and the Notes-integration mechanism gate.
- Task A orientation, Task B repository, and Task C planning evidence are recorded in `LEARNING_LOG.md`.
- Task C selected a deliberate hybrid from a regular-prompt plan, a Plan-mode plan, and an isolated regular-prompt control without `PLANS.md`. The approved plan requires a lightweight keyboard interaction, separate cold/warm gates, system-latency measurement excluding human decision time, and a stop before product implementation.
- The temporary post–Task-A root and backup branch were deleted after restoration; obsolete commit `68ecdb2` was pruned and never pushed.

## Relevant durable context

- Skill confidence: `docs/curriculum/SKILLS.md`
- Agentic-AI context and outside ideas: `docs/curriculum/AGENTIC_AI_MAP.md`
- Approved learning evidence: `LEARNING_LOG.md` — 2026-08-18, Exercise 01, Task A; 2026-08-19, Exercise 01, Tasks B–C
- Active durable plan: `docs/exec-plans/PLAN-001-notes-interaction-spike.md`, approved and not yet executed

## Next action

Open Exercise 01 and complete only Task D. Have the user open the pushed `tutorial/exercise-01` pull request against `learner/main`, inspect its complete documentation-only diff and checks, and answer the checkpoint teach-back before any merge.
