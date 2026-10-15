# PLAN 013 — Implement a persistent session scratchpad with margin conversation

This approved ExecPlan follows repository-root `PLANS.md`. Keep Progress, Surprises
& Discoveries, Decision Log, and Outcomes & Retrospective current. The coach accepted
the bounded scope and authorized local preparation followed by offline implementation
on 2026-10-14. Live API defaults/calls, installation and integration into learner/main
remain separate gates. No client-history work is part of this implementation.

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


In progress, 2026-10-14. The user accepted the recommended scope and authorized
preparation and implementation, beginning with the offline workspace/fake assistant.
Model, spending and credential/retention defaults remain a required checkpoint before
live calls; no paid API request, push or merge into learner/main is authorized here.

## Progress

- [x] (2026-10-15) Connect unrecorded snapshots to the scratchpad controller/window registry with an explicitly absent Notes association, no invented boundary protection, addition-aware chat/comparison, conservative unverified copy, and retained-window reuse. Two new synthetic tests exercise these paths and reject fabricated associations. Programming-entry New Session remains disabled pending post-paste association/ambiguity handling and proposal presentation; native acceptance remains outstanding.

- [x] (2026-10-14) Implement new-session entry preparation/acceptance: preview without writes, resume existing unrecorded work, retain uncertain-heading review data, fresh source validation before creation and no suspension between duplicate check and save. Three added entry tests cover concurrency, reopen, heading styles, changed source and multiple pending workspaces. UI connection and post-paste association remain outstanding.

- [x] (2026-10-14) Add explicit unrecorded session state, schema-2 snapshots with read-only schema-1 compatibility, and context-as-addition. Five regressions cover legacy bytes/backups, downgrade rejection, no recorded-region ownership, identity and context limits. All five verification stages pass (198 tests/32 suites). Creation/resume UI and post-paste association remain pending; the existing recorded-session controller explicitly refuses an unrecorded snapshot.

- [x] (2026-10-14) Coach resolves naming: increment the number or letter after Session; use an editable placeholder on ambiguity and never prompt. Implement automatic skeleton labels, omission of old date/suffix, overflow/rollover/mixed-label fallback, and collision avoidance. Placeholder remains ordinary editable content, not a verified Notes identity. Creation/persistence/UI wiring remains pending.

- [x] (2026-10-14) Add a Foundation headings-only skeleton proposal with three regressions: remove old outer date/label via caller-supplied heading, retain all lettered-session weeks, exclude body exercises/doses/observations/Parking Lot and inline attributes, and hold ambiguous headings plus descendants for review. New-session heading defaults are awaiting coach choice; no new-session creation, persistence, or automatic post-paste association is claimed.

- [x] (2026-10-14) Add Command-P to the feature branch's autocomplete chooser and defer an independent programming entry window until the Service callback returns. Wire captured-note latest-session entry, explicit permission/retry, active-window menus, retained-window reopen and quit-time flush. Label the fake assistant/empty profile; use a separate development store. Permission onboarding regression passes, as do all five verification stages (188 tests/29 suites). No Service launch/registration/installation or native shortcut acceptance; new-session/recovery entry remains disabled or explicitly unavailable.

- [x] (2026-10-14) Wire the live-context boundary browser and apply path to shared full reads and atomic ownership persistence. Add asynchronous boundary-only undo/redo preflight; preserve rejected actions, isolate typing groups, cancel checks on close/quit, and keep ordinary undo immediate. Four added regressions exercise live apply/undo/redo, changed Notes, newly occupied regions, cancellation, menu labels and grouping. All five verification stages pass: 187 tests/28 suites. Native Notes/shortcut entry acceptance and unresolved-association recovery remain pending.

- [x] (2026-10-14) Add boundary commit validation/persistence before ownership publication, with a latched recovery requirement after uncertain local saves. Three regressions cover protected preview/adjacent and overlapping owners, stale observations/revisions, unchanged confirmed baseline, successful ownership persistence and failure after file promotion. Synthetic boundary selection now previews protected shrink before Apply. Live controller commit/undo and Service shortcut wiring remain incomplete.

- [x] (2026-10-14) Add captured-identity latest-session entry preparation and app-owned window registry. Five injected-reader regressions cover lettered weeks, selection changes, simultaneous/repeated entry, closed-window reuse, renumbered relocation, duplicate/unknown/changed regions and damaged-current recovery refusal. Preserve scratchpad and baseline on verified relocation; mark old edit coordinates uncertain. Service entry UI, explicit recovery/boundary UI and native integration remain outstanding.

- [x] (2026-10-14) Implement approved first-slice Format menu: Option-Command-2 Heading, Option-Command-3 Subheading, Option-Command-0 Body, Command-B Bold, Option-Command-7 Bulleted list; no toolbar. Semantic transforms, focus routing, revision/protection, undo/redo and persistence have regressions. Native keyboard conversion from ordinary text, Body conversion, list undo/redo, visible Return continuation/empty-bullet exit, bold typing, quit/reopen and Notes paste observed. Saved synthetic revision 79. Bounded supported-content authoring evidence, not completion of the full offline slice or arbitrary formatting fidelity.

- [x] (2026-10-14) Coach authorizes local prep and implementation. Move accepted plan to PLAN 013; reserve ADR 005 and PLAN 012 for Notes direction/capability evidence because current learner/main uses ADR 004/PLAN 011 for alias guidance. Mockup artifacts in this checkout match the old source byte-for-byte. App archival is blocked by other-chat ownership; preserve that checkout.
- [x] (2026-10-14) Commit approved preparation as 0a023a2 and reconcile local learner/main (221544f) into this feature branch as 5e7f4bb. One merge base equals current learner/main; baseline five-stage verification passes. No push or merge into learner/main.
- [x] (2026-10-14) Start offline implementation: Foundation workspace/request types and reader contract; secure-archive snapshot store with validation/recovery/fault injection; supported Markdown exporter; native synthetic editor/chat/comparison executable. Native launch attempt is blocked by locked Mac; no UI pass claimed. Work is uncommitted pending native validation.
- [x] (2026-10-14) Mac unlocked: native synthetic edit/ask, pending Enter blocking and disabled Send, Stop, scratchpad-changed reply, Markdown publication, comparison toggle, close/reopen and quit/relaunch observed. Composer typing falsely showed Scratchpad changed; fix and controller regression pass, corrected native behavior observed. This is not native Notes paste or full offline-slice acceptance.
- [x] (2026-10-14) Final initial-increment verification: five repository stages and 134 tests/17 suites pass. Copy menu is visible and Command-Shift-C works in the native synthetic window; app quit after testing. Preserve the initial increment as a local checkpoint, not completed PLAN 013 or authorization to install/use paid APIs.
- [ ] Finish production Notes capture/monitor, association/boundary browser/edit tracking, profile inspection and exact exercise decoration before offline slice acceptance. Test actual editor-generated Markdown paste/formatting in the synthetic Notes fixture, not only publication.
- [x] (2026-10-14) Add read-only native Notes adapter and shared refresh components: serial off-main Automation, explicit consent separated from reads, metadata-only idle checks, body validation for all safety consumers, same-date/formatting changes, deferred change coalescing, error backoff and stale-result rejection. Offline tests use an injected reader; native Notes execution and window/registry integration remain outstanding.
- [x] (2026-10-14) Implement structured session candidates and set-level stable association, including hierarchy/typos, lettered weeks, Parking Lot, duplicates, renumbering, stale confirmation and occupied ranges. Add bounded semantic HTML import, shared note context with ordered observation delivery, and saved edit-protection state. Older snapshots without source evidence require confirmation rather than inferred identity.
- [x] (2026-10-14) Connect a read-only boundary browser to the synthetic development window. Native Command-Shift-B, Shift-Down expansion, Command-Return, undo, reopen and blocked shrink observed. Fix a native undo aliasing defect with independent attributed-string snapshots; regression verifies undo/redo text, formatting, range and save. This does not establish live Notes ownership/freshness integration.
- [x] (2026-10-14) Add per-note context pooling with closed-workspace header discovery, monotonic observation delivery, optional fresh-context chat integration, and read-only preference inspection. Private profile packaging, live boundary/checked-copy/diff wiring, skeleton, decoration and Service entry remain open.
- [x] (2026-10-14) Add creation-time workspace ownership to the shared context: validate a current explicit region, reject overlap/unlocated saved owners, persist before publishing ownership, retain existing manual mappings, and restore closed ownership from store headers. Two new integration regressions cover stale choices, overlap, reopen and failed persistence; ten focused association/context tests pass. Native entry/window registry and live boundary editing remain unconnected.
- [x] (2026-10-14) Coach accepts ignoring terminal empty body paragraphs in handoff comparison, preserving them in the scratchpad. Add structured comparison helpers and use them for live-context text comparison/verified baseline comparison. Interior blanks, empty headings/list items, whitespace-bearing lines and content/formatting differences remain significant. No session identity inference, baseline advancement or persisted-text rewrite. Two new regressions and controller regressions pass; full live reconciliation remains incomplete.
- [x] (2026-10-14) Coach grants this development app's separate Notes Automation permission. Its explicit synthetic fixture test succeeds: captured-note read, import of 83 supported paragraphs/two session regions, metadata identity and captured-ID reread. No Notes write, body persistence, clipboard change or provider call. This proves the bounded native reader path, not full workspace integration or arbitrary formatting support.
- [x] (2026-10-14) Wire optional live-context checked copy and comparison: one-time publication concurrent with verification, app-only timeout/late warnings, superseded-operation rejection, fresh comparison reads, and preserved scratchpad on unresolved association. Three copy concurrency regressions and a controller integration regression pass; full five-stage verification passes with 163 tests/23 suites. The default synthetic app still has no live context; native full-path timing and live workspace entry remain outstanding.
- [ ] (2026-10-14) Native editor-generated Markdown preserves heading tiers at a paragraph boundary but adds blank lines between body paragraphs. Test pastes and the inserted paragraph were undone in the synthetic capability note. Compact-spacing control was blocked before execution because it would overwrite the general clipboard; request explicit approval before repeating that control. No formatting acceptance or clipboard workaround.
- [x] (2026-10-14) Coach explicitly approves synthetic clipboard/Notes spacing controls. Native single-newline control retains separate paragraphs but adds trailing spaces; two-space hard breaks retain separate body paragraphs without added spaces or blank rows. Correct exporter heading/body boundaries and preserve intentional blank rows; explain and update the old extra-blank-line test expectation, add two regressions. All five verification stages pass. Undo all native controls and verify fixture HTML exactly matches pre-control HTML.
- [x] (2026-10-14) Coach accepts one blank separator after a bullet list before ordinary body text for the first handoff. This is a narrow spacing exception, not approval of other formatting changes. Native no-separator control made the body another bullet.
- [x] (2026-10-14) Add bounded reimport of the two observed empty system-font heading suffixes after Markdown paste. Only exact empty h2/h3 runs adjoining the same closed heading are normalized; nonempty text, other styles and standalone wrappers still fail. Captured-shape regression and all three importer tests pass. A rebuilt native round trip is still required.
- [x] (2026-10-14) Resolve independent-review safety/interface gaps at specification level: validated snapshot promotion/recovery, provider-neutral request correlation and explicit failures, preference evidence distinctions, and Notes-copy labeling. Record coach verification of the Notes shortcut. No production code or passing-test claim added.
- [x] (2026-10-14) Coach chooses direct highlighted boundary movement in a read-only note browser. Use the coach-authorized pending-reply fallback: keep typing available, block Enter/Send until completion or Stop; queue/cancel/steer remains a later interaction.
- [x] (2026-10-14) Native disc-marker control preserves regular ul; parallel prototype completes four warm samples in 168–180ms. Initial timeout notice at 759ms fails; candidate 700ms dispatch yields 728–742ms in three delayed repeats, with unchanged clipboard. Small Notes body/large synthetic copy only; keyboard configuration and production acceptance remain gated.
- [x] (2026-10-14) Reconcile ordinary-copy acceptance with prior approval; native typed Markdown replacement/literal/bold/list tests pass after two serializer regressions were fixed (8/8 local, 8/8 captured-native). Keyboard-only invocation, original spacing/list styles and real copy/check timing remain unproved.

- [x] (2026-10-13 02:33Z) Inspect the capability evidence, reusable checkout, and learner Service/library interfaces; distinguish implemented behavior from design.
- [x] (2026-10-12 local date) Record accepted read-only adapter direction in ADR 005 and prepare this proposal.
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
- [x] (2026-10-14) Coach accepts scope/contracts and authorizes offline implementation after local preparation; tutorial progress is unchanged.
- [ ] Verify session association and full rich-text paste fidelity with synthetic native tests; finish the outstanding capability-plan session-anchor item only on evidence.
- [ ] Implement persistent native workspace and production Notes permission/read adapter; pass offline/close/relaunch/recovery tests with a fake assistant.
- [ ] Select API model and explicit spending bounds, approve credential/retention defaults, and validate the request/response contract before live calls.
- [ ] Implement conversation freshness, fixed read-only profile, and truthful exercise decoration; verify fake-provider behavior before paid tests.
- [ ] Complete synthetic end-to-end acceptance, regression checks, and coach review; publish only the approved coherent package under the repository Git lifecycle.

## Surprises & Discoveries

Unrecorded windows, 2026-10-15: existing boundary initialization assumed every
scratchpad owned a recorded range. Make that association explicitly optional and
guard every recorded-boundary operation. A successful Notes read for an addition
cannot establish comparison with a baseline that does not yet exist; checked copy
must remain unverified rather than claiming Notes agreement.

New-session entry, 2026-10-14: two accepts can finish their Notes reads in either
order. Lookup existing unrecorded work again after the read, then save without
suspension. The simultaneous-accept regression observes one stored workspace and
one local identity, not competing scratchpads.

Unrecorded continuation, 2026-10-14: an optional new anchor field alone would let an
older reader silently interpret a new session as a recorded Notes region. Use a new
snapshot schema for new files; accept legacy files without rewriting them. Header
scanning also validates that unrecorded snapshots claim no baseline, source range or
boundary protection before excluding them from recorded ownership.

Skeleton continuation, 2026-10-14: omitting an ambiguous parent while copying its
recognized child headings silently changes structure. Treat those descendants as
review items too. The synthetic regression was corrected to require that stronger
hierarchy guarantee rather than promoting orphan headings into the new session.

Service entry continuation, 2026-10-14: the existing Service bundle had no Notes
Automation usage description, because autocomplete did not read Notes. Add that
description for the new explicit programming branch, without requesting permission
at launch. Permission may take long enough for selection to change, so a grant
does not automatically recapture; the coach explicitly retries the intended note.
The injected-reader onboarding test verifies no capture at construction, no prompt
on a denied read, no recapture on grant, and no workspace creation on capture alone.

Live boundary continuation, 2026-10-14: Cocoa's undo stack advances synchronously,
whereas Notes validation must be asynchronous. Starting a read inside the undo
callback would consume the action before detecting stale or occupied targets.
Add a boundary-only preflight manager that validates/persists first, then advances
the stack without another suspension. Isolate boundary groups from typing so later
text actions cannot hide their preflight, and expose friendly menu labels rather
than internal correlation keys. Tests include default event grouping.

Boundary continuation, 2026-10-14: snapshot saving can report a failure after the
candidate has already reached the current file. Keeping only the old in-memory
owner and clearing the error on the next Notes read would expose incorrect vacant
regions. Latch context ownership failure until durable headers are reloaded, for
both creation and boundary commits. The fault-injection regression fails at the
promoted phase and verifies that another body read cannot clear that lock.

Entry continuation, 2026-10-14: stable association correctly relocates a saved
session when earlier labels change length, but controller restore still rejected
its old absolute protection range. Accept only the shared context's current verified
association, preserve editor content/baseline, and reset protection conservatively.
The renumber/reopen regression now constructs the controller and checks persistence;
it is not evidence that automatic association works after arbitrary content edits.

Full-suite entry verification exposed an existing copy test's scheduler assumptions:
publication failure can cancel verification before it starts, and a 20ms checking
status may expire before the test polls it. Correct the synchronization expectations
without changing production copy logic or the dedicated timeout test. The rerun
passes all five verification stages and 180 tests across 26 suites; the initial
failure is retained here rather than reported as an uninterrupted pass.

Formatting continuation, 2026-10-14: ordinary NSTextView Return retained list style
without creating a visible marker. Add explicit visible continuation through normal
text-edit/undo/delegate handling; Return in an empty bullet invokes Body. The earlier
failed test left a line with invisible list attributes that pasted as a bullet.
Refuse export of list-styled paragraphs lacking visible markers, without changing
the clipboard, and explain Body/Bulleted list repair. Tests cover that failure and
repair. In the native test, explicitly repair the synthetic line with Body, reopen,
copy and paste; exported Notes HTML now agrees with the visible list/body structure.
The fixture was restored exactly after both handoff tests. Native reimport of the
first authored paste succeeded with 97 supported paragraphs/three session regions.

Approved spacing controls, 2026-10-14: native Notes HTML confirms two-space Markdown
hard breaks become separate `div` paragraphs without the trailing spaces inserted
by soft newlines. Heading/body adjacency needs no blanket blank separator. A body
line immediately after a list without a separator becomes an extra `li`; adding a
blank separator prevents that, but creates a visible empty paragraph. Ask the coach
about that remaining fidelity tradeoff. Notes also exports empty `.AppleSystemUIFont`
wrappers following pasted headings, which the bounded importer currently rejects;
this requires explicit tested handling, not silent dropping of arbitrary styles.

Actual editor-generated Markdown pastes expose paragraph spacing changes that unit
serialization expectations did not catch. A mid-paragraph insertion also joins the
first heading to existing body text; a new-paragraph control preserves its native
Heading tier. Preserve the fidelity requirement and test compact spacing before
changing serializer expectations. General-clipboard control requires explicit
approval after the execution review blocked it; the blocked command did not run.

The development app's explicit Automation grant now permits the synthetic native
fixture read. The earlier probe grant did not substitute for this app's permission.
Checked-copy timeout scheduling reserves 50ms for main-run-loop delivery (700ms
timer against the accepted 750ms wait limit). This is not a measured production
latency guarantee, especially while main-thread rich-text preparation is running.
Legacy or reassociated formatting evidence that cannot establish the confirmed
baseline yields Notes not verified rather than a false agreement claim.

Native boundary undo initially retained a live attributed-string reference instead
of a detached before-image. Undo then paired newer text with the old range/tracker,
and validation refused the save. Copy the before/redo images explicitly and suppress
incidental text-storage undo registration during the composite operation. The
regression and native retry restore text, formatting and range together. The failed
synthetic process was restarted from its last acknowledged snapshot; no real note
was edited. Source parsing rejects unsupported formatting rather than silently
discarding it; support beyond the tested native headings/bold/disc-list fragment
remains a fidelity gate.


Native continuation, 2026-10-14: composer text changes incorrectly displayed a
Scratchpad changed status while a reply was pending, although revision stayed fixed.
Require an editor change for that warning. A new native-controller test distinguishes
composer typing, scratchpad editing and Stop; corrected native test reproduces the
expected distinction. AX element indices change when transcript scrolling appears;
derive them from the latest state, not earlier fixed indices. Shell-sandbox clipboard
verification failed; permitted read-only retry confirmed only the expected synthetic
heading without printing the clipboard. Neither attempt is a Notes paste test.

2026-10-14 implementation start: existing branch now includes current alias guidance
without conflicts; one intended merge base remains. Mockups are byte-identical in
this checkout, but the app refuses to attach/archive the older checkout because it
belongs to another chat. Leave it intact; client-history was not modified.
The new standalone development app intentionally has no Notes permission, Service
registration or API access. Computer-use launch is blocked by the locked Mac;
unit tests/builds are not native acceptance. Initial compilation found CGFloat
ambiguity and throwing Swift Testing macro syntax; fix code/syntax, not expectations.

2026-10-14 independent CLI review: snapshot recovery and assistant request contracts
were too vague to drive failure tests, despite passing bounded probes. Resolve the
behavioral invariants below rather than adopting a migration framework or detailed
UI architecture. The coach subsequently chose direct boundary movement in a read-only
browser and authorized a simple send-blocking fallback instead of queue/steer for
this slice. The coach manually verified the
Notes Paste as Markdown keyboard shortcut; this is host-specific user evidence,
not an automated production keyboard test.

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

- Decision: Unrecorded windows have no `SessionAssociation` and no boundary edit
  protection. Recorded-boundary commands are unavailable; comparison is an addition
  and chat uses the existing unrecorded assembler after a full context read.
  Rationale: Avoid invented offsets/ownership or false copy verification while
  implementing the approved unrecorded state. Keep the entry button disabled until
  post-paste association/ambiguity handling is ready.
  Date/Author: 2026-10-15, Codex implementation.

- Decision: Separate non-writing skeleton preparation from explicit acceptance.
  Revalidate the source before creation and resume existing unrecorded work before
  either step creates a file. Multiple pending workspaces are not silently ranked.
  Rationale: Keep preview/cancel safe and preserve unfinished work through repeated
  invocation, relaunch and simultaneous entry. No additional naming question.
  Date/Author: 2026-10-14, Codex implementation of the approved new-session flow.

- Decision: New snapshots use schema 2; schema 1 remains readable without eager
  migration. Missing recording state in a legacy anchor means recorded. Unrecorded
  anchors have no Notes baseline or range, and their heading is only an initial
  label hint. Save refuses schema downgrade and recorded-to-unrecorded conversion.
  Rationale: Prevent old readers or recorded-section code from treating a new
  scratchpad as a replacement. Explicit upgrades preserve the previous file.
  Date/Author: 2026-10-14, Codex implementation of the approved addition contract.

- Decision: Increment the number or single letter after Session automatically.
  On ambiguity use `Session [number or letter]`; never ask a naming question or
  block entry. Remove the previous suffix/date. Mixed sequences, Z rollover,
  numeric overflow or collisions with supplied existing headings use the placeholder.
  Rationale: The coach explicitly chooses low-friction editable output rather than
  a prompt. This supersedes the proposed ask-for-lettered-headings alternative.
  Date/Author: 2026-10-14, coach instruction; Codex implementation.

- Decision: Keep this entry composition explicitly developmental: fake assistant,
  empty profile, separate ServiceWorkspaces local store, and visible unavailable
  new-session/recovery paths until implemented. Do not launch the Service executable
  for validation because its startup registers Services.
  Rationale: Connect the approved local workflow without crossing API or installation
  gates or implying completion of unfinished entry choices.
  Date/Author: 2026-10-14, Codex Service-entry implementation.

- Decision: Temporarily block scratchpad edits during boundary undo/redo validation,
  without blocking composer typing or adding Notes reads to ordinary text undo.
  Rationale: The asynchronous check must not apply a before-image over edits made
  while it waits; rejected checks must retain the existing undo/redo action. This
  implements the approved fresh, atomic undo requirement without a new workflow.
  Date/Author: 2026-10-14, Codex live-boundary implementation.

- Decision: Treat unacknowledged workspace persistence as an ownership recovery
  condition, not a Notes freshness failure. Keep the editor available and prevent
  subsequent ownership-dependent actions in that context until recovery/reload.
  Rationale: A successful read from Notes says nothing about whether the local
  candidate file was promoted. Do not silently revert or overwrite either image.
  Date/Author: 2026-10-14, Codex boundary implementation.

- Decision: Reuse app-owned controllers after fresh entry validation; never treat
  a recovered or unresolved saved workspace as an empty region for new creation.
  Rationale: Closing/re-entering or concurrent invocations must not create competing
  scratchpads or overwrite a pending editor. This implements existing ownership and
  recovery requirements, without adding a new product choice.
  Date/Author: 2026-10-14, Codex implementation continuation.

Accepted 2026-10-14: handoff comparison may ignore only empty body paragraphs at
the end of the copied session, since native Notes omitted those paragraphs. Keep
the local scratchpad unchanged. Interior blank paragraphs, empty headings/list items
and whitespace-bearing lines remain significant. Apply the exception only when
structured evidence distinguishes body from other paragraph kinds; do not use it
to infer association or independently advance the confirmed baseline.

Decision, 2026-10-14, coach-approved side conversation: include a small Format menu
and discoverable local keyboard shortcuts for Heading, Subheading, Body, Bold and
Bulleted list in the first slice, without a permanent toolbar. Rationale: preserving
seeded/imported formatting is insufficient for freely writing a session. This
records implementation scope and authoring acceptance, not completed controls or
native test evidence. No broader text-formatting feature set is approved.

Accepted 2026-10-14: the first Markdown handoff may add one blank separator between
a bulleted list and subsequent ordinary body text. Native controls show that omitting
it can turn the body into a bullet. Preserve native heading tiers, bold, list identity
and compact ordinary paragraphs; this does not authorize broader formatting loss.

Implementation choice, 2026-10-14: create new workspace ownership only after its
validated snapshot is durably saved, using a candidate registry before publishing.
Treat unlocated saved owners as unresolved rather than vacant. This enforces the
approved non-overlap/data-integrity contract without discarding manual mappings.


Review resolution, 2026-10-14, authorized by the coach: make save/recovery and
assistant request invariants explicit without choosing algorithms or new product
scope. Preserve existing preference constraints instead of inventing a numerical
priority ladder. Label the explicit handoff Copy Markdown for Notes while retaining
its floating icon and ordinary Command-C semantics. Rationale: these clarify already
approved behavior; they do not require a migration engine, preference editor, tool
access or another panel. The subsequent coach decisions below resolve pending
reply handling and boundary interaction.

Coach decisions, 2026-10-14: boundary adjustment uses a read-only note browser with
direct movement of a highlighted start/end, not a paragraph picker. For chat the
desired direction is queue, cancel and steer; the coach authorizes blocking Enter
on another request if that is too much first-slice work. Select that fallback because
no assistant request layer exists yet and queue/steer would add pending-message and
request-replacement behavior beyond the single-request boundary. Keep composing and
Stop available; block both Enter and Send while generation is active, preserving
the unsent text. This is the approved simpler slice, not rejection of the richer
direction or permission to silently queue a paid request.

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

Accepted: ADR 005 adds read-only Notes Automation alongside the existing Service.
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

Monitoring revision after native equal-date edits: idle checks remain metadata-only;
chat, diff, and explicit checked copy validate body/id/date together, sharing only
reads that cover each request. Cache parsing and comparisons when content is unchanged.
Ordinary Command-C has no synchronous check. No model calls from monitoring.
Rationale: modification time is not a reliable body revision. Date/author:
2026-10-14, Codex evidence reconciliation of the shared freshness policy.

## Outcomes & Retrospective

Unrecorded windows, 2026-10-15: the editor now persists and reuses an unrecorded
scratchpad without inventing a Notes range. Injected-reader/native-controller tests
cover fresh chat context, addition comparison, conservative copy using an isolated
pasteboard, close/re-entry identity and no claimed recorded ownership. These are
synthetic tests, not live Notes or installed shortcut acceptance. The New Session
entry button is still disabled: proposal presentation and post-paste association
remain required before exposing the complete path.
All five deterministic verification stages pass: 203 tests across 32 suites.

New-session entry, 2026-10-14: `SessionWorkspaceEntry` can prepare, accept and reload
a heading-only unrecorded scratchpad without reserving any recorded Notes range.
All five verification stages pass (201 tests/32 suites), including three new entry
regressions. The UI is not
connected: it still needs proposal presentation, reuse of an unrecorded window,
addition-aware comparison/copy/chat and conservative post-paste association.

Unrecorded continuation, 2026-10-14: the persistence and request foundations now
distinguish additions from replacements. Full verification passes (198 tests/32
suites). No real snapshots were migrated and no Notes, clipboard or provider call
was used. The recorded controller rejects the new state until its UI path is
implemented; new-session entry, durable UI resume and post-paste association are
still outstanding. Package tests do not establish native behavior.

Skeleton continuation, 2026-10-14: heading-only proposal generation is implemented
and covered by three synthetic tests. All five verification stages pass with 191
tests across 30 suites. Recognized structural names and bare block,
slot and week headings can carry forward; unfamiliar/content-bearing or ambiguous
hierarchy remains separate review data. This is deliberately not a complete
new-session workflow. The heading-default choice is now resolved and implemented:
increment number/letter, otherwise placeholder, never prompt. Pending work includes
preview/review UI, durable UI resume, and conservative post-paste association without
replacing the last session. Explicit unrecorded identity and context-as-addition are
now implemented in the foundation, as recorded above.

Service-entry continuation, 2026-10-14: the feature branch now connects chooser
Command-P to independent captured-note latest-session entry. The Service pasteboard
is untouched on that route; reads, permission prompts and window lifetime happen
after its callback returns. Active-window menus, quit saves and retained-window
reopen are wired. One added onboarding test and all five verification stages pass
(188 tests/29 suites). Native shortcut/Notes acceptance has not run, and no app was
installed or launched. New-session skeleton, unresolved entry/recovery UI, profile
packaging and exercise decoration remain outstanding before offline acceptance.

Live-boundary continuation, 2026-10-14: the optional live-context controller now
opens the read-only browser with current neighboring owners, rechecks on apply,
and persists before installing the new text/range. Boundary undo/redo revalidates
Notes and ownership before consuming its action; tests reject externally changed
Notes and a newly occupied expansion. Four added tests and all five verification
stages pass (187 tests/28 suites). Native acceptance has not run. Service entry,
new-session skeleton, unresolved association/recovery UI, real profile and library
decoration remain outstanding; no paid API or installed Service changes occurred.

Boundary continuation, 2026-10-14: candidate commits now preserve the confirmed
baseline and validate durable identity/revision before publishing ownership. The
browser can explain protected shrink during selection without applying it. Three
targeted tests and all five repository verification stages pass (183 tests across
27 suites). The live controller still refuses boundary changes until its
fresh-read, transaction and undo/redo paths are connected together; do not enable
the command merely because the lower-level transaction now exists. Shortcut entry,
native boundary acceptance and recovery controls are still pending.

Entry continuation, 2026-10-14: the new composition components prepare a latest
session and reuse its retained controller with an injected reader. Five targeted
tests pass; full verification passes five stages and 180 tests/26 suites after the
copy-test synchronization correction described above. They are not yet wired to the Service's Command-P branch or development
app menus; native entry, boundary/recovery interaction and new-session skeleton
remain unfinished. No installed Service, Notes content, clipboard or API changed.

Terminal-blank follow-up, 2026-10-14: the coach approved the narrow comparison
exception. Implementation preserves stored scratchpad content and significant
interior/structured differences. All five verification stages pass, with 175 tests
in 25 suites. No new native UI test was run for this comparison-only increment;
full live association/reconciliation and the remaining PLAN 013 work are not complete.

Continuation, 2026-10-14: the approved formatting controls are implemented and have
bounded native keyboard/reopen/paste evidence; visible list continuation and unsafe
invisible-marker export were corrected after native testing. Shared context creation
now publishes ownership only after successful persistence. Final verification passes
all five stages, with 173 tests in 24 suites. PLAN 013 is not complete: live entry,
boundary/window registry, profile packaging, decoration, skeleton and timing remain,
followed by the explicit API/installation gates. Terminal empty paragraphs omitted
by Notes need a coach decision before equivalence/reconciliation treats them as
nonsemantic. No client-history checkout, installed Service or client note was changed.

2026-10-14 continued implementation: structured association and boundary protection
have package coverage; the synthetic browser now has a native keyboard/undo/reopen
test trail, including a found-and-fixed undo failure. A shared note-context pool and
read-only preferences inspection exist, and optional fresh-context chat wiring is
available for integration. All five repository verification stages passed after
these changes. The explicit native reader test correctly refused missing access;
its separate Automation request is awaiting user input. Live boundary/diff/checked
copy, Service entry, new-session skeleton, exercise decoration and private profile
packaging still remain; the offline slice is not accepted or installed. Resume at
the pending native reader check, then continue those integration items without
stopping at ordinary milestones. The paid-model defaults remain the explicit gate.

2026-10-14 follow-on: the read-only Notes adapter and refresh coordinator are now
implemented as components, not yet connected to real workspace windows. Five-stage
verification passed, followed by nine passing focused tests after a queued-tick
backoff correction. Native permission/read execution, per-note registry ownership,
visibility/reactivation delivery and copy-time latency still need acceptance.
Resume implementation with that integration and session association; do not treat
these injected-reader passes as a native monitoring or complete-slice checkpoint.


Native continuation supersedes the earlier locked-Mac handoff below: synthetic
window editing, delayed fake request/Stop, truthful scratchpad freshness, local
save/reopen, copy publication and in-place text comparison now have direct native
evidence. No real Notes or API access occurred. See
[offline checkpoint evidence](../design/SCRATCHPAD_OFFLINE_CHECKPOINT.md). This initial
implementation remains separate from the installed Service and is not the completed
offline product slice; production capture/monitor/boundary/profile/library work remains.

Implementation start, 2026-10-14: approved prep is committed and current learner/main
reconciled. Workspace and macOS implementation has begun in separate targets with
an explicit synthetic development executable. Formatted store validation, failure
injection, immutable context substitution, request identity/cancellation and Markdown
serialization have package tests. No production Notes capture/monitor, association
resolver, protected boundary browser, live profile or library decoration is connected
yet. Those are remaining work, not accepted omissions. Native app launch could not
be tested because the Mac is locked; unlock is the next required user action.
No installation, paid API call, push, learner/main merge or client-history edit.

Verification at this handoff: scripts/verify passes all five deterministic stages;
133 package tests in 16 suites pass, including the new workspace/macOS tests.
Development bundle builds, signs and passes plist/signature validation. Diff
whitespace and added-code credential/private-link scans have no findings; that is
not proof of correctness or privacy completeness. Tests cover fault injection and
store reconstruction, not actual OS crash/power-loss or native close/relaunch.
The native launch tool reports locked Mac; do not claim the window was tested or
the development app is running. The temporary native bundle built before the final
integrity regression changes must be rebuilt before resuming native testing.

2026-10-14 review resolution: documentation now states the minimum testable recovery
and assistant boundaries and carries the existing evidence-category/conflict rules
into the profile contract. The independently reviewed proposal remains proposed.
No implementation, API call or runtime verification follows from these edits.
The coach's subsequent answers settle both interactions as recorded in Progress.

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
Coach-facing endpoints must use nearby headings and short source excerpts; numeric
offsets remain internal/diagnostic coordinates, not the primary way to choose scope.
Identify an adjacent owner by its session/workspace label, and explain blocked shrink
with the protected content excerpt (including a deleted-content marker when needed).
Selected interaction: a read-only note browser highlights the current session range
and the start/end being adjusted. Move that endpoint directly through source text,
by keyboard or mouse; do not substitute a paragraph-picker workflow. Moving the
highlight previews scope only, not a committed change. Show the added edge content,
protected-shrink explanation and neighboring owner in this browser; apply the existing
freshness and overlap rules before committing. Exact key bindings are implementation
details to make discoverable and test natively. Cancel without change and preserve
the editor's content and focus on return.

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
free text. Coach-approved clarification, 2026-10-14: expose these through a small
Format menu with Heading, Subheading, Body, Bold and Bulleted list commands and
discoverable keyboard shortcuts; no permanent formatting toolbar. Paragraph-style
commands apply to the current paragraph or selected paragraphs. Bold applies to
selected text or the typing style. Use semantic heading/list attributes rather
than font-size approximations; Markdown markers typed into the editor remain text.
Keep command routing confined to the editable scratchpad, not the composer,
transcript or comparison. Choose local bindings that do not collide with existing
commands such as Adjust Session Boundary and Copy Markdown for Notes.
Route formatting changes through the same revision, save, freshness and protected
edit tracking as text edits, with undo/redo. A new session copies only the prior session's structural headings, not
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
freshness check below. Explicit checked copy publishes concurrently with its bounded
safety check and warns about external changes or failed checking; ordinary copy needs no
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

Copy Markdown for Notes is an icon floating in the upper-right of the scratchpad pane,
not a labeled primary button or a separate handoff panel. It copies the entire
scratchpad with plain-text Markdown for Notes' Paste as Markdown command. A rich
representation for other paste destinations is subject to separate fidelity testing;
the timing probe's raw RTF control is not that implementation. Proposed
local Command-Shift-C invokes that whole-scratchpad command regardless of selection;
show this explicit name in the Edit menu, tooltip, and accessible command name;
include the instruction to use Notes' Paste as Markdown. Keep standard
Command-C selection semantics. With editor focus, Command-A then Command-C copies
the full scratchpad immediately through the rich export path, without a synchronous
Notes check; the explicit icon/whole-copy command is checked. Partial selection
copies only that range. Command-C in chat still copies chat selection. Test both
copy paths for their separately stated formatting contracts; intercepting native copy must not
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

Explicit whole-scratchpad copy is also a safety checkpoint. Concurrently with icon/
whole-copy shortcut publication, use the shared freshness
check and compare current Notes with the last confirmed baseline, not merely the
scratchpad's edits. Warn Notes changed—review differences before pasting and expose
the diff if Notes independently changed; if current Notes already equals the
scratchpad, report the verified match instead. An unavailable read or uncertain
association must warn Notes could not be verified. Copy remains available with
warning, not as a claim of safe paste. Partial-text/chat copy retains ordinary
semantics and does not preflight Notes.

Accepted 2026-10-13: wait for publication before pasting. For the explicit checked
copy, distinguish Copied—checking Notes from a completed check or the bounded
Copied—Notes not verified fallback; publication alone is not verification.
Ordinary Command-C remains immediate and Notes-unverified at export, including
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
Superseding decision, 2026-10-14: for every late conflict, update Gym Assistant's
warning and diff state only. After publishing the checked copy, do not clear,
replace, or otherwise write the clipboard—not even when the app's copy token and
pasteboard `changeCount` still match. The 2026-10-13 conditional clipboard warning
was superseded because no public atomic compare-and-write across apps was found.
Test no intervening copy, identical recopy, unrelated copy, a later scratchpad
copy, and stale results; none may change the clipboard. Scope conflicts to the
associated session and captured baseline/revision; do not mistake the coach's own
paste for an external conflict. A late warning cannot retract a completed paste.

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
[Notes monitoring and session association](../design/NOTES_MONITORING_CONTRACT.md); the
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
seconds; twenty metadata reads took 1.939 seconds. Checked-versus-ordinary copy and
the 400ms/750ms timing contract are accepted; production scheduling remains untested.
Cache the raw body and
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
and explicit checked copy share body/id/date validation, coalescing only reads that
cover each request. Ordinary Command-C is immediate and Notes-unverified.
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

Profile evidence keeps authored philosophy, confirmed tendencies, unconfirmed
inferences, client/session constraints, and scientific claims distinct. Preserve
source wording, stated scope and exceptions; do not invent missing scope or turn
an inference into a commitment. Scientific claims retain their evidence status
instead of being presented as established facts. Current explicit constraints
outrank tendencies; tendencies are not hard exercise filters. Surface a material
conflict rather than silently resolving it. If the sources do not establish how
to resolve conflicting commitments, retain the uncertainty and seek clarification
when relevant to the coach's question. Do not add a global priority score or new
preference-learning flow. Inspection and model context must preserve the same
distinctions; conversation cannot upgrade confirmation or change the profile.

## Plan of Work


### Milestone 1 — Prove association and rich handoff before dependent work


Extend the isolated `spikes/session-scratchpad/` fixture tests, not production
behavior yet. Use the proposed boundary and confirmation contract in
[the monitoring contract](../design/NOTES_MONITORING_CONTRACT.md#proposed-executable-association-contract).
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
completing PLAN 012's outstanding session-association item.

The bounded typed Markdown fixtures already preserve native Heading, Subheading,
bold and continuing lists through Notes Paste as Markdown on the tested host; the
coach has verified its keyboard shortcut. Do not repeat superseded public-HTML
experiments as a prerequisite. Implement the editor-to-Markdown adapter and test
its actual formatting/spacing/literal conversion and native paste before claiming
production fidelity. Boundary browser, protected edit tracking and full recovery
are native implementation acceptance tests, not additional passing probe claims.
Retain failed expectations and stop for review if fidelity needs a scope change.

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

Both providers consume the same immutable application request, including its coach
question and ordered conversation messages, captured workspace/session/note
observation identities, scratchpad revision and profile version/evidence. Separate
the coach's current instruction from quoted note/profile/history context; neither
provider receives tool or mutation capabilities. A response or failure carries its
request identity so it can be attached to the originating conversation and context,
never mistaken for the current scratchpad after edits or reassociation. Completed
replies based on older context remain visibly marked; cancellation must not allow
a late completion to replace the active reply or revive a stopped request.

Use typed context/unavailability, size-limit, cancellation, transport and provider
failure outcomes, preserving the submitted question and, if partial replies are
displayed, their clearly marked incomplete text. This does not require streaming.
Validate context before network submission and check configured provider
input/output limits without silent truncation. No automatic retry or another paid
request follows an uncertain outcome. First-slice pending-follow-up behavior uses
the coach-authorized fallback: composer typing remains available, but Enter and Send
cannot submit another request until the active request completes, fails or is stopped.
Explain the unavailable send state compactly and keep Stop discoverable. Stop cancels
the active request locally, preserving its submitted question and unsent follow-up;
it does not promise reversal of a request or charge already received by the provider.
Sending after Stop uses a fresh context check and the latest scratchpad, not the
cancelled request's cached inputs. Do not queue or auto-send text when generation ends.

Decision example: after submitting What should B2 be?, the coach types Keep it
unloaded before the reply finishes. Keep that follow-up in the composer; pressing
Enter while generation runs sends nothing and loses no text. The coach can Stop and
then send it, or wait and send after completion. Queue, cancel and steer like the
coach's preferred chat experience remains a future direction; do not implement a
queue or in-flight steering in this slice.

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


Current local implementation entry (synthetic content only):

    scripts/verify
    bash app/scratchpad-development/build.sh

The build prints a temporary Gym Assistant Scratchpad Development.app path. Open it
through native computer-use tools or manually once the Mac is unlocked, not by
bypassing a locked screen. The synthetic workspace lives separately under Application
Support/GymAssistantScratchpadDevelopment; it does not use the installed app's
library or real Notes. Whole-copy changes the normal clipboard only when explicitly
invoked; it always says Notes not verified in this development path. Preserve that
distinction until production monitoring is connected. The current comparison is a
text-only changed hunk against frozen synthetic source, not a live formatting diff.

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

Inject failure during candidate write, validation, promotion and reopening; include
disk/write failure, corrupt current with valid prior, valid current with corrupt
prior, semantically invalid archives and unsupported schema. Assert preservation
of acknowledged content, explicit recovery revision and no empty replacement.

Fake-provider tests assert that a follow-up uses the latest revision and surrounding
whole-note context, not the older recorded session. Mid-generation editing produces
Scratchpad changed and leaves the editor usable. Visible external Notes edits are
flagged automatically within one completed metadata/body-refresh cycle, nominally
five seconds plus the bounded coalescing/read time when available. Slow/failed reads
expose freshness limits rather than claim that timing. With a cached unchanged large
note, 20 scheduled ticks perform metadata reads only: zero body reads, reparses,
diff recomputations, tokenization passes, or model calls. Chat, diff and explicit
checked copy require body/id/date validation even when modification time is equal;
share covering reads and reuse parsing when content is unchanged. Ordinary copy
does not synchronously check Notes. Rapid edits produce at most one in-flight
read and bounded coalesced refresh; hidden/sleeping workspaces make no timer reads.
Two open workspaces for the same note share metadata/body reads rather than doubling
them. A monitor validates all stored associations affected by renumbering, not just
the visible editor's association.
Use synthetic multiweek notes and a large fixture (for example 1,000 program lines)
with reader/computation counters to verify costs; record measured timings, not a
promise derived from token length. Failed/stale reads cannot set a false matched
state, and opening a diff never triggers an API/model call.

Before handoff acceptance, author Heading, Subheading, Body, bold
text and a bulleted list from ordinary scratchpad text using only the keyboard.
Discover every shortcut in the Format menu, convert heading/list paragraphs back
to Body, and verify that unrelated paragraphs and chat text are unchanged. Undo
and redo must restore both text and semantic attributes; formatting-only edits
must advance scratchpad freshness and protect the affected region from shrinking.
Close/reopen must retain the result. Test Notes handoff with this coach-authored
formatting, not solely programmatically seeded fixtures. No native authoring pass
is claimed until these interactions are observed.

The explicit copy icon/whole-scratchpad shortcut supplies the approved Notes handoff
representation; native Paste as Markdown must preserve Heading, Subheading, bold and
continuing bullets for supported content. Verify conversion rather than assuming
exact spacing: the coach accepted one added blank separator after a bulleted list
before ordinary body text on 2026-10-14, but no broader spacing/formatting exception.
Verify native tiers rather than assuming
ordinary rich Command-V retains native tiers. The whole-copy shortcut is discoverable
in the menu without mouse movement. Ordinary editor Command-A/Command-C remains
immediate rich-selection copy and Notes-unverified, with no synchronous Notes check;
it does not promise native heading fidelity. This distinction follows the approved
2026-10-13 interaction, not a new exception introduced by implementation.
Copy alone never indicates saved/matched; automatic Notes monitoring verifies the
correct session or stays not verified. The diff toggle shows current or explicitly
last-known Notes versus the scratchpad in place of the editor, without requiring a
Check Notes control or losing editor content/undo on return. Heading-only skeletons contain no old exercise/dose/
warmup/result content. Conversations remain accessible after a break without an
extra permanent context/summary panel.

Externally edit the confirmed Notes session immediately before each whole-copy
checked path: the icon and whole-copy shortcut must warn and offer the existing diff.
Command-A/Command-C must copy immediately without a Notes preflight and must not claim
verification; automatic monitoring may independently surface a conflict. A confirmed
match must not produce a false overwrite warning.
Read failure/timeout warns without losing the scratchpad or falsely verifying paste.
Inject a late conflict after a checked copy, with and without intervening copies:
Gym Assistant shows the conflict and diff, while the clipboard remains unchanged
by the late result. An older scratchpad revision's result must not replace current
warning state. No clipboard warning replacement is implemented.
Partial-text/chat copy never invokes Notes. Test copy-preparation timing and rapid
copy/application-switch/paste so the coach can assess old-clipboard risk. Validate
equal-time edit detection and record the chosen shared freshness safeguard before
declaring monitoring accepted.

Confirmed canonical/alias mentions have truthful library decoration; unconfirmed
or ambiguous wording does not establish identity. Profile viewing exposes existing
provenance; chat cannot change the profile or library. Synthetic integration tests
record which inputs were sent, verify no hidden truncation, and exercise API failure
without new automatic charges. Live trials separately establish coach usefulness.

Fake-provider contract tests compare the complete application request with what
the adapter receives, including roles, evidence status and version identities.
Stale/unresolved association and oversized context must fail before submission.
Test edit/reassociation during generation, cancellation followed by late completion,
transport/provider failure and uncertain response delivery: no result is mislabeled
current, no submitted question is lost and no automatic retry occurs. Profile
fixtures include a machine-aversion tendency plus an explicit request for today's
leg press, an unconfirmed inference and an unevaluated transfer claim. Assert that
constraints override tendencies without rewriting the profile, and that uncertainty
and claim status survive assembly/display rather than being silently upgraded.

During a delayed fake response, type a follow-up and attempt both Enter and Send:
no second request occurs, no text disappears and the scratchpad stays editable.
Completion/failure does not auto-send it. Stop then explicit Send creates a new
request with fresh context; a late completion cannot revive the stopped reply.
For boundary UI, test direct highlighted start/end movement by keyboard and mouse,
preview/cancel, protected shrink and adjacent-owner display rather than accepting
the synthetic policy model alone as native interaction evidence.

## Idempotence and Recovery


Use a workspace registry to reuse existing session identities and serialize writes
for one workspace; a second window request brings forward its existing controller.
Never overwrite an unreadable snapshot, import a new schema over it, or silently
start empty. Keep the prior valid file and report its revision when recovering.
Local snapshots live outside Git under the app's Application Support directory;
keys live in Keychain if that proposal is approved. No automatic deletion or cloud
workspace sync is part of this slice. Back up before any later schema migration.

For each save, stage and validate a complete candidate before replacing acknowledged
state. Validation includes the supported schema, workspace/note/session identities,
revision and conversation consistency, and secure decoding of the formatted content;
successful JSON decoding alone is not enough. Preserve the previous validated copy
through promotion until the new saved file has been reopened and validated. Report
a save as acknowledged only after that validation; failed saves preserve the last
acknowledged state and expose the failure. Choose the file-level mechanics during
implementation and prove them with fault injection rather than mandating a storage
framework here.

On recovery, validate current and prior copies independently, identify the recovered
revision, and preserve damaged or unsupported files instead of overwriting them.
If neither copy is usable, keep a visible unavailable/recovery state; do not create
an empty replacement. An unsupported newer schema is refused non-destructively.
The first storage version needs no migration engine: later migration requires its
own tested, backup-preserving change. A migration must never replace its readable
input or recoverable backup with an unvalidated result.

Repeated synthetic runs may replace only their named temporary fixtures. Keep failed
capability results; do not weaken tests to match lost formatting. Revoke/read failure
does not switch to broad Accessibility or private Notes database access. Keep the
scratchpad, stop claims of current Notes context, and allow explicit retry or Copy.
Quit cancels work and flushes saved state; a retry after API uncertainty is deliberate
and may incur another charge. Do not infer a successful response after timeout.

## Artifacts and Notes


See [the earlier independent CLI review assessment](../design/SESSION_SCRATCHPAD_REVIEW.md) for the
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

Define a Foundation-only `ProgrammingAssistant` boundary and explicit
`ProgrammingRequest`, `ProgrammingResponse` and failure types in this module.
Use the immutable request identities, context versions and ordered messages described
in Milestone 3; the context assembler returns that request or a typed problem.
The fake and OpenAI adapters implement the same boundary. Provider payload encoding
and model-specific limit accounting stay in the adapter; native objects and API
response dictionaries do not become workspace state. Exact method spelling is an
implementation detail; correlation, cancellation and typed failure semantics are not.
Profile entries retain evidence category, provenance, confirmation and source-stated
scope/exceptions without adding a new numerical precedence scheme.

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

Revision note, 2026-10-14, fallback approval: the isolated pasteboard experiment
found no supported conditional compare-and-write across apps. The coach chose an
app-only late-conflict warning, leaving clipboard contents untouched after copy.
This supersedes the conditional clipboard-replacement proposal and adds acceptance
cases for unchanged clipboard and stale-result routing. No production code or
tutorial progress changed by this design revision.

Revision note, 2026-10-14, checkpoint reconciliation: remove active conditional-body
read and sequential-copy wording superseded by equal-date evidence and approved
parallel checked copy. Explicit copy uses the selected Notes Markdown handoff;
ordinary rich Command-C stays immediate and unverified. Record observed evidence
without claiming production fidelity, scheduling or implementation approval.

Revision note, 2026-10-14, independent-review resolution: clarify recovery validation,
non-destructive unsupported-schema handling, typed provider-neutral requests/results,
and existing preference evidence/conflict rules. Name the explicit Markdown handoff
without changing normal copy semantics. Record coach-verified Notes shortcut and
leave pending-message and boundary interaction decisions open. Documentation only;
no migration framework, production code, preference-learning scope or API defaults
were adopted.

Revision note, 2026-10-14, coach interaction choices: select direct highlighted
boundary movement in the read-only note browser. Record queue/cancel/steer as the
desired future direction and use the explicitly authorized send-blocking fallback
for the first slice, with editable unsent text and Stop. Add corresponding acceptance
scenarios; no production implementation or new passing-test evidence.

Revision note, 2026-10-14, implementation approval/preparation: accepted as PLAN 013;
Notes direction becomes ADR 005 and capability evidence PLAN 012 to avoid collisions
with merged alias guidance. Preserve the identical frozen mockups. Other-chat app
ownership prevents archiving the legacy checkout from this chat; do not remove it
manually. Client-history checkout is untouched. Begin local offline implementation
only after learner-baseline reconciliation; live API and target-branch merge remain
gated. Native UI fidelity/recovery tests remain required during implementation.

Revision note, 2026-10-14, offline implementation start: add real workspace/macOS
targets, a synthetic native development entry and regression tests without changing
the installed Service. Preserve unsent composer text, stop late responses, and refuse
close/quit after a failed save. Unknown copy formats fail rather than being silently
flattened. Locked Mac prevents native validation; leave this implementation work
uncommitted and record remaining real Notes/boundary/profile/library integration.

Revision note, 2026-10-14, unlocked native validation: test the initial synthetic
native path, fix the false freshness warning and add the regression without weakening
expectations. Add accessible editor/composer labels, visible composer boundary,
Window-menu reopening and discoverable Markdown-copy menu command. Preserve existing
Notes and no-paid-API boundaries. Record the bounded evidence separately; remaining
offline-slice integration is not marked complete.

Initial offline increment checkpoint: full verification passes five stages,
134 tests/17 suites. Native Edit-menu discovery and Command-Shift-C publication
were checked in the final temporary bundle. The app was quit with saved synthetic
state retained. Local checkpointing preserves the tested increment; production
Notes/boundary/profile/library work remains the next task. No target-branch merge,
push, paid API request or unrelated worktree change follows from this checkpoint.

Revision note, 2026-10-14, native reader/checked-copy continuation: record successful
app-specific consent and the bounded native fixture read. Add tested concurrent
publication/verification and fresh diff wiring for optional live contexts. Full
verification passes 163 tests and five stages. Native handoff still fails spacing
fidelity; compact-spacing control awaits approval to overwrite the clipboard.
No Service installation, target-branch merge, provider call or client-history change.

Revision note, 2026-10-14, approved spacing controls: native evidence supports compact
heading/body serialization and two-space body hard breaks. Correct the exporter and
add regression coverage without relaxing unsupported formats. All five verification
stages pass. The synthetic note's exported HTML is exactly restored after undo;
the clipboard retains synthetic control text. List-to-body blank separator acceptance
and native exported heading-wrapper reimport remain open; do not claim full fidelity.

Revision note, 2026-10-14, spacing acceptance: record the coach's narrow approval of
the list-to-body blank separator in the active contract. Implement and test exact
normalization of observed empty native heading export suffixes so they do not cause
false extra paragraphs or blanket rejection. Arbitrary styled/text-bearing wrappers
remain unsupported; native rebuilt round-trip acceptance is still outstanding.

Revision note, 2026-10-14, formatting-authoring scope: the coach approved first-slice
Format menu commands and discoverable shortcuts for Heading, Subheading, Body,
Bold and Bulleted list. Add implementation work and keyboard/native acceptance
coverage because retaining seeded styles alone does not make the scratchpad a
usable program-writing editor. No toolbar, broader formatting scope, implemented
control or passing native-authoring test is implied by this documentation update.

Revision note, 2026-10-14, formatting implementation: add the approved five commands
with local shortcuts, semantic transformation, protected revisions and composite
undo, plus visible list continuation. Native keyboard authoring/reopen/handoff
evidence and regressions expose/fix invisible list markers; final five-stage
verification passes. No Service installation, API call, profile learning or
client-history changes. Shared live workspace/boundary integration remains next.

Revision note, 2026-10-14, shared creation ownership: implement/test in-memory and
reopened ownership, overlap/staleness checks and failed-save atomicity. No new
workspace entry UI or installed Service integration is claimed. Native terminal
empty-paragraph differences remain a separate handoff acceptance question; only
the list-to-body separator exception is currently approved.

Revision note, 2026-10-14, terminal-blank acceptance: record coach approval and add
tested structured comparison without destructive normalization. Use the bounded
exception in live-context comparison/checked-copy baseline checks; absence of a
verified association still blocks those checks. No full reconciliation claim.

Revision note, 2026-10-14, entry ownership: implement captured-ID preparation and
window lifetime components with five regressions. Fix controller restoration after
verified relocation and remove the synthetic-only save label for live contexts.
Retain explicit outstanding UI/recovery/native acceptance work; tests are not a
claim of completed shortcut entry or completed PLAN 013.

Revision note, 2026-10-14, boundary transactions: implement and test the persistence
and ownership commit boundary, including failure after promotion, and add immediate
protected-selection preview to the existing synthetic browser. Keep live editing
disabled pending freshness-aware undo/redo integration; no native acceptance claim.

Revision note, 2026-10-14, live boundary wiring: connect preview/apply and safe
undo/redo to shared Notes validation and the persisted ownership transaction.
Supersede the preceding implementation-disabled note for optional live-context
windows only. The default development launch remains frozen/synthetic and Service
entry is still unconnected; native acceptance is not implied by package tests.

Revision note, 2026-10-14, Service entry: connect the Command-P route and independent
latest-session/permission UI, including lifecycle and development-mode labeling.
Supersede the preceding unconnected-Service note for this feature branch only;
the installed app and native acceptance status remain unchanged.

Revision note, 2026-10-14, skeleton extraction: implement the independent safe
headings-only proposal while asking the coach how new session labels should be
chosen. No inferred naming default, storage migration, new-session creation or
native acceptance is included in this increment.

Revision note, 2026-10-14, no-prompt naming: record and implement the coach's
number-or-letter increment with editable placeholder on ambiguity, replacing the
pending naming question. All five verification stages pass: 193 tests across 30
suites. No creation UI or recorded-session identity is inferred
from the placeholder.

Revision note, 2026-10-14, unrecorded foundation: implement schema-2 persistence,
legacy read compatibility and explicit addition context with five regressions.
No actual snapshot migration or new-session UI is claimed. Preserve old bytes and
backups and refuse recorded ownership for an unrecorded addition.

Revision note, 2026-10-14, new-session entry preparation: add non-writing preview,
explicit acceptance with a fresh source read, and durable resume before duplicate
creation. Synthetic concurrent/reopen/changed-source tests and all five verification
stages pass (201 tests/32 suites). New Session remains disabled until the
addition-aware controller and post-paste association path are connected and tested.

Revision note, 2026-10-15, unrecorded windows: connect the controller and window
registry to absent Notes associations, addition-aware chat/comparison and safe
unverified copy. This supersedes the earlier controller-refuses-unrecorded note;
it does not enable the programming entry button or claim post-paste reconciliation.
