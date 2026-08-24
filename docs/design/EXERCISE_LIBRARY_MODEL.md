# Exercise Library Model — Design for Exercise 04 Task A

Status: proposed for review. This is a logical persistence design, not a migration or implementation.

## Scope

This design stores stable exercise identity, one preferred display name, and other durable confirmed names. It supports deterministic exact lookup and leaves room for future records to reference an exercise ID.

Here, **canonical exercise** means the stable `Exercise` entity identified by `Exercise.id`; it does not require a separately persisted canonical-name designation. There is no demonstrated product need for a formal taxonomy name distinct from the coach-facing preferred name.

It does not implement fuzzy matching, candidate ranking, variants or relationships, program context, client history, performance history, movement-pattern taxonomy, equipment dimensions, or load recommendations. A fuzzy candidate is not an owned name unless a user explicitly confirms the relationship.

## Domain types

### Exercise

| Field | Type | Rules |
| --- | --- | --- |
| `id` | `ExerciseID` (UUID) | Primary key; application-generated; stable and never derived from a name. |
| `preferredNameID` | `ExerciseNameID` | Required deferred foreign key to a name owned by this exercise. |
| `createdAt` | UTC instant | Set once when the exercise is created. |
| `updatedAt` | UTC instant | Greater than or equal to `createdAt`; changes with persisted edits. |

`Exercise.id` is canonical identity. Human-readable names may change without changing that identity.

User-facing and ordinary developer-facing output uses the preferred name, not a bare UUID. When disambiguation is useful, diagnostics may combine the preferred name with a short UUID prefix, such as `Front Squat · 8E22A4D3`. Full UUIDs remain available for structured logs, database inspection, and exact correlation.

### ExerciseName

| Field | Type | Rules |
| --- | --- | --- |
| `id` | `ExerciseNameID` (UUID) | Primary key; application-generated. |
| `exerciseID` | `ExerciseID` | Required foreign key to `Exercise.id`. |
| `text` | non-empty text | Preserved user-facing wording as entered or confirmed. |
| `normalizedText` | normalized text | Required global lookup key; unique across all exercise names. |
| `provenance` | closed value | Initially `systemSeeded`, `userConfirmed`, or `importedConfirmed`; supplied by the workflow rather than entered manually during ordinary seeding. |
| `createdAt` | UTC instant | Set once when ownership is established. |

Names are separate durable records. Their relationship to `Exercise.id` is authoritative after explicit confirmation; fuzzy similarity is neither stored here nor treated as ownership.

Creating an exercise from one entered name creates the `Exercise` and its preferred `ExerciseName` automatically. The caller does not supply IDs, normalized text, timestamps, provenance controls, or speculative future fields.

## Keys and constraints

Database-enforced constraints:

1. `Exercise.id` and `ExerciseName.id` are primary keys.
2. `ExerciseName.exerciseID` references `Exercise.id`; names cannot outlive their exercise.
3. `ExerciseName.text` and `normalizedText` are non-empty after trimming.
4. `ExerciseName.normalizedText` is globally unique, preventing ambiguous exact ownership.
5. `ExerciseName` has a unique composite key on `(exerciseID, id)`.
6. A deferred composite foreign key from `Exercise(id, preferredNameID)` to `ExerciseName(exerciseID, id)` requires every exercise to reference an existing name that it owns.
7. `ExerciseName.provenance` accepts only the initial closed values.
8. `Exercise.updatedAt >= Exercise.createdAt`.

Transaction/application invariants:

1. Creating an exercise and its initial preferred name occurs in one transaction with deferred foreign-key checking; an exercise cannot commit without an owned preferred name.
2. Changing `Exercise.preferredNameID` selects another owned name atomically; the former preferred name remains a durable alias.
3. The same deterministic normalizer produces every `normalizedText`. Exercise 06 owns the algorithm; this exercise reserves only the persisted key and constraints.
4. No API silently reassigns a name. Cross-owner reassignment requires an explicit user decision.
5. Fuzzy matching may propose an exercise but cannot add a name until the user confirms identity.
6. The initial API exposes no hard-delete operation. A future lifecycle must protect history before deletion is introduced.

The required composite foreign key prevents all three invalid states at commit time: an exercise with no preferred name, a preferred name that does not exist, and a preferred name owned by another exercise. It is deferred because the new `Exercise` and `ExerciseName` refer to one another and must be inserted within the same transaction before the relationship can be validated.

## Deterministic normalization boundary

Normalization makes indexed exact lookup and uniqueness enforceable while preserving entered display text. An illustrative future contract could normalize Unicode, case-fold, convert common dash characters to separators, trim, and collapse whitespace:

| Entered text | Illustrative normalized key |
| --- | --- |
| `  Single–Leg   RDL ` | `single leg rdl` |
| `single-leg rdl` | `single leg rdl` |
| `SINGLE LEG RDL` | `single leg rdl` |

These cosmetic forms resolve to one durable name rather than producing redundant aliases. Normalization must not infer semantic equivalence: `1-leg RDL`, `SL RDL`, and `Single-Leg Romanian Deadlift` remain distinct normalized keys unless each wording is explicitly confirmed for the same exercise.

The exact algorithm is deferred to Exercise 06. If it changes after data exists, a migration must recompute keys and surface collisions before applying the new unique index.

## Indexes

| Index | Purpose |
| --- | --- |
| Unique primary-key indexes on both IDs | Stable exercise identity and durable name-record identity. |
| Unique index on `ExerciseName.normalizedText` | Exact lookup and unambiguous global ownership. |
| Unique composite index on `ExerciseName(exerciseID, id)` | Supports the ownership-enforcing preferred-name foreign key. |
| Non-unique index on `ExerciseName.exerciseID` | Retrieve all names for an exercise and support foreign-key operations. |

Do not add fuzzy-search, ranking, recency, program, client-history, or block indexes in this exercise.

## Conflict behavior

When a normalized name is proposed:

- If unused, insert it for the explicitly chosen exercise.
- If already owned by that exercise, return the existing name idempotently.
- If owned by another exercise, return `ExerciseNameOwnershipConflict` with the proposed text and existing owner ID. Do not insert, overwrite, merge, or silently choose an owner.

Conflict resolution beyond choosing the existing exercise or changing the wording is outside Exercise 04.

## Example

Exercise ID: `8E22A4D3-BC17-4C42-A973-7D04D0EC6C51`

`Exercise.preferredNameID` refers to the `SL RDL` name record.

| `text` | Illustrative `normalizedText` | `provenance` |
| --- | --- | --- |
| `SL RDL` | `sl rdl` | `systemSeeded` |
| `Single-Leg Romanian Deadlift` | `single leg romanian deadlift` | `userConfirmed` |
| `1-leg RDL` | `1 leg rdl` | `userConfirmed` |
| `single leg Romanian deadlift` | `single leg romanian deadlift` | not inserted; normalized key already exists |

The last row demonstrates normalization idempotence, not fuzzy matching. Future client history stores the UUID; UI and ordinary diagnostics display `SL RDL` or, when useful, `SL RDL · 8E22A4D3`.

## Decisions settled before migration

- **Identity:** application-generated opaque UUID, never name-derived.
- **Human interaction:** preferred names in user-facing and ordinary developer-facing output; short UUID prefixes for useful disambiguation.
- **Name representation:** one durable `ExerciseName` type; no separate canonical-name role.
- **Cardinality:** one required owned `preferredNameID` and any number of other names as aliases; database constraints reject orphan exercises.
- **Lookup:** persisted deterministic normalized keys with global uniqueness.
- **Conflict behavior:** same-owner proposals are idempotent; cross-owner proposals fail explicitly.
- **Provenance:** workflow-supplied on names, not manual seed input.
- **Lifecycle:** no initial hard-delete API.

Task B still chooses storage-specific syntax and a minimal concrete normalizer for its tests. These are implementation details constrained by the design, not unresolved product decisions.

## Initial migration strategy

With no production exercise data, the first migration creates the schema atomically:

1. Create the persistence layer's schema-version record.
2. Create `Exercise` and `ExerciseName` with their primary keys, timestamps, ownership relationship, normalized-name uniqueness, and deferred preferred-name foreign key.
3. Create the supporting `ExerciseName.exerciseID` and composite indexes.
4. Enable and verify SQLite foreign-key enforcement for every database connection.
5. Commit only if the entire migration succeeds.

For a later import or upgrade:

1. Stage source strings without asserting identity.
2. Compute normalized candidates and group collisions.
3. Collapse only normalized duplicates already tied to the same exercise ID.
4. Quarantine cross-exercise conflicts for explicit resolution; never choose from fuzzy similarity.
5. Insert exercises before names in one transaction.
6. Validate uniqueness after conflicts are resolved and preserve a rollback boundary.

Future client history references `Exercise.id`. Legacy name strings require explicit resolution rather than automatic conversion to canonical identity.

## Tradeoffs

### UUID identity versus a human-readable identifier

A human-readable ID adds rename ambiguity, collision rules, spelling and Unicode concerns, and another decision during creation or import. UUIDs remain stable across renames, exports, imports, fixtures, and possible synchronization. Preferred-name-plus-short-ID diagnostics recover readability without making wording part of identity.

### Preferred name without a canonical-name role

The workflow needs one stable identity, one default display name, and other confirmed names. A formal canonical-name role has no demonstrated consumer. It can be added later without changing exercise IDs or name ownership if taxonomy or export requirements emerge.

### Global name uniqueness versus contextual meanings

Global uniqueness guarantees deterministic lookup and surfaces ambiguity early. It cannot represent one wording as two context-dependent exercises. Reconsider contextual ownership only if concrete shorthand must intentionally resolve differently by client, coach, gym, program, or source.

### Persisted normalization versus query-time computation

Persisted normalized keys make uniqueness and indexed lookup enforceable. They duplicate derived data and require collision-aware migration if normalization later changes.

### No soft deletion yet

Retirement and merge semantics affect names and future history but are not required now. The initial API therefore avoids hard deletion until that lifecycle is deliberately designed.

## Evidence-backed future directions — do not implement now

A read-only review of all 57 Apple Notes in the Strength Training folder found recurring program/session context, progressions and regressions, movement-pattern labels, equipment/loading distinctions, source attribution, and client-specific constraints. This supports preserving room for future `Program`, `ClientContext`, `ExerciseRelationship`, source-provenance, and optional-classification concepts.

It does not establish a need for more required `Exercise` or `ExerciseName` fields. Program provenance and client goals, injuries, or mobility constraints belong to their own future scopes. Potential future relationships include `variationOf`, `progressionOf`, and `regressionOf`; until such a model has its own acceptance criteria, uncertain equipment or technique variants remain distinct exercises rather than silently becoming aliases.

## Approval boundary

Task B may implement only this model, migration, and four required behaviors: create exercise, add a confirmed non-preferred name, exact normalized-name lookup, and reject conflicting name ownership. Any broader normalizer behavior, fuzzy candidates, canonical-name role, contextual ownership, variant graph, merge or deletion workflow, resolver behavior, program/client context, taxonomy, equipment dimensions, blocks, or history requires a later exercise or a new design checkpoint.
