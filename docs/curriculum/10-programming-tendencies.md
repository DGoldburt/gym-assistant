# Exercise 10 — Learn Programming Tendencies

## Why we're doing this

The library should eventually surface what the user tends to program, not merely what exists.

This is programming history, not client performance history.

## Codex skill

- deriving suggestions from historical data
- separating observed behavior from explicitly saved content
- ranking without hiding provenance

## Skills practiced

- `frame-work` — Frame a bounded task
- `verify` — Build an evidence-producing delivery loop

## Goal

Allow the system to distinguish:

Saved block:
> intentionally reusable

Observed tendency:
> frequently appeared together in prior programs

Possible outputs:

`Front Squat`

Frequently paired:
- Aussie Pull-up — 17 appearances
- Box Jump — 8
- 1-Arm DB Row — 6

## Task A — Design ingestion

Propose a minimal way to ingest past programming examples without building a full client database.

Possible inputs:
- pasted text
- exported notes
- selected blocks
- manually imported historical programs

### STOP / REVIEW

Inspect the proposed input boundary, examples, identity-resolution path, provenance, and explicit non-goals. Make sure:
- exercise identity uses the resolver/library
- historical observations do not silently become canonical aliases
- client load history is still out of scope

Decide which minimal input format is sufficient for the first tendency model.

Teach back: Why must imported observations not silently become canonical aliases?

## Task B — Implement a minimal frequency/tendency model

Start simple:
- co-occurrence
- recency
- frequency

Do not add opaque AI ranking unless a simpler method has been tested first.

### STOP / REVIEW — Tendency model evidence

Inspect fixture inputs, expected rankings, actual frequency/recency/co-occurrence output, and provenance shown to the user. Test at least one tie or sparse-history case; decide whether the simple model is understandable and useful before considering opacity or complexity.

Teach back: What evidence would justify a more complex ranking method later?

After the user approves the reflection and checkpoint, append learning evidence, update justified skill confidence and progress, and advance to Exercise 11.
