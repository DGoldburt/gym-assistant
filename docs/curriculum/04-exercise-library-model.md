# Exercise 04 — Exercise Library Data Model

## Why we're doing this

The durable value of the product is exercise identity and vocabulary, not the Notes adapter.

## Codex skill

- domain modeling
- future-proofing without premature implementation
- schema review before migration/code generation

## Skills practiced

- `orient` — Orient before changing
- `frame-work` — Frame a bounded task
- `plan` — Plan in proportion to risk

## Requirements

The model must support:

Canonical exercise:
- stable ID
- canonical name
- preferred display name
- created/updated timestamps

Aliases:
- many aliases per exercise
- normalized representation
- durable provenance where useful
- uniqueness rules that prevent ambiguity where appropriate

Example:

Canonical name:
`Single-Leg Romanian Deadlift`

Preferred display:
`SL RDL`

Aliases:
- SL RDL
- 1-leg RDL
- single leg Romanian deadlift

Future client history must reference the stable exercise ID.

## Task A — Design only

Ask Codex for:
- proposed entities
- keys
- constraints
- indexes
- migration strategy
- examples
- tradeoffs

Do not implement yet.

### STOP / REVIEW

Inspect the proposed entities, keys, constraints, indexes, examples, migration path, and explicit tradeoffs. Check:

1. Are aliases separate durable records?
2. Is preferred display text distinct from canonical identity?
3. Could client history reference a stable exercise ID later?
4. What happens if the same alias is proposed for two exercises?
5. Does the design accidentally encode fuzzy similarity as truth?

Decide whether the schema is small enough for the current exercise while preserving stable exercise identity.

Teach back: Which decisions must be settled before generating a migration, and why is design review cheaper than repairing persisted data?

## Task B — Implement after approval

Create the persistence layer and migration.

Add basic tests for:
- create exercise
- add alias
- lookup exact alias
- prevent invalid duplicate alias ownership

## Verification

Run the relevant tests and inspect the actual database/schema.

### STOP / REVIEW — Persistence verification

Inspect the migration, actual schema, test output, and diff. Test create exercise, add alias, exact alias lookup, and conflicting alias ownership; decide whether implementation matches the approved design without adding resolver or history behavior.

Teach back: How did the approved constraints become machine-verifiable behavior?

After the user approves the reflection and checkpoint, append learning evidence, update justified skill confidence and progress, and advance to Exercise 05.
