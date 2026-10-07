# Future Programmed-Session History Model

**Status:** Proposed future design — do not implement in the current product slice.

## Purpose and boundary

This design preserves a path from the current exercise library to later programming
history. It does not authorize application code, database migrations, client or
session records, history UI, trend calculations, or load recommendations.

Gym Assistant primarily supports programming. A dated session begins as a plan.
After its date passes, the product presumes that it was performed as programmed.
If the coach later edits the session, the edited version becomes the best-known
account of what occurred.

This assumption matches the current workflow and avoids requiring a second data-
entry pass. It also means that an uncorrected cancellation or modification will
remain indistinguishable from completed-as-programmed work. Revisit that tradeoff
before using presumed history for consequential load recommendations.

## Proposed relationships

```text
Client * ── * ProgrammedSession 1 ── * ProgrammedExercise 1 ── * ProgrammedSet
            via SessionClient             │
                                           * ── 1 Exercise (canonical Exercise.id)
```

A programmed session may reference zero, one, or several clients:

- zero clients: valid general or class-level programming history;
- one client: an individual session;
- several clients: a shared session that appears in each linked client's history.

Every `ProgrammedExercise` references `Exercise.id`. A display name or alias is
never used as the foreign key.

### Client

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | `ClientID` (UUID) | Stable opaque identity. |
| `displayName` | non-empty string | Coach-facing label. Not a key. |
| `createdAt` | timestamp | Record provenance. |
| `updatedAt` | timestamp | Last correction time. |

Goals, injuries, mobility constraints, contact information, and profile taxonomy
are deliberately absent. They require separate product evidence and need not be
invented to store programming history.

### ProgrammedSession

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | `ProgrammedSessionID` (UUID) | Stable session identity. |
| `sessionDate` | optional local calendar date | Date for which the session was programmed; absent while unscheduled. |
| `contextLabel` | optional string | Class, location, or other coach-facing context. |
| `notes` | optional string | Session-level context that does not belong to one exercise. |
| `createdAt` | timestamp | When the session record was created. |
| `updatedAt` | timestamp | Last plan edit or historical correction. |

An undated session is a program draft and does not appear in client history. Once
`sessionDate` is assigned, it becomes a scheduled session and can later become
presumed history. The first slice does not need precise event time. If later work
requires timed events or cross-time-zone synchronization, it can add `startsAt`,
`endsAt`, and an IANA time-zone identifier without changing session IDs.

### SessionClient

| Field | Type | Meaning |
| --- | --- | --- |
| `sessionID` | `ProgrammedSessionID` | Required reference to the session. |
| `clientID` | `ClientID` | Required reference to the client. |

The composite pair is unique. A join record is used instead of an embedded ID list
so the database can enforce client existence and efficiently query history in both
directions. Attendance and per-client completion are not implied. If later evidence
requires them, they need their own explicit behavior rather than overloading this
association.

### ProgrammedExercise

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | `ProgrammedExerciseID` (UUID) | Stable programmed-exercise identity. |
| `sessionID` | `ProgrammedSessionID` | Required owning session. |
| `exerciseID` | `ExerciseID` | Required reference to canonical `Exercise.id`. |
| `position` | non-negative integer | Preserves exercise order within the session. |
| `recordedName` | non-empty string | Snapshot of the wording selected or written. |
| `notes` | optional string | Exercise-level instruction or later correction. |
| `createdAt` | timestamp | Record provenance. |
| `updatedAt` | timestamp | Last plan edit or historical correction. |

`recordedName` preserves meaning when a confirmed alias includes a progression or
prescription, such as `Touch-Down with 5 sec negative`. It is a snapshot, not an
identity assertion: renaming an alias does not rewrite history, and importing the
text does not automatically create an alias.

### ProgrammedSet

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | `ProgrammedSetID` (UUID) | Stable set identity. |
| `programmedExerciseID` | `ProgrammedExerciseID` | Required owning exercise entry. |
| `position` | non-negative integer | Preserves set order. |
| `prescriptionText` | optional string | Faithful wording when the prescription is not fully structured. |
| `repetitions` | optional non-negative integer | Repetitions when a single completed count is known. |
| `load` | optional `Load` value | External resistance or assistance. |
| `side` | optional `SetSide` | `left`, `right`, `both`, `alternating`, or unspecified. |
| `tempo` | optional string | Forms such as `5 sec negative` or `3-1-X-0`. |
| `rpe` | optional decimal | RPE, constrained to 0–10. |
| `rir` | optional non-negative integer | Reps in reserve. |
| `notes` | optional string | Set-specific detail that typed fields cannot express. |
| `createdAt` | timestamp | Record provenance. |
| `updatedAt` | timestamp | Last plan edit or historical correction. |

`prescriptionText` preserves ranges, durations, percentages, rounds, and incomplete
handwritten information such as `6–8 each`, `30–60 sec`, or `70%`. Those forms
should not be forced into false precision merely to populate typed fields.

`Load` has a non-negative decimal magnitude, an explicit `kg` or `lb` unit, and a
kind of `resistance` or `assistance`. The original unit is preserved; display and
analytics may convert units without destructively rewriting stored values. An
absent load means no external load was recorded. It can represent bodyweight work
without pretending that body mass is the exercise load.

Structured percentages require a future definition of their reference value, such
as a dated training max. Until that consumer exists, the original percentage stays
in `prescriptionText` rather than becoming an ambiguous numeric load.

## Date and edit semantics

There is one mutable programmed-session record, not parallel planned and performed
copies:

1. Without `sessionDate`, the session remains an unscheduled draft and is excluded
   from history.
2. Before an assigned `sessionDate`, edits change the planned session.
3. After `sessionDate`, the unchanged plan is presumed to have been performed.
4. A later edit corrects the best-known historical account.
5. History queries use the current stored values and `Exercise.id` links.
6. `updatedAt` records when current truth changed; it does not preserve every prior
   value.

Full event sourcing or a revision ledger is not justified for the first history
slice. Stable IDs leave room to add revisions later if correction audit becomes a
real product requirement.

An import or synchronization process must not silently overwrite a manual edit.
Re-imports should be idempotent and surface a conflict when source evidence differs
from a record corrected after import.

## Future interaction implication — do not implement now

The same record remains editable before and after `sessionDate`, but the interface
should make the semantic transition visible:

- before `sessionDate`, the user is editing a draft program;
- after `sessionDate`, the user is correcting the best-known record of work presumed
  to have been performed.

The historical edit mode should make that consequence understandable before saving,
because its changes affect client history and any later history-based assistance. It
does not require a second performed-work record or a full revision ledger.

Gym Assistant currently has interfaces for individual exercise insertion and exercise-
library management. It has no approved interaction for drafting a session, drafting a
multi-session program, or editing historical sessions. Those interactions require a
separate product slice and evidence before this proposed model becomes an ADR or an
implementation plan.

## Examples

### Individual session with different sets

```text
Session: 2026-08-14 · Client C7A1…
Exercise: Front Squat · Exercise 8E22…
Recorded name: Front Squat

Set 1: 5 reps · 30 kg
Set 2: 5 reps · 32.5 kg
Set 3: 4 reps · 32.5 kg · RPE 9
```

Each set is its own row. A UI may compact identical adjacent rows into
`3 × 5 @ 35 kg`, but storage does not assume all sets have the same reps or load.

### Shared class session

```text
Session: 2026-08-06
Context: Youth Weightlifting Class
Clients: optional C7A1…, D20B…, E991…, F08C…

Strength: Dead Hang; RDL/GHD with stick; Chest-Supported Row
Conditioning: 40/20 intervals
```

With no client links, this remains valid class-level programming history. With
client links, the same canonical exercise entries become visible in each linked
client's history without duplicating the session.

## Invariants and lifecycle consequences

1. Every programmed exercise references an existing canonical `Exercise.id`.
2. Every set references an existing programmed exercise; every client link
   references an existing session and client.
3. Positions are unique within their owner so ordering is deterministic.
4. Loads retain both kind and unit; conversions are query/display behavior.
5. `recordedName` and `prescriptionText` are evidence, not aliases or identity keys.
6. Changing an exercise's preferred name or aliases does not rewrite history.
7. An exercise with referenced history cannot be hard-deleted. A future merge must
   repoint references transactionally and retain enough evidence to explain it.
8. A session may have no clients. Absence of clients does not make it a template or
   reusable block.
9. Only a session with `sessionDate` participates in chronological or client
   history.

## Photographed and legacy source migration

Existing Notes and photographed notebooks are not clean relational history. A
future ingestion flow should:

1. Preserve the source image or text with provenance and an idempotent source key.
2. Transcribe or parse candidate dates, context, clients, exercises, and sets
   without yet creating history or asserting exercise identity.
3. Expose uncertain handwriting, source boundaries, and interpretations for human
   correction.
4. Resolve only deterministic, already-authoritative exercise names automatically.
   Fuzzy matches remain review candidates.
5. Create the session, client links, exercises, and sets in one transaction only
   after required relationships are resolved.
6. Link created records back to bounded source evidence so later OCR corrections
   can be understood.
7. Re-run safely by recognizing the source key, validate record counts against
   staged observations, and retain a rollback boundary.

The existing observation extractor and exercise-identity review workflow may
provide inputs, but their decisions do not establish a session date, client link,
or set prescription.

## Compatibility with the current exercise library

The current model already supplies the critical seam:

- `Exercise.id` is an opaque, stable canonical identity.
- display names and confirmed aliases can change without changing that identity.
- fuzzy similarity proposes candidates but cannot establish ownership.
- hard deletion is already withheld pending future history and merge semantics.
- exercise records are not burdened with client, program, or session fields.

No current `Exercise` or `ExerciseName` field is required for this design.

## Tradeoffs and deferred decisions

- **Presumed completion versus explicit confirmation:** presumption matches the
  current low-friction workflow but can retain an uncorrected false history.
- **Current truth versus revision history:** transactional correction is the
  smaller surface. Stable IDs preserve a later path to revisions.
- **Faithful text versus early structure:** prescription text and notes retain
  meaning without prematurely defining every programming dimension.
- **Zero-to-many clients versus attendance:** client links make a session visible
  in individual histories; they do not claim who actually attended.
- **Local date versus exact time:** a calendar date satisfies the stated history
  need. Precise timing and time zones remain addable.
- **History versus recommendations:** the model can supply later consumers, but it
  neither calculates nor stores recommended loads.
- **Client profile context:** goals, injuries, and constraints remain separate
  future models rather than required fields on history records.

Multi-session programs, cycles, reusable sources, and copy-on-use behavior are
described separately in `FUTURE_PROGRAM_MODEL.md`. This document should remain a
future design until an implementation exercise approves product interactions,
correction behavior, and migration evidence.
