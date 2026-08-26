# ADR 002 — Separate observation ingestion from identity review

Status: accepted for the initial product direction on 2026-08-26.

## Context

The personal-library seed began as a complete import batch: every consolidated
observation had to become exact reuse, Link, Create, or explicit Defer before any
approved batch could reach the live library. That made the first import safe, but
it coupled source acceptance to hundreds of human identity decisions.

The product also needs to review completed programs without interrupting the next
program-writing task. A personal-library source can be understood as observations
from many completed programs collected at once. Both sources need to preserve
observed wording and provenance, surface a resumable review queue, and allow the
user to dismiss it without losing evidence or blocking Apple Notes.

## Decision

Separate observation ingestion from exercise-identity resolution.

An import or completed-program adapter creates an ingestion record and stores all
valid observations with their occurrence-level source evidence transactionally.
Unreviewed observations remain `pending`; an inspected but unresolved observation
may be marked `deferred`. Neither status creates an exercise/name, appears in
autocomplete identity, or blocks program writing.

Identity review is on-demand, dismissible, and resumable. Exact normalized lookup
may recognize an already-confirmed name without writing. Each Link or Create
decision atomically updates one observation and any corresponding exercise-library
records. Defer changes only review state. Ingestion idempotency and decision
idempotency are verified independently.

Routine review is reachable from the keyboard-accessible Gym Assistant UI. The
existing autocomplete panel provides a visible Review Library action with a local
keyboard equivalent, opening a separate review window and releasing the Notes
Service invocation. This reuses the established global shortcut rather than adding
another shortcut to remember or configure. Command-line tooling remains appropriate
for administrative ingestion, backup, dry-run, and diagnostics, but is not the
ordinary review entry point.

Personal-library import and completed-program review are sibling observation-source
kinds rather than separate identity-review systems or literal subtypes of one
another. A later reusable exercise-observation extractor may turn mixed completed-
program text into source-backed observations, but it cannot establish identity.

One observation may have evidence from multiple notes, programs, or ingestions.
Durable provenance therefore uses an ingestion record plus occurrence/evidence
records instead of flattening provenance into one adapter/reference field on the
observation. These records do not add required fields to `Exercise` or
`ExerciseName`.

## Evidence

- Exercise 10 Task A found 1,891 logical source records and 2,224 occurrences, with
  158 rows requiring explicit extraction-boundary review.
- Requiring a disposition for every consolidated observation delayed testing the
  useful autocomplete slice even though pending observations cannot affect search.
- Exercise 10 Task B already persists observations independently of exercises and
  supports durable pending/deferred state plus transactional Link and Create.
- The learner explicitly wants both import and completed-program review to run in
  the background of program writing and be callable, dismissible, and resumable.
- A single consolidated observation can preserve evidence from multiple Notes
  locations, which the current one-adapter/one-reference storage shape cannot fully
  represent.

## Alternatives considered

### Require a complete decision manifest before import

Rejected. It safely prevents accidental identity writes but makes unresolved work
block otherwise harmless observation capture and useful reviewed identities.

### Treat personal-library import as a completed-program record

Rejected as a persistence model. The workflows share ingestion and review
semantics, but an import may aggregate many programs and needs distinct source
metadata. Both are represented as observation-source kinds.

### Implement completed-program extraction in Exercise 10

Deferred. Task A exposed unresolved questions about headings, prescriptions,
comments, compound lines, and exercise boundaries. Exercise 10 can preserve the
evidence and interfaces without expanding its useful-product gate into a new
extraction product.

## Consequences

- Exercise 10 Task C ingests the complete source but reviews only a useful subset
  before the Notes autocomplete field test.
- Pending is a valid durable state, not an incomplete batch error. Defer indicates
  inspected uncertainty and remains distinct from untouched pending work.
- The review interface needs close/resume behavior and may apply approved decisions
  incrementally.
- The existing Gym Assistant autocomplete panel needs a keyboard-operable Review
  Library entry point, and the resulting review window must outlive the originating
  Notes Service request safely.
- Import receipts split into ingestion and identity-decision receipts or equivalent
  independently idempotent records.
- Source evidence needs a one-to-many occurrence relationship.
- Task A extraction decisions and Task C review outcomes are retained privately as
  inputs to a future extractor evaluation, without committing private Notes text.

## Known limitations

- The current implementation stores one adapter/reference pair directly on an
  observation and must migrate before live ingestion can preserve all occurrence
  provenance.
- No reusable completed-program extractor is implemented by this decision.
- Review ordering, reminders, queue aging, and a polished hygiene dashboard remain
  unspecified.
- A dedicated global review shortcut, menu-bar item, shortcut-settings UI, and full
  library-management navigation remain outside this decision.
- An identity outcome is not extraction truth. In particular, Defer can mean
  identity uncertainty, unsuitable wording, insufficient context, or an extraction
  problem.

## Revisit triggers

Revisit this decision if pending observations make the library chronically
incomplete, the queue becomes too burdensome to resume, source provenance cannot be
retained within acceptable privacy constraints, independently applied decisions
produce inconsistent candidate state, or real completed-program use demonstrates
that ingestion must synchronously block another workflow for correctness.
