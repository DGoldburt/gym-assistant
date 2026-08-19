# Optional Lab 04 — Stabilize Before Scheduling

## Skill practiced

- `scale-capabilities` — Apply advanced capabilities deliberately

## Learning objective

Learn why recurring automation should follow a proven manual workflow. Define useful output, failure evidence, permissions, cadence, and a stopping or escalation condition before scheduling anything.

## Task

1. Select a harmless workflow that has already run manually and produced useful evidence.
2. Define inputs, expected output, failure reporting, allowed writes, cadence, and ownership.
3. Run one equivalent unscheduled trial.
4. Propose automation only if the trial is predictable and worth repeating.

### STOP / REVIEW

Inspect the trial artifact and decide whether the workflow is stable, useful, and safe enough to recur without supervision. Confirm how failures will become visible and how the automation can be disabled.

Teach back: What can go wrong when an unstable agent workflow is scheduled too early?
