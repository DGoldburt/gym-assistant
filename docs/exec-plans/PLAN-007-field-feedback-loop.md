# Build a private field-feedback loop before automating product changes

This ExecPlan is a living document. Maintain it in accordance with `PLANS.md` at the
repository root, including the required `Progress`, `Surprises & Discoveries`,
`Decision Log`, and `Outcomes & Retrospective` sections.

## Purpose / Big Picture

After this work, ordinary use of Gym Assistant autocomplete and identity review can
produce private, structured evidence without requiring the learner to write a detailed
bug report. A deterministic evaluator can replay and summarize that evidence, update a
durable signal ledger without duplicating occurrences, and later support a read-only
scheduled review. The user can flag a surprising result with one icon or
Shift-Command-R and continue working.

The system will not automatically change exercise identity, product success criteria,
source code, or issue priority. Those remain foreground decisions. This separation lets
collection and checking scale while preventing an unattended process from turning a
weak signal into an unauthorized product change.

## Plan Status

In progress.

## Progress

- [x] (2026-09-21) Approved the field-signal, privacy, disposition, first-batch, and automation-authority contract.
- [x] (2026-09-21) Approved a small Report Issue icon with hover text that names Shift-Command-R.
- [x] (2026-09-21) Define typed event, candidate snapshot, interaction outcome, anomaly, ledger, and report interfaces in the reusable core.
- [x] (2026-09-21) Add owner-readable private event storage under Gym Assistant Application Support; retain the old operational log only for unrelated service diagnostics.
- [x] (2026-09-21) Add Report Issue to autocomplete and identity review without closing either panel or changing identity.
- [x] (2026-09-21) Add the deterministic evaluator, idempotent ledger update, bounded report command, and synthetic replay tests.
- [x] (2026-09-21) Extend the bounded report with approved session-derived
  identity-review metrics without adding raw fields or UI.
- [x] (2026-09-21) Prove collection and evaluation have no exercise-library dependency and preserve identical ledger state on replay.
- [ ] Install the app and manually verify a real record, a flagged record, and repeated quiet evaluation.
- [x] (2026-09-21) Install the app and manually verify real records, flagged records, owner-only permissions, and repeated quiet evaluation.
- [x] (2026-09-21) Present the Task B checkpoint and create the explicitly approved daily read-only scheduled review.
- [x] (2026-09-21) Trigger and inspect scheduled runs, correct report semantics, and accept Task B after real structured, visual, disposition, replay, and accepted-queue review.
- [ ] Collect resolver signals during the short Task C intake window, then freeze the accepted case IDs before implementation.

## Surprises & Discoveries

- Observation: The existing `WorkflowEventLog` writes loosely structured dictionaries to a temporary Exercise 09 file.
  Evidence: `Sources/GymAssistantNotesService/main.swift` logs result counts and actions but omits ordered candidates, evidence, scores, selected rank, linkability, and durable disposition.
- Observation: `DL` is not currently classified as hinge vocabulary even though `RDL` and `deadlift` are.
  Evidence: `ProtectedModifierPolicy.movementPattern` recognizes only `deadlift` and `rdl`; this remains a Task C baseline rather than a Task B fix.
- Observation: Mixed identity-review evidence does not define a total ordering.
  Evidence: lexical candidates compare by score only when both sides carry lexical evidence; mixed comparisons can fall back to display name. This remains a Task C baseline.
- Observation: Pretty-printed JSON cannot serve as one-record-per-line JSONL.
  Evidence: the first store round-trip test failed when embedded newlines were split as records; interaction encoding is now compact while ledger JSON remains human-readable.
- Observation: The first scheduled run could not invoke `swift run` because unattended sandboxing denied Swift and Clang cache access.
  Evidence: the automation preserved the failure in its generated run history without reading private events or changing the ledger. The evaluator is now packaged in the installed app so scheduled review does not require a compiler or package-manager write.
- Observation: A valid `allow` rule does not help when the scheduled agent chooses an ordinary sandboxed invocation and never requests outside-sandbox execution.
  Evidence: repeated post-rule runs launched the installed evaluator inside the sandbox and failed on the same permitted ledger write. The durable prompt now explicitly directs the agent to request elevated execution for the exact rule-matched command and forbids any other exception.
- Observation: The first successful scheduled report counted a highlighted row in a Report Issue snapshot as a committed selection and treated quiet replay as if no durable findings remained.
  Evidence: metadata contained one rank-1 insertion and one flagged rank-29 highlight, which incorrectly produced median rank 15 and 50% top-result acceptance. Five ledger entries remained `new` or `reproduced`. Selection metrics now include only Insert and Link outcomes, and every run reports unresolved ledger summaries independently of replay changes.
- Observation: The aggregate label `backCount` suggested that it measured every Back navigation control, but the event is emitted only by the identity-review transaction undo action.
  Evidence: the recorder emits `.backed` from the identity-review undo path. The report field is now named `identityReviewUndoCount`; the durable event value remains compatible with existing records.
- Observation: A category/count-only scheduled report could surface an inbox but could not support an informed human disposition.
  Evidence: the deployed prompt prohibited the query and candidate details needed to understand user-flag and ranking cases. The report now emits stable case IDs, dates, and bounded type-specific evidence, while continuing to exclude Notes, client, and surrounding-program context.
- Observation: Reusing evaluator arguments for disposition would place observation and human-controlled mutation behind the same executable rule.
  Evidence: disposition is instead owned by a no-argument `SetFieldFeedbackDisposition` executable with a separate exact rule, interactive confirmation, validated human-only states, and atomic history.
- Observation: Structured candidate evidence cannot reveal UI-specific problems such as clipping, expansion state, density, or misleading visible selection.
  Evidence: explicit Report Issue actions now save an owner-only PNG of the Gym Assistant window keyed by event ID. Passive interactions never capture images, and the capture excludes the Notes window and full screen.
- Observation: Exercise rank alone does not identify a selected alias within an expanded exercise row.
  Evidence: the real panel screenshot showed `DB bent over row` selected under rank-1 `Hinge DB Row`, while the first packet printed only rank 1. Review packets now print the captured selected or highlighted name as well as its exercise rank.
- Observation: An unstructured dump of every open case transfers evaluator complexity to the human reviewer.
  Evidence: the scheduled procedure now leads with a bounded AI assessment and presents a compact, ordered review batch with repeated disposition options. Recommendations remain advisory; only an explicit foreground confirmation authorizes the separate setter.
- Observation: Sequential one-case writes made a small review queue feel like a slow carousel and risked partial application.
  Evidence: the revised automation renders one inline interactive card deck. Previous/Next navigation and tentative choices remain local; one final control submits the queued proposal for human confirmation, after which the setter performs one atomic ledger save.
- Observation: Averaging scheduled report outputs would count unchanged replayed interactions repeatedly.
  Evidence: the evaluator instead compares the most recent ten interaction events with the preceding ten, exposes sample sizes, and labels sparse selection metrics for caution.
- Observation: Moving a signal to `acceptedForBatch` removed it from the open-review deck and made the next intervention depend on direct ledger inspection or chat memory.
  Evidence: the evaluator now emits a separate read-only Accepted batch queue with stable IDs and the same bounded interaction and screenshot evidence. The private JSON remains authoritative; the evaluator provides the schema-aware agent read model.

## Decision Log

- Decision: Enter Task C before freezing its intervention batch, using a short field-use intake window.
  Rationale: Additional real product use can improve the evidence base before implementation begins. The learner must explicitly freeze accepted resolver case IDs; signals accepted afterward belong to a later batch, and focus-recovery evidence remains routed to Task D.
  Date/Author: 2026-09-21 / Learner and Codex.

- Decision: Store raw field interactions and reports privately under the user's Gym Assistant Application Support directory, not in Git.
  Rationale: Queries, observations, and exercise names are necessary to reproduce ranking but may reveal personal programming vocabulary.
  Date/Author: 2026-09-21 / Learner and Codex.
- Decision: Exclude note titles, source lines, program text, client context, and credentials from field events.
  Rationale: Candidate reconstruction does not require broader private Notes content.
  Date/Author: 2026-09-21 / Learner and Codex.
- Decision: Use a small Report Issue icon in both candidate panels and mention Shift-Command-R only in its hover text.
  Rationale: Reporting should be one action and visually quiet; it must not compete with primary candidate actions.
  Date/Author: 2026-09-21 / Learner and Codex.
- Decision: Permit automatic `new` and `reproduced` signal bookkeeping but require foreground review for `accepted-for-batch`, `deferred`, and `resolved`.
  Rationale: Occurrence accounting is mechanical; priority, product meaning, and closure require judgment.
  Date/Author: 2026-09-21 / Learner and Codex.
- Decision: Test the evaluator manually and observe repeated idempotent behavior before creating a scheduled task.
  Rationale: Scheduling an unproven prompt or evaluator would automate confusion rather than a stable procedure.
  Date/Author: 2026-09-21 / Learner and Codex.
- Decision: Do not implement multi-user telemetry now.
  Rationale: The learner sees scaling potential, but the present success criterion is a private single-user loop. Typed records and stable case IDs preserve a future path without adding accounts, networking, consent, or server infrastructure.
  Date/Author: 2026-09-21 / Learner and Codex.
- Decision: Record the time from the last focus return until the interaction outcome, but do not yet classify short returns as failures.
  Rationale: The measurement can distinguish likely resumed work from possible window-cleanup behavior without recording destination applications. Duration alone remains ambiguous.
  Date/Author: 2026-09-21 / Learner and Codex.
- Decision: Run the verified evaluator daily at 09:00 local time as a standalone local-project scheduled task.
  Rationale: Local mode can reach the private Application Support records. The durable prompt permits only the private signal-ledger update and forbids source, Git, live-library, identity, success-criteria, and human-disposition changes.
  Date/Author: 2026-09-21 / Learner and Codex.
- Decision: Permit the installed evaluator outside the workspace sandbox through one trusted project-local command rule.
  Rationale: The first packaged-binary run proved that Application Support ledger writes are the remaining sandbox boundary. The rule matches the evaluator executable prefix only and grants no shell, SwiftPM, or Service-provider authority.
  Date/Author: 2026-09-21 / Learner and Codex.
- Decision: Derive identity-review session count, zero-decision sessions, decisions
  per session, skip share, and median time to first decision from existing private
  events grouped by session ID.
  Rationale: These aggregates can test whether defaulting into review remains useful
  and whether skipped additions deserve more visible access. They require no new raw
  fields, UI, exercise-library access, or inference about which future maintenance
  action the user wanted.
  Date/Author: 2026-09-21 / Learner and Codex.

## Outcomes & Retrospective

Task A established the approved contract. Task B implementation and evidence remain in
progress. Record the final event counts, detected anomalies, idempotent rerun evidence,
manual Report Issue result, remaining limitations, and schedule disposition here before
marking the plan complete.

## Context and Orientation

`Sources/GymAssistantCore/ExerciseAutocompleteSearch.swift` returns one
`ExerciseSearchMatch` per exercise identity with a matched durable name, aliases, match
kind, and score. `Sources/GymAssistantCore/ExerciseIdentityReview.swift` prepares
`ExerciseReviewCandidate` values with transformation, prescription, lexical, or conflict
evidence plus `linkAllowed`. `Sources/GymAssistantNotesService/main.swift` owns both
candidate panels and currently contains a temporary `WorkflowEventLog` that appends JSON
lines under the system temporary directory.

The live exercise library is SQLite under the user's Gym Assistant Application Support
directory. Raw feedback artifacts belong beside, but not inside, the exercise database.
The evaluator must receive immutable snapshots and has no `ExerciseLibrary` write
dependency. Synthetic tracked fixtures use invented exercise wording only. Real event
files, ledgers, and reports remain untracked.

A field interaction is one autocomplete or identity-review session. A candidate snapshot
records the exact ordered candidates shown at a decision point. A signal is a stable,
deduplicated anomaly or subjective report derived from one or more interactions. A ledger
is the durable collection of signals and their dispositions. A replay feeds a frozen
synthetic interaction to the evaluator and checks the expected signal without launching
AppKit.

## Plan of Work

First add explicit `Codable` domain types in GymAssistantCore for workflow kind,
candidate evidence, candidate snapshot, interaction outcome, focus evidence, field
interaction, subjective report state, anomaly kind, signal disposition, signal ledger,
and evaluation summary. Evidence scores are optional because categorical transformations
and conflicts do not own numeric scores. Use UUID event/session IDs and a deterministic
case key derived from anomaly kind plus a normalized non-private reproduction signature.

Add a private file store that creates a `Feedback` directory under Gym Assistant
Application Support, applies owner-only POSIX permissions where supported, appends JSONL
interactions safely, and atomically replaces ledger and summary JSON files. Parsing must
reject incompatible schema versions or malformed records without partially updating the
ledger. Empty input and repeated evaluation must be valid.

Replace direct loose logging at the two candidate controllers with snapshot construction.
Finalize one record at choice, raw-query insertion, Link, Create, Skip, Back, Cancel, or
close. Record the last candidate snapshot, duration, selection rank, alias expansion,
deactivation count and duration, and focus-return attempt/result. Avoid logging every
keystroke; preserve the decision-relevant final query or observation only.

Add a small borderless Report Issue icon to both panels. Its tooltip explains that it
saves the current candidates for later review and names Shift-Command-R. A local shortcut
monitor calls the same action. Reporting immediately appends a flagged snapshot, shows a
brief non-blocking acknowledgement, leaves the panel open, and performs no library write.

Implement a deterministic evaluator and executable report command. Detect numeric
score-order inversions within a scored tier, categorical exact transformations below
lexical candidates, known protected conflicts that are linkable, unstable replay order,
and aggregate interaction friction. Update `new` or `reproduced` occurrences
idempotently; preserve all human-controlled dispositions. Emit a compact machine-readable
summary and readable terminal report, suppressing unchanged findings in the latter.
For identity review, group existing events by session ID and report session count,
zero-decision sessions, decisions per session, skip share, and median time to first
decision. Do not add source text or a new event schema merely for these aggregates.

Add synthetic fixtures for the approved field examples without fixing them: a `DL`
observation with a squat candidate, exact `DB` expansion below lexical candidates, a
`.50` lexical candidate below `.45`, a clean ordered case, a subjective flag, and focus
deactivation. Tests must snapshot exercise/name/review-decision state before and after
collection and evaluation and prove equality.

Finally build and install Gym Assistant, generate one ordinary and one flagged real
interaction, run the report command twice, and inspect its private files and permissions.
Stop at the Task B checkpoint. Draft a recurring read-only scheduled task for review, but
do not create it until the learner has inspected the manual outputs and approved the
schedule boundary.

## Concrete Steps

Work from repository root on `tutorial/exercise-11`. Add feedback domain and storage code
under `Sources/GymAssistantCore/`, the report executable under `Sources/`, and synthetic
tests and fixtures under `Tests/`. Update `Package.swift` only for the new executable.
Use the existing AppKit target for both Report Issue controls.

Run:

    swift test
    swift run ResolverFixtureRunner Tests/Fixtures/resolver-cases.json
    swift run IdentityReviewFixtureRunner Tests/Fixtures/identity-review-cases.json
    swift run FieldFeedbackReport <private-event-path> <private-ledger-path> <private-summary-path>

The first three commands must retain their Exercise 10 results until Task C intentionally
changes ranking: 58 or more tests pass, resolver fixtures pass 37/37 with zero protected
leaks, and review-policy fixtures pass 6/6 with zero candidate-caused writes. The report
command must show new signals on its first run and zero new or changed signals on an
identical second run.

Use the repository's existing Notes Service build/install procedure only after automated
verification passes. Manual testing must start from Notes, exercise both panels, flag one
result with the icon or Shift-Command-R, close normally, and inspect the report without
copying private artifacts into the repository.

## Validation and Acceptance

Task B passes when a real autocomplete or review interaction produces a complete private
typed record; Report Issue produces a flagged record without closing the panel or changing
identity; the evaluator detects the relevant synthetic anomalies; the ledger deduplicates
identical reruns while advancing occurrence history only for genuinely new events; and a
second unchanged report is quiet. Synthetic tests must also prove that identity-review
session aggregates exclude autocomplete events and distinguish productive sessions from
sessions closed without a Link, Create, or Skip decision.

File inspection must show owner-only access where supported. Malformed and incompatible
records must fail with a useful message and leave the previous ledger intact. Tests must
prove zero exercise, exercise-name, or review-decision mutation. Existing resolver and
identity-review fixture suites must remain unchanged and green.

The checkpoint also requires a reviewable proposed schedule: cadence, prompt, project
mode, sandbox boundary, input/output paths, unchanged-state behavior, and stop/escalation
conditions. The schedule remains uncreated until explicit learner approval.

After enough real focus-return interactions accumulate, inspect the distribution of
`lastReturnToOutcomeMilliseconds` alongside outcome, workflow, and deactivation count.
Only then decide whether evidence supports a tested “possible cleanup-only return”
threshold. Do not infer such a threshold from one session or silently turn it into a
product success criterion.

## Idempotence and Recovery

Interaction events are append-only and uniquely identified. Reprocessing an event ID
does not increment a signal twice. Ledger and summary updates use write-to-temporary plus
atomic replacement so interruption preserves the last valid version. A corrupt event is
reported and skipped only if doing so cannot conceal a schema incompatibility; otherwise
the evaluator stops without updating durable outputs.

The evaluator never opens the exercise database for writing. Removing a generated report
is recoverable by rerunning evaluation from append-only events, while deleting raw events
or the ledger is outside normal workflow and requires explicit learner approval. If the
installed app fails, retain the previous application bundle or rebuild the last merged
learner state; do not restore or replace the live exercise database automatically.

## Artifacts and Notes

Tracked artifacts include typed feedback code, synthetic fixtures, tests, this plan, and
the reviewed automation prompt in `docs/operations/GYM_ASSISTANT_SIGNAL_REVIEW.md`, and
non-private aggregate evidence. Private artifacts include real interactions, queries,
observations, candidate names, flags, focus traces, the signal ledger, and reports. The
candidate diff must be searched for private paths, note/client text, credentials, live
database files, and raw feedback before each commit.

The design is informed by Ryan Lopopolo's *Harness engineering*: make application state,
logs, metrics, and constraints legible to agents, then encode repeated judgments as
tools and fixtures. It also follows OpenAI's scheduled-task guidance: test manually,
inspect early runs, use narrow permissions, isolate mutations, and let a durable inbox
surface findings. These references justify the operating sequence; repository tests and
field evidence remain the authority for this product.

## Interfaces and Dependencies

Use Foundation and existing GymAssistantCore dependencies only. Prefer explicit structs
and enums over `[String: Any]`. The core should expose a recorder/store protocol so tests
can use a temporary directory and AppKit can use Application Support. The evaluator takes
event values or a read-only event source and a ledger value; it must not depend on
`ExerciseLibrary` mutation APIs.

The report executable owns command-line paths and formatting. AppKit owns buttons,
tooltips, shortcut monitors, window lifecycle, and conversion from search/review values
into field snapshots. Scheduling is not an implementation dependency; it will invoke the
verified report command later.

Plan revision note (2026-09-21): Created after learner approval of Exercise 11 Task A,
including the icon-plus-tooltip Report Issue refinement and explicit interest in a
scalable scheduled agent-review pattern.

Plan revision note (2026-09-21): Added the learner-approved Task B contract amendment
for privacy-minimal, session-derived identity-review aggregates. The amendment reuses
existing events and does not authorize new UI, raw capture, product changes, or automatic
prioritization.
