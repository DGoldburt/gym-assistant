# Exercise 13 — Independent Review + Parallel Worktrees

## Why we're doing this

The next agentic skill is delegation and review rather than direct implementation.

## Codex skill

- independent review
- task decomposition
- worktrees
- parallel agents
- merge judgment

## Skills practiced

- `set-boundaries` — Control autonomy safely
- `collaborate` — Work through reviewable Git collaboration
- `verify` — Build an evidence-producing delivery loop
- `review` — Challenge work from more than one perspective

## Task A — Independent review

Choose one recently completed feature.

Have one Codex task implement or improve it.

Then start a separate review task with instructions such as:

- inspect the diff as an independent reviewer
- look for incorrect behavior
- missing tests
- unnecessary complexity
- architecture violations
- security/privacy concerns
- UX regressions

Do not tell the reviewer what the first agent was worried about.

### STOP / REVIEW

Inspect both review reports against the same diff and test evidence. Compare:
- implementer's self-review
- independent review

Which findings were unique?

Decide which findings require changes and whether independence actually added information.

Teach back: Why can a separate context notice risks that the implementing context's self-review missed?

## Task B — Parallel worktrees

Pick 2-3 independent small enhancements, for example:
- keyboard navigation
- favorites
- autocomplete ranking edge cases

Run them in separate worktrees.

Your job is to:
- keep scopes independent
- inspect each diff
- decide what to merge
- resolve conflicts only if necessary

## Reflection

Explain the difference between:
- prompting one assistant
- supervising multiple bounded agents

### STOP / REVIEW — Parallel work and merge judgment

Inspect each worktree's scope, branch, diff, verification output, overlap, and review result. Decide independently which changes should merge and confirm that no task relied on another worktree's uncommitted state.

Teach back: What makes two tasks safe to run in parallel, and what responsibilities remain with the human supervisor?

After the user approves the reflection and checkpoint, append learning evidence, update justified skill confidence and progress, and advance to Exercise 14.

## Optional map check-in

After this exercise is recorded, offer a brief, non-blocking map check-in: Which review perspective found something the implementing context would likely have missed, and when would parallel work add value rather than coordination cost? Preserve a summary in `LEARNING_LOG.md` only if the user asks or approves.
