# Product Definition

## Primary user outcome

Help the user write strength-training programs faster while keeping Apple Notes as the main programming workspace.

## Core workflows

The user writes naturally in Notes. The companion should help while the program is
being composed and should not require a complete draft before it becomes useful.

Example:

    Session 3 — Olympic Focus

    A1 Front Squat
    A2 Aussie Pull-up

    B1 SL RDL
    B2 DB Floor Press

The companion tool should help at the point of writing, not only after the program is complete.

Primary writing interaction:

1. The user places the cursor where an exercise should appear without first typing
   or selecting exercise text.
2. The user invokes the companion with a keyboard shortcut.
3. The companion focuses a search field immediately.
4. The user types a short query, chooses an existing exercise without a mouse, and
   inserts its preferred display name at the original Notes cursor.

Selected-text and post-program interactions remain useful secondary workflows.
They can resolve wording already present in a note, link a confirmed alias, create
a genuinely new exercise, or review unmatched exercise text after a program has
been written. Choosing an autocomplete result for insertion does not by itself
confirm an alias or create an exercise-identity relationship. Autocomplete has one
narrow explicit mutation: when the selected wording is already a confirmed alias
owned by that exercise, Make Preferred & Insert may change which owned name is the
default while inserting it. This does not create, delete, link, or merge identity.

## Exercise identity

Each exercise has a stable, opaque exercise ID. That ID is the canonical identity
and does not change when the exercise's names change.

An exercise may own multiple user-confirmed aliases. All aliases have the same
identity relationship to the exercise, but exactly one is marked as the preferred
alias. The product uses that preferred alias as the exercise's default display name
in Apple Notes and other user-facing output.

Example:

Stable exercise ID:

    8E22A4D3-…

Confirmed aliases:

- `SL RDL` — preferred
- `1-leg RDL`
- `single leg Romanian deadlift`
- `Single-Leg RDL`

Changing which alias is preferred changes only the default display text. It does
not create a new exercise, change the stable exercise ID, or remove the former
preferred alias.

New wording becomes an alias only through explicit user confirmation. Cosmetic
normalization may make equivalent formatting resolve consistently, but similarity,
abbreviation expansion, or fuzzy matching must not establish an alias relationship
by itself.

## Exercise-library trust and hygiene

Autocomplete is only as useful as the exercise identities behind its results. If
aliases are imported as separate exercises, the immediate symptom may be confusing
near-duplicate search results. Later, the same mistake can fragment blocks,
exercise attributes, programming frequency, recent exposure, client history, and
load history across identities that should have been one.

The product therefore needs a reusable exercise-observation and identity-review
workflow. Personal-library imports and completed-program reviews both contribute
durable observations with source evidence to the same resumable review queue.
Ingestion does not block program writing or require every identity question to be
answered: the user may open, dismiss, and later resume review while pending and
deferred observations remain outside autocomplete identity.

Routine library improvement must not require Terminal. Library-edit navigation
provides visible, keyboard-accessible Edit Library and Add Exercises routes from
autocomplete. Autocomplete first serves exercise search and insertion. Edit Library
opens exercise search even without a selection, carrying the selected stable
identity when one exists; Add Exercises
starts with creation from scratch, with Import as a suboption. Import contains
Review candidates for the existing observation queue. Its button badge counts
pending To review candidates across sources, excluding Skipped and exact confirmed
names. Add and Edit have no cross-navigation; each is reached from autocomplete.
Edit keeps exercise search visible, with arrow-key exercise/alias selection rather
than a dropdown and a large detail box.
Merge with duplicate keeps the exercise being edited automatically and asks for
one confirmation showing both name groups; no direction choice or comparison
screen is needed. All names remain usable after combination. Review keeps source details collapsed
until requested. Undo reverses the last review decision; it is distinct from
returning to Import. All source observations share the same To review and Skipped
views. Both routes use the current review-window lifecycle: return the Notes
Service, then open a standalone window. While open, Gym Assistant is Dock/app-switch
eligible with its branded icon; closing restores the previous activation mode.
Autocomplete's Service lifecycle and timeout remain unchanged. Administrative backups and
diagnostics may remain local command-line operations.

This navigation is implemented in the local feature worktree and passed an isolated
synthetic-data keyboard/Notes trial. Visual review and release remain outstanding.
Current source ingestion scope is the
existing CSV format. Asynchronous video/image processing and scheduled
feed ingestion are future directions feeding the same queue; instructional video
segments will belong to confirmed aliases after human review. They require a
separate model/processing design before implementation.

Given staged exercise wording and its source evidence, the workflow may let the
user:

- link the wording to an existing exercise as a confirmed name;
- create a genuinely new exercise using the preserved observation as its initial
  preferred name;
- defer an uncertain decision without losing the observation.

A manual library-edit workflow may directly correct already-persisted identities:
it may deliberately merge true duplicates or split an incorrectly linked confirmed
alias into a distinct exercise. In Edit, Merge on a parent row combines its whole
exercise; Merge on an alias child moves only that alias to an existing exercise.
Promotion is available only on a selected alias child, with no parent/default
wording in its confirmation. Multiple groups can remain expanded. Merge target
selection is subordinate to Edit Library in an attached sheet; cancellation leaves
the primary editor intact. Those are not import or completed-program
observation decisions.

Deterministic transformations, candidate match scores (using fuzzy matching), and
AI-extracted source material may help surface possibilities, but none may establish
identity without user confirmation. AI preparation of source data should preserve
observed wording and provenance rather than produce a supposedly cleaned canonical
library.

The personal-library import is the first observation source for this review
workflow. It is behaviorally equivalent to reviewing observations from one or
many completed programs, although the import and completed-program adapters retain
their own source records and provenance. A reusable exercise-observation extractor
should later identify plausible exercise wording inside mixed completed-program
text while preserving verbatim evidence and making no identity decision. Manual
library editing may use the same candidate evidence to explain a proposed merge or
alias split, but each persisted-identity change requires an explicit reviewed action.

## Non-goals for initial MVP

- replacing Apple Notes with a custom editor
- full client CRM
- workout delivery to clients
- billing
- nutrition programming
- implementing client performance/load history

## Product horizons

The current and next slices should establish low-friction library maintenance,
keyboard-first retrieval of known exercises, and trustworthy non-blocking
observation ingestion from the personal library through the reusable identity-
review workflow. Later slices may add reusable completed-program observation
extraction, help the user search by programming intent, select complementary
exercises, and insert reusable blocks.

These horizons preserve the larger product direction without adding their scope
to the active slice. The evidence, opportunities, candidate solutions, and current
horizon assignments live in [the Opportunity Solution Tree](OPPORTUNITY_SOLUTION_TREE.md).

## Longer-term data direction

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
