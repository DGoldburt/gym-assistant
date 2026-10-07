# Future Multi-Session Program Model

**Status:** Proposed adjacent future design — do not implement in the current
product slice.

## Purpose and boundary

This design preserves a path for writing more than one session at a time. It
groups concrete programmed sessions into a program, supports alternating session
days and small progressions across weeks, and allows an existing program to be
copied safely for later use.

It does not authorize program-builder UI, automatic scheduling, generated
progressions, template inheritance, attendance tracking, load recommendations, or
application/database implementation.

The programmed-session records and their date/edit semantics are defined in
`FUTURE_CLIENT_HISTORY_MODEL.md`.

## Proposed relationships

```text
Program 1 ── * ProgrammedSession 1 ── * ProgrammedExercise 1 ── * ProgrammedSet
                    *
                    * ── * Client via SessionClient
```

A `ProgrammedSession` may stand alone or belong to one program. A program groups
sessions; it does not replace their optional dates, client links, canonical
exercise IDs, or correction behavior. An undated session remains a relative plan;
copying or scheduling the program may assign its calendar date.

### Program

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | `ProgramID` (UUID) | Stable program identity. |
| `title` | non-empty string | Coach-facing program name. |
| `notes` | optional string | Program-level intent or context. |
| `copiedFromProgramID` | optional `ProgramID` | Provenance for an explicit copy operation. |
| `createdAt` | timestamp | Record provenance. |
| `updatedAt` | timestamp | Last edit to program-level information. |

An unassigned program is valid, but absence of client links does not implicitly
turn it into a special template type. Any program may be deliberately copied and
adapted. `copiedFromProgramID` explains origin without creating live inheritance.

### Program membership on ProgrammedSession

The future programmed-session record may add these optional fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `programID` | optional `ProgramID` | Owning program; absent for a standalone session. |
| `programPosition` | optional non-negative integer | Stable order within the program. |
| `cycleLabel` | optional string | Coach-facing cycle or phase label. |
| `weekIndex` | optional positive integer | Relative week when useful. |
| `dayLabel` | optional string | Labels such as `Session A`, `Session B`, or `Day 1`. |

These labels support the observed programming structures without immediately
creating `ProgramCycle` and `ProgramWeek` tables. Promote them to entities only if
cycle- or week-level notes, rules, navigation, or editing become demonstrated
product needs.

## Multi-session examples

### Alternating sessions with explicit progression

```text
Program: Example client · Three-week strength cycle

1. Week 1 · Session A · 2026-10-05
2. Week 1 · Session B · 2026-10-08
3. Week 2 · Session A · 2026-10-12 · progressed sets/load
4. Week 2 · Session B · 2026-10-15 · progressed exercise variation
5. Week 3 · Session A · 2026-10-19 · progressed sets/load
6. Week 3 · Session B · 2026-10-22 · progressed exercise variation
```

Each occurrence is a concrete, independently editable programmed session. The
progression is visible in its exercises and sets rather than hidden behind an
override system.

### Multi-cycle reusable source

```text
Program: 3-Day Intermediate Training Plan
Cycle: 2

Week 1
  Day 1 · Snatch / squat / hinge work
  Day 2 · Clean / press / pull work
  Day 3 · Jerk / front squat / pull work

Weeks 2–4
  Same day structure with explicit set, rep, and percentage changes
```

Percentage prescriptions remain faithful text until a separate, dated training-
max model defines what the percentage references. The tabbed source may describe
several cycles without forcing every cycle into the first implementation.

## Copy-on-use rule

Reuse creates snapshots rather than live inheritance:

1. The coach chooses an existing program as a source.
2. The product creates a new `Program.id` and new IDs for every copied session,
   exercise entry, and set.
3. The new copy may receive different clients, dates, exercise wording, sets,
   loads, and notes.
4. Editing either program later cannot alter the other.
5. `copiedFromProgramID` retains bounded provenance without coupling behavior.

This rule protects presumed historical sessions from retroactive template edits
and allows each repeated Session A or Session B to contain a slight progression.

## Client and class semantics

Clients remain attached to concrete programmed sessions through `SessionClient`.
A program-level UI may offer default clients and apply them to newly created
sessions, but the session links are authoritative for individual history.

This supports:

- an individual program whose sessions all link to one client;
- a shared class program whose sessions link to several known clients;
- a class or general program with no recorded clients;
- changes in the client set between sessions without rewriting the program.

It does not yet model attendance. Linking a client means that the programmed
session contributes to that client's presumed history under the approved workflow.

## Relationship to reusable blocks

A reusable block is a smaller composition—such as a warm-up, A1/A2 pairing, or
conditioning circuit—that may be inserted into a session. A program is an ordered
collection of sessions. Neither should be inferred from whether clients are linked.

Block design remains a separate future concern. This proposal only ensures that a
later block can populate copied session content without changing exercise identity
or historical records.

## Invariants

1. Program membership is optional; standalone programmed sessions remain valid.
2. Session positions are unique within a program.
3. A copy receives new stable IDs throughout its owned graph.
4. Copy provenance never causes live propagation between programs.
5. Canonical exercise identity remains `Exercise.id` inside every programmed
   exercise.
6. Later edits to a source program cannot mutate previously copied or historical
   sessions.
7. An undated program session is not history; it becomes eligible for presumed
   history only after `sessionDate` is assigned.

## Explicitly deferred

- recurring-calendar rules and automatic date assignment;
- automatic generation of progressions or deloads;
- shared mutable templates or inheritance/override semantics;
- attendance and per-client completion;
- cycle- and week-level entities before they have their own behavior;
- training-max records and calculation of percentage loads;
- recommendations based on program balance, fatigue, constraints, or history;
- a program-builder or multi-day Notes interaction.

This proposal should remain adjacent to the programmed-session history design
until a future product slice defines how the coach writes, copies, schedules, and
edits more than one session at a time.
