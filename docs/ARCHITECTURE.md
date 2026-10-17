# Architecture

## ChatGPT subscription connection checkpoint

`GymAssistantOpenAI` contains authorization, model discovery and a subscription
`ProgrammingAssistant`, exercised by `ChatGPTConnection` and an opt-in synthetic
development window. The installed Service still uses the fake provider. Browser OAuth uses PKCE, state and
nonce; identity verification checks the OpenAI signature and bound claims before
accepting credentials. App-owned credentials live in macOS Keychain, separately from
workspace files and Codex credentials. Registration/refresh is serialized across
processes. Connection commands send no Notes/profile content; the explicit synthetic
trial makes inference calls using 5.6 Terra medium. The adapter validates a 100 KB
whole-request text bound, reserves attempts durably in Keychain, and requires a
completed stream event plus a valid reply before updating conversation text. No
automatic retries or API-key fallback. Four attempts have yielded no completed reply.
Usage-check unavailability is distinct from an exhausted allowance; diagnostics
separate known provider codes from local format rejection without exposing raw
provider messages. PLAN 013 records remaining live/native/production validation.

Status: the Notes adapter direction is validated by ADR 001. The initial
exercise-identity persistence boundary, deterministic normalization and
normalized-name lookup, scored candidate generation, explicit suggestion
confirmation, read-only autocomplete
search, empty-cursor Notes autocomplete interaction, and the reusable exercise-
identity review core are implemented. Library Edit, alias splitting, directed
merges with old-ID redirects, and CSV import are implemented in the local feature
worktree, with automated verification and an isolated synthetic-data foreground
keyboard/Notes trial. Visual layout review and release remain outstanding.
Search-query transformations, blocks, tendencies, and
client history remain later slices or design hypotheses.

Observation ingestion is separated from identity review by
[ADR 002](decisions/002-non-blocking-observation-ingestion.md). The complete source
may be stored with provenance while identity decisions remain incremental,
dismissible, and resumable.

## Architectural principle

Apple Notes is an input/workspace adapter. It must not contain the core business logic.

Conceptual structure:

    Apple Notes --> AppKit macOS Service adapter --> Exercise Search --> Exercise Library
                       |                                  + Durable Name Knowledge
                       +--> selected-text hygiene -----------------------+
                                                                         |
    Personal-library source ------+                                      |
    Completed program(s) later ---+--> Observation Ingestion/Store ------+--> Exercise Identity Review
                                  |                                              |
                                  +--> Exercise-observation extractor (later)    +--> Resolver evidence
                                                                                 +--> Exercise Library writes

    Manual library-edit workflow --> Exercise Library management of existing IDs

    Saved Blocks / Programming Tendencies / Client History (later)
        reference stable Exercise Library identities

## Boundaries

### Notes integration layer
Responsibilities:
- receive selected text or an empty-cursor invocation
- invoke library/search workflows
- display a lightweight chooser
- optionally return replacement/insertion text
- preserve the selected range, cancellation integrity, and natural focus return

Must not own:
- duplicate matching logic
- canonical identity rules
- persistence rules

The adapter direction is accepted in [ADR 001](decisions/001-notes-integration.md). The Exercise 02 spike validates the AppKit Service/pasteboard interaction shape but is not production code. The local development Service now uses Option-Command-G; packaging, durable signing, external distribution, and identical-text feedback remain open implementation concerns.

The `GymAssistantNotesService` executable is wired to the real core workflow and
Application Support SQLite library. Its `Gym Assistant: Review Selection` entry
performs deterministic bypass, explicit identity review through a Link Existing
action, and same-panel new-exercise creation. Its separate `Gym Assistant` entry
supports empty-cursor autocomplete: focused query input, at most five identity-
deduplicated results, keyboard alternate-name expansion, exact cursor insertion,
raw-query
fallback, and cancellation without writes. The Service owns no ranking or identity
rules. Packaging, signing, and distribution outside the local development install
remain open concerns.

### Exercise library
Responsibilities:
- stable opaque exercise identity
- durable exercise names owned by one exercise identity
- exactly one owned preferred/default name per active exercise
- nameless merged exercise records retaining old IDs and redirecting to active identities
- globally unambiguous exact normalized-name ownership

SQLite schema version 4 uses lifecycle CHECK constraints, a deferred composite
foreign key for active preferred-name ownership, redirect foreign keys, and guards
against names owned by merged records. Existing v1–3 databases are rebuilt in one
transaction only after a read-only preflight and verified SQLite backup, stored
beside the original with a unique pre-v4 filename and owner-only permissions.
Known v4 opens perform no migration DDL. Human-facing autocomplete shows the
winning name, not technical IDs or the internal preferred designation.

The library's current normalizer is deliberately minimal and supports only the
normalized-name lookup persistence contract. Fuzzy similarity may rank review
candidates but cannot establish identity. Semantic name-ownership inference,
contextual ownership, variant
relationships, program/client context, taxonomy, and history remain outside this
boundary.

### Resolver
Responsibilities:
- deterministic normalization
- normalized-name lookup across all durable exercise names
- scored candidate generation with supporting evidence
- candidate relationship policy
- workflow-independent resolver results

The resolver layers are:

    Input text
        |
        v
    Deterministic normalization
        |
        v
    Normalized-name lookup across all durable exercise names
        |
        +-- match --> Exercise identity
        |             evidence: normalized-name match
        |             score: 1.000
        |
        +-- no match --> Scored candidate generation
                             |
                             +-- lexical similarity
                             +-- morphological similarity
                             +-- explicit equivalence rules
                             |
                             v
                        Candidates scored below 1.000
                             |
                             v
                        Candidate relationship policy
                             |
                             +-- linkable
                             +-- compatible prescription difference
                             +-- protected/non-linkable conflict

Deterministic normalization removes only differences that are guaranteed cosmetic.
It is limited to case, whitespace, and one trailing period or exclamation point;
other punctuation remains meaningful. For example, ` FRONT   SQUAT! ` and
`Front Squat.` normalize to the same lookup key. Normalization does not
singularize words, correct spelling, expand abbreviations, or encode exercise
vocabulary.

Normalized-name lookup compares that key with every durable exercise name. A
preferred name and an alternate name are the same persisted kind of name; the
preferred flag only selects the default display and insertion wording. A lookup
match returns the owning exercise identity with `normalized-name match` evidence
and score `1.000`.

Scored candidate generation runs only when normalized-name lookup finds no match.
Each generated candidate carries the evidence supporting its score. Lexical
similarity covers token overlap, containment, prefix similarity, and edit
similarity. Morphological similarity covers narrowly scoped linguistic forms such
as `Jump` and `Jumps`. Explicit equivalence rules cover reviewed vocabulary such as
`DB` and `Dumbbell`, `1-legged` and `1-leg`, or `Australian Row` and
`Aussie Pull-up`. Approval of such a rule authorizes candidate scoring, not durable
identity. No non-authoritative signal or combination of signals may score `1.000`;
the shared scorer caps such results below `1.000`, and the fixture harness reports
an authoritative-score leak if a review candidate reaches the reserved score.

Candidate relationship policy annotates or constrains a generated comparison; it
does not manufacture similarity. A compatible prescription difference, such as
`Touch-Down with 5 sec negative` versus `Touch-Down`, may remain linkable while preserving the
observed wording as a durable selectable name. A protected identity conflict, such
as `Lateral Lunge` versus `Reverse Lunge`, is excluded from ordinary suggestions or
shown explicitly as non-linkable evidence in an identity-review interface. The
fixture harness reports a protected candidate leak separately from an automatic
false merge.

Representative layer contracts and fixtures are:

- deterministic normalization and normalized-name lookup: `Front Squat!` matches
  stored `Front Squat`; ` FRONT   SQUAT ` matches stored `Front Squat`; a stored
  `SL RDL` alternate name returns its owning exercise
- scored candidate generation: `Paloff Press` suggests `Pallof Press` from lexical
  evidence; `Box Jumps` suggests `Box Jump` from morphological evidence;
  `Australian Row` suggests `Aussie Pull-up` from an explicit equivalence rule
- candidate relationship policy: `Touch-Down with 5 sec negative` and `Touch-Down` carry a
  compatible prescription annotation; resistant RNT/base, short-/long-lever Copenhagen,
  and `Lateral Lunge` versus `Reverse Lunge` carry a
  protected, non-linkable conflict

The morphology examples and any new explicit equivalence rules describe the
evidence category and required fixture behavior; each rule still requires separate
approval and implementation before the resolver uses it.

An explicit confirmation boundary turns an accepted suggestion into a durable
exercise name through the library's existing ownership-checked persistence API.
Rejection performs no write. The next lookup of that observed wording therefore
uses normalized-name lookup rather than scored candidate generation.

The resolver supplies identity evidence about wording that already exists. It is
separate from autocomplete search, which retrieves an exercise for insertion and
does not by itself create identity knowledge.

The workflows interpret the same resolver results differently:

                              Shared resolver
                                    |
            +-----------------------+-----------------------+
            |                       |                       |
            v                       v                       v
    Autocomplete search      Selected-text flow      Import/completed-program
                                                     observation processing

    Normalized match         Normalized match        Normalized match
    ranks first at 1.000     resolves without        recognizes the existing
                             opening review          exercise and avoids review

    Other candidates         Other candidates        Other observations enter
    rank below 1.000         enter identity review   identity review
            |                       |                       |
            v                       +---- Link/Create/Defer-+
    User selects wording
    for insertion; no
    identity write

Here, exercise identity review means the interactive Link, Create, or Defer
decision workflow for unresolved observed wording. Normalized-name lookup is a
resolver operation used before that interaction, not a separate workflow.

For example, in the **import or completed-program observation-processing
workflow**:

    Observation: Box Jumps
        |
        v
    Deterministic normalization
        |
        v
    Normalized-name lookup: no match
        |
        v
    Scored candidate: Box Jump
    evidence: morphological similarity plus lexical similarity
    score: below 1.000
        |
        v
    Exercise identity review: Link / Create / Defer

### Autocomplete search

The core autocomplete search reads all durable exercise names from the library and
returns at most one result per stable exercise identity. A normalized-name match
ranks first with score `1.000`; all other scored candidates rank below it. A result
exposes the preferred/default name and the exercise's other durable names so the UI
can insert any of them deliberately. Search performs no library writes. Search and
identity review use the same underlying scored candidate generator and explicit
equivalence evidence. Autocomplete may display candidates at a lower minimum score
than identity review because selecting a search result inserts wording but does not
create a durable name relationship. Known protected identity conflicts are
excluded by both. New equivalence rules require separate evidence and approval
before becoming part of the shared generator.

Empty-query and unmatched-query insertion behavior belongs to the application/UI
workflow, not this domain search component. Autocomplete is fully read-only: Return
inserts the selected durable name, and no autocomplete search or insertion changes
the internal preferred-name pointer. Explicit creation, identity review, and
confirmed Library Edit operations own durable identity writes. Splitting a
preferred name repairs the original default deterministically without a chooser.

### Exercise identity review

Responsibilities:
- accept an observed exercise name with source and provenance
- use normalized-name lookup before opening review
- gather scored candidates with visible supporting evidence for unresolved wording
- expose meaningful modifier conflicts instead of hiding uncertainty
- support explicit link, create, and defer decisions
- apply approved identity writes through the exercise library's persistence boundary
- preserve enough decision provenance and deferred state for later audit

The review component coordinates evidence and authoritative user decisions. A
normalized-name match recognizes an existing identity without opening interactive
review or writing a new name. Scored similarity, morphology, explicit equivalence
rules, prescription relationships, and AI-produced source files may surface
evidence but cannot establish identity.

For a staged observation, the implemented decisions are Link, Create, and Defer.
Link adds the preserved observation as an `importedConfirmed` name through an
ownership-checked transaction. Create accepts no editable name and makes the
observation itself the sole initial preferred name, preventing semantic drift
during review. Defer persists the unresolved observation and evidence snapshot
without changing the exercise library. The current learner implementation still
contains a legacy `Keep Separate` operation for two existing exercise IDs. It is
not part of the library-edit direction and is scheduled for removal in a later,
focused cleanup; it must not be used as an import or library-edit decision.

Resolver fixture category and human-review disposition are independent.
`MUST_NOT_MATCH` continues to prohibit automatic identity. The review policy may
still expose tempo/negative wording as linkable with confirmation, preserving
the full name. Execution progressions such as short-/long-lever Copenhagen and
resistant RNT/base names are non-linkable under ADR 004. Existing confirmed
aliases remain authoritative; this revision performs no cleanup or migration.
Fixture-established identity conflicts, such as lateral versus
reverse lunge, are visible but non-linkable. There is no separate Exercise Family
entity; the stable Exercise and its durable names are the current grouping
envelope.

`AliasIdentityGuidance.text` is the shared policy copy; AppKit `AliasPolicyHelp`
shows it in transient info popovers in Edit, Merge target selection and Import
Review. The labeled control has a tooltip and Command-Shift-/ access. It changes
no query, selection or durable state; UI acceptance is recorded in PLAN-011.

The identity review is independent of the source adapter. Its first adapter stages
a personal-library source. Import and completed-program adapters supply durable
observations to the same non-blocking queue and preserve their own ingestion record,
occurrence evidence, and provenance. Pending or deferred observations do not enter
autocomplete and do not block program writing. The reviewer may dismiss and resume
the queue; each explicit identity decision is independently transactional and
idempotent.

Library Edit exposes Edit Library and Add Exercises as peer routes from
autocomplete, without cross-navigation. Edit uses the ranked search chooser for
exercise and alias selection rather than a dropdown.
Expanded exercise groups are independent. Promotion requires an alias child row.
Merge on a child uses `previewMoveName(nameID:from:to:)`, preserving both active
identities and all other names, with deterministic source-default repair if needed.
Its transaction and exact-preview receipt use the same safeguards as whole merge;
the receipt's typed `moveName` action distinguishes single-name transfer from the
schema-v4 `merge` action family. No redirect is created for an alias move.
Exercise merge search prefills selected wording and retains other already-visible
identities until query editing; a successful edit invalidates those transient
results. Merge target selection is a smaller attached sheet owned by Edit Library,
with its own search/chooser controls, not a peer window or replacement screen.
Escape/Cancel dismisses it without disturbing the parent's query, selection, or
expanded groups. Confirmation attaches to the sheet; success dismisses it and
refreshes the parent. Maintenance messages clear on new navigation, input, or selection.
The combine entry point automatically retains the exercise being edited; choosing
a duplicate opens one confirmation with both name groups attached to the Merge sheet.
There is no comparison screen or user-facing source/survivor choice. The retained
ID and default name are unchanged; the duplicate's old ID redirects to it.
Add Exercises contains creation from scratch and Import as a suboption. Review candidates is an Import
child and uses the single To review / Skipped observation queue. Import's badge
counts unresolved pending observations across sources, excluding Skipped and
already-confirmed exact names. Refresh it from durable state on view entry and
after ingestion or identity/review changes. Both routes
use the same Service-return and standalone-window handoff as the current review
window; no parent-child relationship between Edit Library and Add Exercises is
required. Import and Review preserve the Add session's draft input in memory.
Review source evidence is disclosed on demand; Undo is the guarded last-decision
transaction reversal, not parent navigation.
Autocomplete query/selection may be retained for orientation, but this handoff
ends the original insertion request. Inline editing, longer Service deadlines,
and window-shim focus experiments belong to deferred PLAN-008.

The complete library-edit design was approved on 2026-10-06 in
[ADR 003](decisions/003-library-edit.md) and
[PLAN-009](exec-plans/PLAN-009-library-edit.md). The storage model moves
names to a merge survivor and retains the former exercise ID as a redirect.
`ExerciseLibraryEditService` prepares read-only typed previews and applies the exact
confirmed preview under BEGIN IMMEDIATE, rechecking a fingerprint of ownership,
defaults, observations, redirects, and prior affected edits. Each edit and its
versioned append-only receipt commit together. Old-ID reads follow chains with
cycle/missing-target detection; writes reject merged selections. Observation Back
records the name it actually created and checks current state before destructive
undo, preserving pre-existing aliases and later edits. Source lines stay in their
original observation store, not edit receipt payloads.

`LibraryImportService` validates CSV counts before ingestion, checks the source
hash again at apply, and reuses the original ingestion reference for duplicate
content, including CLI imports or renamed files. `LibraryMaintenanceNavigation`
keeps only transient routes, drafts, and selection; AppKit uses one standalone
parent window with the existing ranked chooser, an attached Merge target sheet,
and an embedded queue controller. The
code and synthetic tests are implemented, and an isolated keyboard/Notes trial
passed on the development machine. This is not a general focus guarantee or
visual layout sign-off; see PLAN-009 for evidence and limitations. The later legacy Keep Separate
cleanup is recorded in [PLAN-010](exec-plans/PLAN-010-legacy-keep-separate-cleanup.md).

#### Future asynchronous import adapters — do not implement in PLAN-009

Video, image, and feed adapters may accept a source and process it independently
of the window, preserving processing state and occurrence provenance. Results
append source-backed candidates to the same review queue as processing completes;
they never create exercise/name ownership automatically. The Import view will
show processing status separately from its pending-review count and refresh while
open. Durable job/retry/duplicate-handling details belong to later scoped plans.

Video extraction proposes exercise wording and associated start/end timestamps.
Segments remain candidate source evidence until confirmation, then attach to the
durable ExerciseName.id. One alias may have multiple segments; merge/split keep
those associations with the preserved name ID. A separate instructional-video
model ADR and migration precede video import. Image transcription preserves source
and reviewable extraction uncertainty. Scheduled WOD pulls preserve source URL,
workout date, and observed wording as occurrence evidence, using verified access
and idempotent ingestion; workout occurrence is distinct from instructional media.
These directions add no job system, media fields, or scheduling to the current CSV
feature. See docs/OPPORTUNITY_SOLUTION_TREE.md for opportunities and sequencing.

Autocomplete and observation review share one AppKit ranked-candidate chooser for
identity-deduplicated rows, winning-name presentation, name disclosure, selection,
and evidence presentation. The collapsed row displays the highest-scoring durable
name rather than always displaying the preferred name. Expanding it shows every
other durable name without exposing the internal preferred/default designation.
Match reasons use compact labels and the collapsed row reports the number of aliases
without repeating a confirmed-alias label on every durable name. Their controllers
remain separate: autocomplete owns its query and read-only insertion result, while
observation review owns provenance,
queue state, and explicit Link/Create/Skip transactions. Autocomplete begins with
no selected candidate so Return preserves and inserts the query; Down Arrow
deliberately selects the top result. Review may preselect its top candidate because
Link remains a separate explicit action. The chooser reserves Left and Right Arrow
for alias disclosure; review-specific Undo and Skip use Command-Z and Command-S.
An autocomplete request also self-cancels after 105 seconds, before the synchronous
Service's 120-second deadline, so an abandoned chooser returns Notes cleanly instead
of producing a Service timeout.

Gym Assistant starts as an accessory application; the synchronous autocomplete
panel does not change that activation mode. The standalone Library Edit/Add/Import
window promotes it to regular activation while open, so it is Dock/app-switch
eligible. Its bundled `GymAssistant.icns` is generated from the existing branding
PNGs and loaded as the application icon. Dock reopen raises or deminiaturizes the
existing library window without resetting drafts. Window close restores the prior
activation policy. Edit Library is enabled without a selection and opens search.
This maintenance-only change differs from the rejected Task C experiment, which
temporarily promoted it during an outstanding Service to a
regular application, but that caused a distracting launch bounce and still could
not restore Notes after the learner consulted another app. The synchronous Service
request prevents Notes from accepting ordinary programmatic activation while
autocomplete is open. Prior window-ordering attempts did not establish reliable
keyboard recovery. PLAN-008 retains a deferred smaller presentation experiment
(ordinary window or hidden-window shim) before considering asynchronous insertion
and Accessibility. No focus fix has been validated or promoted.
Autocomplete remains owned by the synchronous Notes Service invocation that opened
it. Live testing shows Notes queues another invocation until the first returns and
does not redirect the pending output after a cross-note attempt. Supporting several
simultaneous note-bound autocomplete windows therefore requires a different
asynchronous insertion adapter with a durable note-and-cursor context; it is not a
window-management change and must be spiked before replacing the safe Service path.

The personal-library adapter owns CSV parsing, row validation, source fingerprinting,
and import reporting. It must not own candidate semantics or identity rules. A later
completed-program adapter may use a reusable observation extractor before staging;
that extractor identifies exercise-like wording in mixed program text, preserves
verbatim evidence and location, and makes no durable name or exercise-identity decision.

Library-edit workflows present existing exercise IDs and confirmed aliases for
explicit Merge, alias-move, or alias-promotion operations. Merging IDs that already
own durable names preserves old-ID redirects and remains distinct from linking a
staged observed name; neither operation silently establishes identity.

### Observation ingestion and provenance

Observation ingestion and identity resolution are separate lifecycles. A source
may be ingested transactionally even while some or all observations remain pending.
Later Link or Create decisions atomically update one observation and the exercise
library; Defer records an intentional postponement without creating identity.

One observation can occur in more than one note, import, or completed program, so
provenance must not be flattened into a single adapter/reference string. The minimal
durable relationship is an ingestion record, a staged observation, and one or more
occurrence/evidence records that connect the observation to source locations and
counts. This provenance belongs to the observation workflow, not as additional
required fields on `Exercise` or `ExerciseName`.

Extraction and identity review have different ground truth. Extraction asks whether
and where program text contains an exercise observation. Identity review asks what
stable exercise, if any, owns that preserved wording. Task A extraction decisions
can train and test the future extractor. Task C Link/Create/Defer outcomes can reveal
useful error clusters, but they must not be relabeled automatically as extraction
truth; especially, Defer may indicate identity uncertainty, unsuitable wording, or
an extraction-boundary problem and requires reason review.

The private extractor-feedback exporter joins the Task A extraction audit to all
current Task C observation outcomes by source fingerprint and deterministically
normalized reviewed wording. It reports unmapped audit rows rather than guessing,
includes occurrence provenance and initial candidate snapshots, and publishes a
direct skipped-observation index. Review decisions accumulate in SQLite; the
owner-readable private packet is a regenerable snapshot and never enters Git.

### Blocks
Responsibilities:
- reusable groups of exercises
- display/insertion formatting
- later ranking based on context/history

### Future client history
Must reference canonical exercise IDs rather than exercise-name strings.

## Validated architecture risk

The macOS Service interaction was tested in actual Apple Notes usage on macOS 26.6. The AppKit fallback passed the approved cold, warm, cancellation, integrity, and focus gates; the Automator Quick Action did not satisfy the complete contract.

This supports retaining Notes as the initial workspace while keeping the resolver and domain logic independent. Revisit the decision using ADR 001's falsifiable triggers rather than treating one successful spike as permanent proof.

## Contextual program assistance direction — capability work in progress

New-session creation carries a clearly trailing Parking Lot as idea context while
keeping the previous session body headings-only. The skeleton reports the carried
paragraph count; acceptance revalidates the source and copies that suffix directly
from the imported attributed Notes text, preserving bullet and inline formatting.
Missing/ambiguous sections yield an empty heading. Consolidation is manual in Notes.

Previous planning now reads validated local snapshots and captures retained editors
without saving or stopping requests. It performs one isolated Notes read and builds
a temporary association registry solely to label references; it does not publish
ownership, trigger insertion promotion, or repair associations. Failed Notes reads
leave local records accessible as unverified. Damaged snapshots are not silently
replaced by backups. The native reference window is read-only and uses its own
Copy/Select All menu routing, not the underlying scratchpad's mutation commands.
No extracted-history schema, revision archive or automatic preference learning is added.

Schema 3 adds an optional setAsideAt date. Schema 1/2 records stay active without
eager rewrite; explicit set-aside upgrades only its selected record. Persist the
complete snapshot through validated backup/promotion/reopen before releasing the
registry claim and retiring its controller. Failed saves retain the in-memory claim;
an uncertain post-promotion failure requires reopen/recovery. Set-aside records are
immutable to stale editors and excluded from active ownership and unrecorded resume,
but retain source evidence and appear in Previous planning. No deletion or automatic
reactivation occurs. The older app must reject schema 3 rather than ignore this state.

Explicit Notes replacement rechecks the preview's source paragraphs, verified range
and exact saved/editor snapshot. It saves an independent inactive reference with a
fresh workspace ID and optional preservedFromWorkspaceID before replacing the active
snapshot. Conversation identity, messages and composer stay attached. Only this
explicit operation advances the original comparison baseline. Any uncertain persistence
failure latches the context and locks the editor until reopen; subsequent autosaves
cannot overwrite the uncertain result. Historical references survive backup rotation.

Previous planning can explicitly resume an active workspace by ID, preserving any
retained editor. Unlocated recorded work opens without inventing a Notes range.
The association pane supports identity-only recorded repair: fresh preview, exact
saved snapshot, no overlapping or other unresolved owners, persistence before
publication, and unchanged original baseline/content/conversation. Opening an
unchanged saved workspace does not rewrite its native archive or rotate backups.
Batch association repair is deferred. Historical evidence is not an extracted
session/performance record.

Offline implementation has begun under PLAN 013 in the feature worktree; it is not
installed; live Notes composition is implemented but not natively accepted. `GymAssistantWorkspace` owns typed snapshots,
context assembly, evidence-tagged profile inputs and a one-request gate without
AppKit, a library-write dependency or provider transport. `GymAssistantMacOS` owns
secure attributed-string persistence, supported Markdown export and the native
synthetic development window. `ScratchpadDevelopment` composes these with a fake
assistant and a frozen synthetic note; it registers no Service and calls no API.
It uses a separate local synthetic store. The feature branch's Service adds a
Command-P programming route; the installed autocomplete/library Service is unchanged.
A read-only `NotesContextReader` now implements the reader contract
on a shared serial worker queue, with non-prompting permission checks and an explicit
separate access request. `NotesRefreshCoordinator` serializes each note's reads,
batches consumers received before capture, polls visible notes every five seconds,
coalesces changed metadata, backs off failures and discards suspended-generation
results. Foundation `NotesObservationState` preserves last-known content and a
content identity for parsed-structure reuse. The native adapter passed a synthetic
fixture read/import, metadata and captured-ID reread after its own permission grant.
An optional window context now supplies fresh chat, checked-copy and comparison
reads; the default synthetic entry and installed Service do not yet use it. The registry must share one
coordinator per captured NoteID, explicitly validate on resume, and supply aggregate
visibility. `SessionNoteContext` consumes ordered observations and shares parsed
structure and set-level association across saved sessions. Foundation session
registration reserves a newly created workspace's range without rebuilding existing
manual mappings. The shared context validates a candidate registry, persists the
workspace, then publishes ownership; failed saves cannot reserve phantom regions.
Unresolved saved owners block new creation rather than being treated as vacant.
The context's boundary-commit operation validates the preview observation, saved
identity, increased revision, unchanged confirmed baseline and non-overlapping
ownership before saving/publishing the candidate. A save failure latches ownership
unavailability until durable owners are reloaded: failure may occur after file
promotion, so a successful Notes refresh alone cannot make ownership safe again.
The live-context controller now uses that transaction for boundary apply/undo/redo.
`ValidatedBoundaryUndoManager` awaits a fresh read and candidate persistence before
advancing Cocoa's undo stack. Failed checks retain the action; ordinary text undo
does not read Notes. The editor is briefly noneditable during boundary preflight,
while the composer remains available. Close/quit cancels pending checks. Named
boundary groups remain separate from typing, with human-readable menu labels.
This wiring has injected-reader tests, not native Notes acceptance.
`SessionWorkspaceEntry` captures selection once, refreshes by captured identity,
chooses the last region in note order, and loads its saved owner rather than creating
a competing scratchpad. Duplicate headings, unknown boundaries, unresolved ownership
and recovered snapshots require explicit handling instead of automatic replacement.
`SessionWorkspaceWindows` retains one controller per saved workspace, including
closed windows, and aggregates quit-time saves. These app-composition components
are covered with injected-reader tests and connected to the feature branch's
Service UI through `SessionProgrammingEntryWindow`. The callback schedules that
window after returning without changing the Service pasteboard. Permission prompts
are explicit and outside the callback; granting access requires explicit recapture.
Latest-session entry is wired, while new-session and recovery entry remain visibly
unavailable. This development composition uses a labeled fake assistant, empty
profile and separate ServiceWorkspaces development store; it makes no API calls.
Quit flushes retained windows; reopening restores the last standalone route without
recapturing selection. Workspace-specific menus follow the active scratchpad window.
A verified relocation after renumbering preserves scratchpad/baseline and resets
old absolute edit coordinates conservatively; it does not discard coach edits.
Native entry and native boundary acceptance remain incomplete. Foundation session
structure compares supported body/formatting evidence, never mutable labels alone.
The semantic Notes importer rejects unsupported HTML instead of rendering web
resources or silently dropping formatting. Boundary edit protection retains
deletion/insertion evidence; the synthetic window has a keyboard-accessible read-only
boundary browser and composite undo. `ScratchpadFormatting` applies bounded semantic styles; controller-owned Format
commands route only to the editor and share revision/protection/persistence paths.
Foundation `SessionSkeleton` now proposes heading-only content from a previous
session with an automatically incremented number/letter or editable ambiguity
placeholder, never a naming prompt. It preserves recognized nested structure,
separates ambiguous headings (including descendants of ambiguous parents) for
review, excludes attached Parking Lot content, and never copies body prescriptions
or old inline attributes. Schema-2 snapshots can persist explicit unrecorded
sessions without a Notes baseline, source range or boundary protection. Schema-1
files remain readable without rewriting; an explicit upgrade preserves the previous
file and save refuses downgrade. Missing legacy recording state means recorded.
Unrecorded anchors do not reserve recorded Notes regions. Their heading is an
initial label hint, not proof of identity. `ProgramContextAssembler` appends their
scratchpad separately to the unchanged whole note and marks the request as an
unrecorded addition. Development entry now exposes New Session and its skeleton preview.
The scratchpad controller now accepts an unrecorded snapshot only with no Notes
association. It creates no boundary protection, disables recorded-boundary actions,
assembles addition context after a fresh read, and compares against an empty source.
Checked copy remains unverified without a recorded baseline; a successful read alone
does not establish that pasting is safe. The window registry retains/reuses the same
unrecorded controller across close/re-entry instead of replacing its editor.
`SessionWorkspaceEntry.prepareNewSession` returns either existing unrecorded work
or a non-writing skeleton proposal including omitted-heading review data.
`acceptNewSession` rereads Notes, rejects a changed source, checks again for pending
work and saves without suspension between lookup and creation. Multiple pending
workspaces require explicit resolution rather than choosing one silently. These
entry operations and unrecorded windows have synthetic coverage and are exposed by
the programming entry UI. Command-N resumes unfinished unrecorded work or displays
a non-writing headings-only preview with omissions explicitly listed. Create checks
freshness again; Cancel creates nothing. Naming never prompts. The entry window's
generation/cancellation guards cover preview acceptance and reopening.
New unrecorded snapshots now retain whole-note semantic origin evidence separately
from the empty session baseline. `UnrecordedSessionAssociation` verifies only one
exact session insertion whose removal restores that origin. It compares visible
formatting while ignoring inline marks on paragraph terminators only; it does not
apply the handoff-only trailing-blank exception to identity. Missing origin,
duplicate labels, other Notes changes or changed session content require review.
`SessionNoteContext.associateInsertedSession` requires the saved snapshot and current
observation, validates unoccupied ownership, persists the recorded transition and
then publishes ownership. IDs, editor content and conversation stay unchanged; the
previous snapshot remains the recovery copy. This transaction has synthetic tests
and is now invoked by live controller refresh. The controller saves its complete
editor state before promotion and never replaces its text or undo stack. Formatting
undo captured before association retains conservative boundary protection rather
than restoring absent coordinates. Ambiguous/missing-origin changes preserve the
composer and block chat/comparison until reviewed. Latest-session entry refuses to
create another owner while unrecorded work is unresolved. `SessionAssociationPane`
temporarily replaces the conversation with a formatted read-only Notes browser;
the scratchpad becomes read-only and its existing text diff compares against the
selection. Line-level differences preserve matching interior lines and show two
lines of context around changes, with omitted context marked by an ellipsis.
Heading search and Shift–Arrow/drag selection identify a proposed region,
not identity proof. The entry-installed Edit menu exposes Find Session in Notes
(Command-Shift-F) and Compare with Source (Command-Shift-D). Find validates the
unrecorded/idle/live-context state; the comparison menu and checkbox share state.
Tab in heading search focuses the read-only source without replacing its selection.
Changed Notes clears selection before reconfirmation. Occupied
regions are blocked; the transaction revalidates ownership after a fresh read.
Explicit confirmation records identity/reference evidence without replacing either
version and marks edit correspondence uncertain. Cancel restores the conversation
and editor. “Not pasted yet” refreshes origin evidence while retaining the unrecorded
addition. New Session entry presentation is connected on the development branch;
native acceptance and installed rollout remain unfinished.
`ScratchpadTextView` supplies visible list continuation through normal text edits.
Export refuses invisible-marker list states rather than silently changing apparent
body text into bullets. `CheckedScratchpadCopy` separates one-time
clipboard publication from asynchronous verification and timeout/status delivery.
Generation guards suppress obsolete copy results; late verification never writes
the clipboard. The comparison remains explicitly text-only, not formatting agreement
or permission to advance a baseline. Native timing remains unverified.
Full native acceptance of live Notes window/registry integration and real
profile inspection remains incomplete. Exercise decoration uses optional validated
`ExerciseMention` ranges on responses/messages; older messages decode without them.
The macOS conversation view decorates completed assistant mentions only, using a
read-only injected lookup returning in-library canonical name, not-matched, or
unavailable. The Service composition root calls existing exact-name/preferred-name
library methods; no resolver guesses or library writes are exposed. Solid/dotted
underlines carry tooltips and keyboard-focus labels without changing stored text.
Unavailable lookup leaves text undecorated. Provider mention extraction and actual
library integration still need acceptance; package tests do not establish their native
behavior. No module from concurrent client-history
work is imported or changed by this implementation.

Damaged snapshot discovery reports its workspace ID to the programming entry window.
`WorkspaceSnapshotStore.recoveryPreview` validates the previous copy without writing;
`restore` compares the current/backup bytes with the preview, preserves damaged bytes
under a unique `.recovery` filename, promotes the valid backup and reopens it before
acknowledging success. The valid backup is never rotated away by restoration.
Valid-current rollback and newer-schema recovery are refused. Restoration with any
retained workspace controller is refused until normal quit/relaunch; successful
restoration resets entry context caching before a fresh association check. This is
local file recovery, not resolution of multiple unlocated Notes-session owners.

The selected product direction is a persistent, session-scoped working scratchpad
with conversational assistance. The coach edits the scratchpad directly and later
records the work in Apple Notes. This bounded working copy needs a context boundary
separate from the synchronous Service used for autocomplete.

The accepted [ADR 005](decisions/005-read-only-notes-context.md) direction captures
one Notes document identity when the coach enters the program workspace, then reads
that document's formatted body, plain text, and change evidence through read-only
Notes Automation. Later selection of another note must not silently redirect the
workspace. The Service must return before the long-lived scratchpad window opens.
The adapter reports unavailable or changed context explicitly and has no Notes
write methods, exercise-identity rules, or model-reasoning responsibilities.

The workspace owns its session association, working text, conversation, local
revisions, and last confirmed Notes baseline. Notes remains the recorded program
destination. Manual copy and paste is the selected initial handoff; copy alone is
not evidence that Notes received the text. A changed Notes session must not silently
replace the scratchpad or be overwritten by it.

The [synthetic capability report](design/SCRATCHPAD_CAPABILITY_CHECKPOINT.md)
demonstrates captured-note reads and external-change detection. It also found that
the reported modification date can remain unchanged across body changes, so
safety-critical freshness cannot rely on metadata alone. Session-boundary recovery,
complete rich-text handoff, production permission onboarding, and continuous
monitoring remain unverified. The [monitoring contract](design/NOTES_MONITORING_CONTRACT.md)
and [implementation proposal](exec-plans/PLAN-013-session-scratchpad.md)
record the remaining design work. No production implementation or active-slice
success criteria have been approved by this architecture entry.
