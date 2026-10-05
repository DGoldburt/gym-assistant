# Optional Lab 07 — Review Saturation and OpenCode Comparison

## Skills practiced

- `review` — Challenge work from more than one perspective
- `verify` — Build an evidence-producing delivery loop
- `set-boundaries` — Control autonomy safely
- `operate-cli-agents` — Direct coding agents through terminal workflows

## Learning objective

Learn how much new, actionable information a few independent reviews add when the
review target and conditions stay fixed. Then compare an OpenCode review against the
same evidence while separating the effects of the agent harness, model, and provider.
Review repetition measures diminishing returns; it is not a demand for unanimous
reviewers or endless review.

## Starting state and product-scope guard

Begin after Exercise 13's independent-review task. Choose one small, already
implemented change with a complete diff or fixed commit, acceptance criteria, and
verification evidence. Use a clean review worktree or read-only session; record the
starting Git state. Keep client information, private Notes content, and credentials out
of prompts and retained evidence.

This lab is read-only review practice. Do not change product success criteria, implement
new features, fix the target during the comparison, or advance a numbered exercise.
The human decides what, if anything, to fix afterward. Do not change `PROGRESS.md`.

## Task A — Measure independent-review saturation

1. Freeze and record the target commit hash or exact diff, acceptance criteria,
   verification output, review prompt, model, reasoning effort, sandbox and permission
   settings, and supplied context. Direct each reviewer to inspect the final
   implementation files and the frozen commit diff; supply the acceptance criteria
   separately. Give each reviewer the same repository instructions and evidence,
   without prior reviewers' findings or the implementer's defense. Explicitly exclude
   `docs/curriculum/LEARNING_LOG.md`, `docs/curriculum/PROGRESS.md`, and
   `docs/curriculum/SKILLS.md` from reviewer evidence and instruct reviewers not to
   read them: these learner-state files may contain the implementer's conclusions.
2. Run a fresh, independent, read-only review of that target. Repeat under the frozen
   conditions for at most three eligible runs. Record each session's actual files and
   context accessed, working directory, Git state, configuration, and output; note any
   deviation from the plan. Prompt-level exclusion does not enforce filesystem access:
   a worktree alone does not prevent reads. Audit the transcript or tool log for access
   to excluded files. If a reviewer accessed one, mark that run context-contaminated
   and do not count it toward the saturation stopping rule. When warranted, a sanitized
   review bundle or stronger filesystem boundary is an optional stricter control.
   Do not edit, rebase, or otherwise change the target between runs.
3. For each reported finding, cite the target location and supporting evidence. Label
   it **actionable** (a supported issue requiring a change), **duplicate** (the same
   issue already found), **nitpick** (a preference without material effect), or **false
   positive** (contradicted by the target or acceptance evidence). Track new actionable
   findings by eligible run, counting each issue once; keep contaminated reports out of
   those counts.
4. Stop early after two consecutive eligible reviews yield zero new actionable findings.
   Stop after the third eligible review in any case. Preserve the full run sequence,
   including zero-finding and context-contaminated runs; do not keep sampling until
   reviewers agree.
5. Present the deduplicated findings to the learner for a human disposition: fix now,
   defer with reason, or reject with evidence. Keep any approved fixes outside the
   frozen comparison and its counts.

### STOP / REVIEW — Saturation and disposition

Inspect the frozen inputs, separate acceptance criteria, final implementation files and
commit diff reviewed, session boundaries, transcript or tool-log audit, actual files and
context accessed, each report, classification table, and new-actionable count per run.
Identify any context-contaminated run and exclude it from the stopping-rule calculation.
Decide whether the stopping rule was met and give a reasoned disposition for every
actionable finding. Explain what the sample supports about diminishing returns and what
it cannot establish about review completeness.

Teach back: Why must the target and review conditions remain fixed while you count new
findings, and why is zero new findings not proof that the change is correct?

## Task B — Compare an OpenCode review

1. Before setup, inspect the current OpenCode installation options and configuration,
   available model and provider, authentication method, permissions, data handling, and
   likely usage cost. Record what is known and unresolved. Obtain explicit user approval
   before installing OpenCode, changing persistent configuration, or using an external
   account or paid provider. If approval or a suitable read-only setup is unavailable,
   stop at a comparison plan; do not simulate a run.
2. If approved and available, review the **same frozen target**, acceptance criteria,
   verification evidence, and review prompt from Task A in a fresh read-only OpenCode
   session. Check the effective filesystem, command, network, and external-tool
   permissions. Share no private repository content with a provider unless the user
   explicitly authorizes that data flow. Record the effective model, provider, harness
   version/configuration, supplied context, output, usage or cost, and final Git state.
3. Classify OpenCode findings with the same four labels and human evidence standard.
   Compare unique actionable findings, false positives, review effort, and permission
   behavior with Task A. Identify changes in **harness** (agent interface and tooling),
   **model** (the model that reasons), and **provider** (the service or host serving it)
   separately. If more than one variable differs, treat any quality difference as an
   observation, not a causal claim about OpenCode or a model.
4. Ask the learner to decide whether another controlled comparison would be useful.
   Do not fix the frozen target or expand the product scope as part of this task.

### STOP / REVIEW — OpenCode comparison

If setup was not approved or a read-only run was unavailable, inspect the comparison
plan and the reason it stopped. Otherwise inspect the approved setup boundary, effective
permissions and data flow, unchanged target and acceptance evidence, OpenCode report,
classifications, cost record, and final Git status. Decide which findings warrant later
work and which observed differences could plausibly come from the harness, model,
provider, or changed context.

Teach back: What would you hold constant to test a harness difference, and what can you
conclude when the model or provider also changes?

## Evidence and completion

Retain the frozen target identifier, prompt and context manifest, acceptance and test
evidence, review configurations, per-run outputs and classifications, stopping-rule
calculation, human dispositions, and the OpenCode setup decision and comparison (if
run). Use redacted or synthetic excerpts when necessary; keep secrets and private
content out of Git.

After each checkpoint's required inspection and teach-back, draft a first-person
reflection in chat. Record only user-approved evidence and reflection in the learning
log, and update only justified skill confidence. This optional lab never changes
`PROGRESS.md` or completes a numbered exercise.
