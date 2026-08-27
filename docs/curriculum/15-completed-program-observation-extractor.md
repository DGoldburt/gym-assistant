# Exercise 15 — Reusable Completed-Program Observation Extractor

## Why we're doing this

Completed programs contain valuable exercise observations mixed with headings,
sets and reps, coaching notes, alternatives, warmups, client context, and other
non-exercise text. The product needs to find those observations without turning
the extractor into an exercise-identity authority or requiring the user to finish
review before writing another program.

Exercise 10 Task A created unusually useful extraction-boundary evidence. Task C
adds downstream identity outcomes and a durable deferred queue. This exercise uses
both sources to build and evaluate a reusable extractor while keeping their labels
semantically separate.

## Starting state and prerequisites

- Exercise 10 has ingested the personal source with occurrence provenance.
- The private Task A extraction audit remains available by source fingerprint.
- The private Task C feedback packet connects stable observation IDs to review
  status, candidate snapshots, and explicit outcomes. Re-run the packet exporter to make sure it covers all review decisions that have accumulated in the database since the last packet was generated.
- The observation store and identity-review service remain independent of Notes.

If any private prerequisite is unavailable, stop and reconstruct only the smallest
evidence set with explicit approval. Never commit private Notes, client names, or
program text merely to make the harness portable.

## Codex skill

- converting human review into ground truth without confusing adjacent decisions
- building a deliberately failing extraction harness before implementation
- improving a component from error clusters rather than isolated anecdotes
- preserving a reusable domain boundary behind source-specific adapters

## Skills practiced

- `frame-work` — Frame a bounded task
- `verify` — Build an evidence-producing delivery loop
- `set-boundaries` — Keep extraction separate from identity authority
- `review` — Diagnose uncertain and deferred cases with independent evidence

## Product-scope guard

This exercise extracts source-backed exercise observations from completed-program
text and sends them to the existing non-blocking review queue. It does not link an
alias, create or merge an exercise, choose a preferred name, infer client history,
structure sets/reps/load, classify movement patterns, or recommend programming.

The extractor may use deterministic parsing, heuristics, or an explicitly approved
model-assisted adapter. Regardless of mechanism, it must preserve verbatim spans,
locations, and provenance and must expose uncertainty. No extraction score or AI
output may establish exercise identity.

## Task A — Turn prior reviews into an extraction evaluation corpus

Build a private evaluation adapter around the Task A audit. Preserve the original
decision categories—plausible observation, not exercise, split/trim, and expand—plus
their source spans. Define boundary-aware measures for missed observations, false
observations, incorrect spans, and incorrect split/expand behavior. Hold out a
representative portion before tuning so the same examples are not both memorized
and reported as independent evidence.

Join Task C outcomes only as a second diagnostic axis:

- exact reuse, Link, and Create are evidence that an extracted wording was usable;
- pending means no downstream judgment exists;
- Defer is an audit queue, not a negative extraction label.

Review every deferred observation from Task C's reviewed subset and assign an
extraction diagnosis: correct extraction with uncertain identity, correct
extraction but unsuitable durable name, insufficient source context, extraction
boundary error, or another explicitly described reason. Only human-confirmed
extraction diagnoses may change extractor fixtures.

Create tracked synthetic fixtures for recurring error shapes, while the private
runner evaluates the full private corpus locally.

### STOP / REVIEW — Ground-truth and feedback boundary

Inspect the private/tracked separation, category mapping, held-out split, metrics,
synthetic fixtures, and deferred-observation diagnoses. Confirm that Task A labels
remain extraction ground truth, Task C outcomes remain downstream evidence, and no
identity outcome was silently converted into an extraction label.

Teach back: Why can a deferred identity decision reveal an extractor problem
without proving that extraction was wrong?

## Task B — Implement the reusable extractor boundary

Define a source-independent extractor that accepts completed-program text plus an
opaque source reference and returns ordered candidate observations with verbatim
text spans and locations. Put Apple Notes access, import formats, and other source
retrieval outside the extractor. Preserve repeated occurrences and compound-line
boundaries so later ingestion can consolidate them without losing provenance.

Run the deliberately failing baseline first. Implement only the smallest parsing
or model-assisted behavior justified by the approved Task A corpus, and repeatedly
report false observations, missed observations, boundary errors, privacy handling,
and the untouched holdout result. Do not optimize identity resolution inside the
extractor.

### STOP / REVIEW — Extractor behavior

Inspect the extractor interface, complete synthetic fixture report, private corpus
summary, holdout result, representative false positives/negatives/boundary errors,
and every path that could discard or rewrite source wording. Decide whether its
quality and review burden are acceptable for a real completed-program trial.

Teach back: How does the failing harness distinguish a missing extractor capability
from an identity-resolution question?

## Task C — Run a completed-program feedback loop

Run the extractor on a bounded set of newly completed programs, ingest its proposed
observations with provenance, and verify that the user can dismiss and resume the
review queue without interrupting new programming. Compare extractor output with
the source, then inspect downstream exact reuse, Link, Create, pending, and Defer
clusters.

For each justified extractor correction, add or update an extraction fixture,
rerun the full corpus and holdout, and check for regression in more severe failure
classes. Limit the iteration to an approved review budget; do not wait for perfect
agreement or eliminate every ambiguous observation.

### STOP / REVIEW — Product feedback loop

Inspect the real completed-program comparison, review friction, deferred-reason
audit, fixture changes, full regression report, and holdout result. Decide whether
the extractor is useful enough to run routinely, needs another bounded iteration,
or should remain manual.

Teach back: Which feedback changed extractor behavior, and which feedback properly
remained an identity-review or human-judgment question?
