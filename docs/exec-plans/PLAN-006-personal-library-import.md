# Import the reviewed personal exercise library safely

This ExecPlan is a living document. Maintain it in accordance with `PLANS.md` at the repository root, including the required `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` sections.

## Purpose / Big Picture

After this work, Gym Assistant will have ingested the learner's complete reviewed source into a durable, resumable observation queue, and autocomplete can search a useful explicitly reviewed subset rather than a four-exercise development seed. Ingestion will preserve occurrence provenance privately without requiring every identity question to be answered. Each identity write will still require explicit review, preview against a scratch database, and an independently transactional and idempotent decision.

## Plan Status

Complete.

## Progress

- [x] (2026-08-25) Confirmed the approved private source exists, has the exact six-column schema, and hashes to `950bd73f76a4db725d25975d77272e2542becc263a44a3831932e5cd0e0f4921`.
- [x] (2026-08-25) Confirmed the live Application Support library exists and currently contains 4 exercises and 5 names; no write was performed.
- [x] (2026-08-25) Learner approved the initial Task C plan and the explicit deferred-observation lifecycle.
- [x] (2026-08-26) Learner revised the architecture so complete observation ingestion is non-blocking and identity review is incremental, resumable, and dismissible.
- [x] (2026-08-26) Shared the ranked-candidate chooser presentation between autocomplete and observation review while keeping insertion and identity decisions in their separate workflow controllers.
- [x] (2026-08-26) Added and ran the private extractor-feedback exporter: all 158 Task A decisions mapped with zero gaps to the 1,210-observation/2,224-occurrence Task C corpus, and all 9 current skips are directly indexed with retained candidate evidence.
- [x] (2026-08-26) Implemented and tested the private-source adapter, consolidation, validation, durable ingestion, occurrence provenance, review queue, decision preview, and reporting.
- [x] (2026-08-26) Ingested the complete source through scratch validation and a transactional live write after backup and reconciliation.
- [x] (2026-08-26) Proved idempotent ingestion and review decisions, controlled rollback, durable provenance, and resumable pending and skipped observations.
- [x] (2026-08-26) Installed the verified build and exercised review-to-autocomplete behavior from Notes without Terminal.
- [x] (2026-08-27) Learner approved the Task C checkpoint and chose to continue into a bounded field-feedback exercise rather than repair every new finding immediately.

## Surprises & Discoveries

- Observation: The CSV has 2,312 physical lines but 1,891 logical observations because quoted source evidence contains embedded newlines.
  Evidence: `wc -l` reports 2,312 while the approved Task A audit reports 1,891 records. The adapter must parse RFC 4180-style quoted fields rather than split on newline.
- Observation: The live product database contains only four exercise identities and five names.
  Evidence: read-only SQLite counts returned `exercises|4` and `names|5` before Task C.
- Observation: Separate AppKit candidate tables drifted in alias disclosure, evidence display, selection behavior, and keyboard ownership even though both workflows consumed the same resolver.
  Evidence: live testing found review omitted the winning alias and autocomplete/review assigned conflicting meanings to Left and Right Arrow.
- Observation: As an accessory Service app, Gym Assistant disappears from Command-Tab when the user consults another app while a chooser is open.
  Evidence: live testing could leave both autocomplete and review open but provided no standard application-switcher route back to them.
- Observation: A synchronous Notes Service request prevents independent note-bound autocomplete windows.
  Evidence: switching to another note produced no insertion, a second invocation queued until the first assistant closed, and the queued assistant then appeared. Multiple assistants require an asynchronous insertion-context mechanism rather than additional windows around the existing Service call.
- Observation: Command-Tab can recover Gym Assistant, but macOS otherwise leaves the most recently viewed application behind its window rather than the invoking Notes context.
  Evidence: live testing returned from a browser to Gym Assistant with the browser still visible behind it, even though the original Notes insertion target remained safe.
- Observation: Notes rejects ordinary programmatic activation while its synchronous Service request is still open.
  Evidence: the workspace delivered both Notes and Gym Assistant activation events, but `NSRunningApplication.activate` returned false for Notes and neither an immediate nor delayed AppKit reorder placed Notes behind Gym Assistant.
- Observation: Leaving autocomplete open beyond the Service deadline produces a misleading unresponsive-Service error even though search remains fast.
  Evidence: event traces show otherwise responsive modal sessions lasting approximately 132 and 192 seconds against the declared 120-second autocomplete Service timeout.
- Observation: A timer scheduled only in the default run-loop mode does not enforce a deadline while the autocomplete panel is running AppKit's modal loop, especially after focus changes.
  Evidence: the first 105-second watchdog failed its manual field test. The revised timer is explicitly registered in both common and modal-panel run-loop modes.
- Observation: The approved feedback packet existed in the plan but not in the runner while Task C review was already accumulating decisions.
  Evidence: the live database retained the necessary outcomes and provenance, and the private Task A audit and initial candidate snapshot remained available, but no command joined them. The completed exporter now maps all 158 audit decisions with zero unmapped rows and indexes all 9 current skips.
- Observation: Visible non-linkable conflict evidence depends on recognizing protected vocabulary before ordinary lexical scoring.
  Evidence: the policy recognizes `deadlift` and `RDL` as hinge wording but not `DL`; field use therefore allowed a `DL` observation to surface squat candidates without the expected conflict treatment.
- Observation: Candidate ordering lacks a total comparison across evidence types.
  Evidence: transformation candidates carry categorical evidence without a numeric score, and mixed transformation/lexical comparisons may fall back to name ordering. Field use showed an exact `DB` to `Dumbbell` transformation too low and a `.50` lexical row below a `.45` row.
- Observation: Cross-application focus recovery is frequent enough to be product friction, but repairing each finding inside Task C would prevent a stable field-test batch.
  Evidence: the learner accepted the functional checkpoint while explicitly reporting repeated tab-away annoyance and chose to capture and batch further findings in Exercise 11.

## Decision Log

- Decision: Parse the private CSV only at runtime from a command-line path and never copy its rows, note titles, or source lines into the repository.
  Rationale: The generic adapter and synthetic tests are reusable; the learner's source remains private evidence.
  Date/Author: 2026-08-25 / Codex, proposed for learner approval.
- Decision: Consolidate source records by deterministic normalized observed wording before identity review while retaining every contributing private source reference and aggregate occurrence count.
  Rationale: Identity is reviewed once per distinct normalized observation, not once per note occurrence. Consolidation reduces repetitive review without creating aliases or losing provenance.
  Date/Author: 2026-08-25 / Codex, proposed for learner approval.
- Decision: Run review and batch simulation against a scratch copy of the live database; do not treat a proposed fuzzy or transformed candidate as an approved Link.
  Rationale: Sequential preview must account for the existing four identities and earlier decisions while remaining fully reversible. Human decisions—not ordering or a score—control every new alias relationship.
  Date/Author: 2026-08-25 / Codex, proposed for learner approval.
- Decision: Keep the private review manifest and batch audit outside Git, addressed by source hash and stable observation IDs.
  Rationale: Reruns and audits require durable private decisions, but the public learner artifacts need only counts, hashes, and non-private verification summaries.
  Date/Author: 2026-08-25 / Codex, proposed for learner approval.
- Decision: Separate complete source ingestion from incremental identity decisions.
  Rationale: Import and completed-program review both surface and store observations without blocking program writing. Ingestion must account for every source row and preserve occurrence provenance, while pending observations remain valid and invisible to autocomplete. Link and Create are separate human-authorized transactions rather than prerequisites for accepting the source.
  Date/Author: 2026-08-26 / Learner and Codex.
- Decision: Make review resumable and dismissible; pending observations do not block ingestion or require explicit Defer.
  Rationale: Defer remains a deliberate signal that the learner inspected an observation and postponed it. Pending means not yet reviewed. Both remain outside autocomplete identity, and reopening regenerates candidates from the current library without losing the source evidence or earlier position.
  Date/Author: 2026-08-26 / Learner and Codex.
- Decision: Record ingestion idempotency separately from identity-decision idempotency.
  Rationale: Repeating the same source fingerprint must not duplicate observations or provenance. Repeating an accepted Link, Create, or Defer must not duplicate or drift its effect, but unresolved observations must not prevent already-approved decisions from becoming useful.
  Date/Author: 2026-08-26 / Learner and Codex.
- Decision: Keep administrative ingestion in the command-line runner, but make routine observation review reachable from the existing keyboard-accessible Gym Assistant autocomplete panel through a visible Review Library action and local keyboard equivalent.
  Rationale: A command-line-only queue can verify mechanics but cannot test whether the product becomes better through routine library improvement. Reusing the existing Gym Assistant shortcut avoids another global shortcut. Review opens in a separate window so the Notes Service request can return; closing and reopening preserves progress. A full dashboard, menu-bar item, merge workflow, reminders, sorting system, and shortcut-settings UI remain outside Task C.
  Date/Author: 2026-08-26 / Learner and Codex.
- Decision: Share the ranked-candidate chooser view, alias expansion, and selection behavior, but retain separate autocomplete and review workflow controllers.
  Rationale: Both workflows present one identity-deduplicated row per exercise and score every durable name, while only autocomplete inserts text and only review can persist Link/Create/Skip. The shared collapsed row now displays the winning durable name; expansion shows the exercise's other names without displaying every non-winning score. Left and Right Arrow belong to name disclosure, while review uses Command-Z for one-step Back and Command-S for Skip.
  Date/Author: 2026-08-26 / Learner and Codex.
- Decision: Keep autocomplete fully read-only and do not expose the internal preferred/default-name designation.
  Rationale: Once the collapsed row became the query's highest-scoring durable name, neither a default-alias marker nor Command-Return mutation improved the primary insertion workflow. Every visible name is a simple insertion choice. The database retains its preferred-name constraint as a stable fallback and orphan-prevention invariant; changing it is deferred to a future library-maintenance workflow if field evidence demonstrates a need.
  Date/Author: 2026-08-26 / Learner and Codex, superseding the Make Preferred & Insert experiment.
- Decision: Keep Gym Assistant as an accessory application rather than temporarily promoting it into the Dock and Command-Tab switcher.
  Rationale: Field testing showed that temporary regular-app activation caused a distracting Dock bounce but did not let ordinary AppKit restore blocked Notes behind an open synchronous Service panel. The rejected experiment offered no reliable recovery benefit. Cross-application recovery requires an asynchronous insertion adapter or explicit Accessibility control rather than more window ordering.
  Date/Author: 2026-08-26 / Learner and Codex, superseding the temporary activation experiment after field evidence.
- Decision: Do not preselect an autocomplete result.
  Rationale: Return must preserve and insert the user's query unless the user deliberately moves into the candidate list. Down Arrow selects the top result as the first candidate-navigation action. Observation review may retain top-candidate preselection because Link remains separately explicit.
  Date/Author: 2026-08-26 / Learner and Codex.
- Decision: Display each exercise identity's highest-scoring durable name in its collapsed chooser row.
  Rationale: A preferred-name parent plus a separately labeled best-matching alias made several visible rows appear to claim “Best match” and added navigation before inserting the most relevant wording. The collapsed row now inserts the winning name directly and uses a compact reason, score, and alias count. Expansion shows every other durable name without exposing the internal default, repeating a confirmed-alias label, or displaying every non-winning query score. Identity deduplication, scoring, and review linking remain unchanged.
  Date/Author: 2026-08-26 / Learner and Codex.
- Decision: Auto-cancel autocomplete at 105 seconds while the synchronous Service boundary remains.
  Rationale: The declared Service timeout is 120 seconds. Returning before that deadline prevents abandoned panels from surfacing as unresponsive Services without lengthening the period during which Notes is blocked. Normal quick interactions are unaffected.
  Date/Author: 2026-08-26 / Learner and Codex.

## Outcomes & Retrospective

Task C completed the non-blocking personal-library ingestion and review-to-search
vertical slice. The source fingerprint and reconciled counts account for 1,891 source
records, 1,210 consolidated observations, and 2,224 occurrences. The private feedback
packet maps all 158 extraction decisions with zero gaps and indexes all 9 skipped
observations. At the checkpoint the live queue contained 43 created identities, 39
linked observations, 9 skips, and 1,119 pending observations; unresolved work remains
valid and absent from autocomplete.

The learner verified that review decisions persist, review resumes, Escape returns to
Notes, and newly resolved identities become available to autocomplete. Fifty-eight tests,
all 37 resolver fixtures, and all six review-policy fixtures passed with zero
candidate-caused identity writes. Product use also exposed ranking and focus limitations.
Rather than broadening Task C, the learner chose a fixed next exercise that automatically
collects and evaluates signals, preserves subjective friction with low effort, improves
one approved resolver batch, and prepares the larger focus-recovery spike.

## Context and Orientation

Task A produced a private six-column CSV whose logical records contain observed wording, source note, verbatim source line, occurrence count, extraction status, and extraction note. All extraction statuses are approved plausible observations. Task B added `ExerciseIdentityReviewService`, which distinguishes exact confirmed identity reuse from reviewable candidate evidence and persists explicit Link, Create, and Defer outcomes. `ExerciseLibrary` owns the SQLite database used by the Notes Service. `ExerciseAutocompleteSearch` reads preferred and confirmed names from that same database without writing identity.

An import adapter translates private CSV records into staged observations; it does not decide identity. An ingestion record identifies the source fingerprint and provenance. Occurrence/evidence records preserve the possibly many source notes and lines that contributed to a consolidated observation. A private review manifest records only explicit decisions keyed by stable observation ID. A dry-run applies a selected set of decisions only to a scratch database and reports what those live transactions would do. Ingestion and decision receipts are distinct so each lifecycle can be retried independently.

## Plan of Work

First, add a reusable CSV adapter and synthetic multiline fixtures. It will validate the exact schema, positive occurrence counts, approved extraction status, nonblank observed wording and provenance, and deterministic consolidation. Invalid input will fail before staging anything and identify the private row number without echoing private source text.

Next, add ingestion and decision-planning types plus a private command-line runner. It will copy the live database to a scratch location, ingest every consolidated observation and its occurrence provenance, reuse already-confirmed exact names without a write, and prepare every unresolved observation for a resumable queue. The command-line runner owns initial ingestion, backup, dry-run, and diagnostics. The same persisted queue is presented for routine use through a separate Gym Assistant review window, reached from a visible Review Library action and local keyboard equivalent in the existing autocomplete panel. It will show one observation at a time with aggregate occurrence count, bounded source evidence, preferred-name candidates, aliases, structured evidence, and Link/Create/Defer controls. It will support close and resume without requiring a disposition and will never offer Keep Separate because that belongs to a two-existing-identity library audit.

The review interface will preserve every decision privately and be safely resumable. Create will accept no edited name. Link will require selecting a linkable existing identity. Defer will create no exercise or name and will be distinguishable from an untouched pending observation. As decisions accumulate, later candidate searches will run against the scratch library state so newly confirmed names can resolve repeated wording, but no inferred relationship will be approved automatically.

Then add an ingestion API that validates the complete source, persists its ingestion record, observations, and occurrence provenance in one transaction, and returns pending, exact-reuse, invalid, duplicate, and failure counts. Add a separate decision API that previews and applies any explicitly approved Link/Create/Defer subset, uses the existing confirmed-name provenance, and reports its effects. Deliberately failing synthetic ingestion and decision transactions will prove rollback; immediate reruns will prove zero duplicate observations, evidence rows, exercises, or names.

Before the live write, produce a complete ingestion reconciliation and a dry-run summary for the useful reviewed subset, including samples of every decision type, for learner approval. After approval, create a timestamped backup beside the live database, verify its hash, ingest the source, apply the approved subset, query destination counts and provenance, rerun both lifecycles, and retain the private manifest, receipt reports, and backup outside Git.

Finally, rebuild and install the verified Gym Assistant Service. From an empty Notes cursor, invoke the existing autocomplete shortcut, open Review Library by keyboard, resolve at least one observation, close and reopen review to prove resumption, and return focus to Notes. Invoke autocomplete again, find the newly resolved preferred name or alias, insert it, and confirm focus returns to programming. Stop at the Task C checkpoint before merging the exercise branch or advancing beyond the field-test pause gate.

## Concrete Steps

Work from the repository root on `tutorial/exercise-10`. Add generic implementation under `Sources/GymAssistantCore/` and a dedicated executable under `Sources/PersonalLibraryImport/`; add only synthetic fixtures and tests under `Tests/`. The runner accepts source CSV, destination database, and private artifact directory arguments, with distinct preview/apply operations for ingestion and identity decisions. Ingestion apply requires an exact validated source fingerprint but no completed review manifest. Decision apply must refuse any decision whose source fingerprint, observation ID, or current destination state does not match its preview.

The runner must preserve a private machine-readable extractor-feedback packet keyed by source fingerprint and stable observation ID. It links Task A extraction-boundary decisions and evidence to Task C review status, candidate snapshot, and any Link/Create/Defer outcome. This packet is evidence for the future extractor exercise, not training truth: exact reuse, Link, and Create are useful positive signals that the wording was actionable, while Defer must be reviewed qualitatively to distinguish identity uncertainty, unsuitable naming, insufficient source context, and a possible extraction-boundary error.

Run `swift test`, the 37-case resolver exam, the six-case human-review report, and synthetic import dry-run/apply/rerun/rollback tests. Run the real source initially with `--dry-run` against a scratch copy only. Expected pre-approval behavior is a complete accounting report and resumable private review artifact, with the live database hash unchanged.

## Validation and Acceptance

Every logical source record must be either consolidated into a staged observation or reported as invalid; totals must reconcile with the approved 1,891-record, 2,224-occurrence Task A evidence. Ingestion must preserve every contributing occurrence reference rather than flatten provenance to one adapter/reference pair. The decision dry-run must report the reviewed subset, existing exact matches, each explicit Link/Create/Defer decision, collisions, failures, and projected destination counts; untouched pending observations are valid and separately counted.

Candidate preparation and dry-run generation must leave the live database hash and counts unchanged. Complete ingestion must commit transactionally, and each approved identity decision must commit atomically with the existing confirmed-name provenance. Controlled failures must independently roll back ingestion and identity writes. Immediate identical reruns must create zero duplicate ingestion, observation, occurrence, exercise, or name rows and return the corresponding receipts. Pending and deferred observations must remain resumable, reportable, and absent from autocomplete identity.

The private extractor-feedback packet must reconcile Task A extraction decisions with the ingested observation IDs and Task C review outcomes without changing either kind of judgment. At least the deferred subset must be queryable for later reason review. No private wording, note title, source line, or client information may enter tracked fixtures merely to make the future extractor reproducible.

The final Notes test must demonstrate the complete improvement loop without Terminal: invoke autocomplete from an empty cursor; enter Review Library through its visible keyboard action; resolve an observation; close and reopen review without losing queue progress; return to Notes; find the newly resolved identity through autocomplete; deliberately choose a preferred name or alias; insert it; and return focus to Notes. The learner decides whether this review-to-improved-search loop is easy and useful enough for a field-test pause.

The tracked diff must contain no private CSV rows, source-note titles, source lines, client information, private manifest, live database, backup, or review screenshots containing private Notes content.

## Idempotence and Recovery

Dry-run operates on disposable scratch copies. Before live ingestion or identity writes, make a timestamped byte-for-byte database backup and record both hashes. If ingestion fails, its transaction rolls back and no ingestion receipt is stored. If an identity decision fails, that decision rolls back without reversing successful ingestion or other accepted decisions. If post-commit verification fails, stop and retain both live and backup databases; do not automatically overwrite the live file. Restoring the backup is a separate destructive action requiring explicit learner approval. Repeating an identical source fingerprint or accepted decision is read-only and reports its prior receipt.

## Artifacts and Notes

Tracked artifacts contain generic code, synthetic fixtures, tests, architectural documentation, and non-private count/hash evidence. Private artifacts contain the raw source, Task A extraction audit, consolidated evidence, review manifest, extractor-feedback packet, complete decision audit, dry-run report, ingestion and decision receipt reports, live backup, and any screenshots showing personal exercise wording.

## Interfaces and Dependencies

Use Foundation, the existing SQLite3 dependency, CryptoKit for deterministic SHA-256 identifiers and receipts, and the existing AppKit Service target. The core should expose explicit ingestion, source-row, consolidated-observation, occurrence-evidence, review-decision, and report types. CSV parsing and private file paths remain in the import adapter. Ingestion persistence belongs at the observation-store boundary; identity decisions belong at the exercise-library boundary because each must atomically coordinate the observation status with any exercise/name write. The Notes Service adds only the Review Library entry action and separate review window needed for the approved closed-loop product test; it must not absorb ingestion parsing, resolver policy, or persistence rules.

Plan revision note (2026-08-25): Initial Task C proposal created after read-only verification of the approved private source and the four-exercise live destination.

Plan revision note (2026-08-25): Marked the plan in progress after learner approval and added the approved durable, reversible deferred-observation lifecycle.

Plan revision note (2026-08-26): Separated complete, idempotent observation ingestion from incremental identity decisions; made pending review non-blocking and resumable; added occurrence-level provenance and a private Task A/Task C feedback packet for the future completed-program extractor exercise.

Plan revision note (2026-08-26): Initially limited review invocation to a command-line-launched local artifact, then superseded that choice after the learner identified that it could not support a true product test of iterative library improvement. Administrative ingestion remains command-line driven, while routine review is now reached from the existing Gym Assistant autocomplete panel and opens in a separate resumable window.

Plan revision note (2026-08-26): Extracted a shared ranked-candidate chooser after live testing exposed presentation and keyboard drift between autocomplete and observation review. Workflow-specific query, provenance, insertion, and identity-decision controls remain outside the chooser.

Plan revision note (2026-08-26): A short-lived Make Preferred & Insert experiment was later removed after the chooser began displaying the query's winning durable name directly. Autocomplete is fully read-only and does not expose the internal preferred-name designation.

Plan revision note (2026-08-26): Field testing rejected temporary regular-app activation: it caused a Dock bounce and did not provide a reliable path back to Notes. Gym Assistant remains an accessory app. Cross-application recovery is now an explicit asynchronous-adapter or Accessibility boundary.

Plan revision note (2026-08-26): Live cross-note testing confirmed that the synchronous Service safely avoids redirecting insertion but serializes invocations. Recorded multi-window note-bound autocomplete as a separate asynchronous insertion-context spike and removed autocomplete's default candidate selection.

Plan revision note (2026-08-26): Two AppKit attempts to coordinate an open chooser with Notes failed in field testing; diagnostics showed that Notes rejected activation while servicing the synchronous request, and raising the chooser on Notes activation did not restore a usable window pair. Removed both failed strategies rather than retaining unverified focus code.

Plan revision note (2026-08-26): Changed collapsed chooser rows from preferred names to each identity's highest-scoring durable name; expanded alternatives no longer expose the internal default. Added a 105-second local cancellation deadline after traces tied two unresponsive-Service alerts to sessions exceeding the 120-second synchronous Service timeout.

Plan revision note (2026-08-26): Closed the missing private feedback-packet requirement. The generic runner now exports an owner-readable, regenerable Task A/Task C join with reconciliation counts, observation outcomes, occurrence provenance, initial candidates, audit-row mappings, unmapped-row reporting, and a direct skipped-observation index. The first real packet mapped 158/158 Task A decisions, reconciled 1,210 observations and 2,224 occurrences, and indexed 9/9 current skips with evidence.

Plan revision note (2026-08-27): Marked Task C complete after the learner passed the product checkpoint. Preserved repeated tab-away friction, unrecognized `DL` conflict vocabulary, categorical transformation evidence, and unstable mixed-evidence ordering as field signals for Exercise 11 rather than extending this plan indefinitely.
