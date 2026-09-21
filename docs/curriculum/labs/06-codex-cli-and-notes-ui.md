# Optional Lab 06 — Codex CLI and the Notes UI Boundary

## Skills practiced

- `operate-cli-agents` — Direct coding agents through terminal workflows
- `orient` — Orient before changing
- `set-boundaries` — Control autonomy safely
- `verify` — Build an evidence-producing delivery loop

## Learning objective

Learn to start, inspect, steer, and stop Codex CLI sessions deliberately. Compare
interactive work with non-interactive execution, then investigate how a terminal agent
can invoke and verify a workflow that crosses into Apple Notes without mistaking a
successful shell command for successful UI behavior.

This is a surface-learning lab, not a product feature. It must not change product scope,
advance `PROGRESS.md`, install orchestration software, create custom agents, or grant
broad permissions merely to make an experiment pass.

## Starting state and safety boundary

- Run from the repository root with a clean or fully explained working tree.
- Record the exact Codex executable and version; do not assume the app-bundled and
  separately installed CLIs are identical.
- Use a disposable Notes scratch note containing synthetic text and no client or
  personal content.
- Keep raw screenshots, accessibility output, and UI logs outside Git. Commit only
  synthetic evidence and an approved learning reflection.
- Treat shell permissions, macOS Accessibility or Automation permissions, and desktop
  Computer Use app approvals as separate controls.
- Stop before installing software, editing persistent Codex configuration, changing
  macOS privacy settings, or using an unrestricted permission profile unless the user
  separately approves that action after inspecting the narrower failure.

## Task A — Inspect an interactive CLI session

Before asking Codex to change anything:

1. Identify the executable and version used by the terminal.
2. Start Codex from the repository root.
3. Inspect the session status, active permissions, model and reasoning effort, working
   directory, Git branch and status, and visible context indicator.
4. Ask for a read-only repository orientation: which instructions are active, which
   files are authoritative for the current task, and what actions are prohibited.
5. Exit without changing files and verify the final Git status.

Record what was directly visible, what Codex reported about itself, and what was
inferred. Do not treat the agent's explanation as a literal dump of hidden context.

### STOP / REVIEW — Interactive CLI orientation

Inspect the executable, version, session configuration, discovered repository
instructions, initial and final Git status, and any difference from a desktop project
thread. Decide whether the session began with an appropriately narrow permission
boundary and whether its account of context distinguishes observable evidence from
inference.

Teach back: What state belongs to the CLI process, the current conversation, the
repository, and persistent configuration respectively?

## Task B — Compare interactive and non-interactive execution

Choose one bounded, read-only task with an objective result, such as inventorying the
current verification commands and identifying one uncovered failure. Run the same task:

1. in an interactive Codex CLI session; and
2. through `codex exec` without allowing edits.

Preserve the prompt, relevant configuration, output, elapsed time if useful, and final
Git status. Compare steerability, approval behavior, output structure, reproducibility,
context visibility, and suitability for a repeatable script. Quality and safe execution
matter more than speed.

### STOP / REVIEW — Execution-mode comparison

Inspect both outputs against the same repository evidence. Decide which mode is better
for exploratory work and which is better for a stable repeatable task, and identify any
claim that one run made without sufficient evidence.

Teach back: When does `codex exec` improve reproducibility, and what interactive
judgment does it remove?

## Task C — Investigate the CLI-to-Notes boundary

Define one synthetic, reversible Notes case before acting. The narrow target is to learn
which layers a CLI task can invoke and observe, not to obtain unrestricted GUI control.

1. Have the CLI build or prepare only the existing approved Notes mechanism.
2. Attempt the smallest authorized command-line bridge that can invoke the workflow or
   a read-only UI probe. Keep the exact process identity and permission request visible.
3. Require structured evidence for shell completion, application invocation, expected
   text or cancellation integrity, and focus. Mark any property the CLI cannot observe
   as unverified.
4. Where necessary, use an independently authorized desktop Computer Use process or
   direct learner inspection to verify the visible Notes result. Do not relabel that
   evidence as CLI observation.
5. Preserve denials and failed calibration separately from product failures and valid
   passes. A cleanly identified permission or observability boundary is a valid learning
   result.

### STOP / REVIEW — Notes UI boundary

Inspect the synthetic case, commands, process and permission boundary, structured
assertions, independent UI evidence, and final Notes and Git state. Decide which claims
were proven by shell output, accessibility state, visual inspection, or human judgment.
Reject any conclusion that equates command success with correct Notes behavior.

Teach back: What bridge lets a terminal agent act on a GUI workflow, and what evidence
must return across that bridge before the agent can verify success?

## Completion

After the user completes a task checkpoint's required inspection and approves its
reflection, append that task's lab evidence to `LEARNING_LOG.md` and update only
justified skill confidence before continuing. Do not update `PROGRESS.md`.

Do not extract a reusable prompt, project configuration, custom agent, or packaged Skill
from this lab unless repeated use later reveals a stable procedure whose benefit can be
tested against the simpler instructions above.

## Official references

- [Codex CLI](https://learn.chatgpt.com/docs/codex/cli)
- [Permissions](https://learn.chatgpt.com/docs/permissions)
- [Computer Use](https://learn.chatgpt.com/docs/computer-use)
- [Agent approvals and security](https://learn.chatgpt.com/docs/agent-approvals-security)
