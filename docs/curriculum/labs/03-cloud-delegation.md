# Optional Lab 03 — Bounded Cloud Delegation

## Skill practiced

- `scale-capabilities` — Apply advanced capabilities deliberately

## Learning objective

Learn to delegate work when a reviewable result matters more than continuous interaction. Practice making the task self-contained enough for an isolated environment while retaining human approval over the resulting changes.

## Task

1. Choose a small task with explicit inputs, constraints, and verification that can run without local UI access.
2. Record the starting Git state and environment assumptions.
3. Delegate the task without combining unrelated work.
4. Review the returned diff and evidence locally; do not merge automatically.

### STOP / REVIEW

Inspect whether the remote environment reproduced the task, whether the diff stayed in scope, and whether verification evidence is sufficient. Decide what additional context was genuinely necessary and what would have been redundant.

Teach back: When is delegation a better fit than an interactive local Codex task?
