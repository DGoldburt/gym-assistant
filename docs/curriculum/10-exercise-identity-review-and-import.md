# Exercise 10 — Exercise Identity Review + Personal Library Import

## Why we're doing this

Autocomplete becomes a useful product only when it searches the user's real
exercise library. Importing a flat list without identity review could create
separate exercise IDs for aliases, fragmenting search results and later blocks,
frequency evidence, program context, and client history.

The import is the first observation source for a reusable exercise-identity review
workflow. Like a later completed-program review, it stores source-backed
observations in a resumable queue without blocking program writing. The same
identity boundary should also support manual library audits without turning this
exercise into those complete products.

## Codex skill

- extracting evidence without delegating identity decisions to AI
- designing a reusable domain workflow behind a one-time import adapter
- separating high-recall candidate generation from authoritative confirmation
- delivering and field-testing a useful vertical product slice

## Skills practiced

- `frame-work` — Frame a bounded task
- `verify` — Build an evidence-producing delivery loop
- `set-boundaries` — Reuse the right core without implementing future adapters
- `record-decisions` — Preserve the provenance of identity decisions

## Product-scope guard

This exercise imports a reviewed personal exercise library and builds only the
shared identity-review behavior required to do that safely. Similarity and
deterministic transformations may surface review candidates but must never create
an alias, merge identities, or choose a preferred name without user confirmation.

The workflow may link an observed name to an existing exercise, create one new
exercise from the preserved observation text, or defer a decision. Pending and
deferred observations may remain in the queue without blocking import or program
writing. Merging or affirming separation between two already-persisted exercise
IDs, building the reusable completed-program observation extractor, building a
polished hygiene dashboard, adding movement taxonomy, learning semantic similarity,
and rewriting historical references remain outside this exercise.

## Task A — Prepare auditable source evidence from Strength Training Notes

Use the guarded prompt in
[`docs/reference/STRENGTH_TRAINING_LIBRARY_SOURCE_PROMPT.md`](../reference/STRENGTH_TRAINING_LIBRARY_SOURCE_PROMPT.md)
to ask ChatGPT for a high-recall inventory of observed exercise wording. ChatGPT
must preserve distinct wording and source evidence rather than decide aliases,
canonical names, duplicate groups, corrections, or merges.

Inspect coverage against the Notes folder, sample source lines, review every
ambiguous extraction, and correct extraction errors without performing the later
identity review inside ChatGPT. Define the staged input format and keep the raw
source file local and uncommitted if it contains client or program information.

### STOP / REVIEW — Source-evidence boundary

Inspect the exact prompt, ChatGPT's coverage report, the source schema, sampled
Notes comparisons, all ambiguous rows, and the repository/privacy handling plan.
Decide whether the source is complete enough to stage and whether ChatGPT was kept
inside extraction rather than exercise-identity judgment.

Teach back: Why is preserving `SL RDL`, `1-leg RDL`, and `Single-Leg Romanian
Deadlift` as separate observations safer than asking ChatGPT to produce a cleaned
canonical library?

## Task B — Build the reusable exercise-identity review workflow

Model a staged observation with its source and provenance, candidate exercises,
visible ranking or transformation evidence, modifier conflicts, review status,
and an explicit decision. Support these decisions:

- link the observed name to an existing exercise as a confirmed name;
- create a new exercise from the preserved observation text;
- affirm that similar items remain separate;
- defer an unresolved item without losing it.

Use several high-recall candidate signals rather than relying on the current fuzzy
ranker alone: exact normalized collisions, conservative search-only abbreviation
or phrase transformations, bidirectional lexical similarity, and reviewable
exercise-family grouping. A protected modifier should be displayed as conflict
evidence during this audit instead of silently hiding the pair. No score may write
an identity relationship.

Keep candidate generation and review decisions independent of the import parser so
completed-program and manual-audit adapters can reuse them later. Cover known alias
pairs, similar-but-distinct exercises, abbreviations, word-order changes,
modifier conflicts, deferral, repeated decisions, and zero-silent-merge behavior
with fixtures and tests.

### STOP / REVIEW — Identity-review evidence

Inspect the domain types, adapter boundary, candidate evidence, complete fixture
report, protected conflicts, every possible write path, provenance, and deferred
state. Confirm that known aliases are surfaced for review, meaningful variants can
remain separate, and no candidate score or AI output establishes identity.

Teach back: Which parts of this workflow can serve imports, completed-program
hygiene, and library audits, and which operations remain specific to one adapter?

## Task C — Import the personal library and test the useful product slice

Build the narrow import adapter around the reviewed source. It must validate and
account for every row, ingest the complete source transactionally into a durable
observation queue, preserve occurrence provenance, be safe to rerun, and report
pending, deferred, resolved, invalid, and failed items. Ingestion and identity
resolution are separate lifecycles: pending observations do not block ingestion,
and closing review must preserve the learner's place.

Review a useful subset rather than requiring a disposition for every observation.
Preview the subset's Link and Create effects against a scratch library, apply only
explicitly approved identity decisions, and prove that each decision is
transactional and idempotent. Then use Exercise 09 autocomplete against the
resulting real library in Apple Notes. Preserve an ingestion record and source
references sufficient to audit every observation without committing private Notes
content. For this exercise, invoke the resumable review interface through a local
command-line runner while preparing and validating the initial source. Also add a
visible, keyboard-operable Review Library action to the existing Gym Assistant
autocomplete panel. It opens a separate resumable review window without requiring
Terminal or another global shortcut. Do not add a full library dashboard, merge
workflow, reminders, queue sorting, or shortcut-settings UI.

### STOP / REVIEW — Import and useful-product pause gate

Inspect reconciled source and observation counts, ingestion provenance, a dry-run
summary for the reviewed subset, a sample of every decision type, collision and
rollback evidence, idempotent ingestion and decision-rerun evidence, the resumable
pending/deferred queue, persisted names, and real Notes autocomplete results from
the imported library. From Notes, verify that the existing Gym Assistant shortcut
can reach Review Library, an identity decision persists immediately, closing and
reopening resumes the queue, focus returns to Notes, and autocomplete can retrieve
the newly resolved identity without using Terminal.

Decide whether the vertical slice—invoke from an empty Notes cursor, search the
personal library, choose entirely by keyboard, insert the preferred display name,
and return to programming—is useful enough to pause development for a field-test
period.

Teach back: What evidence shows that ingestion is complete and the reviewed subset
is trustworthy enough for autocomplete without claiming that every identity
question has been solved?

After the user approves the reflection and checkpoint, append learning evidence,
update justified skill confidence and progress, and advance to Exercise 11 only if
the user chooses to continue development after the pause gate.
