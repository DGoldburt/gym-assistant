# Gym Programming Assistant — Codex Tutorial Bootstrap

This repository bootstrap is a project-based tutorial for learning agentic development with Codex while building a real macOS companion tool for Apple Notes.

It teaches two tracks together:

1. **Product engineering** — build a low-friction exercise assistant without replacing Notes.
2. **Agentic engineering** — create durable context, frame bounded tasks, supervise autonomy, demand evidence, and preserve what the user learned.

## Product goal

Help a strength coach write programs faster **without replacing Apple Notes as the main workspace**.

The companion tool should eventually provide:

- fast exercise lookup from selected text in Notes
- insertion/replacement of canonical exercise names
- a durable exercise library with aliases
- sophisticated duplicate detection
- a frictionless "add new exercise" workflow
- reusable exercise blocks
- suggestions based on prior programming tendencies

Future direction, deliberately **not implemented in the initial tutorial**:

- client histories
- exercise dates
- sets/reps/load history
- recent load lookup while programming
- suggested working weights

## How to use this tutorial

1. Put these files in a local project folder and open that folder in Codex.
2. Ask Codex: “Start or resume the tutorial.”
3. Work through one `STOP / REVIEW` checkpoint at a time.
4. Answer the teach-back prompt and inspect the evidence yourself.
5. Approve the proposed first-person reflection only when it accurately represents your understanding.
6. Let Codex record progress and learning evidence only after that approval.
7. Do not ask Codex to "build the whole app."

At the start of work and at every checkpoint, Codex should show a compact tutorial dashboard: current exercise and task, what completes that task, completed and remaining tasks, a rough estimate of time to the next checkpoint, and the scope guard. A task has one terminal `STOP / REVIEW` checkpoint; when you pass it, that task is complete. See `docs/curriculum/EXERCISE_BLUEPRINT.md` for the durable exercise conventions.

Exercise 01 assumes the bootstrap may begin as an ordinary local folder. It teaches when to use `git init`, `git clone`, and `git switch`/`checkout`, then creates the first local commit, private GitHub repository, and pull request. Exercise 02 investigates the macOS integration mechanism and handles full Xcode setup only after the tooling/architecture checkpoint.

## Agentic-AI learning record

- `docs/curriculum/SKILLS.md` is a compact confidence record for the agentic-AI abilities practiced in the tutorial.
- `docs/curriculum/AGENTIC_AI_MAP.md` is a living mental map for the research ideas, project connections, and useful outside reading.
- `docs/curriculum/LEARNING_LOG.md` stores append-only portfolio evidence and first-person reflections.
- `docs/curriculum/PROGRESS.md` stays compact and records only the current course location.
- `PLANS.md` persists approved, multi-session plans when planning is justified by risk or uncertainty.

Skills use Not yet used → Used with guidance → Demonstrated, with Revisit used when evidence exposes a gap. Demonstrated always requires approved reflection plus observable evidence.

The mental map is not a checklist. Use its optional check-ins after the Notes spike, resolver work, and review/worktree work—or whenever outside reading changes a live question. Its built-in “Use with ChatGPT” section explains how to carry this context into a dedicated ChatGPT Project.

## Topics taught

- repository orientation and Git/GitHub collaboration
- task framing and risk-scaled planning
- `AGENTS.md` and durable context placement
- reasoning effort, sandboxing, permissions, and approval boundaries
- architecture spikes and decision records
- acceptance criteria and fixture-driven development
- verification harnesses and agentic manual testing
- self-review, independent review, worktrees, and parallel delegation
- optional MCP, Skills, cloud delegation, and scheduled-automation labs

A living overview of ideas and connections is in `docs/curriculum/AGENTIC_AI_MAP.md`; the practical skills record is `docs/curriculum/SKILLS.md`.

## Directory guide

- `AGENTS.md` — durable instructions for Codex
- `PLANS.md` — durable instructions for planning
- `docs/PRODUCT.md` — product truth
- `docs/ARCHITECTURE.md` — current architecture
- `docs/decisions/` — architecture decision records
- `docs/curriculum/PROGRESS.md` — where the main course is
- `docs/curriculum/EXERCISE_BLUEPRINT.md` — exercise, task, checkpoint, and concept-integration conventions
- `docs/curriculum/SKILLS.md` — compact agentic-AI skill confidence record
- `docs/curriculum/AGENTIC_AI_MAP.md` — living agentic-AI map and external-source context
- `docs/curriculum/LEARNING_LOG.md` — approved evidence of learning
- `docs/curriculum/01-...md` through `13-...md` — required tutorial exercises
- `docs/curriculum/labs/` — optional, non-blocking agentic-AI labs

## Core rule

The project is successful if it reduces the friction and keystrokes required to write good programs in Apple Notes while teaching the user to supervise agentic work with evidence.

The project is **not** successful merely because it has many features or because Codex produced a large amount of code.
