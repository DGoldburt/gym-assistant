# Deliver keyboard autocomplete in Apple Notes

This ExecPlan is a living document maintained according to `PLANS.md` at the repository root.

## Purpose / Big Picture

After this change, a coach can place an empty cursor in Apple Notes, invoke Gym Assistant, type a short query, choose an existing exercise or confirmed alias entirely by keyboard, and insert that wording at the original cursor. If no exercise matches, Return inserts the visible query without changing the exercise library, so an incomplete library never interrupts programming.

## Plan Status

Complete. Exercise 09 Tasks A–C passed, including the corrected physical shortcut,
active-caret behavior, learner-usefulness gate, incremental ranking, and cancellation.

## Progress

- [x] (2026-08-24) Approved the empty-cursor interaction, alias expansion, unmatched-query insertion, read-only fuzzy ranking, and measurable acceptance budgets.
- [x] (2026-08-24) Implemented, tested, and passed review for persisted-library search behind an Apple Notes-independent boundary; 32 tests and the unchanged 37-case resolver exam pass.
- [x] (2026-08-24) Connected search to the AppKit Service and completed automated
  and real Notes evidence with zero observed integrity or identity-write failures.
- [x] (2026-08-24) Passed the physical-shortcut and learner-usefulness review at
  5/5 after bounded shortcut, focus, ranking-continuity, and cancellation fixes.

## Surprises & Discoveries

- Observation: A query is retrieval input, not necessarily exercise-name evidence.
  Evidence: Approved examples such as `fro`, `sl`, and `db fl` are intentionally incomplete and must never be persisted as aliases merely because a result is selected.
- Observation: Returning unmatched query text preserves writing flow without adding a creation dialog.
  Evidence: The learner explicitly preferred raw-query insertion and recognized that later program review and identity reconciliation consequently become more important.
- Observation: The approved short misspelling `coppen` exposed that a separate search-only fuzzy calculation would drift from identity review.
  Evidence: An initial duplicate implementation needed its own threshold calibration. It was removed after learner review; the shared candidate ranker now supplies token-level edit evidence to both policies, with autocomplete using the more permissive `0.35` threshold while retaining the unrelated `Novel March` no-result guard.
- Observation: Deterministic alphabetical ordering applies only after unmatched-character count.
  Evidence: For query `press`, `Beta Press` correctly precedes `Alpha Press` because it has one fewer unmatched character; the initial test expectation contradicted the approved contract and was corrected.
- Observation: AppKit's field editor consumes Return and navigation commands before an `NSSearchField` subclass receives `keyDown`.
  Evidence: The first real Notes trial displayed `fro` and selected Front Squat, but synthetic Return left the panel open and inserted nothing. Routing `insertNewline:`, movement, and cancellation selectors through `NSSearchFieldDelegate` addresses the actual command boundary.
- Observation: A Service pasteboard return can insert correctly without restoring
  an active Notes caret.
  Evidence: The first physical-shortcut checkpoint inserted at the requested cursor,
  but the learner could not continue typing there. The adapter had activated Gym
  Assistant without explicitly reactivating the invoking Notes process; direct
  application handoff is now required and remains pending physical retest.
- Observation: Search success alone did not make the complete workflow preferable.
  Evidence: All five physical search cases worked, but the learner preferred the
  workflow in only three because Control-Option-Command-G required looking down and
  moving a hand. Option-Command-G was approved for retest without changing the 4/5
  acceptance threshold.
- Observation: The permissive fuzzy threshold admitted a coincidental short-token
  similarity between `test` and a token in Tall Kneeling Bottoms-Up KB Press.
  Evidence: The learner discovered the unrelated result during physical retesting.
  Short single-token fuzzy input now requires a stronger score, while direct prefix,
  containment, longer fuzzy input such as `coppen`, and close `sqat`-to-`Squat`
  correction retain their approved behavior.
- Observation: Testing isolated final queries missed an incremental-search
  discontinuity: `cop` and `coppe` found Copenhagen Plank while `copp` did not.
  Evidence: The learner tried each intermediate character after the first short-
  query correction. Short fuzzy scoring now recognizes strong same-length prefix
  edits, and the regression runs the complete `c` through `coppen` sequence while
  retaining the unrelated-`test` exclusion.
- Observation: In a long incremental-query trial, Escape cleared the search field
  instead of canceling the panel, which then outlived the Service's 30-second timeout.
  Evidence: The event log ended with an empty-query update and had no cancellation
  or service-return event. The panel now intercepts Escape before `NSSearchField`,
  and the autocomplete request timeout is two minutes to support deliberate review.

## Decision Log

- Decision: Deduplicate top-level results by stable exercise identity and show the preferred name with subtle alias-count context.
  Rationale: Multiple matching names must not make one exercise appear to be several exercises.
  Date/Author: 2026-08-24 / Learner
- Decision: Right Arrow exposes confirmed aliases; Return inserts the selected preferred name or alias without changing which name is preferred.
  Rationale: Retrieval should not lock the coach into preferred wording, and insertion is not an identity write.
  Date/Author: 2026-08-24 / Learner
- Decision: Return with no result inserts the visible query exactly and performs no library write.
  Rationale: Programming should continue even when the library is incomplete; later identity review owns reconciliation.
  Date/Author: 2026-08-24 / Learner
- Decision: Use fuzzy lexical similarity only as the lowest-priority read-only ranking tier, while deferring vocabulary transformations such as `KB` to `kettlebell`.
  Rationale: Approximate retrieval can be useful without establishing identity, but abbreviation expansion is separate domain knowledge that requires field evidence and its own contract.
  Date/Author: 2026-08-24 / Learner and Codex
- Decision: Observe selected-text dialog cancellation as evidence for a possible later replacement-search workflow, but do not change selected-text behavior in Exercise 09.
  Rationale: Cancellation count may reveal friction, but intent also requires surrounding behavioral or qualitative evidence.
  Date/Author: 2026-08-24 / Learner and Codex
- Decision: Identity review and autocomplete use one candidate-ranking component with explicit consumer policies rather than separate fuzzy implementations.
  Rationale: Anything safe to surface as an identity-review suggestion is safe to surface in read-only search, while search may use a more permissive threshold because its consequences are reversible. Autocomplete therefore uses every equivalence already accepted by identity review plus its lower threshold. Exercise 11 remains the gate for proposing new transformations such as `KB` to `kettlebell`.
  Date/Author: 2026-08-24 / Learner

## Outcomes & Retrospective

The interaction and ranking contract is approved. Task B provides a separate,
deterministic, read-only search component with explicit match evidence, confirmed
aliases, stable identity deduplication, protected fuzzy exclusions, and zero-write
regression evidence. Task C connects that search to a keyboard-only AppKit Service,
preserves the selected-text review Service, and passes the measured Notes integration
budgets. Thirty-two tests pass across seven suites, and the unchanged
37-case resolver exam retains zero false merges and zero protected-candidate leaks.
Option-Command-G, active-caret restoration, and a 5/5 learner preference passed the
final checkpoint. Field-discovered `test`, `copp`, and Escape failures are retained
as regression evidence rather than hidden by the original automated results.

## Context and Orientation

`Sources/GymAssistantCore/ExerciseLibrary.swift` owns stable exercise identities, one preferred name per exercise, and confirmed aliases in SQLite. `Sources/GymAssistantCore/ExerciseNameWorkflow.swift` coordinates the selected-text link/create workflow and must remain separate from autocomplete. `Sources/GymAssistantCore/ExerciseCandidateGenerator.swift` contains existing lexical candidate mechanics designed for identity review; autocomplete may reuse compatible low-level scoring behavior but must expose a separate search contract with no writes. `Sources/GymAssistantNotesService/main.swift` is the AppKit Service adapter currently requiring selected text. `app/notes-service/` builds the locally installed Service bundle.

A preferred name is the default coach-facing name owned by an exercise. A confirmed alias is another user-approved name owned by the same stable exercise identity. Fuzzy similarity is approximate text evidence; it may order search results but cannot create identity knowledge. The shared ranker's already-approved identity-review equivalences are available to autocomplete. New vocabulary transformations, including `KB` meaning `kettlebell`, are not part of this plan.

## Plan of Work

First implement an Apple Notes-independent search component in `GymAssistantCore`. It must read all preferred names and confirmed aliases from the persisted library, score every stored name, retain each exercise's strongest match, and return each exercise once. The result type must contain the stable exercise ID, preferred name, confirmed aliases needed for expansion, match explanation, and deterministic rank information. Search must have no path to a library mutation method.

Ranking strength is exact normalized name, whole-name prefix, ordered token-prefix, lexical substring or token containment, then fuzzy lexical similarity above an explicit threshold. Stronger evidence always wins. Within one tier, prefer fewer unmatched characters, then a preferred-name match, then preferred display name, with stable exercise ID as the invisible final tie-breaker. Cosmetic normalization remains limited to case, whitespace, and one trailing period or exclamation point. A fuzzy-only candidate with a known protected-modifier conflict must be excluded. No `KB` expansion or other unconfirmed transformation is permitted.

Automated tests must cover preferred and alias retrieval, alias-driven matches displayed as one preferred-name result, duplicate suppression when several names match, deterministic ties, empty queries, below-threshold queries, fuzzy misspellings, protected conflicts, and proof that every search leaves persisted names unchanged. Stop for Exercise 09 Task B review before editing the Notes adapter.

After Task B approval, extend `GymAssistantNotesService` to support invocation at an empty cursor. The compact panel receives focus immediately, displays at most five top-level results with subtle alias-count context, supports Up/Down navigation, expands and collapses aliases with Right/Left Arrow, inserts the selected preferred name or alias with Return, and cancels with Escape. An empty query displays `Type to search`; Return does nothing. When no result passes the threshold, the panel offers Return to insert the visible query exactly. No path creates an exercise, alias, or preferred-name change.

The adapter must insert exactly once at the original cursor, add no spaces, punctuation, bullets, or newlines, preserve surrounding Notes content, and restore the invoking Notes body focus. Existing selected-text behavior remains unchanged. Existing local event evidence should distinguish selected-text cancellation so later field use can evaluate the replacement-search hypothesis without implementing it now.

## Concrete Steps

Work from `/Users/dan/Documents/D/dev/gym_assistant`. During Task B, run `swift test` and `swift run ResolverFixtureRunner Tests/Fixtures/resolver-cases.json`. Expect every package test to pass and the unchanged 37-case resolver exam to retain zero false merges and zero protected-candidate leaks. Add focused search tests that demonstrate `fro`, `copen`, `coppen`, `sl`, and `db fl`, plus empty, unmatched, duplicate, tie, alias-expansion data, and protected-conflict cases.

During Task C, rebuild and install the bundle through `app/notes-service/build.sh`, refresh Service registration, restart Notes if needed, and use only a disposable note with no client content. Preserve concise machine-readable timing and event evidence plus a human-readable report under `evidence/exercise-09/`.

## Validation and Acceptance

Task B passes when the search result ordering is understandable, each exercise appears once, confirmed aliases are available for deliberate insertion, fuzzy evidence remains lowest priority, protected fuzzy conflicts remain excluded, empty and below-threshold queries behave deterministically, and snapshots before and after every query prove zero library writes.

Task C requires zero mouse use. Five of five fresh-launch invocations must provide a usable query field within 1,000 ms. Twenty of twenty warm invocations must succeed with median latency at most 250 ms and nearest-rank p95 at most 500 ms. Query-update nearest-rank p95 must be at most 100 ms. Return-to-restored-Notes-focus must take at most 500 ms. Five of five Escape trials must leave Notes unchanged. Across all trials there must be zero wrong-note, wrong-position, surrounding-text, duplicate-insertion, or identity-write failures.

Matched trials use `fro` for Front Squat, `copen` for Copenhagen Plank, `coppen` for a fuzzy Copenhagen Plank result, `sl` for Single-Leg Romanian Deadlift through confirmed `SL RDL`, and `db fl` for Dumbbell Floor Press through confirmed `DB Floor Press`. Query characters must be at least 40 percent shorter than the inserted stored name in at least four of five trials, and the learner must prefer autocomplete to full-name typing in at least four of five trials. Additional trials cover alias insertion, unmatched-query insertion, empty query, cancellation, ties, duplicate suppression, protected fuzzy conflicts, and cursor integrity.

## Idempotence and Recovery

Automated tests use unique temporary SQLite databases and may be repeated safely. Search is read-only by contract. Bundle rebuilding replaces the local development bundle without altering the exercise database. Manual trials must use a disposable Notes document and known test records. If installation or Service discovery fails, preserve that failure as evidence, repair the existing local installation, and restart the trial count rather than counting setup failures as successful product trials.

## Artifacts and Notes

Task B evidence belongs in tests and a concise search report if terminal output alone is insufficient. Task C evidence belongs under `evidence/exercise-09/` and must contain no client Notes content. Selected-text cancellation counts are discovery evidence only and do not change the accepted Exercise 09 behavior.

## Interfaces and Dependencies

Add explicit Swift domain types for autocomplete query results and match evidence in `GymAssistantCore`; do not return dictionaries or UI types. Add read-only library access for preferred names and confirmed aliases if the current API is insufficient. Keep AppKit, pasteboard handling, focus, and key events in `GymAssistantNotesService`. SQLite remains the only persistence dependency, and no new external package is required.

Revision note (2026-08-24): Created after Exercise 09 Task A approval to preserve the complete interaction, ranking, safety, and evidence contract across Tasks B and C.

Revision note (2026-08-24): Updated after Task B implementation and verification.
The first regression run calibrated the approved `coppen` fuzzy case and corrected
a test that contradicted the accepted unmatched-character tie-breaker. A later
self-review separated matched-alias tie-breaking from preferred-display ordering.

Revision note (2026-08-24): Revised after learner review to make autocomplete
evidence a strict superset of identity-review evidence. Both policies now enable
all currently approved equivalences; autocomplete additionally uses a lower fuzzy
threshold. New equivalences remain evidence-gated future work.
