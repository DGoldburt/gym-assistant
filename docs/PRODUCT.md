# Product Definition

## Primary user outcome

Help the user write strength-training programs faster while keeping Apple Notes as the main programming workspace.

## Core workflow

The user writes naturally in Notes.

Example:

    Session 3 — Olympic Focus

    A1 Front Squat
    A2 Aussie Pull-up

    B1 SL RDL
    B2 DB Floor Press

The companion tool should help at the point of writing, not only after the program is complete.

Potential interaction:

1. User types or selects text in Notes.
2. User invokes a macOS Service / Quick Action / keyboard shortcut.
3. The companion tool receives the selected text.
4. It searches or resolves against the exercise library.
5. User chooses an existing exercise, links an alias, or creates a new exercise.
6. The tool returns useful text to Notes with minimal interruption.

## Exercise identity

These may refer to one canonical exercise:

- SL RDL
- 1-leg RDL
- single leg Romanian deadlift
- Single Leg RDL

Canonical identity example:

    Single-Leg Romanian Deadlift

Preferred display name might still be:

    SL RDL

Canonical identity and preferred display text are separate concepts.

## Non-goals for initial MVP

- replacing Apple Notes with a custom editor
- full client CRM
- workout delivery to clients
- billing
- nutrition programming
- implementing client performance/load history

## Future direction

A later system should be able to associate:

- client
- date
- exercise
- sets
- reps
- load
- notes

with a stable exercise ID so that program-writing tools can surface recent training history and load suggestions.

The initial data model must not make that future direction unnecessarily difficult.

## Success metric

The product should reduce:
- keystrokes
- repeated lookup
- repeated typing of common exercise names
- repeated construction of common blocks
- cognitive load when choosing familiar programming patterns

A feature that adds workflow friction should be treated skeptically even if technically impressive.
