# ADR 003 — Edit persisted library identities through explicit local actions

Status: accepted on 2026-10-06. Implemented in the local feature worktree with
automated verification and an isolated synthetic-data keyboard/Notes trial.
Visual layout review and release remain outstanding; PLAN-009 records trial limits.
Future import adapters are recorded as direction, not current scope.

## Context

Autocomplete helps the coach find wording to insert into Apple Notes. Its results
may reveal duplicate exercises or an incorrectly linked alias. The coach also
needs a place to add a missing exercise without navigating unrelated review work.

`Exercise.id` is canonical identity. `ExerciseName.id` identifies a durable name
record, whose globally unique normalized wording has exactly one owner. Active
exercises have exactly one owned preferred name, although autocomplete displays
the query's winning name and does not expose the preferred designation. Exact
selected-text resolution and tie-breaking still use the preferred name internally.

The current Review Library action ends autocomplete's synchronous Notes Service
request and opens a standalone review window. The coach reports better keyboard
recovery after switching applications in this window. The implementation has no
merge or alias-split operation; it does contain unused Keep Separate persistence.

## Decision

Expose Edit Library and Add Exercises as peer, keyboard-operated routes from
autocomplete, without cross-navigation between them. With a selection, Edit Library receives
its stable exercise ID and selected durable name. Without a selection, Edit opens
exercise search with no identity selected; the entry remains enabled.
Add Exercises receives the query
for optional creation prefill. Add Exercises is the user-facing name for the former
Review Library surface. Add Exercises opens a creation field, optionally prefilled
with the query, and offers Import as a suboption. Review candidates is a child of
Import and contains the single To review / Skipped observation queue. The Import
button carries a count of candidates in To review across all ingestions, excluding
Skipped and observations already recognized by exact confirmed-name lookup. A
zero count needs no badge. Edit Library is not a required parent of Add Exercises.
The user approved this navigation and the standalone Service-return lifecycle.

Match the current Review Library lifecycle: end the modal chooser, invalidate its
watchdog, return the Service with no insertion, and schedule a standalone window.
Each route opens its own session in that retained window.
The standalone window promotes the application to regular activation while open,
using the bundled branding icon for Dock and keyboard app switching. Closing it
restores the prior activation policy. This does not change the outstanding
autocomplete Service's presentation or deadline. Edit keeps a search
field and ranked exercise/alias list visible rather than a name dropdown or a
large provenance text box. Arrow keys select names and expand aliases; split and
duplicate actions operate on the selected durable name. Source evidence in import
review is available through Details, not expanded by default. Its Undo action
reverses only the last review decision in the session, retaining stale-state
safeguards; navigation to Import remains separate. Closing the window restores Notes focus.
Preserve the query in memory for orientation and prefill; a later Notes insertion
uses a fresh autocomplete invocation. Window shims, longer deadlines, and editing
within an outstanding autocomplete invocation remain deferred in PLAN-008.

Merge automatically retains the exercise the coach started editing, including its
stable ID and default wording. The coach chooses its duplicate and confirms once;
there is no direction choice or separate comparison screen. Merge with duplicate
prefills the selected wording and retains other
visible search results so an already-visible duplicate needs no repeat search.
Editing the query resumes fresh search. Status messages clear on continued
navigation, query changes, or selecting another name. The confirmation asks
“Combine these exercises?” and shows both name groups, without an additional
explanatory sentence. Cancel preserves the search context. Technical IDs and a full
change ledger do not belong in this prompt. A merge transfers all duplicate names to
the survivor, preserving each name ID, text, normalization, creation time, and
original provenance. The survivor keeps its preferred name and stable exercise ID.
The former exercise ID remains as a merged record pointing to the survivor; it is
never deleted or reused. The user approved this transfer-plus-redirect storage
model on 2026-10-06; it replaces the earlier chat proposal to leave names owned
by merged rows.

This automatic-retention UI policy was approved on 2026-10-08 and supersedes the
earlier two-direction UI. Retained default wording can affect selected-text
Review Selection and ranking ties, but does not require the coach to choose a
technical surviving ID. The core's directed merge API remains explicit for
transaction validation; the maintenance entry point uses
`previewCombine(retaining:duplicate:)` to enforce this UI rule.

A merged record has no owned names and no preferred name. An active record must
still have a non-null preferred name that it owns. The persistence schema must
enforce these distinct lifecycle states rather than allowing nameless active
exercises. Reads of old IDs resolve through redirects to the active exercise;
historical records retain the IDs originally recorded. Later merges may create
redirect chains; root resolution detects cycles and missing targets and fails
explicitly. Autocomplete emits only active identities. Writes reject retired IDs
until the UI refreshes and the user confirms an action on the current identity.

Split moves one confirmed name to a new exercise, preserving the name record's ID
and provenance. That name automatically becomes the new exercise's preferred name.
No additional preferred-name choice is required. The original active ID survives.
If the moved name was preferred, select its replacement by earliest creation time,
then name UUID as a stable tie-breaker. Offer promotion only on an explicitly
selected alias child row, confirming “Promote ‘X’ to its own exercise?” without
parent/default wording. Exercise groups expand independently. An exercise's only name cannot be split because
there would be no remaining named identity. These split/default/confirmation rules
were approved by the user in chat.

Merge follows the selected row: a parent combines the whole exercise, retaining
the starting identity; an alias child moves only that name to the chosen existing
exercise. An alias move preserves both active exercise IDs, all other names,
name ID/provenance, and the destination default. Repair the source default by the
same deterministic rule when necessary; reject an only-name move. The typed
`moveName` receipt distinguishes it from whole merge; the schema-v4 action column
indexes both as the merge family, without a schema change or identity redirect.

The target chooser is a smaller attached sheet under Edit Library, not a peer
window or a replacement of the primary editor. Its search field and ranked chooser
are separate controls so the parent's query, selection and expanded groups remain
intact on Cancel/Escape. The explicit confirmation is subordinate to this sheet;
success dismisses it and refreshes the primary editor.

Each merge, alias move, and split commits with an append-only edit receipt containing an
operation ID, timestamp, local explicit-confirmation marker, involved IDs,
before/after ownership and preferred-name state, and the preview that was confirmed.
Provenance on a name records its original establishment; the receipt records the
later correction. The app is local and single-user, so this marker documents an
application confirmation rather than authenticating a person's identity.

Historical observation outcomes and source evidence remain unchanged. A previously
linked observation can refer to an exercise whose alias was subsequently split;
the receipt explains that later correction. Historical attribution is not silently
recomputed from today's name ownership. Current exact lookup uses current ownership.
Merge redirects resolve old IDs for present use without rewriting their history.

Keep Separate is excluded. Direct manual editing has no repeated duplicate-proposal
queue requiring dismissal. PLAN-010 retains removal of its unused API and fresh-
database schema in a later small PR, preserving any existing table and records.

## Evidence

`ExerciseLibrary.swift` enforces globally unique normalized names and an owned
preferred-name composite foreign key. Its current schema cannot retain a merged,
nameless source record without a lifecycle-aware migration. `ExerciseAutocompleteSearch`
already groups names by their owner ID, so transferring ownership preserves the
existing one-result-per-identity behavior with fewer special grouping rules.

`ExerciseServiceProvider.autocompleteExercise` schedules `showLibraryReview` after
`ExerciseAutocompletePanel.runModal` returns. The timer is invalidated on exit and
the review window has no pending Service insertion. `PersonalLibraryCSVAdapter`
and `ExerciseIdentityReviewService.ingest` already parse and transactionally stage
the supported CSV format, preserving occurrence evidence and import idempotency.

## Alternatives considered

Leaving names on merged source rows avoids rebuilding the exercise table, but
requires every read to group names across redirect members. Splitting a preferred
name from a member with no other names then creates a lifecycle problem anyway.
The proposed transfer makes active name ownership and split behavior uniform.

Deleting source exercises or rewriting downstream references loses stable-ID
continuity. Changing names into canonical identifiers introduces rename ambiguity.
Both are rejected. A generic variant graph, history model, bulk edit queue, and
automatic merges add scope without improving this direct repair interaction.

An inline editor that returns to refreshed autocomplete remains a useful
experiment in PLAN-008. It is not selected for this feature because the user chose
the existing standalone Review Library lifecycle.

## Consequences

The feature needs a tested, transactional migration distinguishing active and merged
rows, redirects for old IDs, explicit preview/confirmation/apply boundaries, and
guarded observation undo. Existing Back receipts must refuse to delete a name or
exercise affected by a later library edit. Preview preparation and result selection
remain read-only; commit requires the exact confirmed preview and rejects stale state.

The Import route initially supports the existing six-column CSV format through a
file picker, validation/count preview, and explicit ingestion action. It stages
observations without asserting identity. Pasted sources, URLs, photographs, and
extraction remain later work. Source import from this UI is an extension of the
current command-line-only administration boundary and was approved by the user
on 2026-10-06.

Future exercise import from a video URL, especially YouTube, depends on a separately
designed instructional-video-link extension to the exercise model. Videos belong
to durable aliases (`ExerciseName.id`), not directly to exercise IDs. An alias may
have multiple instructional segments; a segment identifies the URL and optional
start/end timestamps, and one video may supply several exercise candidates.
Extraction proposes wording and segment boundaries for human correction. Before
identity confirmation, segments are candidate source evidence; confirmation
associates them with the alias. Merge and split preserve name IDs, so attached
segments follow the alias. Implement neither video metadata nor extraction here.

Future video/image/feed adapters may process sources asynchronously and append
candidates to the same import review queue as processing completes. Closing a view
must not discard accepted processing work or review progress. Import's pending
review badge and processing status represent different counts/states. Scheduled
WOD ingestion preserves source URL/date as occurrence provenance; a workout page
is not automatically instructional material. Feed availability and extraction
policy need later verification. These are future directions only.

## Known limitations

The standalone handoff ends the original insertion request. It does not establish
focus recovery for autocomplete. There is no unmerge, split rollback, deletion,
client-history feature, bulk operation, or new similarity policy in this slice.
Receipt-based diagnosis and an explicit backup restore remain recovery tools.

## Revisit triggers

Revisit when real use requires unmerge, correction of historical attribution,
ambiguous/contextual alias ownership, external references that cannot resolve old
IDs, or repeated friction from returning to Notes and reinvoking autocomplete.
Focus experiments remain in PLAN-008; legacy cleanup remains in PLAN-010.

Revision note — 2026-10-06: Accepted after the user's approval. Replaced the earlier
parent/Add navigation with peer Edit Library and Add Exercises routes, nested Review
under Import, defined the pending-review badge, and recorded future asynchronous
adapters and alias-owned video segments. Current ingestion remains CSV-only.
