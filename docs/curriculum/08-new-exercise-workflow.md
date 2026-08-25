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
- prefill one `Name` field from the selected text
- allow the user to confirm or edit that name, or go back
- save only the confirmed name as the new exercise's required preferred name
- save
- return to Notes immediately

The original selected text is not also saved when the user edits the name. A
confirmed name is added as an alias only through the explicit Link Existing path.

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

## Curriculum amendment — product-direction review before advancement

This amendment is additive: Tasks A and B above remain unchanged. After Task B's
reflection and checkpoint are approved and recorded, continue to Task C below
instead of advancing immediately to Exercise 09.

The amendment exists because product discovery conducted while Exercise 08 was
current showed that exercise identity and new-exercise creation are enabling
capabilities, but keyboard retrieval during program composition is the more direct
route to the primary outcome of writing programs faster.

## Task C — Review and approve the assistant-use-case redirection

Inspect the completed new-exercise workflow in both documentation and code. Name
where the selected-text interaction, application workflow, library writes, and
resolver safety boundary now live, and verify that finishing this slice did not
silently turn a search selection into an alias relationship.

Then inspect the complete redirection package:

- the primary writing workflow and product horizons in `docs/PRODUCT.md`
- the evidence, opportunities, candidate solutions, and Now/Next/Later boundaries
  in `docs/OPPORTUNITY_SOLUTION_TREE.md`
- the post-acceptance no-selection extension recorded in ADR 001
- the corresponding boundary description in `docs/ARCHITECTURE.md`
- Exercise 09's keyboard autocomplete scope
- Exercise 10's reusable identity-review and personal-library import scope
- Exercise 11's field-evidence-gated reuse of search-query transformations

The review must distinguish three things: selecting an existing exercise for
insertion, confirming that user-entered wording is an alias, and creating a new
exercise. It must also confirm that completed-program hygiene, movement-pattern
search, pairings, blocks, programming tendencies, client context, and load history
remain preserved future opportunities rather than requirements of autocomplete.

### STOP / REVIEW — Redirection package

Inspect the complete candidate diff and the finished new-exercise behavior. Decide
whether the package accurately preserves both the larger product and the bounded
next slice, and approve or revise the package before Exercise 09 begins.

Teach back: Why can exercise identity remain foundational even though identity
resolution is no longer the primary interaction for writing a program?

After the user approves the reflection and checkpoint, append the approved evidence
and reflection, update only justified skill confidence, update `PROGRESS.md`, and
advance to Exercise 09.
