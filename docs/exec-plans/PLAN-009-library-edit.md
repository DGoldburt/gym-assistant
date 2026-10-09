# Edit library identities and add exercises through peer maintenance views

This ExecPlan is a living document maintained according to `PLANS.md`. Keep
Progress, Surprises & Discoveries, Decision Log, and Outcomes & Retrospective
current. ADR 003 (`docs/decisions/003-library-edit.md`) contains the accepted
architecture; this plan contains the implementation and evidence path.

## Purpose / Big Picture

From autocomplete, a coach can open Edit Library to repair duplicate identities
or split an incorrectly confirmed alias, or open Add Exercises to create a missing
exercise. Add Exercises offers Import, whose child Review candidates uses the
existing observation queue. Import shows a badge of candidates awaiting review.
Both peer views use the established review-window handoff, so the standalone window
can stay open after the Notes Service returns. A coach can verify the result by
closing it, invoking autocomplete again, and selecting the corrected wording.

## Plan Status

In progress: initial implementation and the user's subsequent UI tightening are
verified locally on 2026-10-06. Release/integration
remains pending. This follows approval of peer entry routes, short confirmations, automatic
split defaults, transfer-plus-redirect storage, migration, CSV-only import, the
Import badge, and child Review candidates. The user authorized implementation on
2026-10-06. Future adapter direction and PLAN-008 revisions do not activate those
workstreams. The original work is retained in the attached feature/library-edit
worktree. On 2026-10-08 the user separately authorized preparing and publishing a
product-only integration PR from current learner/main; merge, installation, and
live-database trials remain gated.
The user separately approved a temporary foreground trial with synthetic data and
disposable Notes content; its evidence is recorded below.

## Progress

- [x] (2026-10-08) Implement Merge target search as a smaller attached sheet under Edit Library with separate controls and retained parent state.
- [x] (2026-10-08) Refresh the isolated bundle and verify attached-sheet search, nested alias confirmation cancellation, Escape returning to the parent with query/selected alias/expanded group intact. Automated verification passes with 102 tests. No foreground edit was committed for this sheet revision; post-commit parent refresh remains a human UI check.

- [x] (2026-10-08) Remove the Edit Search Command-L affordance and shortcut at the user's request. Keep search input, Command-A replacement, and arrow navigation; Review's separate Link Command-L action is unchanged.

- [x] (2026-10-08) Allow independently expanded groups; restrict Promote to explicit alias children and shorten its prompt. Implement approved row-sensitive Merge: an alias moves only its name, while a parent combines identities. Add preservation, default-repair, replay, stale, invalid-input, and row-policy regressions.
- [x] (2026-10-08) All five verification stages pass with 102 tests; refresh the isolated bundle. Native trial confirms both groups remain expanded, parent promotion disabled, child promotion prompt/cancellation, and child Merge entering Move alias with a destination-names confirmation. No trial move was committed; durable transfer is covered by automated regressions including replay/reopen and injected rollback.

- [x] (2026-10-08) Replace both split prompts with “Make ‘X’ separate from ‘Y’?” and keep default repair internal. Exact prompt regressions pass for ordinary/default splits; all five verification stages pass with 98 tests. Refresh the isolated bundle; no new foreground split trial was run for this text-only revision.

- [x] (2026-10-06) Inspect the corrected implementation base, library constraints, search grouping, import adapter, Service lifecycle, and tests.
- [x] (2026-10-06) Record the user's library-edit name, standalone handoff, and split confirmation/default decisions.
- [x] (2026-10-06) Draft ADR 003, this plan, and the separate legacy cleanup plan for review.
- [x] (2026-10-06) Obtain approval of the ADR and plan; reconcile peer navigation, Import badge, and Review as an Import child.
- [x] (2026-10-06 20:57Z) Implement and verify lifecycle migration, pre-open backup, and old-ID resolution on synthetic databases, including v1–3 upgrades, invalid source data, preserved legacy pairs/occurrences, failed backup, and rollback.
- [x] (2026-10-06 20:57Z) Implement and verify merge/split previews, transactional writes, append-only receipts, operation replay, stale confirmation, and guarded Back.
- [x] (2026-10-06 20:57Z) Implement peer Edit Library/Add Exercises views, CSV preview/ingestion, pending badge, and embedded child Review candidates with To review/Skipped. Automated navigation/import evidence passes; foreground usability remains below.
- [x] (2026-10-06 20:57Z) Run all five stages of ./scripts/verify: 95 tests in 13 suites, 37/37 resolver cases, 8/8 identity-review cases, cleanup regression, and non-installing bundle smoke check.
- [x] (2026-10-06) Obtain temporary foreground-trial approval and run keyboard/Notes acceptance using a distinct temporary bundle, synthetic SQLite database, and disposable Notes note. Fix two local keyboard gaps, rebuild, and repeat the affected paths. No live-library upgrade or replacement of the installed app was performed.
- [x] (2026-10-06 21:56Z) Rerun all five verification stages after the foreground fixes; all pass. Inspect synthetic edit receipts and foreign keys; one merge and two splits persisted, with no foreign-key violations.
- [x] (2026-10-06 20:57Z) Review the implementation diff, address stale displayed-detail confirmation and existing exact-alias Back deletion, and keep production timeout values unchanged.
- [x] (2026-10-08) User authorized a product-only PR into learner/main, excluding learner records, with a stop before merge. Prepare codex/library-edit-integration from current learner/main, retaining newer Exercise 14 history.
- [x] (2026-10-08) Verify the product-only integration candidate on current learner/main: all five verification stages pass, including 102 tests, resolver/identity fixtures, cleanup regression, and non-installing bundle smoke checks. Implementation files match the frozen Lab 07 review target.
- [ ] Publish the product-only PR; keep merge and installation gated. Remaining foreground UI checks are recorded separately from automated review.
- [x] (2026-10-06) Review the earlier Back/Undo decision; PLAN-007 already identifies this action as transaction undo, not navigation. Rename it Undo without changing its one-decision scope or safety guards.
- [x] (2026-10-06) Remove Add/Edit cross-navigation, replace the Edit dropdown/detail box with persistent ranked search, and collapse review evidence behind keyboard-accessible Details.
- [x] (2026-10-06) Retest revised search focus/replacement, arrow-key alias selection, split cancellation, duplicate comparison, Details, Undo, and parent navigation in the isolated foreground bundle. The earlier foreground evidence describes the superseded layout.
- [x] (2026-10-06) Final verification after UI refinements: all five stages pass, including 95 tests in 13 suites, 37 resolver cases, and eight identity-review cases. Refresh the isolated bundle; leave release and human visual acceptance pending.
- [x] (2026-10-08) Scope status messages to the current action; rename Find Duplicate to Merge with duplicate, prefill selected wording, and retain already-visible alternatives until query editing. Add a read-only merge-search regression test.
- [x] (2026-10-08) Synthetic foreground checks: merge prefill and retained alternatives, directed confirmation, success-message clearing on continued navigation, and fresh Notes Service insertion at the original middle-of-line caret after closing Edit. Command-L callback itself remains unimplemented; fresh invocation is not resurrection of a completed Service.
- [x] (2026-10-08) Final verification passes all five stages: 96 tests in 13 suites, 37 resolver cases, eight identity-review cases, cleanup regression, and bundle smoke check. git diff --check passes; refresh only the isolated bundle.
- [x] (2026-10-08) Implement approved automatic retention of the exercise being edited; remove the comparison screen and two direction buttons. Duplicate selection opens one confirmation showing both name groups.
- [x] (2026-10-08) Foreground Cancel preserves query/selection and receipt count; Combine adds one receipt, keeps the starting ID/default, and preserves names. Notes remains unchanged. Full verification passes all five stages with 97 tests in 13 suites; the isolated bundle is refreshed.
- [x] (2026-10-08) Enable Edit entry with no selected identity, remove the extra Combine sentence, and promote the standalone maintenance app to regular activation while open, restoring its prior policy on close. Package the existing branding icon; smoke checks require the resource and icon plist entry.
- [x] (2026-10-08) All five verification stages pass with 98 tests in 13 suites. The isolated foreground trial opens empty Edit, returns by keyboard app switching and accepts search input, and shows the shorter confirmation. Notes remains unchanged. Direct Dock accessibility/tile inspection was unavailable; do not claim visual Dock-icon acceptance.

## Surprises & Discoveries

Observation: exact equality against an in-memory creation timestamp intermittently
fails after SQLite conversion. Preservation tests compare persisted before/after
records instead, checking unchanged stored metadata rather than conversion precision.

The original worktree was based on reusable `main` with documentation only. It is
now attached to `feature/library-edit` on the learner implementation. Recheck its
actual HEAD and dirty files before implementation; do not assume an earlier hash
is still current.

Preferred names are hidden as a user-facing designation but remain meaningful to
exact selected-text replacement, ranking ties, and the active-record ownership
constraint. Splitting them therefore needs deterministic internal repair.

The existing review window is shown after the autocomplete Service returns.
Its recoverability is useful field evidence but does not prove that adding a
window inside an outstanding Service request fixes autocomplete focus.

The local SQLite build does not rewrite foreign-key references when renaming
tables with enforcement off. The rebuild now declares final table names
explicitly; the first implementation failed with `no such table: main.exercise_v4`,
and synthetic migration/normal persistence tests pass after correction.

Date values returned before storage can have greater precision than SQLite REAL
round-trips. The new preservation test compares the persisted pre-edit baseline,
not the pre-storage Date; name creation timestamps are unchanged by edits.

Existing observation Back could delete an established alias when Create reused an
exact name. Undo now records the specific name actually created by the decision,
if any, and never deletes a reused name. A dedicated regression proves this.

The foreground CSV picker returned focus to the window rather than a useful
control, and Tab did not reach the review queue's segmented control under the
current macOS keyboard settings. The first affected trials stopped. Import now
focuses its explicit apply button and supports Command-I; To review and Skipped
have local Command-1/Command-2 shortcuts. Rebuilt trial runs passed without
changing system settings. This is maintenance navigation, not PLAN-008's modal
focus experiment. Native screenshots were unavailable through the trial's UI
automation, so accessibility-state checks do not constitute visual layout review.

## Decision Log

Decision: integrate through a product-only PR based on current learner/main, not
reusable main. Exclude learner reflection/skill files and reusable curriculum
changes; preserve those in their original worktree for separate handling. Retain
the newer Exercise 14 history by starting from learner/main rather than copying
older learner records. Stop before merge, installation or live database migration.
Rationale: separate reusable teaching material, personal learning evidence and
the running product. Date/Author: 2026-10-08 / User approval and Codex.

Decision: show Merge target search as an attached 560-by-380 sheet beneath the
640-by-500 primary Edit window, using separate search and chooser controls.
Cancel/Escape restores the existing parent query, selection and expansions;
confirmation remains subordinate, and a successful edit dismisses the sheet and
refreshes the parent. Rationale: Merge is a subtask, not a peer editor. Alias/parent
operation scope and persistence are unchanged. Date/Author: 2026-10-08 / User.

Decision: remove Edit's Search Command-L label and local key handler, not the
search field or Review's Link shortcut. Rationale: the user finds the search-focus
affordance redundant and ineffective; selector callbacks remain out of scope.
Date/Author: 2026-10-08 / User.

Decision: supersede the parent-naming split prompt with “Promote ‘X’ to its own
exercise?” and enable it only on alias children. Allow multiple expanded groups.
Merge on an alias child moves just that name to the selected exercise; Merge on
a parent retains the existing whole-exercise behavior. Preserve both active IDs
and other names for an alias move, repairing only the source's hidden default if
needed. Reject an only-name move. Use a typed `moveName` preview/receipt, indexed
under the existing schema-v4 merge action family, without a schema upgrade.
Rationale: row selection defines the operation's scope and avoids accidental
whole-parent merges. Date/Author: 2026-10-08 / User approval and Codex.

Decision: use only “Make ‘X’ separate from ‘Y’?” for split confirmation, without
describing internal default-name repair. Rationale: the user needs to confirm
separate identity, not manage a hidden designation. The automatic repair rule and
exact-preview validation remain unchanged. Date/Author: 2026-10-08 / User.

Decision: call the feature Library Edit and exclude Keep Separate.
Rationale: direct repair does not need a durable negative-pair disposition or
another queue. Date/Author: 2026-10-06 / Learner.

Decision: Edit Library and Add Exercises are peer routes from autocomplete, with
no cross-navigation after the user's later UI revision. Add Exercises starts with creation from scratch;
Import is a suboption and Review candidates is a child of Import. The Import badge
counts unresolved To review candidates across all sources, excluding Skipped.
Rationale: maintenance distinguishes direct creation from source processing and
review without making Edit a parent.
Date/Author: 2026-10-06 / Learner.

Decision: split any name when another remains; automatically make the moved name
preferred on the new exercise and deterministically repair the source default.
Rationale: expose one meaningful decision rather than an internal designation
step. Date/Author: 2026-10-06 / Learner.

Decision: use the current Service-return handoff and keep focus/timeout experiments
in PLAN-008. Rationale: match the existing review lifecycle chosen by the user.
Date/Author: 2026-10-06 / Learner.

Decision: move names on merge and retain the former ID as a redirect.
Rationale: preserve IDs while keeping active ownership and alias splits uniform.
Date/Author: 2026-10-06 / Learner approval of Codex proposal.

Decision: use only existing-format CSV import in this slice.
Rationale: reuse validated ingestion with a native file picker rather than adding
new extraction/source systems. Date/Author: 2026-10-06 / Learner approval of Codex proposal.

Decision: retain asynchronous video/image/feed adapters as future work; video
segments belong to alias IDs after confirmation. Rationale: source processing
feeds one human review queue but needs design beyond CSV.
Date/Author: 2026-10-06 / Learner.

Decision: use LibraryEditPreview with a typed merge/split action, common before
state, and fingerprint, rather than duplicating common fields in enum cases.
Rationale: retain explicit domain types and exact preview validation with one
versioned receipt format. Date/Author: 2026-10-06 / Codex implementation.

Decision: duplicate CSV imports retain the original ingestion reference even
when selected under a different filename or previously imported by CLI.
Rationale: content identity is the existing source hash; relabeling must not
create conflicts or rewrite provenance. Date/Author: 2026-10-06 / Codex.

Decision: expose an explicit absolute GYM_ASSISTANT_DATABASE_PATH environment
override for future approved foreground trials and disable private field-feedback
appends under that override. Rationale: test synthetic data without touching the
user's default library or private feedback ledger. Date/Author: 2026-10-06 / Codex.

Decision: give maintenance actions explicit keyboard equivalents and restore
focus after CSV preview. Rationale: foreground trials exposed navigation gaps
with the user's existing macOS settings. Split uses Command-S, merge direction
uses Command-1/Command-2, CSV apply uses Command-I, and review queue views use
Command-1/Command-2 in their own route. Production timeout values are unchanged.
Date/Author: 2026-10-06 / Codex implementation within approved keyboard acceptance.

Decision: remove cross-navigation and keep Edit searchable, selecting names in
the existing ranked chooser instead of a dropdown. Collapse import-review source
details behind Command-D and label the last-decision reversal Undo. Rationale:
the user found the original screens mouse-heavy and information-dense. PLAN-007
already explicitly distinguishes transaction undo from navigation Back; its
guarded, session-local semantics remain unchanged. Preserve blocked-link warnings
in the collapsed review list. Date/Author: 2026-10-06 / User request and Codex implementation.

Decision: clear maintenance status on query editing, a new selection, or navigation;
call the action Merge with duplicate and prefill the selected name while retaining
other already-visible identities in their existing order. Editing the prefilled
query resumes fresh search; successful edits discard retained results so merged
IDs cannot remain selectable. Rationale: avoid sticky success instructions and
unnecessary re-search of duplicates already on screen. Date/Author: 2026-10-08 /
User request and Codex implementation.

Decision: automatically retain the exercise the user started editing and combine
the chosen duplicate into it. Replace the separate comparison screen and two
direction buttons with one compact confirmation: “Combine these exercises?”, both
name groups, and “All names remain available.” Cancel stays in the same search
context. Rationale: the user should not manage technical identity direction or
survivor terminology. The retained default can affect selected-text Review
Selection and ranking ties, so the UI follows a predictable rule rather than
claiming direction has no effect. Date/Author: 2026-10-08 / User approval.

Decision: investigate the requested Command-L selector callback without changing
the standalone Service-return lifecycle or adding an insertion permission boundary.
Rationale: the original Service has already returned before Edit opens. A fresh
Notes-side invocation retains cursor insertion; simply reopening a panel cannot
return another response to the completed call. Automatic re-invocation/context
capture remains a separate PLAN-008 decision. Date/Author: 2026-10-08 / Codex.

Decision: use regular application activation only while the standalone library
window is open, with the existing app branding icon, and restore the previous
activation mode when it closes. Dock reopen raises the retained window rather
than creating another session. Rationale: the user requested Dock/app-switch
recovery for maintenance. The Service has already returned; this does not reopen
PLAN-008's outstanding-Service focus or insertion experiments. Enable Edit without
a selection so search is reachable independently. Remove the extra Combine
explanation, retaining the prompt and both name groups. Date/Author: 2026-10-08 /
User request and Codex implementation.

## Outcomes & Retrospective

Merge target search is now a subordinate sheet rather than replacing the primary
Edit screen. Native trial confirms sheet hierarchy, keyboard search/selection,
nested confirmation cancellation, and parent-state preservation on Escape. The
trial did not commit an edit for this UI-only revision; post-commit refresh is not
claimed as foreground evidence. Persistence behavior is unchanged and covered by
automated tests. Installed app and live library are untouched.

The subsequent Search Command-L removal passes all five verification stages with
102 tests. The isolated trial bundle is refreshed; no foreground shortcut check
was performed for this removal. Review Link, insertion, and production are unchanged.

The current row-sensitive revision adds single-alias transfer and independent
expansion without a new window or preferred-name choice. All five stages pass
with 102 tests. Native checks cover row gating, promotion cancellation, and the
single-alias move route/confirmation and simultaneous expansion of two groups.
Transfer commits are tested automatically, not claimed as foreground trials. Installed app/live data
remain untouched. Earlier foreground evidence below predates this revision.

Core persistence, edit services, maintenance navigation, and CSV UI are implemented
and pass all five automated verification stages. The feature preserves IDs and
original name provenance, stores exact confirmed previews atomically, protects
Back from later edits and exact-name reuse, and maintains one observation queue.
The isolated foreground trial passed the Notes-to-maintenance-to-fresh-insertion
loop, including peer drafts, queue counts/Back, both split confirmations, merge,
and app-switch recovery on this machine. It exposed two keyboard gaps, now fixed
and retested. This is observed behavior, not a universal focus guarantee or a
visual layout sign-off. PLAN-008 implementation, future adapters, legacy cleanup,
tutorial progress, live-library upgrade, and release/integration remain outside
this work. The installed app was not replaced. The next separate decision is
release/integration and any human visual review before installation.

The subsequent user review rejected cross-navigation and the original density.
The revised Edit screen keeps search and the ranked alias chooser visible, without
the dropdown/provenance text box. Review defaults to concise candidates with
optional Details and a distinct Undo action. Retesting exposed field-editor arrow
and select-all handling gaps, now handled locally with Command-L search focus,
Command-A, and arrow routing. The revised keyboard trial passed; visual review
is still the user's acceptance, not inferred from accessibility output.

The later approved simplification eliminates the sparse comparison screen and
its Search control. The maintenance entry point now selects a duplicate and
confirms once, retaining the editing exercise automatically. The isolated trial
verified Cancel with unchanged query/selection and no new receipt, then Combine
with exactly one new receipt and the starting ID/default preserved. Foreign-key
checking passed and the disposable Notes text was unchanged. All five verification
stages pass with 97 tests. Human acceptance and release remain pending.

## Context and Orientation

Work from the repository root of the attached `feature/library-edit` worktree.
`Package.swift` defines the Swift core, AppKit Service executable, tests, and fixture
runners. `Sources/GymAssistantCore/ExerciseLibrary.swift` owns SQLite and schema
versions 1–3. Every active exercise has an opaque UUID and exactly one owned
preferred name. Name text is globally unique after the existing cosmetic normalizer.

`ExerciseAutocompleteSearch.swift` reads all names, ranks them, and groups by
exercise ID. `ExerciseNameWorkflow.swift` supports selected-text creation/linking
and returns preferred wording. `ExerciseIdentityReview.swift` stages observations,
exposes candidate evidence, links/creates/skips, and provides a session Back receipt.
`PersonalLibrarySource.swift` parses a six-column CSV and constructs source-backed
ingestion. The `PersonalLibraryImport` executable remains an administrative tool.

`Sources/GymAssistantNotesService/main.swift` contains the autocomplete modal panel,
shared ranked chooser, Service provider, and separate LibraryReviewWindowController.
Selecting Review Library stops autocomplete; the Service then returns and opens
the review window asynchronously. The production watchdog stays 105 seconds and
`app/notes-service/Info.plist` stays at 120000 milliseconds.

A redirect preserves a merged exercise ID as a durable row pointing to another ID.
The root is the final active exercise reached by following redirects. A receipt
records what a confirmed edit changed; it does not authorize automatic replay or
reverse history. The local app is single-user, so explicit confirmation is recorded
without introducing accounts or authentication.

## Plan of Work

### Milestone 1: Preserve exercise IDs through a lifecycle-aware migration

In `ExerciseLibrary.swift`, add schema version 4 with two persisted states: active
rows have an owned non-null preferred name and no redirect; merged rows have a
non-null target and no preferred name. Keep the public `Exercise` representation
for active exercises; add a distinct internal merged-record representation.
Retain the original ID and creation time for merged rows. Enforce the exclusive
state combinations with CHECK constraints and the target with an exercise FK.
Retain normalized-name uniqueness and the active preferred-name composite FK.
Enforce that names can be owned only by active rows and that merged rows own none
at commit; use an ordered transition plus database guards and verify with direct
SQL tests rather than relying only on UI checks. No hard-delete API is added.

Because existing SQLite constraints cannot simply be relaxed, rebuild the exercise
and name tables in a versioned transaction, copying IDs, names, timestamps, and
provenance exactly. If the rebuild requires disabling FK checking, do it before
BEGIN on this migration connection only, restore it on every exit, and run
`PRAGMA foreign_key_check` and lifecycle checks before committing. Preserve the
legacy separate table and all observation/occurrence rows. Fail on unknown future
schema versions or invalid source data without repairing it silently. Fresh
databases create the latest schema directly; reopened version-4 databases do no
DDL or repeated copying. Existing v1–3 paths must remain tested.

`ExerciseLibrary.init` currently migrates immediately on opening a database.
Ensure the consistent pre-upgrade backup is made before that first mutating open,
not after the app has already run its migration. The version check/backup entry
path must preserve the existing file on backup failure. Test startup with an
upgrade-required database and an injected backup failure; no schema/data change
may occur when backup preparation fails. Keep experimental UI trials pointed at
synthetic data rather than the user's default Application Support database.

Add `resolvedExerciseID(for:)` with visited-ID cycle detection and explicit missing
target errors. `allPreferredNames` returns active exercises only. Read paths that
accept old exercise IDs resolve their current preferred name through the root;
mutations require an active ID and reject stale retired selections. Add tests for
old-ID resolution, chains, malformed cycles, all supported migration versions,
FK enforcement, and database reopen. This milestone passes when synthetic upgrade
counts/IDs match and direct invalid active/name/redirect states are rejected.

### Milestone 2: Commit only the exact merge or split the user confirmed

Create `Sources/GymAssistantCore/ExerciseLibraryEditing.swift` for explicit domain
types and a reusable edit service. Expose read-only exercise detail by ID, all
confirmed names, source evidence relevant to those names, and read-only previews.
Keep current candidate scoring unchanged. Search for a duplicate uses current
confirmed names; show both full name lists so a score cannot substitute for review.

Each preview includes an operation ID, involved active IDs/name IDs, before/after
state, and a deterministic fingerprint of affected ownership, preferred names,
redirects, and relevant reference state. Confirm passes that exact preview. Under
`BEGIN IMMEDIATE`, reread and compare the affected state; a mismatch returns a
refresh-required error with zero changes. The fingerprint is state validation,
not a security credential. Cancelled previews create no durable rows.

Merge transfers every name from source to survivor without changing name ID,
text, normalized key, original provenance, or creation time. Preserve the
survivor's preferred name, set the source to merged with a redirect, update affected
timestamps, and append the receipt in that transaction. Reject identical roots
and stale source/survivor IDs. An identical operation-ID replay returns the stored
receipt; reusing that ID with different contents fails. Repeated merges forming
A→B→C retain all IDs and resolve to C without rewriting older receipts.

Split accepts an owned name and creates one new active exercise, making the moved
name its sole preferred name. If it was the source preferred name, select the
replacement by `createdAt`, then name UUID. Reject a source with only one name.
Transfer ownership and append the receipt atomically. Preserve name establishment
provenance and link the edit receipt to source observation evidence by IDs, without
copying private Notes lines into the receipt. Keep historical observation statuses
and originally recorded IDs unchanged. Current exact lookup follows current name
ownership; historical reporting shows original outcomes plus later edits.

Audit every existing write and undo path for lifecycle compatibility. In particular,
current observation Back can delete a linked name or a newly created exercise.
Extend its receipt/state validation so a merge, split, or later ownership edit
invalidates a stale Back action; reject safely rather than deleting edited names or
redirect sources. Exercise-name add and preference changes reject merged IDs.

Add append-only `exercise_library_edit` persistence with operation ID, typed action,
timestamp, confirmation origin, involved IDs, a versioned typed before/after payload,
and the confirmed preview. Use Foundation Codable for payloads and existing
CryptoKit for fingerprints. Database uniqueness and transaction boundaries enforce
operation replay behavior. Existing IDs in historical payloads are never rewritten.
Run core tests plus both fixture runners. Demonstrate merge, later preferred-name
split, reopen, replay, stale preview, stale Back, and injected rollback with synthetic
wording. No successful edit may exist without its receipt.

### Milestone 3: Route peer maintenance views and nested import review

In `Sources/GymAssistantNotesService/main.swift`, replace the direct Review Library
entry with visible Add Exercises (retain ⌘R for continuity) and Edit Library (⌘E).
Edit Library is always enabled; if selected, pass
`ExerciseID` and the selected durable name ID, otherwise open exercise search
without an identity. Enrich
chooser item data with that name ID instead of finding identity by displayed text.
Add Exercises is always available and receives the query for optional creation
prefill. Preserve query text in memory for orientation only. Selection or navigation
writes nothing. There is no Add-to-Edit cross-navigation.

End the modal loop using a typed maintenance-route result; invalidate its watchdog and
return the Service with its pasteboard unchanged. Schedule the retained standalone
LibraryEditWindowController using the current review pattern. Present Edit Library
and Add Exercises as independent entry routes to this retained window, with no
cross-navigation. Import is an Add child; Review candidates is an Import child. Child
Back returns one level with input and focus preserved. Avoid accumulating windows.
Reuse the ranked chooser and review controller/domain behavior where practical;
the queue controller must not own merge/split persistence.

Edit keeps a search field and the ranked exercise/alias chooser visible. There is
no Search Command-L affordance or shortcut. Command-A replaces the query; up/down select and right/left
expand/collapse aliases. There is no dropdown or large provenance text box. The
selected alias child drives Promote (Command-S), and the selected row drives
Merge with duplicate (Command-F), prefilled with the selected wording. Keep other
already-visible results available without typing again, excluding the original
identity. Changing the query performs normal fresh search; completing an edit
invalidates the retained results. Parent rows cannot promote. Disable promotion if it is the only name, explaining that
constraint in the action's help. Search itself is read-only.
Choose the other exercise and immediately show “Combine these exercises?” with
both name groups, with no additional explanatory sentence. Combine retains the exercise
the user started editing; Cancel preserves the duplicate query and selection.
No separate comparison screen, source/survivor terminology, or direction buttons
remain. Target search is a smaller attached sheet with separate controls; keep
the parent search and expansions untouched until success. Cancel/Escape dismisses
only the sheet. Attach confirmation to the sheet; success refreshes the primary
editor. The core `previewCombine(retaining:duplicate:)` wraps the explicit directed
merge API, preserving exact-preview and stale-state validation. For an alias child,
the same flow previews `moveName` to the chosen existing identity, with one explicit
Move alias confirmation instead of whole-exercise Combine. Preserve both IDs,
other names and destination default; repair the source default if needed.
A name's promotion action uses only “Promote ‘X’ to its own exercise?”
Do not disclose the internal default-name change. Both actions use the preview/apply service. Disable only-
name splitting or transfer with an ordinary explanation that the original needs a remaining
name. On stale preview, refresh and require a fresh confirmation. After success,
refresh search results and show a compact success message.
Clear that message when the user edits a query, changes the selected name, or
navigates to another screen; do not carry stale insertion instructions forward.

Add Exercises starts with creation from scratch and an Import suboption. Creation uses one
editable Name field, optionally prefilled with the autocomplete query. Save uses
the existing create boundary and `userConfirmed` provenance; an exact normalized
collision stays in Add and reports that the name already exists, without adding an alias or merging.
Errors preserve input. A successful create stays in Add Exercises; it does not insert
into the completed Notes Service request.

Import uses NSOpenPanel for the already supported CSV format. Show the exact header
requirements, parse using PersonalLibraryCSVAdapter, and display record, observation,
occurrence, and exact-reuse counts before the explicit Import action. Validation
failure reports the row/error without partially staging data. On Import call the
existing transactional ingest API and report the actual receipt/counts. Detect a
changed file between preview and apply using its source hash and require a new
preview. Retain occurrence provenance privately in the existing store. Idempotent
reimport stages no duplicate observations or exercises. Import exposes Review
candidates even when no new file is selected, so previous ingestions remain
accessible. Successful import refreshes counts and offers review in that child view.

The Import button badge counts the same visible unresolved pending observations
that To review presents, using `reviewQueue()` filtered to pending. Exclude deferred
(Skipped) and already-confirmed exact names. Count observations rather than source
rows, occurrences, or processing jobs; hide zero and expose the count accessibly.
Refresh when showing Add/Import and after ingestion, Link/Create/Skip/Back, merge,
or split. Recompute from durable state rather than decrementing a cached count.
This slice needs these refreshes, not background streaming, a scheduler, or jobs.

Expose To review and Skipped as views over existing pending/deferred observations,
with no second import queue and no new source-specific identity policy. Preserve
Link/Create/Skip/Undo behavior and source evidence. Undo (Command-Z) reverses only
the last review decision in the session and keeps existing stale-state guards;
it is not navigation or merge/split undo. Source evidence and detailed ranking
explanations are collapsed behind Details (Command-D), while blocked-link warnings
remain visible. Queue selection uses Command-1/Command-2. Leaving Review candidates
returns to Import; leaving Import returns to Add Exercises, with focus on the
originating control. Child navigation preserves Add draft input; there is no
Edit/Add switching control. Closing the standalone window restores the invoking application
through the existing review focus path. Reopening retains durable observations
and refreshes selected identity state.

### Milestone 4: Verify the complete Notes-to-library-to-Notes loop

Run `./scripts/verify` and expect all five stages to pass. It builds a temporary
bundle without installing or registering it. After automated evidence and approval
of an experimental build for foreground testing, use disposable Notes content and
a synthetic database. Demonstrate keyboard entry from selected and unselected
autocomplete, create, merge, both split cases, import preview/apply/rerun, queue
review, child Back, app-switch recovery, badge updates, and window close-to-Notes focus. Confirm
the original note remains unchanged by every editing/addition action. A fresh
autocomplete invocation must retrieve the resulting names and insert only after
explicit selection. Record observed timings and action counts without claiming
an untested focus guarantee. Stop if navigation needs a mouse or loses draft input.

## Concrete Steps

From the attached worktree root run these read-only orientation commands before
implementation: `git status --short`, `git branch --show-current`, and
`git merge-base --all learner/main HEAD`. Inspect existing documentation changes
as part of this feature; preserve unrelated edits. Confirm approval before writing
code. Implement one milestone at a time and update this plan with actual output.

Implementation evidence on 2026-10-06: branch feature/library-edit, single merge
base 7a6a58c0b3082c9f1b4ea647907f187007526498, with prior approved documentation
edits preserved. `./scripts/verify` passed all five stages with 95 tests in 13
suites, 37/37 resolver cases with zero false merges, and 8/8 identity-review cases
with zero candidate-caused writes. The initial sandboxed `swift test` could not
write its module cache or invoke its compiler sandbox. Verification subsequently
ran through the repository script with approved execution permissions; no build
dependency or app was installed. `git diff --check` passes.

For another foreground trial, request approval first. Launch the experimental
process with GYM_ASSISTANT_DATABASE_PATH set to an explicitly located absolute
synthetic SQLite path in a temporary directory. This opt-in avoids the default
Application Support database and disables appending synthetic interactions to the
private field-feedback ledger. The normal launch path remains unchanged. Do not
launch without the override for initial trials, and do not interpret the automated
bundle build as app-launch or Services-registration approval.

The approved trial on 2026-10-06 used
an isolated temporary `Gym Assistant.app` bundle, with the
distinct bundle ID `com.dangoldburt.gym-assistant.library-edit-trial`, an executable
wrapper setting the database override to the adjacent `synthetic-library.sqlite`,
and the temporary Service name Gym Assistant Library Edit Trial. Launching this
bundle exposed that temporary Service in Notes; it did not replace the installed
bundle or its normal shortcut. The synthetic CSV and database remain adjacent
for reproducibility. No private feedback records were appended under the override.

Foreground evidence: empty-query Add was available and Edit disabled; creation
used Command-R, name entry, and Return. An unsaved creation draft survived
Command-E then Command-R. CSV preview reported three observations/four occurrences;
Command-I ingested them, and a repeated apply created no duplicates. Command-J
opened child Review. Link, Create, Skip, and Command-Z Back produced pending
counts 3→2→1→0→1→0, with the zero Add Import badge hidden and one candidate
retained in Skipped. Command-2/Command-1 reached both queue views. Escape returned
Review→Import→Add, restoring focus to the parent controls, then closed to Notes.

A fresh autocomplete query selected DB Squat and Command-E opened its exact name
ID and source evidence. Command-S opened the ordinary split confirmation;
Escape cancelled without an edit, then Command-S/Return split with no default-name
chooser. Command-F, duplicate search, Return, Command-1, Return merged the split
identity into the explicitly named original. Command-S/Return then split its
default name with the replacement disclosed in the sole prompt. The resulting
database has exactly two split receipts and one merge receipt and passes
foreign-key checking. Single-name splitting was disabled with an explanation.

Command-Tab away and back left the standalone Import window usable; Command-J
still opened Review. Maintenance loops preserved the disposable note's baseline
and empty insertion line. Only a subsequent fresh autocomplete query, Down, and
Return inserted Dumbbell Squat at that line; Notes focus returned correctly.
Service menu invocation itself used accessibility menu clicks because the trial
deliberately had no shortcut conflicting with the installed app. Inside the
maintenance flow, the tested actions used keyboard input. Wall-clock interaction
latency was not instrumented; automation-call durations are not product timing
measurements. The production 105-second watchdog and 120000-ms Service timeout
remain unchanged. Screenshots/visual layout and other macOS configurations were
not verified. The temporary bundle, synthetic data, and disposable note are
retained for review; no release commit, push, PR, or installation was performed.

For core changes run `swift test`,
`swift run ResolverFixtureRunner Tests/Fixtures/resolver-cases.json`, and
`swift run IdentityReviewFixtureRunner Tests/Fixtures/identity-review-cases.json`.
At the final milestone run `./scripts/verify` and `git diff --check`. Expect the
unchanged resolver and identity-review fixture contracts to pass and all new
edit/migration tests to pass. Record actual test counts rather than a guessed total.

New tests belong in `Tests/GymAssistantCoreTests/ExerciseLibraryEditingTests.swift`,
with migration tests in ExerciseLibraryTests and regression additions in
ExerciseIdentityReviewTests, ExerciseAutocompleteSearchTests, and
PersonalLibrarySourceTests. UI navigation tests should use a small typed route
model so durable identity actions can be tested independently of AppKit. Manual
AppKit trials remain necessary for shortcut, focus, and Notes insertion evidence.

## Validation and Acceptance

Merge A into B leaves both IDs addressable, transfers all durable names unchanged,
returns one autocomplete identity B, and resolves old A references to B. A later
B into C merge resolves A to C. Split any one name from an active multi-name
exercise yields a new ID, preserves the original ID and all other names, and uses
the moved name automatically. Preferred splitting requires no extra chooser and
applies the disclosed deterministic default. Failed migration, stale preview,
cancelled confirmation, invalid replay, and injected write failure leave no partial
changes or success receipts. Stale Back refuses destructive edits.

Migration/reopen tests preserve original name/ID/provenance and observation counts.
Direct SQL tests reject malformed lifecycle states and foreign keys. Receipt
retrieval explains every changed ownership and preserves historical decisions.

The UI acceptance is observable: query → Edit Library or Add Exercises → repair,
create, or Import → Review candidates → close window → Notes → fresh autocomplete
→ selected insertion. Test each relevant path, query replacement, alias selection, Undo, Details, and the child Back
chain by keyboard. Review candidates exists under Import, which is under Add
Exercises. To review and Skipped are the only observation views. Badge tests cover
ingestion, exact-name filtering, Skip, Back, and reopening; the badge excludes
Skipped and returns to zero after pending candidates are resolved. Current production Service
timeout values remain unchanged. Automated verification does not substitute for
the foreground window and Notes trials.

## Idempotence and Recovery

Prepare is read-only. Apply validates inside its transaction and stores the receipt
atomically; retrying an identical operation ID returns that receipt. Import reuses
existing source fingerprint idempotency. Migration version 4 applies once and is
tested against a deliberately failing upgrade and a second reopen.

Before any approved live upgrade, close active app/database writers and create an
explicitly located backup using SQLite's backup API or an equivalent consistent
copy. Verify that the backup opens and preserve it outside Git. Upgrade failure
rolls back; post-upgrade validation failure stops use and retains both files.
Restoring a backup requires a separate explicit decision because it can discard
later edits. Do not add unmerge or automatic restore. Initial development and all
rollback tests use synthetic temporary databases.

## Artifacts and Notes

Maintain the approved status of this plan and ADR 003; mark work In progress only
when implementation starts. Synchronize
`docs/ARCHITECTURE.md` and `docs/PRODUCT.md` with implemented behavior at completion,
clearly distinguishing current and planned navigation until then. Preserve
completed plan history and append-only learning evidence. Do not advance tutorial
PROGRESS, SKILLS, or LEARNING_LOG for this feature.

The separate follow-up is `docs/exec-plans/PLAN-010-legacy-keep-separate-cleanup.md`.
Run it after this feature settles to avoid concurrent changes in the same files.
PLAN-008 retains all window-shim, inline-editing, extended-timeout, and asynchronous
insertion experiments. This plan excludes background import jobs, scheduled WOD
pulls, alias video metadata, new source formats, extraction, load
history, client history, deletion, unmerge, bulk editing, and automatic identity
decisions. Commits, push, PR, app installation, and merge are separate release
actions governed by repository instructions; plan approval does not perform them.

Future adapters are recorded in docs/OPPORTUNITY_SOLUTION_TREE.md and the future
import boundary in docs/ARCHITECTURE.md. Video/image/feed processing produces
source-backed candidates asynchronously for the same queue. Video candidates
carry proposed names and start/end timestamps; after explicit identity confirmation,
instructional segments attach to alias IDs. A later model design must implement
that relationship before video import. WOD URL/date are occurrence provenance,
and feed access must be verified. Each substantial source/processing capability
gets a separately scoped plan when selected; no placeholder job system is required
for this CSV implementation.

## Interfaces and Dependencies

Use Foundation, SQLite3, existing CryptoKit, and AppKit. Create no new dependency.
In ExerciseLibraryEditing.swift define opaque `LibraryEditOperationID`, typed
`LibraryEditPreview` with typed `LibraryEditAction` cases for merge and split, `LibraryEditReceipt`,
`ExerciseLibraryDetail`, `LibraryEditConfirmation`, and errors for stalePreview,
inactiveExercise, sameIdentity, onlyNameCannotSplit, and operationIDConflict.

The edit service exposes `detail(exerciseID:)`,
`previewMerge(source:survivor:)`, `previewCombine(retaining:duplicate:)`, `previewSplit(nameID:from:)`,
`apply(_:confirmation:)`, and `receipt(operationID:)`. Previews carry name IDs,
display wording, deterministic default replacement, fingerprint, and affected
identity/reference state. Confirmation records an explicit local UI action over
that exact preview. ExerciseLibrary owns transactional SQL; the core service owns
edit validation; AppKit owns presentation and confirmation collection. No Notes
pasteboard or window type enters the core.

Revision note — 2026-10-06: Initial review draft records accepted UI/split choices
and proposes lifecycle migration, transfer-plus-redirect merges, and a narrow CSV
import interface. It supersedes earlier chat-only library-audit proposals and keeps
focus experiments and legacy cleanup in their separate plans.

Revision note — 2026-10-06: Recorded full user approval and reconciled the final
navigation: peer Edit Library/Add Exercises, Import under Add, Review candidates
under Import, and a pending-only badge. Recorded future adapters and alias-owned
instructional segments, retaining CSV-only ingestion. Quick review identified
migration, stale undo, and foreground focus evidence as implementation gates.

Revision note — 2026-10-06: Implemented milestones 1–3 and automated milestone 4
evidence, including safe pre-open backups, lifecycle migration, exact-preview
receipts, guarded Back, shared-window navigation, and CSV import/badge behavior.
Recorded SQLite rename compatibility, persisted timestamp precision, and the
pre-existing exact-alias undo bug. Foreground acceptance remains an explicit
approval gate; no installation, launch, live upgrade, commit, or release occurred.

Revision note — 2026-10-06: After the first isolated trial the user requested a
tighter keyboard-first UI. Removed Add/Edit cross-navigation, the Edit dropdown,
and its large detail text box; kept search visible with stable alias selection.
Review now separates Undo from Import navigation and collapses source/ranking
details behind Command-D. PLAN-007 confirms the existing action is guarded
transaction undo, not navigation; its semantics and durable event compatibility
are unchanged. The revised synthetic foreground trial passed search replacement,
alias expansion/selection and split cancellation, duplicate comparison, Details,
Create/Undo restoring Skipped, and Escape navigation with Notes content unchanged.
No mouse was needed inside those tested maintenance flows; Service menu invocation
still used accessibility menu clicks in the deliberately shortcut-free trial.
Visual layout acceptance remains with the user. Retain the existing isolated
bundle/database and do not install over the production app or upgrade live data.

Revision note — 2026-10-08: User feedback requested action-scoped status messages
and a prefilled Merge with duplicate flow retaining visible alternatives. Synthetic
foreground checks passed those paths. A middle-of-line Notes caret survived
Edit→close→fresh Service; explicit selection inserted between the existing markers.
This verifies cursor insertion is intact, not that Command-L can resume a completed
Service. Command-L remains search focus pending a separate callback/lifecycle
experiment; production timeout, permission boundary, and live data are unchanged.

Revision note — 2026-10-08: Approved automatic-retention merge UI replaces the
earlier explicitly directed comparison screen. The internal merge remains
directed for safe persistence, but the UI uses a single Combine confirmation
with both name groups. Its Cancel path and the exercise-search return remain
inside the existing window; the reported comparison Search control no longer
exists. Foreground checks proved cancellation is read-only and Combine retains
the starting identity/default and all names, without Notes insertion. The new
regression test raises the suite to 97 tests; all five verification stages pass.

Revision note — 2026-10-08: User-requested maintenance Dock recovery now promotes
the standalone window's app to regular activation while open and restores the
previous policy on close. The shared window covers Edit/Add/Import/Review without
new windows. The branded ICNS is built from existing PNG exports and checked by
bundle verification. Empty-selection Edit entry and the shortened confirmation
passed the synthetic foreground trial; keyboard return and subsequent search input
were observed. Dock accessibility inspection timed out, so visual tile appearance
and minimized-Dock reopen remain human checks. All five stages pass with 98 tests;
production installation, live data, and autocomplete deadline are unchanged.

Revision note — 2026-10-08: The user removed the default-name explanation from
split confirmation. Both cases now use “Make ‘X’ separate from ‘Y’?”, identifying
the remaining exercise without explaining the internal default designation.
Split ownership, automatic defaults, and exact-preview safeguards are unchanged.
Exact ordinary/default prompt tests and full verification pass; the isolated
trial bundle is refreshed. Earlier trial descriptions retain historical wording.

Revision note — 2026-10-08: Supersede the parent-naming prompt with alias-only
Promote and independent expanded groups. User-approved Merge now follows the row:
whole identity for a parent, one durable name for an alias child. The latter keeps
both IDs active and repairs the source default if necessary. Its confirmation
shows the moved name and destination names, never just a hidden destination default.
Typed exact-preview receipts distinguish it from whole merge without a schema
upgrade. Tests cover ownership/metadata preservation, default repair, stale and
invalid inputs, replay/reopen, injected rollback, and row policy. Foreground
checks cancel changes; this revision does not authorize installation or live edits.

Revision note — 2026-10-08: Remove the redundant Edit Search Command-L affordance
and handler at the user's request. Keep the search field and arrow controls;
Review's unrelated Link Command-L remains. Full verification passes with 102 tests,
and the isolated bundle is refreshed without modifying the installed app.

Revision note — 2026-10-08: User requested a subordinate Merge window. Implement
a smaller attached sheet with dedicated search/chooser controls rather than a
peer window or replacing Edit's controls. Preserve the primary query, selection
and expansion on cancellation; attach confirmation to the sheet and refresh the
parent after success. Native cancellation checks pass; no trial edit was committed.

Revision note — 2026-10-08: Approved product integration is prepared in a clean
learner/main-based branch. Personal learning records and curriculum maintenance
remain outside the product PR. PR publication does not authorize merge or install.
