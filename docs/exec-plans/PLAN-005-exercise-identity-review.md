# Build a reusable, explicit exercise-identity review workflow

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds. Maintain this document in accordance with `PLANS.md` at the repository root.

## Purpose / Big Picture

After this work, a staged exercise-name observation can be reviewed against the exercise library without allowing a similarity score to establish identity. A reviewer can see why candidates were surfaced and explicitly link the observation, create a new exercise, or defer it. The reusable core can also record that two existing exercise identities must remain separate when a future library audit presents an option to merge them. Tests and a fixture report will demonstrate that the core can later serve the private import, completed-program hygiene, and manual library audits without depending on an Apple Notes parser.

## Plan Status

Complete.

## Progress

- [x] (2026-08-25) Inspected the current exercise library, exact lookup, candidate ranker, confirmation workflow, tests, and Task B acceptance boundary.
- [x] (2026-08-25) Learner approved the complete revised Task B implementation plan.
- [x] (2026-08-25) Added synthetic review-policy fixtures and tests for staged provenance, visible candidate evidence, prescription differences, identity conflicts, Link, Create, Defer, audit-only Keep Separate, repeated decisions, and zero silent writes.
- [x] (2026-08-25) Implemented the minimal reusable review domain and SQLite persistence, including transactional Link/Create and durable deferral.
- [x] (2026-08-25) Ran 43 tests, the unchanged 37-case resolver exam, and the six-case human-review report successfully.
- [x] (2026-08-25) Inspected every identity-write path and the candidate diff; removed private note titles from the tracked Task A learning entry and retained raw source only in the uncommitted private store.
- [x] (2026-08-25) Learner approved the Task B evidence, workflow boundary, teach-back reflection, and checkpoint.

## Surprises & Discoveries

- Observation: `ExerciseNameWorkflow` already supports exact lookup, ranked review, creation, and linking, but its candidates expose only a floating-point score and protected conflicts are currently removed before review.
  Evidence: `Sources/GymAssistantCore/ExerciseNameWorkflow.swift` defines exact/review/no-match lookup, while `ExerciseCandidateGenerator.swift` returns only preferred name and score.
- Observation: Existing confirmation persists aliases immediately, but there is no reusable staged-observation record, durable deferral, explicit keep-separate outcome, or source provenance for a review decision.
  Evidence: `ExerciseSuggestionConfirmation.swift` supports only accept and reject, and reject is not persisted.
- Observation: The existing protected-modifier fixture category encoded automatic-resolution safety but was too coarse to express human-review authority.
  Evidence: The unchanged resolver exam still passes 37/37 with 17/17 protected exclusions, while the new independent review report passes six dispositions including linkable short-/long-lever Copenhagen and non-linkable lateral/reverse lunge.
- Observation: The initial Task A learning entry named four private source notes even though the detailed source was intentionally uncommitted.
  Evidence: Candidate-diff privacy inspection found the titles; the tracked entry now records only four successful cross-note comparisons, leaving titles and lines in the private evidence store.

## Decision Log

- Decision: Extend the existing shared candidate-ranking path instead of creating a second identity matcher.
  Rationale: Exercise 09 established one shared ranker. Task B needs richer, review-visible evidence and a review policy, not a competing resolver.
  Date/Author: 2026-08-25 / Codex, proposed for learner approval.
- Decision: Treat a staged observation and its review record as reusable core domain concepts; keep CSV and Notes parsing outside the core.
  Rationale: Imports, completed-program hygiene, and library audits share review semantics but not source parsing.
  Date/Author: 2026-08-25 / Codex, proposed for learner approval.
- Decision: Distinguish identity-conflict evidence from prescription-bearing differences instead of treating every modifier as a non-linkable conflict.
  Rationale: Meaningfully unrelated exercises such as lateral versus reverse lunge remain non-linkable when the fixtures establish an identity conflict. Prescription-bearing forms such as short- and long-lever Copenhagen, step-up height, RNT, holds, tempo, and loading remain linkable under explicit human confirmation because the confirmed names stay selectable through autocomplete aliases. No token is universally protected without contextual fixture evidence.
  Date/Author: 2026-08-25 / Learner and Codex.
- Decision: Persist explicit review outcomes and provenance, but do not persist raw private Notes lines in the product database during Task B.
  Rationale: Task B must prove durable decisions and deferral while private import storage belongs to Task C. Tests can use synthetic source references.
  Date/Author: 2026-08-25 / Codex, proposed for learner approval.
- Decision: Use the existing `Exercise` as the grouping envelope for confirmed prescription-bearing names; do not introduce an `ExerciseFamily` type.
  Rationale: Autocomplete already lets the user expand an exercise and select a confirmed alias, so linking `Touch-Down with 5 sec negative` to `Touch-Down` preserves rather than discards the programmed wording. Alias growth will be evaluated through product use. A future prescription model may extract structure and collapse aliases, but Task B does not implement that model.
  Date/Author: 2026-08-25 / Learner and Codex.
- Decision: Create stores the staged observation text itself as the new exercise's single preferred name and provides no editable-name input.
  Rationale: Editing during identity review permits cognitive drift, such as turning observed `lateral goblet lunge` into semantically different `reverse goblet lunge`. If the preserved observation is not suitable as a name, the reviewer must defer it. A later explicit library audit workflow may allow for more flexibility - for instance by adding the observed text and creating a preferred alias. Existing cosmetic trimming and deterministic normalization still apply, and a normalized collision returns the already-existing identity instead of creating anything.
  Date/Author: 2026-08-25 / Learner and Codex.
- Decision: Creating an imported observation is sufficient to keep it distinct from surfaced candidates; reserve Keep Separate for an audit that presents two already-existing exercise identities.
  Rationale: An import or completed-program review asks whether observed wording links to an existing identity, creates a new identity, or remains deferred. A separate negative relationship adds no useful action there. A library audit has a different question—whether two existing identities should be merged—and can durably affirm that they remain separate without creating either identity. Merging existing IDs remains outside Exercise 10.
  Date/Author: 2026-08-25 / Learner and Codex.
- Decision: Separate automatic identity reuse from human-reviewed identity creation, and encode human-review disposition independently from resolver fixture category.
  Rationale: Automatic identity resolution is allowed only when normalized lookup finds wording whose ownership was already established by a confirmed `ExerciseName`; it reuses existing authority and writes nothing. `MUST_NOT_MATCH` means a pair must never establish identity automatically, but it does not by itself prohibit a reviewer from linking the names. Task B review-policy fixtures will separately classify protected comparisons as `linkableWithConfirmation` or `identityConflict` while preserving all existing automatic-resolution expectations.
  Date/Author: 2026-08-25 / Learner and Codex.

## Outcomes & Retrospective

The reusable core is implemented and the Task B learner checkpoint passed. It stages source-referenced observations, reuses exact confirmed identity without writes, surfaces structured transformation/bidirectional-lexical/prescription/conflict evidence, and persists explicit Link, Create, Defer, and audit-only Keep Separate outcomes. Forty-three tests, all 37 resolver cases, and all six review-policy cases pass. The private Task A source remains outside Git, and Task C import parsing and batch commit remain unimplemented. The learner confirmed that autocomplete, selected-text review, import, completed-program hygiene, and library audits can share resolver evidence while retaining workflow-specific consequences.

## Context and Orientation

`Sources/GymAssistantCore/ExerciseLibrary.swift` owns stable exercise identities and confirmed names in SQLite. `ExerciseNameWorkflow.swift` currently performs exact lookup, candidate lookup, creation, and linking. `ExerciseTextCandidateRanker.swift` and `ExerciseCandidateGenerator.swift` rank text similarity, while `ExerciseSuggestionConfirmation.swift` is the only existing identity-write boundary. The private Task A CSV is local and uncommitted; this task will use synthetic fixtures rather than read or commit that source.

A staged observation is one preserved wording plus a source reference and occurrence count awaiting identity review. Candidate evidence is a structured explanation of why an existing exercise was surfaced, rather than an unexplained score. Identity-conflict evidence means the fixtures establish that two expressions are different exercises, such as lateral versus reverse lunge; those candidates are visible but non-linkable. Prescription evidence means the wording adds a progression or execution detail such as lever length, a hold, RNT, box height, or eccentric duration; those candidates remain linkable under explicit review and preserve the observed wording as a selectable alias. A review decision is an explicit human-authorized outcome. Deferral means preserving an unresolved observation so it can be reviewed later without changing exercise identity. `ExerciseFamily` is not a domain type in this plan; the stable `Exercise` and its confirmed names provide the current grouping envelope.

Automatic identity resolution means deterministic normalized lookup of a name whose exercise ownership is already stored. The current selected-text workflow uses it to bypass redundant review for an existing name, and the new import review will use it to recognize repeated confirmed wording as already resolved. Autocomplete also retrieves confirmed names, but it remains a read-only text-selection workflow and therefore does not create identity knowledge. Fuzzy scores, abbreviations, lexical transformations, modifier relationships, and AI output never qualify for automatic identity resolution.

Human identity review is used when a selected name or staged import observation lacks an exact confirmed owner and the product proposes linking it, creating a new exercise, or deferring it. The same boundary is intended for future completed-program hygiene. A future library audit additionally reviews relationships between two already-existing exercise identities and may affirm Keep Separate; merging those identities remains outside Exercise 10.

## Plan of Work

First, preserve the existing 37 resolver fixtures as the automatic-resolution regression suite and clarify that `MUST_NOT_MATCH` prohibits automatic identity rather than every possible human confirmation. Add a separate synthetic review-policy fixture axis representing a known alias, a word-order or abbreviation candidate, a similar-but-distinct exercise, a non-linkable identity conflict, linkable prescription-bearing pairs such as `Touch-Down` versus `Touch-Down with RNT` and short- versus long-lever Copenhagen, an exact normalized collision, and an unresolved observation. Write tests that prove candidate generation alone leaves all library names and review state unchanged.

Next, introduce explicit domain types for the staged observation, source reference, candidate evidence, conflict evidence, review status, and explicit decisions. The review service will combine exact normalized lookup with the shared ranker and conservative transformations. It will return linkable candidates—including prescription-bearing names—and visible non-linkable identity conflicts separately. It will not add a formal family entity or family-specific matcher.

Then add the smallest persistence boundary for review records. Link will add the observed wording as an `importedConfirmed` name to the selected existing exercise. Create will accept no replacement-name parameter and will create exactly one exercise whose sole preferred name is the staged observation text after the existing cosmetic trimming rules. If that text has an existing normalized owner, Create will create nothing and return the existing identity. If the observation is unsuitable as a durable name, the available action is Defer, not rewriting it during review. Defer will store the unresolved observation and candidate-evidence snapshot without changing the exercise library; Task C will report and skip it, and a later review will regenerate current candidates while retaining the earlier snapshot. A separate audit-facing operation will record Keep Separate only for two existing exercise IDs and will create neither identity. Reapplying the same decision will be idempotent; incompatible repeated decisions will fail visibly rather than silently overwrite prior judgment.

Finally, add a fixture-report runner or test report that lists every candidate signal, protected conflict, decision result, and write effect. Run the complete package test suite and inspect all calls capable of creating an exercise or name. Stop at the Task B checkpoint before parsing or importing the private CSV.

## Concrete Steps

Work from `/Users/dan/Documents/D/dev/gym_assistant` on `tutorial/exercise-10`.

Add the Task B fixtures and tests under `Tests/GymAssistantCoreTests/` and, if a standalone report improves inspection, a synthetic fixture file under `Tests/Fixtures/`. Run `swift test`; the new tests should fail because the review types and durable outcomes do not yet exist.

Implement the reusable workflow under `Sources/GymAssistantCore/`, keeping SQLite access in the library or a narrowly scoped review store. Run `swift test` after each coherent slice. At completion, run `swift test`, `swift run ResolverFixtureRunner Tests/Fixtures/resolver-cases.json`, and `swift run IdentityReviewFixtureRunner Tests/Fixtures/identity-review-cases.json`; expect every existing regression to remain green and the new Task B report to show zero candidate-caused identity writes.

## Validation and Acceptance

The complete fixture report must show at least one example of exact normalized evidence, conservative transformation evidence, bidirectional lexical evidence, a linkable prescription-bearing candidate, and a non-linkable identity conflict. It must report automatic-resolution results separately from human-review disposition so `MUST_NOT_MATCH` cannot be mistaken for “never reviewable.” A known alias must be surfaced for review; two existing meaningful variants must be affirmable as separate during an audit; and a deferred observation must remain available after recreating the workflow over the same database.

Tests must prove that generating candidates never creates an exercise or name; only explicit link and create decisions can do so. Link uses `importedConfirmed` provenance. Create accepts no editable name, produces exactly one stable exercise with exactly one preferred name equal to the cosmetically trimmed observation, and therefore cannot change `lateral goblet lunge` into `reverse goblet lunge`. A normalized collision creates nothing and returns the existing identity. Keep Separate accepts only two existing exercise IDs, records their reviewed distinction, and creates no identity or name. Defer survives reopening the same database, remains reportable, and writes no exercise identity. Repeating any accepted decision produces no duplicate rows. Prescription-bearing candidates remain linkable, while fixture-established identity conflicts cannot be submitted as link decisions. Existing resolver and autocomplete tests must continue to pass with zero false merges and zero protected-candidate leaks in those workflows.

The repository diff at the checkpoint must contain no private Notes content, client names, or Task A source rows. Task C import parsing, bulk commit, and real-source decisions remain unimplemented.

## Idempotence and Recovery

All fixtures use temporary databases and are safe to repeat. Review decisions use stable synthetic observation identifiers so repeated application returns the existing outcome rather than duplicating it. If persistence migration fails, SQLite transactions must roll back without leaving a partially recorded decision or partially created identity. The private Task A files remain untouched.

## Artifacts and Notes

The checkpoint will include the domain types, adapter boundary, complete synthetic fixture report, all protected-conflict examples, a list of every identity-write call, provenance evidence, durable deferral evidence, and full regression results.

## Interfaces and Dependencies

Use only Foundation and the existing SQLite3 dependency. Add a reusable review service in `GymAssistantCore` whose staged-observation operations are conceptually `prepare(observation:)`, `link(observationID:to:)`, `create(observationID:)`, and `deferDecision(observationID:)`, plus an audit-oriented `keepSeparate(firstExerciseID:secondExerciseID:)`. Create deliberately has no name argument. Exact names may bypass candidate review only as already-confirmed identity. Candidate results must expose structured evidence and whether linking is permitted. Results must identify what was persisted without requiring an import-specific type.

Plan revision note (2026-08-25): Initial proposal created after Task A approval and inspection of the existing shared ranker, workflow, and persistence boundaries.

Plan revision note (2026-08-25): Added the learner-approved prescription-bearing protection and clarified one-name Create, durable Keep Separate exclusions, edited-name collision handling, and the lifecycle of deferred records before implementation approval.

Plan revision note (2026-08-25): Corrected the prescription model after the learner observed that autocomplete alias expansion preserves the chosen prescription text. Removed the informal Exercise Family concept, made prescription-bearing candidates explicitly linkable, limited non-linkable conflicts to fixture-established identity differences, and moved Keep Separate to the existing-identity audit boundary.

Plan revision note (2026-08-25): Removed editable naming from Create to prevent semantic drift. Create now uses only the staged observation text; unsuitable wording must be deferred for a later explicit name-management workflow.

Plan revision note (2026-08-25): Preserved the existing resolver categories as automatic-identity ground truth, added an independent human-review disposition axis, and documented which current and future product workflows use deterministic resolution versus explicit review.

Plan revision note (2026-08-25): Recorded completed implementation, transactional persistence, full verification results, the independent six-case review report, and privacy cleanup in preparation for the Task B checkpoint.

Plan revision note (2026-08-25): Marked the plan complete after learner approval of the evidence, workflow boundary, teach-back reflection, and Task B checkpoint.
