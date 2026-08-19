# Exercise 08 — Frictionless New Exercise Workflow

## Why we're doing this

If adding a new exercise is annoying, the library will become incomplete and the product will stop helping.

## Codex skill

- product acceptance criteria
- micro-interaction design
- implementing the shortest useful workflow

## Skills practiced

- `frame-work` — Frame a bounded task
- `verify` — Build an evidence-producing delivery loop

## Desired workflow

Selected text:
`Tall Kneeling Bottoms-Up KB Press`

If no confident match exists, present:

- candidate existing exercises
- Link Existing
- Create New Exercise

If creating:
- infer a sensible canonical name
- preserve selected text as the first alias
- allow a short preferred display name
- save
- return to Notes immediately

## Task A — Define interaction budget

Before coding, decide a target such as:

> A genuinely new exercise should be addable in a few seconds without navigating away to a separate library screen.

Have Codex propose the minimum UI.

### STOP / REVIEW

Inspect the proposed screens, fields, default values, interaction count, and return-to-Notes path. Reject unnecessary fields.

Ask:
- What absolutely must be entered now?
- What can be edited later?
- Can the original selected text become an alias automatically?

Decide the maximum acceptable interaction budget before implementation.

Teach back: How does a measurable interaction budget constrain Codex differently from "make it frictionless"?

## Task B — Implement and manually test

Test at least:
- obvious existing exercise
- ambiguous exercise
- truly new exercise
- mistaken new exercise that should be linked to existing

Record friction points.

### STOP / REVIEW — Workflow evidence

Inspect the recorded timing/interaction counts, screenshots or logs, saved records, and returned Notes text for all four cases. Decide whether the new-exercise flow meets the approved budget and whether any field or transition still adds avoidable friction.

Teach back: Which part of the manual evidence would an automated unit test fail to capture?

After the user approves the reflection and checkpoint, append learning evidence, update justified skill confidence and progress, and advance to Exercise 09.
