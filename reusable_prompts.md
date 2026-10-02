# Reusable prompts

These prompts are learner-owned workflow aids. Replace the bracketed placeholders
before using them.

## After a pull request is merged

Use this after a reusable pull request has been merged into `main` on GitHub:

> Pull request #[PR number] has been merged into `main`. Verify the merge and
> confirm that the merged changes match the reviewed scope. Then:
>
> 1. Synchronize local `main` with `origin/main` without rewriting published
>    history.
> 2. Merge the updated `main` into `learner/main` and push `learner/main`.
> 3. Merge the synchronized `learner/main` into the active exercise branch and
>    push it, preserving all current learner work.
> 4. Remove the clean temporary worktree used to prepare the pull request, if it
>    still exists.
> 5. Delete the merged pull-request branch locally and remotely.
> 6. Do not delete recovery branches, historical exercise branches, active
>    branches, or any worktree with uncommitted changes.
> 7. Finish by verifying the relevant branch tips and ancestry, the visible
>    remote branches, the worktree list, and the clean status of every affected
>    checkout. Report anything retained and why.
>
> The pull-request branch is `[branch name]`. The temporary worktree is
> `[worktree path, if known]`. Stop and report the discrepancy instead of
> guessing if the PR is not merged, its scope differs from the reviewed change,
> a merge is not a clean integration, or an affected checkout contains
> unexplained changes.

Some remote verification can be automated with GitHub Actions—for example, checks
on the merged commit and repository branch state. Synchronizing local branches and
cleaning local Codex worktrees still requires a runner on that machine and should
retain the safety checks above; a normal GitHub-hosted Actions runner cannot clean
up the learner's local checkout.

## Spawn an independent review

Use this when a candidate change is ready for a second review:

> Spawn one independent review agent to review the candidate change. Give the
> reviewer the acceptance criteria, the repository instructions, and the complete
> diff against `[base branch or commit]`, but do not give it the implementer's
> reasoning, conclusions, or proposed defense of the change. The reviewer must
> not edit files, commit, push, or open or merge a pull request.
>
> Ask the reviewer to inspect correctness, scope, regressions, missing tests or
> verification, architecture and durable-context consistency, privacy or secret
> exposure, and unnecessary complexity. Require findings to be prioritized by
> severity and supported with concrete file and line references. The reviewer
> should also state what it inspected, what verification it ran, and any remaining
> uncertainty. If there are no findings, it should say so explicitly rather than
> inventing issues.
>
> After the reviewer returns, assess each finding independently. For every
> finding, recommend one disposition: accept and revise, reject with evidence,
> defer as a future direction, or escalate for human judgment. Do not make changes
> until I approve the proposed dispositions.

## Spawn an independent plan review

Use this when a consequential plan is ready for a first-pass review that is
separate from the author's rationale:

> Spawn one read-only `explorer` subagent to independently review `[plan path]`.
> Give the reviewer the plan, the repository instructions, and these authoritative
> sources: `[requirements, product, architecture, or planning-convention paths]`.
> Do not give it the author's rationale, previous review findings, desired
> conclusion, or proposed fixes. Use a fresh or minimally inherited agent context
> if supported; if material parent context must be inherited, disclose that
> limitation. The reviewer must not edit files, implement fixes, commit, push, or
> open or merge a pull request.
>
> Determine whether the plan is correct, complete, internally consistent,
> appropriately bounded, safely executable, and capable of producing trustworthy
> evidence. In particular, inspect whether it:
>
> 1. Tests the actual product or architectural risk rather than an easier proxy.
> 2. Maps each material requirement to an activity and observable acceptance
>    criterion.
> 3. Separates observed facts, user decisions, and unresolved assumptions.
> 4. Defines dependencies, failure handling, recovery, stopping conditions, and
>    approval boundaries.
> 5. Uses proportionate evidence and avoids premature or out-of-scope
>    implementation.
> 6. Is executable by someone other than its author without relying on hidden
>    context.
>
> For each material finding, report its severity (`blocker`, `major`, or `minor`),
> the exact artifact location, the conflicting requirement, evidence, or failure
> scenario, why it matters, and the smallest correction or test that would resolve
> it. Also list unresolved assumptions, requirements with no corresponding step or
> control, claims that cannot be verified, and the strongest part of the plan that
> should be preserved. Finish with a verdict: `ready`, `revise`, or `blocked`.
> Ignore cosmetic wording unless it creates ambiguity or operational risk, and do
> not invent findings merely to appear useful.
>
> Wait for the subagent to finish, then show me its first-pass response without
> silently reconciling it with the parent agent's opinion. After I inspect that
> response, assess each finding independently and propose a disposition, but do
> not change the plan until I approve those dispositions.

## Spawn an independent agent-harness review

Use this to review an agent harness, its instructions, tools, checks, and evidence
loop rather than only the application code it operates on:

> Spawn one read-only `explorer` subagent to independently review the agent harness
> represented by `[harness paths]`. Give the reviewer the repository instructions,
> the harness files, and these authoritative requirements or success criteria:
> `[paths or concise criteria]`. Do not give it the harness author's rationale,
> previous review findings, desired conclusion, or proposed fixes. Use a fresh or
> minimally inherited agent context if supported; if material parent context must
> be inherited, disclose that limitation. The reviewer must not edit files, run
> destructive or externally stateful actions, commit, push, or open or merge a
> pull request.
>
> Determine whether the harness can direct work safely and produce trustworthy,
> reproducible evidence. In particular, inspect whether it:
>
> 1. Supplies enough authoritative context without leaking the expected answer or
>    burying important instructions.
> 2. Uses an independent and trustworthy oracle, test, grader, or acceptance check.
> 3. Can create false confidence through weak tests, self-grading, reward hacking,
>    ignored failures, or successful tool execution that does not prove the real
>    task succeeded.
> 4. Defines permissions, approval boundaries, external writes, retries, timeouts,
>    termination, partial failure, and recovery safely.
> 5. Preserves the inputs, outputs, logs, versions, and environment details needed
>    to reproduce and diagnose a result.
> 6. Handles context growth, compaction, handoffs, lost assumptions, concurrent
>    agents, and shared-state conflicts explicitly where relevant.
> 7. Keeps the feedback and verification burden proportionate to the product risk
>    and approved success criteria.
>
> For each material finding, report its severity (`blocker`, `major`, or `minor`),
> the exact harness location, the conflicting requirement, evidence, or failure
> scenario, why it matters, and the smallest correction or adversarial test that
> would resolve it. Also list unresolved assumptions, unverified claims, missing
> controls, and the strongest part of the harness that should be preserved. Finish
> with a verdict: `ready`, `revise`, or `blocked`. Ignore cosmetic wording unless
> it creates ambiguity or operational risk, and do not invent findings merely to
> appear useful.
>
> Wait for the subagent to finish, then show me its first-pass response without
> silently reconciling it with the parent agent's opinion. After I inspect that
> response, assess each finding independently and propose a disposition, but do
> not change the harness until I approve those dispositions.
