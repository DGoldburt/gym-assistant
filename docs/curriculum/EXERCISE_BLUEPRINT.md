# Exercise Blueprint

This file is the durable convention for authoring and revising tutorial exercises. It describes course structure, not the current location; `PROGRESS.md` remains the source of truth for where the learner is now.

## Terms

- **Exercise** — one bounded product-learning increment. It is complete only when all of its tasks are complete.
- **Task** — the next bounded unit of work. It has one outcome, a clear scope boundary, and exactly one terminal `STOP / REVIEW` checkpoint.
- **STOP / REVIEW checkpoint** — the learner passes this by inspecting stated evidence and completing the required explanation, decision, or test. Passing it completes the task.
- **Skills** — practical abilities relevant to the exercise or task. See `SKILLS.md` for confidence and `LEARNING_LOG.md` for supporting evidence.
- **Agentic-AI map** — a living model for connecting ideas, research, and project examples. See `AGENTIC_AI_MAP.md`.

If a proposed task needs more than one review decision, split it into separate tasks. Do not report task progress and checkpoint progress as separate measures.

## Exercise conventions

Each exercise must state its learning objective, relevant skills, prerequisites or starting state, and product-scope guard. Each task must say what Codex may do before its checkpoint, what evidence the learner will inspect, and what the learner must explain, decide, or test to pass.

Use these terms consistently: tasks are **not started**, **in-progress**, or **complete**; a checkpoint is **not started**, **in-progress**, or **passed**; an exercise is **not started**, **in-progress**, or **complete**. Reserve “approved” for an artifact such as a reflection, plan, or decision.

## Skills and map connections in an exercise

List only the relevant skills, by readable identifier and name. A task or checkpoint may strengthen a skill, but the list itself does not advance confidence. After the learner passes a checkpoint, Codex drafts a first-person reflection in chat. Only when the learner explicitly confirms that wording and the checkpoint result may Codex append evidence to `LEARNING_LOG.md` and update the justified confidence in `SKILLS.md`.

An exercise may include an optional map connection or check-in when it helps connect the work to `AGENTIC_AI_MAP.md`; it never blocks product progress. Do not infer `Demonstrated` from explanation by Codex, task completion alone, or an unconfirmed response. Demonstrated requires both an approved first-person reflection and observable evidence.
