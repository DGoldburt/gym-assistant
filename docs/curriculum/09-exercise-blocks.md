# Exercise 09 — Reusable Exercise Blocks

## Why we're doing this

Writing programs faster requires retrieval of groups of exercises, not only individual exercise names.

## Codex skill

- introducing a second domain concept
- maintaining separation of identity and presentation
- insertion workflows

## Skills practiced

- `frame-work` — Frame a bounded task
- `verify` — Build an evidence-producing delivery loop

## Block concept

Example:

Name:
`Front Squat + Pull`

Content:
    A1 Front Squat
    A2 Aussie Pull-up

Another:
    A1 Front Squat
    A2 Aussie Pull-up
    B1 SL RDL
    B2 DB Floor Press

Blocks may contain exercise references plus formatting/text metadata.

## Task A — Model blocks

Ask Codex to propose a model that:
- references canonical exercise IDs
- preserves preferred inserted text/layout
- allows blocks to evolve later

### STOP / REVIEW

Inspect the proposed entity relationships, examples, update behavior, and insertion representation. Avoid storing only one opaque text blob if that prevents structured exercise references.

Also avoid over-modeling every character of the note.

Decide whether the model preserves canonical exercise references while keeping formatting practical.

Teach back: What information must remain structured, and what can safely remain presentation text?

## Task B — Search/insert blocks from Notes

Support a lightweight workflow for:
- searching exercises
- searching blocks
- inserting the selected result

Manually test whether this is actually faster than typing from memory.

### STOP / REVIEW — Block retrieval evidence

Inspect search results, inserted output, timing or keystroke comparison, and the model records behind at least two blocks. Decide whether retrieval is measurably faster and whether edits preserve exercise identity.

Teach back: Why is "the feature works" different from "the feature makes program writing faster"?

After the user approves the reflection and checkpoint, append learning evidence, update justified skill confidence and progress, and advance to Exercise 10.
