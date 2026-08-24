# Stabilize the reusable and learner Git histories

This ExecPlan is maintained according to `PLANS.md`. Keep the living sections current while the work proceeds.

## Purpose / Big Picture

The repository currently contains valuable work in three states that must not be conflated: reusable starter changes intended for `main`, approved learner progress intended for `learner/main`, and unapproved current or later tutorial work that must remain outside both integration branches. Stabilization will preserve every existing change, publish only reviewed reusable material to `main`, bring approved learner work through Exercise 08 Task A into `learner/main`, and leave the next unapproved task on a fresh exercise branch.

After completion, another learner can start from a clean, privacy-reviewed `main`; this learner can resume from the exact approved checkpoint on `learner/main`; and future exercises can follow one branch and pull request per exercise without rewriting prior history.

## Plan Status

Approved on 2026-08-24. Execution is in progress. Committing, pushing, opening pull requests, and merging remain explicit plan steps and must pause for the reviews named below; the user approved committing and pushing the initial reusable update and proceeding with this plan on 2026-08-24.

## Progress

- [x] (2026-08-24T17:34:04Z) Inspected the branch, worktree, and uncommitted-change topology without modifying learner state.
- [x] (2026-08-24T17:34:04Z) Obtained approval for the steady-state branch policy and the one-time stabilization scope.
- [x] (2026-08-24) Preserved the complete learner working state in local-only commit `6dab70d` on `recovery/pre-stabilization-2026-08-24`.
- [x] (2026-08-24) Preserved the dirty reusable candidate in local-only commit `aaa56dc` on `recovery/reusable-candidate-2026-08-24`.
- [ ] Inventory and classify every commit, file, and overlapping hunk into reusable, approved learner, or unapproved work. Reusable classification is complete; learner classification remains in progress.
- [ ] Review, verify, commit, and push coherent reusable updates to `main`.
- [ ] Assemble and verify the approved learner catch-up branch through Exercise 08 Task A.
- [ ] Review and merge the catch-up branch into `learner/main`.
- [ ] Create the correct fresh exercise branch and restore only the next unapproved task there.
- [ ] Confirm that worktrees, branches, remotes, and progress records agree.

## Surprises & Discoveries

- The active branch is still named `tutorial/exercise-03`, although committed and uncommitted work has advanced well beyond Exercise 03. This makes the branch name an unreliable indicator of scope.
- Reusable updates and learner-specific progress coexist in dirty worktrees. File-level copying is not always sufficient because a single file can contain changes from more than one classification.
- Local `main` and `learner/main` are ahead of their remote counterparts, so remote state is not a safe recovery source for all completed work.
- The reusable candidate included a starter-form `PROGRESS.md`, but restoring a learner-ledger file wholesale would violate the repository's safety rule. It was excluded because no separately justified schema change was identified.

## Decision Log

- Decision: Use one fresh `tutorial/exercise-NN` branch per numbered exercise going forward, with coherent commits after approved task checkpoints and a pull request into `learner/main` after the final checkpoint.
  Rationale: This preserves inspectable learning increments without adding a branch per task.
  Date: 2026-08-24

- Decision: Commit reusable work by coherent approved update, not mechanically by conversation or thread.
  Rationale: A conversation is not a stable product boundary; a reviewed artifact-level change is.
  Date: 2026-08-24

- Decision: Perform one catch-up integration rather than manufacturing historical exercise branches for Exercises 04 through 07.
  Rationale: Retrofitting branch history would add ceremony without improving the product or learning evidence.
  Date: 2026-08-24

- Decision: Preserve the complete dirty state in a local-only recovery snapshot before classification. Do not push that snapshot unless a later full privacy review explicitly approves it.
  Rationale: The snapshot makes classification recoverable while preventing unapproved or private material from reaching the remote.
  Date: 2026-08-24

## Outcomes & Retrospective

Not yet executed. On completion, record the final branch tips, pull requests or merge commits, verification results, intentionally retained local recovery material, and any policy adjustment learned from the stabilization.

## Context and Orientation

`main` is the reusable starter line. It may contain shared product documentation, architecture, curriculum, and harness changes, but must not contain this learner's progress, reflections, identity, private links, or credentials. `learner/main` is the persistent integration line for approved personal tutorial state. `tutorial/exercise-NN` branches contain one exercise's work and target `learner/main`.

At initial inspection, local `main` pointed to `64bfe51` and was one commit ahead of `origin/main`. Local `learner/main` pointed to `352f325` and was two commits ahead of `origin/learner/main`. The active `tutorial/exercise-03` branch pointed to `51601eb`, six commits ahead of `learner/main`, and its worktree contained substantial uncommitted work through later exercises. Treat these identifiers as evidence of the starting state, not as commands to reset branches to fixed hashes.

Two reusable candidate worktrees also existed under `/private/tmp`: one dirty worktree attached to `main`, and one detached candidate containing the approved `docs/PRODUCT.md` exercise-identity clarification. Inspect both before choosing a consolidation path. Never delete a worktree until its unique changes are committed to the correct branch or proven duplicated elsewhere.

The three classifications are:

1. Reusable work: shared harness, curriculum, architecture, and product documentation suitable for a clean starter.
2. Approved learner work: completed checkpoints and approved learning evidence through Exercise 08 Task A.
3. Unapproved work: Exercise 08 Task B in progress, later-exercise drafts, rejected alternatives, and any learner evidence not yet approved.

When a file contains more than one classification, classify and apply individual hunks. Do not resolve ambiguity merely from a filename or branch name.

## Plan of Work

### Milestone 1: Preserve and inventory

In the learner worktree, record the current branch tips, worktree list, status, staged diff, unstaged diff, and untracked files. Create a new local recovery branch named with the stabilization date from the current active branch, then make one clearly labeled WIP safety commit containing the complete working state. Do not push this branch. Confirm that the safety commit contains all formerly dirty and untracked files and that the worktree is clean.

Build a classification ledger in the running notes for this plan. For every commit after `learner/main` and every changed or untracked file in the safety snapshot, record its intended lane, approval evidence, dependencies, and whether hunk-level separation is required. Pause for user review wherever approval evidence or privacy classification is uncertain.

### Milestone 2: Publish reusable updates safely

Start from an updated, clean `main` worktree. First inspect the existing local-only `main` commit and every dirty reusable candidate; do not assume that being based on `main` makes a change reusable. Consolidate only approved reusable changes into coherent commits. The product-identity clarification and the Git-lifecycle guidance may share a documentation-maintenance series, but each commit must remain understandable and independently reviewable.

Before each commit, inspect the complete candidate diff, including untracked files, for learner progress, reflections, identity, private links, credentials, and unrelated changes. Run documentation checks and any tests affected by shared harness or exercise changes. Present the full reusable candidate and verification evidence for review. Only after approval, commit it to `main` and push `main`. Do not amend or force-push published history.

After the reusable series is published, bring the new `main` into both the learner catch-up branch and whichever fresh exercise branch remains active. Resolve conflicts by preserving reusable starter semantics and then deliberately reapplying learner-only state; never solve a conflict by copying learner ledger files into `main`.

### Milestone 3: Assemble approved learner history

Create a catch-up branch from the synchronized `learner/main`. Bring in the already committed approved exercise work from the old exercise branch without rewriting its commits when a normal merge suffices. Then selectively apply only approved uncommitted work through Exercise 08 Task A from the recovery snapshot, separating reusable changes and unapproved work at hunk level where necessary.

Group commits around genuine approved checkpoints or coherent recovery units. Preserve the append-only learning log. Confirm that `PROGRESS.md` points to Exercise 08 Task B only after the approved Task A evidence, reflection, skill updates, and verification are present together.

Run all verification required by the included exercises plus the repository's full relevant test suite. Inspect the entire difference from `learner/main`, with special attention to credentials, accidental private material beyond intended learner evidence, later-exercise implementation, and reusable files that should instead land on `main`. Present the candidate catch-up diff and evidence for approval, then push the branch, open a pull request targeting `learner/main`, review it, and merge it.

### Milestone 4: Restore the active exercise boundary

Synchronize local `learner/main` after the catch-up merge. Create the fresh branch appropriate for the current exercise from that exact tip. Restore only the next unapproved task's work from the recovery snapshot. Do not restore later drafts merely because they were present in the old worktree.

Verify that the difference between the fresh exercise branch and `learner/main` contains only current-exercise work after the last approved checkpoint. Push the branch only after its privacy review; no pull request is required until the exercise's final checkpoint is approved.

### Milestone 5: Close the stabilization

Fetch and inspect remote refs. Confirm that reusable `main`, personal `learner/main`, and the active exercise branch have the intended ancestry and scope. Confirm that no worktree has unexplained modifications. Retain the local recovery branch until the user accepts the final audit; then ask separately before deleting it or any temporary worktree because those are destructive cleanup actions.

Update this plan's Progress, Surprises & Discoveries, Decision Log, and Outcomes & Retrospective with the exact final evidence. The stabilization itself must not fabricate tutorial reflection or advance progress beyond the last user-approved checkpoint.

## Concrete Steps

Run inspection commands from `/Users/dan/Documents/D/dev/gym_assistant`. Use `git status --short --branch`, `git worktree list --porcelain`, `git branch -vv`, and revision comparisons to capture the starting topology. Inspect staged, unstaged, and untracked content before creating the local recovery snapshot.

Create the safety snapshot on a newly named `recovery/pre-stabilization-YYYY-MM-DD` branch and make a local WIP commit. Because this commit intentionally contains mixed states, never push it as part of the ordinary workflow. Verify that `git status --short` is empty afterward and inspect the committed file list against the pre-snapshot inventory.

Use separate clean worktrees for reusable `main` work and the learner catch-up branch. Apply changes with normal merges, cherry-picks, or patch-level staging according to the reviewed classification ledger. Avoid reset, rebase, force-push, and history replacement. Before every remote mutation, show the exact branch, target, candidate diff, and verification result, then obtain the required approval.

Record exact commands and meaningful outputs in Artifacts and Notes as execution proceeds; do not paste long routine output when a concise summary and the failing or decisive lines suffice.

## Validation and Acceptance

The stabilization is accepted only when all of the following are observable:

- `main` is clean, pushed, and contains only reviewed reusable updates. Its candidate history contains no learner progress, reflections, identity, private links, credentials, or unintended learner-specific map sources.
- `learner/main` is clean, pushed, and contains all approved work and learning evidence through Exercise 08 Task A, with `PROGRESS.md` naming Exercise 08 Task B as next.
- The active `tutorial/exercise-NN` branch starts at the synchronized `learner/main` tip and differs from it only by the current unapproved exercise work.
- Relevant targeted checks and the full applicable test suite pass. Any check that cannot run is named with the reason and residual risk.
- Every worktree modification is either absent or explicitly explained. The local recovery branch still protects the pre-stabilization state until the user approves cleanup.
- No existing starter tag moved. If a new reusable starter checkpoint is published, it uses a new tag after separate approval.

## Idempotence and Recovery

The local recovery snapshot is the primary rollback point. Each later milestone uses new branches or clean worktrees and additive Git operations, so a failed attempt can be abandoned without changing the snapshot. If a merge or patch application becomes ambiguous, abort that operation and return to the clean branch tip; do not discard files from the original learner worktree.

Do not use destructive resets, rebases of published work, force-pushes, or deletion as shortcuts. If a commit is classified incorrectly after publication, use a visible corrective commit and document it here. If network access fails, keep reviewed commits local, record their hashes and worktree paths, and resume pushing later without rebuilding them.

## Artifacts and Notes

Initial evidence, captured 2026-08-24:

- Local `main`: `64bfe51`, one commit ahead of `origin/main`.
- Local `learner/main`: `352f325`, two commits ahead of `origin/learner/main`.
- Active learner branch: `tutorial/exercise-03` at `51601eb`, six commits ahead of `learner/main`, with mixed uncommitted work.
- Detached reusable candidate: `/private/tmp/gym-assistant-product-identity-main`, containing the approved product-identity clarification plus this approved maintenance guidance.
- Existing dirty `main` worktree: `/private/tmp/gym-assistant-agents-main`; preserve it until fully classified.
- Initial reusable policy commit: `7533fe2`, pushed to `origin/main`.
- Learner recovery snapshot: `6dab70d`, local only.
- Reusable-candidate recovery snapshot: `aaa56dc`, local only.

Append concise evidence here during execution, including recovery commit, reusable commits, verification summaries, pull request target and result, final branch tips, and retained cleanup items.

## Interfaces and Dependencies

This plan changes repository history organization and documentation; it does not introduce a runtime software interface. It depends on local Git worktrees and branches, the configured `origin` remote, and GitHub pull requests for review into `learner/main`. Network-dependent fetch, push, and pull-request operations require their normal explicit approval and should occur only after the local candidate passes its review gates.
