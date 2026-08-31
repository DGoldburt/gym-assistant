# Exercise 12 — Verification Harness + Agentic Manual Testing

## Why we're doing this

A coding agent becomes more reliable when the environment can objectively tell it what succeeded or failed.

## Codex skill

- harness engineering
- one-command verification
- evidence-based completion
- agentic manual testing

## Skills practiced

- `verify` — Build an evidence-producing delivery loop
- `review` — Challenge work from more than one perspective

## Goal

Create one obvious verification command, for example:

    ./scripts/verify

It should run the relevant project checks such as:
- unit tests
- resolver fixtures
- database tests
- lint
- typecheck/static analysis
- build
- documentation structure and internal links

Use the tooling appropriate to the actual project stack.

## Task A — Audit the current harness

Ask Codex:
- what can be verified automatically?
- what still requires manual testing?
- what common failure could currently slip through?

### STOP / REVIEW

Inspect the audit's command inventory, blind spots, examples of failures that could escape, and automatic/manual boundary. Do not add meaningless tests merely to increase test count.

Decide which missing signal would most improve the agent's correction loop.

Teach back: What makes a verification check actionable rather than ceremonial?

## Task B — Build one-command verification

Make failures easy for Codex and humans to interpret.

### STOP / REVIEW — One-command verification

Inspect the command, its output, and at least one intentionally observed failure. Decide whether the failure identifies the check that failed and gives a useful route to investigation rather than a vague success/failure claim.

Teach back: What makes a verification check actionable rather than ceremonial?

## Task C — Agentic manual test

Give Codex a bounded workflow such as:

> Exercise the Notes lookup flow using a defined set of cases. Capture logs/screenshots or other artifacts where available. Report each step and result.

The goal is evidence, not "looks good."

### STOP / REVIEW — Manual-test evidence

Inspect the defined cases, the manual-test artifacts, and the reported step-by-step results. Decide whether another Codex session could reproduce the workflow without reconstructing it from chat.

Teach back: What does a manual-test artifact show that automated verification may not?

## Task D — Self-review

Have the implementing Codex context inspect its own diff for unnecessary complexity, brittle output, missing checks, architecture drift, and misleading success reporting. Fix justified findings and rerun verification.

### STOP / REVIEW — Self-review evidence

Inspect the self-review findings, the final diff, and the rerun verification evidence. Decide whether justified findings were fixed and whether the final verification result is honest about any remaining limits.

Teach back: How does self-review complement automated checks and manual artifacts rather than replace them?

After the user approves the reflection and checkpoint, append learning evidence, update justified skill confidence and progress, and advance to Exercise 13.

## Optional extension

After this exercise, Optional Lab 05 can extend the harness from code checks into
documentation invariants and a reviewable code-versus-doc drift scan. The lab does not
advance tutorial progress.
