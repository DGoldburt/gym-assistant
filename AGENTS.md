# AGENTS.md

## Product principles

1. Apple Notes remains the primary workout-writing workspace for the initial product.
2. The companion app exists to make program writing faster, not to replace Notes.
3. Prefer small, low-friction interactions over feature-heavy UI.
4. Exercise identity is canonical. User-entered wording may be an alias.
5. Fuzzy matching may propose identity but must not silently establish identity.
6. User-confirmed alias relationships are durable and authoritative.
7. A new exercise must be easy to add without leaving the programming flow.
8. Preserve the ability to add client training history and load history later.
9. Do not implement client-history or load-recommendation features until explicitly requested.
10. Keep the exercise-resolution engine independent from the Apple Notes integration so other interfaces can reuse it later.

## Engineering rules

- Make the smallest change that satisfies the current exercise.
- Do not implement later curriculum exercises early.
- When a proposed model or architecture expansion does not materially affect the current task's approved product success criteria, push back on implementing it now. Discussion and clearly labeled future directions or `do not implement` decision entries have a lower evidence threshold than changes to the active specification. When discussion suggests the success criteria may be under- or over-scoped, prompt the user with questions to inspect them; surface materially necessary expansion, but give particular attention to opportunities to narrow the criteria or make them more specific. Do not broaden, weaken, or reinterpret product success criteria unless the user explicitly approves the change.
- Prefer explicit domain types over loosely structured dictionaries/strings.
- Keep UI adapters separate from exercise-library and resolver logic.
- Add tests for non-trivial behavior.
- Do not weaken, delete, or rewrite tests merely to make a change pass.
- When a test expectation appears wrong, explain why before changing it.
- Run the relevant verification commands before declaring a task complete.
- Report what was verified and what was not verified.
- Keep architecture decisions in `docs/decisions/`.
- Keep `docs/ARCHITECTURE.md` synchronized with meaningful architectural changes.
- Do not initialize Git, create a remote repository, push, open or merge a pull request, install Xcode, or perform another external/stateful setup action unless the current approved tutorial task explicitly reaches that action.
- When writing complex features or significant refactors, use an ExecPlan (as described in ./PLANS.md) from design to implementation.

## Git lifecycle

### Learner work

- Before starting a numbered exercise, synchronize `learner/main` with reusable `main`, then create a fresh `tutorial/exercise-NN` branch from `learner/main`. Do not carry a previous exercise branch forward.
- After each task checkpoint and reflection are approved, update the justified learning artifacts and `PROGRESS.md`, run the relevant verification, inspect the candidate diff for credentials and unintended private material, then commit and push one coherent checkpoint.
- After the final checkpoint in an exercise, run the exercise's full verification, open a pull request into `learner/main`, review and merge it, synchronize local `learner/main`, and create a fresh branch for the next exercise.
- Do not merge unapproved task work, later-exercise work, or reusable starter changes directly into `learner/main`.

### Reusable work

- Prepare each approved shared-harness, curriculum, or product-documentation update in a clean worktree based on `main`. Inspect its complete candidate diff for learner progress, reflections, identity, private links, credentials, and unrelated files before committing or pushing.
- Use a commit boundary for one coherent approved update, not mechanically for every conversation. Do not commit rejected drafts or incomplete exploration. If an approved update remains incomplete at handoff, report its worktree path, current status, and remaining work so it is not mistaken for finished work.
- Once reviewed, commit and push the reusable update promptly. Then synchronize `learner/main` and the active exercise branch with the new `main` before retaining or adding dependent learner state.

## Durable context map

- `PLANS.md` — durable planning convention.
- `docs/PRODUCT.md` — product truth and scope
- `docs/ARCHITECTURE.md` — current system boundaries
- `docs/decisions/` — durable architecture decisions and evidence
- `docs/curriculum/PROGRESS.md` — exact tutorial location and next action
- `docs/curriculum/EXERCISE_BLUEPRINT.md` — durable tutorial-structure conventions
- `docs/curriculum/SKILLS.md` — compact confidence record for agentic-AI abilities
- `docs/curriculum/AGENTIC_AI_MAP.md` — living mental map, research context, and outside ideas
- `docs/curriculum/LEARNING_LOG.md` — approved learning evidence

## Tutorial behavior

When asked to continue the tutorial:

1. Read `docs/curriculum/PROGRESS.md`, `docs/curriculum/SKILLS.md`, and `docs/curriculum/EXERCISE_BLUEPRINT.md`. Read `AGENTIC_AI_MAP.md` when a current exercise, a planned map check-in, or the user asks to discuss agentic AI.
2. Read the current exercise only. Read only the ledger entries or active plan referenced by that exercise or progress tracker.
3. At the start of tutorial work, state the current step's learning objective in 2–4 sentences. Then introduce the immediate activity in direct, learner-facing language by reading back or closely paraphrasing the current task's instruction and explaining why it comes next. Treat the exercise as teaching material, not only as an execution specification.
4. Inspect prerequisites and distinguish observed facts, user decisions, and unresolved assumptions. If the codebase differs from the tutorial assumptions, adapt the current exercise while preserving its learning objective and approval boundary.
5. Perform only the next task before the next `STOP / REVIEW` checkpoint.
6. At the checkpoint, show concrete evidence and state exactly what the user must inspect, explain, decide, or test to pass it. Passing the checkpoint completes its task; do not track checkpoint progress separately from task progress.
7. Ask the exercise's teach-back question. Draft a concise first-person reflection from the user's answer in chat.
8. Do not write the reflection, append to `LEARNING_LOG.md`, change a skill-confidence state, or update `PROGRESS.md` until the user has completed the checkpoint's required inspection, explanation, decision, or test and explicitly confirms that the drafted reflection is accurate. Once those checkpoint requirements are satisfied, approval of the reflection also confirms checkpoint completion; do not ask for a second, redundant completion confirmation. Ask separately only when a stated checkpoint requirement is still missing.
9. After that approval, record the approved evidence and reflection, update only justified skill confidence, and update `PROGRESS.md` immediately to the next task—or to the next exercise when the completed task was the exercise's last task. This keeps the restart location exact between checkpoints.
10. Never mark a skill Demonstrated unless an approved ledger entry contains both the user's reflection and observable evidence. Task completion or Codex's own explanation is insufficient.
11. Treat `LEARNING_LOG.md` as append-only. Add a dated correction instead of rewriting old evidence.
12. Optional labs never advance or complete a numbered exercise and never change `PROGRESS.md`.
13. Teach the reason behind each step, not just the command.
14. At the start of tutorial work, before substantive work, and before every checkpoint, Codex surfaces the following dashboard: the current exercise and task, current task progress, next step, next checkpoint, a rough time estimate to the next checkpoint, and relevant skill or skills (rarer). State the next step as the learner's next concrete activity in ordinary language, not merely as a task title, status label, or description of Codex's internal execution plan. Time estimates are planning aids rather than promises and can separate learner time, agent time, and external setup or waiting time when relevant. The envelope for this dashboard should be as compact as possible and be the first thing returned - use a single fenced code block labeled as `md` that begins and ends with triple backticks. Do not nest additional triple-backtick code fences inside to avoid prematurely closing the dashboard's code fence.
15. Offer optional map check-ins at the milestones named in `AGENTIC_AI_MAP.md` or when the user brings an external source. They never block tutorial progress. Preserve a check-in in `LEARNING_LOG.md` only when the user asks or explicitly approves.
16. Before asking the learner to approve a decision, restate the complete proposed decision, the concrete artifact or state it refers to, its consequences, and any meaningful alternative. Keep blocking or handoff prompts self-contained; do not rely on shorthand such as "the recommended baseline" whose meaning appeared only in earlier commentary.
17. Apply the Git lifecycle above whenever the shared learning harness or an exercise changes after learner state exists. Never copy learner versions of `PROGRESS.md`, `SKILLS.md`, or `LEARNING_LOG.md` wholesale into `main`; apply only intentional template or schema changes from the clean starter side, and exclude learner-specific orientation or sources from `AGENTIC_AI_MAP.md`. Keep existing starter tags immutable; publish a new tag for a later starter version rather than moving an earlier tag.

When the user asks to change the curriculum itself, the current-exercise-only reading restriction does not prevent inspecting the curriculum files necessary for that maintenance task. Curriculum maintenance must not silently advance tutorial progress.
