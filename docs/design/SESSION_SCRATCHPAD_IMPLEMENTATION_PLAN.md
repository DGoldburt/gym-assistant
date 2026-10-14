# Implement a persistent session scratchpad with margin conversation

This proposed ExecPlan follows repository-root `PLANS.md`. Keep Progress, Surprises
& Discoveries, Decision Log, and Outcomes & Retrospective current. It is held in
`docs/design/` until approved; then assign the next unused PLAN identifier and move
it into `docs/exec-plans/`. Preparing this document is not feature authorization.

Reconciliation note, 2026-10-13: this proposal was drafted in a worktree based on
reusable `main` and then transferred to a branch based on `learner/main`, where the
developed Service, library, observation queue, and future program/history designs
exist. Descriptions below of the earlier "reusable checkout" are historical
discovery evidence. Before implementation, recheck every named interface and file
against the then-current learner branch, including concurrent client-history work.

## Purpose / Big Picture


The coach can start or resume one freely editable session scratchpad from the same
shortcut used for exercise autocomplete, converse beside it, and ask follow-ups
without pasting the evolving program into chat. Closing the window does not lose
the scratchpad or create a competing copy. Notes remains the recorded destination:
copy rich text, paste deliberately, and inspect an automatically refreshed diff
when useful. The first iteration
has no actionable chat proposals or automatic Notes writes.

## Plan Status


Proposed, updated 2026-10-12. The user approved the product boundaries and the separate
read-only Notes adapter, not this plan's implementation defaults or acceptance
criteria. Approve the native-workspace contracts and explicitly sequence this work
before starting production code. Model choice and spending limits remain a separate
required checkpoint before live API calls; they do not block isolated native tests.

## Progress


- [x] (2026-10-13 02:33Z) Inspect the capability evidence, reusable checkout, and learner Service/library interfaces; distinguish implemented behavior from design.
- [x] (2026-10-12 local date) Record accepted read-only adapter direction in ADR 004 and prepare this proposal.
- [x] (2026-10-13 04:14Z) Incorporate review feedback: define commands explicitly, replace Check Notes with automatic monitoring and a diff toggle, and prefer heading correction to elaborate duplicate-label recovery.
- [x] (2026-10-12 local date) Add monitoring lifecycle/edit impacts and preserve workspace identities through verified bulk heading renumbering; correction alone is not proof of association.
- [x] (2026-10-12 local date) Make chat, diff, and whole-scratchpad copy share one freshness policy; add copy-time external-edit warnings and a timestamp/cache validation gate.
- [x] (2026-10-12 local date) Complete an independent read-only CLI review; correct the verification overclaim and specify proposed boundary/confirmation fixtures. See the review assessment below.
- [x] (2026-10-13 local date) Continue synthetic capability work: 39/39 combined local/native-snapshot association assertions pass; direct metadata reads measured. Native copy fails Subheading fidelity; no production implementation.
- [x] (2026-10-13 local date) Record coach boundary correction: hierarchy as strong evidence, trailing parking-lot inclusion, and always-available unobtrusive adjustment; no new implementation or verification claim.
- [x] (2026-10-13 local date) Record approved edited-region protection and previewed expansion; a separate synthetic policy model passes 24/24, not native edit tracking/UI acceptance.
- [x] (2026-10-13) Continue capability experiments: hierarchy 19/19, shared freshness candidate 15/15, native date collisions and large-note timings measured; public hierarchy export and delayed-copy race require handoff choices.
- [x] (2026-10-13 local date) Clarify approved ownership boundaries: workspace-owned reading contracts and state policy; macOS-owned read execution/scheduling and presentation. Documentation only.
- [x] (2026-10-13) Transfer the design package and synthetic probes to a learner-based integration branch; reconcile the OST and architecture against the developed product without changing the source worktree.
- [ ] Approve the proposed association, handoff, recovery, entry, and acceptance contracts; choose execution sequence without advancing the tutorial implicitly.
- [ ] Verify session association and full rich-text paste fidelity with synthetic native tests; finish the outstanding capability-plan session-anchor item only on evidence.
- [ ] Implement persistent native workspace and production Notes permission/read adapter; pass offline/close/relaunch/recovery tests with a fake assistant.
- [ ] Select API model and explicit spending bounds, approve credential/retention defaults, and validate the request/response contract before live calls.
- [ ] Implement conversation freshness, fixed read-only profile, and truthful exercise decoration; verify fake-provider behavior before paid tests.
- [ ] Complete synthetic end-to-end acceptance, regression checks, and coach review; publish only the approved coherent package under the repository Git lifecycle.

## Surprises & Discoveries


2026-10-13 coach clarification: session titles normally use a higher native heading
level than Warmup. The literal Session grammar is therefore an experiment, not the
complete intended recognizer. A trailing Parking Lot is desired scratchpad context,
not a boundary error to fix. New boundary/adjustment validation remains pending;
the existing 39 passes and formatting failure are unchanged.

2026-10-13 capability continuation: API-captured plaintext supports the proposed
renumbering model (39/39 combined assertions), but rich-format-aware association
and native confirmation UI are not proved. Twenty direct metadata-only reads took
1.877 seconds on the fixture, not a shared production-monitor benchmark. Native
editor Command-C loses header metadata; Notes identifies its pasted warmup as Body.
Bold/continuing bullets pass. Retain the full hierarchy gate; another export
candidate may be investigated without broadening the first slice or weakening it.


Whole-note native reads passed, including all 70 context lines and an offscreen end
marker. Captured-note rereads still targeted the fixture after selection changed.
The packaged app initially lacked permission even when a standalone CLI diagnostic
reported availability. Production consent therefore needs its own verification.

The synthetic fixture's repeated Session 1 headings referred to distinct sessions.
The coach clarified that duplicate peer session headings are mistakes, not a
structure to support at all costs: expose the issue and let the coach fix Notes.
Lettered sessions with three weeks of progression are intentional and must not be
treated as duplicate headings or forcibly renumbered. A heading, ordinal, cursor,
or modification date alone cannot prove an unchanged association. RTF decoded heading
level 2 as 0 and changed literal bullet text; secure attributed-string archiving
passed the strict local fixture. HTML h3 pasted as Heading rather than Subheading.
Neither successful local archiving nor partial Notes paste proves full handoff.

The reusable checkout has no production Service yet. The learner checkout has
working autocomplete and library review. Do not copy the learner checkout wholesale
into reusable main or implement against nonexistent starter interfaces.

## Decision Log


Accepted ownership clarification, 2026-10-13, coach approval in the side conversation:
define the consumer-facing NotesContextReading protocol and its snapshot/error types
in Foundation-only GymAssistantWorkspace; GymAssistantMacOS implements it. Keep
workspace registry, association, freshness/cache-validity and baseline decisions in
workspace logic. Native timers/read execution and UI presentation remain in macOS.
Rationale: application logic must be testable with a fake reader without importing
the platform adapter, and a window must not become the owner of session rules.
This clarifies the existing responsibilities, not product scope, implementation
authorization, or approval of the remaining proposed acceptance criteria.

Accepted: one persistent scratchpad per training session, whole-note context,
free-form margin conversation, manual rich-text handoff, headings-only new-session
skeleton, read-only discoverable existing preferences, and minimal exercise identity
decoration. No historical conversation import or new preference learning. The user
selected these on 2026-10-12. They bound the slice, not its execution order.

Accepted boundary direction, 2026-10-13, coach's side-conversation correction:
native heading hierarchy is high-confidence evidence because session titles are
normally higher-level than Warmup. Combine formatting with text/structure; exact
Session spelling is not required. A trailing Parking Lot belongs in the final
scratchpad as idea context, not a new workspace or forced cutoff; exclude it from
new-session skeletons. The coach can always adjust either boundary with minimal UI
friction. Leading UI proposal: top/bottom source-offset markings opening a compact
read-only browser via right-click or discoverable keyboard commands, with up/down
or drag adjustment. Exact keys/display remain proposed. Approved follow-up: expand
with a fresh added-content preview preserving edits; block shrink into edited or
coach-added regions, with no discard override. Allow exact abutment but not overlap
and show the owning workspace. Range/content changes undo together, rechecking
freshness and ownership. Hypothesis: adjustment usually precedes editing. Rationale:
respect natural note structure, preserve ideas and
avoid silent swallowing, identity guesses or mandatory spelling repairs.

Accepted: ADR 004 adds read-only Notes Automation alongside the existing Service.
The Service returns before long-lived work; subsequent reads use the captured note
identity. Rationale: the fixture demonstrated the narrower native read route.
Date/author: 2026-10-12, user approval recorded by Codex.

Accepted review constraint: flag accidental duplicate peer session headings and
ask the coach to correct them in Notes rather than build elaborate recovery around
the mistake. Preserve lettered sessions and their multiweek progression content.
Rationale: duplicate session numbers usually result from forgetting to increment
them; multiweek progressions are a different, valid structure. Date/author:
2026-10-12, user review recorded by Codex.

Accepted association constraint: fixing duplicates can renumber every subsequent
heading. Preserve existing workspaces independently of those labels, and specify
monitoring triggers and each edit's impact. Rationale: heading correction must not
transfer one session's scratchpad to another or forget closed workspaces.
Date/author: 2026-10-12, user's follow-up review recorded by Codex.

Proposed: retain a local workspace/session identity with a confirmed session
boundary and baseline, without hidden identifiers in Notes. Resume unambiguously
or ask for confirmation; heading correction reuses the existing scratchpad rather
than generating another. Date/author: 2026-10-12, Codex proposal following user review.

Proposed association mechanism: verify a one-to-one set of mappings for the
captured note using confirmed session bodies/structure, ignoring only a renamed
outer label, with confirmation for indistinguishable/changed cases. Publish verified
registry updates without using headings as keys. This is not fuzzy/model inference
and does not assume the numbering correction is local. Date/author: 2026-10-12,
Codex proposal responding to the renumbering risk.

Accepted session scope: keep an entire lettered session with all three weeks of
progressions in one scratchpad. No per-week chooser or separate week workspaces.
Rationale: preserve the coach's intentional multiweek structure instead of forcing
one numbering system. Date/author: 2026-10-12, user's explicit clarification.

Proposed: use secure attributed-string archives inside versioned atomic workspace
snapshots, independent of clipboard formats. Keep one previous valid snapshot;
have no deletion UI or automatic eviction initially. Rationale: the archive fixture
preserved formatting while RTF did not. Date/author: 2026-10-12, Codex proposal.

Proposed entry binding: local Command-P in autocomplete opens Program session…;
existing Command-R continues Library Review. These commands are defined under
Entry and handoff commands below, not inferred from their names. Date/author:
2026-10-12, Codex proposal; confirm local key conflicts in native testing.

Accepted handoff revision: a floating upper-right copy icon, ordinary selection/
Command-C, and a discoverable whole-scratchpad copy shortcut; a diff view toggle
replaces a Check Notes action. Notes refresh and comparison happen automatically.
Rationale: the coach does not need separate copy/check buttons or another view
stack. Date/author: 2026-10-12, user review recorded by Codex.

Accepted review revision: whole-scratchpad copy is a pre-handoff chance to detect
an external Notes edit and warn before manual paste. Chat, diff, and whole-copy
use the same Notes freshness check, with distinct outcomes. Partial-text copy is
unchanged. Date/author: 2026-10-12, user approval following the copy-risk discussion.

Proposed monitoring mechanism: metadata-first checks, body caching/coalescing, and
one shared validation policy. Fetch changed/missing/uncertain body state, not a full
body unconditionally for every prompt. Test timestamp resolution and edit/format/
undo timing before choosing the minimum safeguard for equal-time changes. No model
calls from monitoring. Rationale: cache validity is the issue, not which UI command
requested it. Date/author: 2026-10-12, Codex revision approved for design review.

## Outcomes & Retrospective


Planning only. The native read gate passed; session association, complete export
fidelity, production consent, real persistence, and model-backed behavior remain
unverified. No production files, tutorial progress, private profile, or installed
Service are changed by this proposal. A planned milestone is not a completed test.

The 2026-10-13 ownership clarification places the reader contract and state policy
on the workspace side of the dependency boundary. Native execution and views consume
that policy rather than duplicating it. These are implementation instructions, not
new passing tests; the overall plan remains proposed.

2026-10-13 side-conversation update records corrected boundary direction and a
compact adjustable-range UI proposal only. Exact shortcuts/display remain open;
the subsequent coach approval settles conservative edit-protected shrinking and
previewed expansion, not production approval.
No production approval
or new native evidence follows from recording this guidance.
This review adopts the smaller handoff UI and the coach-corrected duplicate-heading
path and preserves multiweek lettered sessions as one scratchpad. Efficient
metadata monitoring still needs verification. No new visuals or production behavior
were created.

The follow-up monitoring contract describes lifecycle triggers and edit impacts,
including reassociation of all saved workspaces after bulk renumbering. Stable IDs
and group verification are requirements, not evidence of working implementation.

## Context and Orientation


The implementation baseline must contain `Sources/GymAssistantNotesService/main.swift`
with `ExerciseServiceProvider.autocompleteExercise`, `ExerciseAutocompletePanel`, and
the asynchronous `showLibraryReview` branch. `app/notes-service/Info.plist` registers
Option-Command-G, and `app/notes-service/build.sh` builds/signs the app. The chooser
is modal: its Service has a 120-second deadline and cancels around 105 seconds.
Ordinary insertion returns plain text; long conversation cannot stay in this call.

`Sources/GymAssistantCore/ExerciseLibrary.swift` supplies `exactName(for:)` and
`preferredName(for:)`. Exact lookup of a confirmed canonical name or alias can prove
identity; fuzzy suggestions and pending observations cannot. The resolver/library
remain independent of Notes. This slice consumes their existing contracts and does
not implement client-history or load recommendations, even if another branch has
work toward those capabilities.

Add `Sources/GymAssistantWorkspace/` for Foundation-only workspace identities,
session association, registry rules, freshness/baseline policy, revisions, messages,
profile records, context assembly, and the consumer-facing note-reading contract.
Add `Sources/GymAssistantMacOS/` for Notes reads, attributed-text storage/export,
native scheduling, the native window, and the provider adapter. It depends on
GymAssistantWorkspace, never the reverse. Workspace types/protocols must not expose
AppKit objects or AppleScript descriptors; native formatting evidence is translated
into typed Foundation values at the adapter boundary. The executable remains the composition
point: it supplies existing library services and opens the window. Update
`Package.swift` with these targets and corresponding test targets; do not put
AppKit or Notes data reads into `GymAssistantCore`.

A baseline is the last Notes session confirmed for this scratchpad, not a live
editor. A revision is a monotonically increasing scratchpad edit number. An anchor
is evidence locating that session inside the captured note, not a Notes-generated
session ID. A workspace snapshot stores one session's formatted scratchpad and its
conversations together. All examples and committed fixtures must be synthetic.

## Proposed user-visible contracts


Entry uses Option-Command-G, then Command-P. Only this chosen branch captures one
selected Notes identity, without prompting or waiting for model work. The chooser
may already have focus; use Notes' data selection rather than foreground UI state.
If access is unavailable, release the Service before offering explicit onboarding
and retry in the independent window. Return the Service, then offer Work on latest
session or New session. Latest means last session in note order, not a guessed most-
recent edit. Show its heading and short excerpt when confirmation is needed. Accept
numbered and lettered session labels; nested Week 1/2/3 progression content is not
three duplicate sessions. If usable boundaries are absent, allow a range selection
in a read-only preview; do not force A/B fields. Treat native heading hierarchy as
high-confidence boundary evidence, combined with text and surrounding structure;
exact Session spelling is not a prerequisite. Lower-level Warmup/week headings
remain nested when structure supports it. A trailing Parking Lot stays in the
final scratchpad as attached idea context even if styled as a peer heading; it
does not create a session or seed a new-session skeleton. The text-only prototype
does not implement these corrected rules. If peer session labels are duplicated,
show the conflicting headings and ask the coach to correct them in Notes. Do not
build fuzzy content relocation to hide a numbering mistake or rewrite Notes for them.
Ordinary entry into an unambiguous latest session should require at most two local
key actions after the global shortcut, excluding first-time permission onboarding.

Always offer coach boundary adjustment, not only when detection is uncertain.
Leading UI: small source-offset markings at the top/bottom of the scratchpad pane,
with right-click or discoverable keyboard/menu commands opening a compact read-only
note browser for endpoint up/down or drag movement. Avoid permanent extra panes
and routine modal confirmation. Offsets belong to a specific Notes observation,
not scratchpad lines. Validate freshness/overlap, preserve workspace identity and
all coach edits. Preview added edge content before expansion. Block shrink into
edited/coach-added regions, including deleted content and uncertain correspondence;
do not offer to discard edits. Permit abutment and identify the neighboring owner,
but reject overlap. Undo the content and association change together only after
freshness and ownership revalidation. The usual-before-editing assumption requires
field validation; it is not justification to lose edits when it proves false.
Moving bounds alone never accepts external text or authorizes Notes writes.
Exact keys and offset display remain proposed.

An existing workspace for that note/session is resumed. A new conversation shares
its scratchpad. Local SessionID and WorkspaceID, not headings, key the registry.
After duplicate-heading correction, automatic refresh notices the correction but
must revalidate every affected saved association, including closed workspaces.
Preserve all existing IDs and scratchpads. Renumbering from 12/13 to 13/14 must not
bind the old Session 13 workspace to the new heading 13 merely because labels match.
Compare prior session bodies/structure with only the outer renamed label excluded;
unchanged distinctive content can support verified relocation. Require a unique
one-to-one mapping, confirm indistinguishable/also-edited cases, and publish verified
mappings together so sequential label changes cannot collide.
While association is ambiguous, keep editing and rich copy available but pause
target-dependent context assembly and reconciliation. Do not use an ordinal as
proof, silently create another copy, or discard the scratchpad. For a uniquely named
session that has moved or changed, use a simple confirmed boundary/baseline check;
ask for confirmation if identity is unclear. A new session gets a local identity
and remains unrecorded until automatic refresh verifies its corresponding Notes
section after paste; request confirmation when association is ambiguous. Later
revisits must offer existing
unrecorded work before creating another new session.

For a synthetic Session A containing three weeks of progressive prescriptions,
retain its complete structure and content; repeated Week 1 headings under different
unique session parents are not duplicate session labels. Approved scope: one
scratchpad for the whole lettered session with all weeks intact, without a week
chooser or separate week identities. Do not turn repeated week labels into new
session identities or flatten/remove their progression prescriptions.

The editor supports native bold, headings/subheadings, and bullets with undo and
free text. A new session copies only the prior session's structural headings, not
old exercises, doses, dates, results, or warmup lines. Ambiguous heading/content
classification is previewed, not silently carried forward. Conversation history
and Programming preferences are quiet access points, not permanent extra panels.

Save locally after each edit with a proposed maximum 500 ms debounce; flush on
prompt submission, Copy, close, and orderly quit. Show local save failure rather
than claiming durability. Closing/reopening restores the same workspace, text,
formatting, revision, and conversations. Cancel unfinished generation on quit; on
relaunch label it interrupted and do not re-send a paid request automatically.
A crash can lose an edit within the unsaved debounce interval; it must never erase
the last acknowledged saved revision. If zero-keystroke crash loss is required,
revisit the persistence contract before promising it.

Monitor the captured note automatically; there is no Check Notes command or button.
Refresh full content on entry/resume; chat, diff, and whole-copy use the same shared
freshness check below. Whole-copy makes a bounded safety attempt before export
and warns about external changes or failed checking; partial-text copy needs no
Notes access. Ordinary monitoring discovers the result of a manual paste. Surface
Notes changed or Notes unavailable with the last successful check time. Keep
baseline and fresh observation separate.
Changes elsewhere in the note may update surrounding context if the original session
still has a reliably located boundary. Duplicate, missing, or renamed target headings
require correction/confirmation before assembling new model context. Changed content
alone under the unique confirmed session heading is not necessarily an association
failure: show the change, preserve the scratchpad, and compare automatically.
Editing and Copy remain available offline;
chat pauses if reliable session context cannot be assembled. Do not silently answer
from cached context as though it were fresh.

At each prompt, snapshot the current scratchpad revision and substitute it for the
confirmed recorded-session range in the whole-note observation validated by the
shared freshness policy. For new sessions,
include it as explicitly unrecorded, not as replacement of the last session. Include
the fixed profile and relevant new workspace conversation; no exported ChatGPT
transcripts are runtime inputs. If the scratchpad changes during generation, show
Scratchpad changed; allow ask-again, do not lock or automatically restart. Tag the
response with the revision actually used. Notes changes during a request also
invalidate any claim that its context is current.

### Entry and handoff commands


Program session… is a new command in the existing autocomplete chooser, with
proposed local Command-P. It opens/resumes the independent workspace after the
Service returns and offers Work on latest session or New session. It is not an
implemented action. Review Library… is the existing chooser action with Command-R,
implemented by `ExerciseAutocompletePanel.openLibraryReview` in
`Sources/GymAssistantNotesService/main.swift`. It remains unchanged. Both appear in
the chooser with their local keyboard equivalents; neither adds a global shortcut.

Copy scratchpad is an icon floating in the upper-right of the scratchpad pane,
not a labeled primary button or a separate handoff panel. It copies the entire
scratchpad as rich text plus a plain-text compatibility representation. Proposed
local Command-Shift-C invokes that whole-scratchpad command regardless of selection;
show it in the Edit menu, tooltip, and accessible command name. Keep standard
Command-C selection semantics. With editor focus, Command-A then Command-C copies
the full scratchpad immediately through the rich export path, without a synchronous
Notes check; the explicit icon/whole-copy command is checked. Partial selection
copies only that range. Command-C in chat still copies chat selection. Test both
copy paths for equivalent supported formatting; intercepting native copy must not
break ordinary selection, undo, or accessibility.

Compare with Notes is a compact diff-view toggle at the scratchpad edge, with an
accessible label and a discoverable View-menu command. It temporarily replaces
the editable scratchpad surface with a read-only comparison of the scratchpad and
the latest automatically read, confirmed Notes session; toggle back to keep editing
the exact same scratchpad. It is not a second stacked note, a manual refresh action,
or an Apply/Merge control. Show differences against current Notes, not only the
original import; retain the original baseline internally for external-change
warnings. When live reading fails, explicitly label the last-known Notes snapshot
and its time; do not present it as current. A new unrecorded session appears as an
addition rather than replacement of the previous session. The toggle uses the
monitor's cached snapshot; opening it never sends data to a model.

Neither copy path pastes automatically or marks reconciliation. Automatic refresh
may establish Notes matches scratchpad only when the correctly associated Notes
session's text and supported formatting agree. If paste normalization prevents
verification, remain not verified and expose the mismatch in the diff. The copy
icon may briefly say Copied, but do not require an app-specific copy receipt to
recognize a match after Command-A/Command-C/manual paste. A different session or
format mismatch must not reset the baseline as though saved. New-session association
after paste needs visible confirmation only if the new target cannot be established
unambiguously. Duplicate-heading correction/reassociation likewise retains the
scratchpad. No automatic Notes merge, write, or scratchpad replacement.

Whole-scratchpad copy is also a safety checkpoint. Before completing the icon,
whole-copy shortcut export, use the shared freshness
check and compare current Notes with the last confirmed baseline, not merely the
scratchpad's edits. Warn Notes changed—review differences before pasting and expose
the diff if Notes independently changed; if current Notes already equals the
scratchpad, report the verified match instead. An unavailable read or uncertain
association must warn Notes could not be verified. Copy remains available with
warning, not as a claim of safe paste. Partial-text/chat copy retains ordinary
semantics and does not preflight Notes.

Accepted 2026-10-13: checked icon/whole-copy shortcut requires waiting for Copied;
ordinary Command-C remains immediate and Notes-unverified at export, including
Command-A/Command-C. A simulated 750ms preflight pasted OLD contents before it
completed at 0.753 seconds; this distinction does not prevent early paste elsewhere.

Accepted timing, 2026-10-13: 400ms target and 750ms maximum verification wait. Capture
the scratchpad revision; prepare/publish rich content concurrently with Notes
verification. Show preparing until publication, then Copied—checking Notes while
verification remains pending. At 750ms show Copied—Notes not verified if publication
succeeded, and keep verification running without locking the editor. Never claim
Copied if export/publication is still pending. Indicate Scratchpad changed for edits
during preparation. Measure publication/read/export/total durations and outcomes
without content; exercise slow/hung readers and large exports. Observed body timings
are not full-copy guarantees. No check prevents edits between copy and manual paste.
Accepted late-conflict behavior: replace clipboard entirely with warning text only
while the exact scratchpad-copy operation still owns it. Any subsequent copy,
including identical text, invalidates ownership; leave it alone and warn in the app.
Use a per-operation identity and publication changeCount, not text comparison alone;
recheck immediately before writing without awaiting between check and write. Always
update the app conflict state. Native recopy/stale-result tests remain required;
the public pasteboard API has no exposed conditional compare-and-write primitive,
so cross-process guard/write race safety must be evaluated, not asserted. If ownership
is uncertain, app warning only. Scope conflicts to the associated session and captured
baseline/revision; do not mistake the coach's own paste for an external conflict.

### Efficient automatic Notes monitoring

Capability follow-up, 2026-10-13: native Edit → Paste as Markdown retained actual
Title/Heading/Subheading, bullets and bold on the current macOS 27 synthetic fixture.
Ordinary Markdown Command-V, single-item HTML and verified WebArchive failed native
heading fidelity. The coach selected pursuing native Markdown handoff on 2026-10-13;
this does not approve untested serializer behavior or production implementation.
It requires faithful rich-to-Markdown conversion, literal/escaping/normalization tests,
platform availability and keyboard-access validation. No shortcut binding was
verified. Do not silently change the minimum deployment target or ordinary
Command-C behavior.


The complete lifecycle and edit-impact contract is recorded in
[Notes monitoring and session association](NOTES_MONITORING_CONTRACT.md); the
implementation-critical rules are repeated here so this plan remains self-contained.
Use one monitor per captured NoteID shared by its open workspaces, not an independent
poller for each session. Preserve stored anchors for inactive workspaces so their
next reopen can verify association against the latest note.

The proposed visible-window cadence is five seconds, checking only the captured
note's identity/existence and modification date. Add a metadata-only read operation:
do not fetch the HTML/plain-text body, enumerate the library of notes, or parse/tokenize
the note on an unchanged tick. Metadata polling is local Notes Automation, not an
API/model request. Verify metadata-only behavior and timestamp responsiveness on
the host; the checkpoint proved full reads, not this optimization.

Fetch the complete captured note when metadata changes or the cache is missing/
invalid, and on initial/resumed entry. Native sampling now demonstrates two body
transitions with identical native dates. Candidate safeguard: validate body/id/date
for chat, diff and checked-copy, sharing only reads that cover each request and
reusing parsing/diffs when unchanged. Keep idle polling metadata-only, with no
prompt-only exception. The injected coordinator passes 15/15 tests, not production
scheduling acceptance. Full reads of a 1,000-line native fixture took 0.227–0.376
seconds; twenty metadata reads took 1.939 seconds. Copy interaction still needs
coach approval. Cache the raw body and
supported formatted/session representation by note identity and content digest;
if the body is identical, reuse parsed ranges, diff, and context rather than compute
them again. Cache request-ready note text; do not tokenize it repeatedly on polling
ticks. This does not authorize silent truncation of a large note.

Coalesce rapid change observations into one body fetch after a proposed 500 ms
quiet interval, with a two-second maximum delay during continuous editing. Allow
only one read in flight for a note, shared across its workspaces; merge
polling/focus/prompt refresh requests
and discard out-of-date completions. Consumer freshness requests have priority over
idle work and await a validated observation; stale data is not declared fresh to
save work. Whole-copy has a bounded warn-and-export fallback; chat pauses when
fresh context cannot be assembled, and diff labels cached observations last-known.
Check metadata immediately on app reactivation. Suspend the timer while hidden or
the computer sleeps; reread automatically on resume. Back off after failures while
showing the unavailable/last-checked state, and retry on reactivation or a prompt.
No background note reads when no workspace is open and no background model calls.

Compute association updates and diff/reconciliation after a changed Notes body;
scratchpad revisions update their own comparison against that observation, not the
other workspaces. A relevant automatic read can mark a verified match after manual paste;
an edit to a different note cannot. Changes elsewhere in the captured note update
surrounding context only when the session remains reliably associated. A changed or
duplicate target is shown without overwriting the scratchpad. Reading/diff work is
off the UI thread and does not block typing or Copy. If metadata is unreliable on a
supported host, stop for a scoped fallback decision rather than silently polling
entire large notes every five seconds.

### Monitoring lifecycle and edit impacts


The Program session branch captures one selected note; ordinary autocomplete does
not monitor. Workspace entry/resume requires a full read. Prompt submission, diff,
and whole-copy share metadata/cache freshness validation and conditional body reads.
Visible idle ticks and app reactivation check metadata and fetch changed content
automatically. Scratchpad edits and partial-text copying require no Notes reads;
whole-copy warns about external edits before/with completion, and the diff uses a
validated or explicitly last-known observation. Manual paste is discovered
by ordinary monitoring. Hiding the last visible workspace for a note, closing,
sleeping, or quitting suspends timer reads; resume performs a full read. Failed
reads back off and preserve last-known status; no old completion can satisfy a
consumer's freshness requirement merely because another read was in flight.

When surrounding/other-session text changes, refresh context and offsets while
preserving this scratchpad. When the target's text changes under reliable boundaries,
show the diff, preserve the confirmed baseline, and recognize a verified match when
appropriate. Renaming/reordering/inserting headings changes location evidence, not
SessionIDs. Bulk renumbering resolves the captured note's saved associations as a
set: retain baselines, find verified one-to-one matches, and ask for concise mapping
confirmation where evidence is insufficient. Do not silently create workspaces,
rewrite scratchpad headers, or bind by ordinal/new label. Detect duplicates for
coach correction, but run the same set-level checks after the fix. Deleted, split,
merged, or ambiguous sections retain their scratchpads and pause dependent requests/
reconciliation until associated reliably. A week edit within a lettered session does
not create another session identity. Selection changes never retarget the monitor.

Only a verified text/format match or explicit baseline decision advances the
confirmed Notes baseline. Label-only association updates need not change scratchpad
text; show its old heading versus the new Notes heading in the diff. A relevant
Notes change during a response marks its context changed without restarting it.
The next request must use the latest reliably associated observation. Partial
confirmation cannot bind two stored sessions to one section or lose a closed
workspace's association. Automatic refresh never means automatic merge.

Preferences use a versioned local read-only profile with wording, provenance, and
authored/confirmed/inferred status. Package the Training Philosophy, approved seed
table, and already-conducted research privately; commit only empty/synthetic schema
examples. The coach can inspect sources but not edit/remove/confirm preferences.
The assistant cannot write the profile. For exercise decoration, render candidate
mention spans as confirmed library match only after existing exact lookup; otherwise
say no confirmed match. Mention detection and identity lookup are separate. Neither
model-provided IDs nor inferred similarity are authoritative. No popup actions,
alias writes, history retrieval, or new-library additions from chat in this slice.

## Plan of Work


### Milestone 1 — Prove association and rich handoff before dependent work


Extend the isolated `spikes/session-scratchpad/` fixture tests, not production
behavior yet. Use the proposed boundary and confirmation contract in
[the monitoring contract](NOTES_MONITORING_CONTRACT.md#proposed-executable-association-contract).
Test unique numbered headings, a lettered Session A with Weeks 1–3,
and repeated week labels under separate unique session parents. The whole lettered
session remains one scratchpad. Duplicate peer session labels must expose a heading
issue; after the coach fixes it in Notes, preserve/revalidate the same workspaces
even if the fix renumbers the whole sequence. Test several saved workspaces, closed
ones included: unique unchanged bodies can verify one-to-one mappings, while
identical/empty or also-edited bodies require confirmation. Do not make elaborate
malformed-note recovery a requirement, but do not weaken stable-ID preservation.
Test inserted earlier sessions, moved/renamed headings, and changed target content:
unambiguous updates work, unclear association pauses dependent operations without
losing text. Test the range preview for unstructured sessions. Add hierarchy-aware
fixtures with higher-level session/lower-level warmup headings, misspelled session
titles, and trailing peer-level Parking Lot inclusion. Test keyboard boundary
adjustment, skeleton exclusion and preservation of edits on scope changes before
claiming these corrected rules work. The existing 39 passes remain evidence for
the narrower prototype, not the new rules. Record evidence before
completing PLAN 011's outstanding session-association item.

Use the native attributed-text editor to export and manually paste Heading,
Subheading, bold exercise labels, and bullets into the synthetic Notes fixture.
Inspect Notes' formatting menu and press Return to verify a real continuing list.
Test editable text after paste, not just appearance. RTF alone is not acceptable;
try explicit HTML heading/list styling or another native rich representation and
retain failed expectations. Stop for review if full fidelity cannot be achieved
without weakening the approved rich-text requirement. Record supported host/version.

### Milestone 2 — Build the offline persistent workspace


Add typed session/context state and snapshot storage under the new targets. Test
versioned secure archive decode, atomic replacement, previous-valid-snapshot recovery,
interrupted writes, save failure, and one active controller per workspace. Expose
inaccessible/corrupt files without overwriting them. Add the Program session branch
to the existing chooser/result enum and Service switch, returning before window
work. Add explicit Notes permission onboarding and captured-ID rereads. Verify the
production app bundle, not only the probe, on a synthetic note.

Build one native rich-text editor and margin conversation using a deterministic
fake provider. Implement new-session headings-only initialization, local save state,
close/reopen, quiet conversation navigation, freshness warnings, the copy icon and
menu command, standard selection copy, and the diff toggle. Implement metadata-only
monitoring with injected readers/timers and content caches; automatic comparison
replaces a user-invoked Check Notes action. Define the reader protocol in the workspace
target and implement it in the macOS target. Exercise association, registry,
freshness/cache-validity and baseline policy in Foundation-only tests with fake
snapshots/readers; native scheduling and the window delegate decisions to that logic.
Do not register/install the updated
Service until the current implementation
task authorizes it. A fake response must demonstrate the actual revision/context it
received without exposing private content in logs. The offline checkpoint proves
editing/recovery and permission behavior, not model usefulness.

### Milestone 3 — Connect assistance without adding editing powers


Before API-backed edits/tests, use the available API-key setup mechanism and official
OpenAI documentation skill. Choose the exact model and maximum request/output and
trial-spending limits with the user. Propose macOS Keychain for the user's key,
locally owned conversations, explicit `store: false` Responses requests, no hosted
conversation objects, no background calls, and no automatic billable retries.
These provider defaults require approval; do not assume credentials or account
controls are already available.

Keep the API adapter replaceable by the fake provider. Build immutable request
context from note/session/scratchpad revision/profile version/conversation. Treat
note and profile content as context, not instructions authorizing tools or mutations.
The assistant returns text only. Capture failures and cancellation without modifying
the editor or losing the submitted question. Do not log keys or note bodies.

Retain the complete note locally and make context-size failure visible; initially
stop oversized requests rather than silently truncating the note or substituting a
transcript summary. A user-approved reduced-context strategy would be a subsequent
decision. Add a read-only preferences view and exact-identity exercise decoration.
Keep sentence-level conversation refinement free-form; no required intent taxonomy.

### Milestone 4 — Demonstrate the whole writing loop and regressions


After deterministic tests pass, conduct bounded synthetic live API trials under the
approved spending limit. Half-plan a session, close/relaunch, resume the same text,
ask about B2 using earlier block context, edit during a response, and ask again.
Copy/paste the correct Notes session; observe automatic matching and inspect the
diff without a manual refresh action. Change Notes externally and switch its
selection during use. Verify no target switching, data loss, false synchronization,
library writes, or profile mutation. The coach judges usefulness, not only whether
an HTTP request succeeded. Run the existing autocomplete/link/create/review flows
unchanged. Stop at a review checkpoint before changing slice sequencing or shipping.

## Concrete Steps


Commands below run at repository root of the approved implementation checkout,
which must contain the learner Service interfaces named above. First inspect status,
current branch, and plan identifier usage. Do not assume this reusable design
worktree is that checkout. Create/synchronize branches according to `AGENTS.md` only
after the user chooses the execution stream. Never copy private learner artifacts
into reusable main.

    git status --short
    rg --files Sources Tests app docs/decisions docs/exec-plans
    swift test
    swift build --product GymAssistantNotesService

After adding the new modules, run their deterministic tests and the full suite:

    swift test --filter GymAssistantWorkspaceTests
    swift test --filter GymAssistantMacOSTests
    swift test
    BUILD_ROOT=/private/tmp/gym-assistant-session-scratchpad app/notes-service/build.sh
    plutil -lint app/notes-service/Info.plist
    git diff --check

Expected: test commands exit 0 with no failed tests; the build script reports a
signed app path and a valid plist. Record actual test counts, not invented targets
passing before they exist. Build does not install/register the Service or prove
Notes permission. Launch and interact with the app/Notes through approved native
computer use; request production consent explicitly when needed. Use a uniquely
labeled synthetic note, never overwrite a real program to demonstrate acceptance.

## Validation and Acceptance


Verify that GymAssistantWorkspace has no dependency on GymAssistantMacOS, AppKit,
or ApplicationServices. Its reader contract uses Foundation-only snapshots/errors.
With a fake reader and no Notes process, workspace tests must exercise registry
updates, association ambiguity, cache validity, changed/unavailable observations,
and baseline preservation. Native coordinator/window tests assert that observations
and coach commands use those same workspace decisions rather than reimplementing
rules. This verifies the existing boundary, not a new user-facing capability.

These are proposed criteria requiring approval, not modifications to existing
active-slice success criteria. A routine latest-session entry takes at most two
local key actions after Option-Command-G; ordinary autocomplete still inserts,
cancels, and opens Library Review correctly. Duplicate headings and changed anchors
cannot resume the wrong session or create a competing scratchpad silently.
Duplicate peer session labels expose the issue and resume after coach correction;
they do not require a sophisticated ambiguity-recovery engine. A lettered session
containing three weeks is retained as one scratchpad with intact progressions.
Bulk renumbering preserves all WorkspaceIDs/SessionIDs and scratchpad contents,
including closed workspaces. Old label 13 must not attach its workspace to new label
13 when that section belongs to old 12. Verified mappings are one-to-one; identical/
empty or substantially edited sections trigger confirmation rather than a guessed
numeric shift. A transient duplicate during correction never creates or discards a
workspace. Heading changes alone never rewrite the scratchpad.

Higher-level session headings and lower-level Warmup sections inform boundaries;
a misspelled title must not be silently swallowed. A trailing Parking Lot stays
visible/editable with the final scratchpad without becoming a session or seeding
a new skeleton. Coach adjustment is always accessible through compact controls
and discoverable keyboard commands; stale/overlapping ranges are rejected and
scope changes cannot discard coach edits or replace scratchpad content. Shrink
into edited/added/deleted or uncertain regions is blocked, not confirmed away.
Expansion previews only new edge content; abutment identifies the owner and overlap
is refused. Undo content/range together, with stale/occupied restoration refused.

Closing/reopening and orderly quit/relaunch restore exact scratchpad text, supported
formatting, revision, and conversations. Fault injection during a save preserves
the last acknowledged saved snapshot or its valid backup, with a visible recovery
warning. Offline, permission failure, and API failure retain editing and rich Copy.
An unsaved crash interval is disclosed rather than called lossless recovery.

Fake-provider tests assert that a follow-up uses the latest revision and surrounding
whole-note context, not the older recorded session. Mid-generation editing produces
Scratchpad changed and leaves the editor usable. Visible external Notes edits are
flagged automatically within one completed metadata/body-refresh cycle, nominally
five seconds plus the bounded coalescing/read time when available. Slow/failed reads
expose freshness limits rather than claim that timing. With a cached unchanged large
note, 20 scheduled ticks perform metadata reads only: zero body reads, reparses,
diff recomputations, tokenization passes, or model calls. A user prompt forces a
metadata/cache freshness check, not an unconditional body read. Diff and whole-copy
use that same check; uncertain timestamp state requires the same additional body
validation for all consumers. Rapid edits produce at most one in-flight
read and bounded coalesced refresh; hidden/sleeping workspaces make no timer reads.
Two open workspaces for the same note share metadata/body reads rather than doubling
them. A monitor validates all stored associations affected by renumbering, not just
the visible editor's association.
Use synthetic multiweek notes and a large fixture (for example 1,000 program lines)
with reader/computation counters to verify costs; record measured timings, not a
promise derived from token length. Failed/stale reads cannot set a false matched
state, and opening a diff never triggers an API/model call.

Rich copy/paste preserves Heading, Subheading, bold, and native continuing bullets
in Notes through the copy icon/whole-scratchpad shortcut and editor Command-A/
Command-C. The shortcut is discoverable in the menu without mouse movement.
Copy alone never indicates saved/matched; automatic Notes monitoring verifies the
correct session or stays not verified. The diff toggle shows current or explicitly
last-known Notes versus the scratchpad in place of the editor, without requiring a
Check Notes control or losing editor content/undo on return. Heading-only skeletons contain no old exercise/dose/
warmup/result content. Conversations remain accessible after a break without an
extra permanent context/summary panel.

Externally edit the confirmed Notes session immediately before each whole-copy
path: the icon, whole-copy shortcut, and Command-A/Command-C must all warn and offer
the existing diff. A confirmed match must not produce a false overwrite warning.
Read failure/timeout warns without losing the scratchpad or falsely verifying paste.
Partial-text/chat copy never invokes Notes. Test copy-preparation timing and rapid
copy/application-switch/paste so the coach can assess old-clipboard risk. Validate
equal-time edit detection and record the chosen shared freshness safeguard before
declaring monitoring accepted.

Confirmed canonical/alias mentions have truthful library decoration; unconfirmed
or ambiguous wording does not establish identity. Profile viewing exposes existing
provenance; chat cannot change the profile or library. Synthetic integration tests
record which inputs were sent, verify no hidden truncation, and exercise API failure
without new automatic charges. Live trials separately establish coach usefulness.

## Idempotence and Recovery


Use a workspace registry to reuse existing session identities and serialize writes
for one workspace; a second window request brings forward its existing controller.
Never overwrite an unreadable snapshot, import a new schema over it, or silently
start empty. Keep the prior valid file and report its revision when recovering.
Local snapshots live outside Git under the app's Application Support directory;
keys live in Keychain if that proposal is approved. No automatic deletion or cloud
workspace sync is part of this slice. Back up before any later schema migration.

Repeated synthetic runs may replace only their named temporary fixtures. Keep failed
capability results; do not weaken tests to match lost formatting. Revoke/read failure
does not switch to broad Accessibility or private Notes database access. Keep the
scratchpad, stop claims of current Notes context, and allow explicit retry or Copy.
Quit cancels work and flushes saved state; a retry after API uncertainty is deliberate
and may incur another charge. Do not infer a successful response after timeout.

## Artifacts and Notes


See [the independent CLI review assessment](SESSION_SCRATCHPAD_REVIEW.md) for the
fresh-process context boundary, findings, dispositions, and remaining capability
versus offline-implementation gates. Review is not implementation authorization.


Keep sanitized capability outcomes in `docs/design/SCRATCHPAD_CAPABILITY_CHECKPOINT.md`
and architecture boundaries in `docs/ARCHITECTURE.md`. Preserve the six frozen mockups
unchanged. Private philosophy/seed/source documents remain separate from reusable
Git artifacts. Show the coach native evidence and resulting text, not just compile
logs. Record exact verification commands, host/version, limitations, and spend for
approved live trials. Tutorial progress and reflections require their own approval.

Provider guidance checked with OpenAI Docs on 2026-10-12: manual conversation state
can be supplied per request; `store: false` disables response-object storage, but
does not promise zero provider retention. Abuse-monitoring logs may retain customer
content under the account's applicable controls. The implementation must not claim
that deleting local workspaces deletes provider logs. See official
[conversation state](https://developers.openai.com/api/docs/guides/conversation-state)
and [data controls](https://developers.openai.com/api/docs/guides/your-data).
Recheck account/model-specific requirements at the provider checkpoint.

## Interfaces and Dependencies


Use Foundation, AppKit, ApplicationServices for Notes Automation consent, Security
for Keychain if approved, and URLSession for provider transport. No new third-party
package is required by this proposal. Add injectable boundaries so tests do not read
real Notes, touch the normal clipboard, or make paid requests.

In `Sources/GymAssistantWorkspace/SessionWorkspace.swift`, define explicit wrappers
for WorkspaceID, SessionID, and NoteID; a NoteSnapshot with identity/body/date;
SessionAnchor with stable local SessionID, baseline range/content/structure,
mutable recorded heading, and adjacent-context evidence; and
WorkspaceSnapshot with schema version, IDs, archived rich-text Data, revision,
conversation records, baseline, and reconciliation freshness state. Retain native
heading-hierarchy evidence and coach-confirmed boundary choices; parking-lot
inclusion is attached-context policy, not a new SessionID. Do not implement exact
Session-word matching as the full approved boundary rule. NoteID remains an opaque value;
range is an offset within one snapshot only. Do not treat it as stable after edits.

In the same module define `SessionAssociation.resolve(anchors:in:)` over all stored
anchors for one NoteID, returning verified one-to-one mappings, duplicate-heading
issues, unresolved confirmations, or unavailable. The registry applies verified
mapping sets without keying by mutable labels or overwriting unresolved anchors.
Also define
`ProgramContextAssembler.assemble(note:workspace:profile:conversation:)` returning
an immutable request or an explicit context problem. A profile record includes its
source reference and confirmation status, not just an instruction string.

In `Sources/GymAssistantWorkspace/NotesContextReading.swift`, define the read-only
NotesContextReading protocol with capture-selected-note and read-captured-ID
operations, a metadata-only read by captured ID, and typed permission/selection/
not-found/read errors. Define shared snapshot/metadata/error types in this module,
without native scripting objects. Metadata returns identity/existence/date without
requesting body or plaintext. In `Sources/GymAssistantMacOS/NotesContextReader.swift`,
implement that protocol using Notes Automation; translate native results/failures
at this boundary. A fake reader implements the same workspace-owned protocol.

Workspace logic owns the per-note registry, association results, current validated
observation/cache digest, freshness/read status, and confirmed baseline decisions.
It decides when metadata is insufficient and a body read is required, when an
observation is stale, and whether association or baseline can advance. The shared
macOS NotesRefreshCoordinator owns native cadence, coalescing, one-in-flight read
execution and subscription delivery, delegating those decisions to workspace logic.
Do not keep an independently authoritative registry or baseline in the coordinator
or a window. Inject readers/timing so tests count metadata/body reads and derived
work independently; no monitoring method depends on the assistant provider. Serialize native
read work off the UI thread with bounded waits; discard stale completion results.
Selection capture happens only for the chosen workspace branch, before the long-
lived window opens, and does not wait for network work or hold a consent dialog
inside the Service. Reject a non-Notes invocation rather than infer a target.

In `Sources/GymAssistantMacOS/WorkspaceSnapshotStore.swift` and
`ScratchpadRichTextExporter.swift`, implement separate secure archive storage and
clipboard export, with test pasteboards injectable. In
`SessionScratchpadWindowController.swift`, own the NSTextView, compact chat view,
warnings, copy icon/menu command, standard selection-copy export, and read-only diff
toggle. Present workspace-owned registry/freshness/association state and dispatch
coach commands to workspace logic; do not implement mapping, cache-validity or
baseline rules inside the view controller. The executable composes and shares the
workspace registry and per-note coordinator across windows. The assistant boundary
accepts immutable context/revision and returns text plus request status; fake and
OpenAI adapters implement it. Exercise decoration calls existing exact library
lookup through a read-only dependency and never exposes library write methods.

Revision note, 2026-10-12: initial proposal records accepted product/adapter choices
and labels new session association, native storage, entry effort, polling, handoff,
and recovery defaults for review. It does not approve implementation, model/spend
settings, or a change to the active tutorial/workstream sequence.

Revision note, 2026-10-12, review response: defined the new Program session command
and existing Library Review command explicitly. Replaced separate Copy/Check Notes
buttons with a floating copy icon, discoverable whole-scratchpad shortcut, ordinary
selection copy, and an automatically refreshed diff toggle. Added metadata-first
monitoring and proposed unchanged-large-note validation. Duplicate session headings are
coach-corrected mistakes rather than a required recovery subsystem. The user chose
one scratchpad containing the full lettered session and all three weeks. These
changes do not approve the remaining plan, implementation sequence, or API spend.

Revision note, 2026-10-12, follow-up review: added the monitoring trigger/edit-impact
contract and corrected the assumption that coach heading fixes are necessarily
local. Bulk renumbering changes labels, not workspace identities. Reassociation is
verified one-to-one across all stored workspaces for the captured note, with concise
confirmation when content cannot distinguish them. Monitoring reads/caches are
shared per note. No production implementation or new visual was created.

Revision note, 2026-10-12, copy/freshness review: whole-copy now performs the same
Notes freshness validation as chat and diff, with baseline-based external-edit
warnings and a bounded not-verified export fallback. Partial copy remains ordinary.
Replaced unconditional prompt-body reads with an explicit timestamp/cache evidence
gate and one shared consumer policy. The copy-preparation keyboard race/deadline
must be verified before acceptance. Production implementation is not authorized.

Revision note, 2026-10-12, independent CLI review: corrected an overclaim about
monitoring measurements, clarified validated cached observations, and added the
proposed executable association contract in the monitoring document. The review
assessment distinguishes pre-production capability gates from tests performed
during offline implementation. No new native evidence or implementation approval.

Revision note, 2026-10-13: record the subsequent native checkpoint's partial evidence
and clipboard failure. Full hierarchy, rich-aware anchoring, rapid-edit cache rules
and copy-preflight timing remain pending. The plan is still proposed, not approved.

Revision note, 2026-10-13, side-conversation boundary correction: elevated native
hierarchy to high-confidence evidence, distinguished literal prototype grammar
from intended recognition, retained trailing parking-lot ideas with the final
scratchpad, and added always-available unobtrusive boundary adjustment. Updated
contracts, milestone and acceptance coverage; exact interaction details remain
proposed and scope-change preservation requires design. No code/test/UI state changed.

Revision note, 2026-10-13, coach-approved scope change: shrink cannot cross edited
or coach-added regions; no discard confirmation. Expansion previews only new edge
content, preserving edits. Exact abutment identifies owners; overlap is refused.
Content/range undo revalidates freshness/ownership. The separate synthetic model
passes 24/24; native tracking and the usual-before-editing hypothesis are unproved.

Revision note, 2026-10-13, approved ownership clarification: moved the planned
consumer-facing reading protocol to GymAssistantWorkspace, with macOS implementing
it. Assigned registry, association, freshness/cache-validity and baseline policy to
workspace logic; limited native coordination/windows to execution and presentation.
Updated orientation, milestone, validation and decision/progress records to prevent
reverse dependencies or duplicated rules. Only this proposal changed; no production
code, capabilities, tutorial progress, or overall implementation approval changed.

Revision note, 2026-10-13, continued capability execution: record observed native-date
collisions and candidate shared body validation, large-note costs, native hierarchy
fixtures and delayed-copy race. Tested public exports do not preserve Subheading.
The capability report originally proposed explicit checked-copy versus ordinary
immediate copy and a public-format/manual-style fallback. The subsequent approval
below supersedes only the copy distinction. Native UI/edit tracking, private-format
dependency and production work remain gated.

Revision note, 2026-10-13, checked-copy approval: record the accepted explicit checked
command versus immediate Notes-unverified ordinary copy. Propose a 500ms target and
1,000ms end-to-end wait limit with warning on timeout; timing still needs approval
and full-path measurement. Exact minimal div/heading public.html paste control is
pending; native-style fidelity has not been relaxed.

Revision note, 2026-10-13, subsequent timing approval and native control: the coach
accepted a 400ms target and 750ms maximum verification wait, with concurrent rich
preparation/publication and continued late verification. This supersedes the
500ms/1,000ms proposal above. The exact div/h1/h2/h3 public.html control was tested
and produced bold Body paragraphs, not native heading styles. The synthetic note
was restored. Full-path timing, native-style fidelity fallback, and requested
late-conflict clipboard replacement remain unresolved as recorded in the capability
checkpoint and monitoring contract.

Revision note, 2026-10-13, selective transfer: the coach clarified that a late
conflict may replace the entire clipboard with a warning only while the exact copy
operation still owns it; any intervening copy, even identical text, requires an
app-only warning. Native ownership and guard/write tests remain necessary. The
synthetic Notes Paste as Markdown control retained native heading tiers, bullets and
bold on this macOS 27 host. The coach chose to pursue that handoff direction; faithful
serialization, keyboard and platform behavior, timing, and production acceptance
remain open. This note supersedes the unresolved clipboard statement above without
erasing its historical decision context.
