# PLAN 011 — Test session-scratchpad capabilities without changing real programs

This living ExecPlan follows `PLANS.md`. It authorizes a bounded prototype, not production implementation or tutorial advancement.

## Purpose / Big Picture

The coach wants a freely editable session scratchpad beside conversation, with the whole Notes program available as context. Establish which integration capabilities actually work before building that experience. Demonstrate formatted local storage and clipboard serialization with synthetic content; separately test live Notes reading, session targeting, change detection, and paste fidelity. A local serialization pass is not a live Notes integration pass.

## Plan Status

In progress. The user approved the capability checkpoint on 2026-10-12, OpenAI API use and transmission of note/profile material, and no historical conversation import. No paid API requests or real-program modifications are part of this checkpoint.

Current status, 2026-10-13: checked icon/whole-copy command, separate from immediate
Notes-unverified Command-C, is accepted. Timing is approved as 400ms target/750ms
verification wait, with concurrent rich preparation/publication and continued late
verification; full-path measurement remains pending. Late-conflict clipboard warning
replacement is accepted only if that exact copy still owns the clipboard; any later
copy, including identical text, prevents replacement. Native ownership/race testing
remains pending. The exact public.html div/h1/h2/
h3 control failed native-style fidelity; the fixture was restored exactly. Native
fidelity fallback, private format, production plan and tutorial advancement remain
unapproved. Research follow-up found a working native Edit → Paste as Markdown
command on the current macOS 27 host: h1/h2/h3, bullets and bold passed the synthetic
fixture. Ordinary Markdown paste, single-item HTML and validated WebArchive did not.
This is a handoff candidate needing product approval, serialization and platform tests,
not permission to change the production clipboard contract.

Update, 2026-10-14: the contextual design was committed as `72b1020` and cleanly
reconciled with current `learner/main` as `e443f37`. The coach selected pursuing
Markdown handoff. Synthetic serializer checks pass 6/6, and the native Notes
Markdown command again preserved heading tiers on the current host. Keyboard-only
invocation and supported-platform behavior remain unverified. Isolated clipboard
ownership checks pass 13/13, but a cross-process guard/write race prevents claiming
the then-accepted exact-copy warning replacement is safe. The coach has now
superseded that proposal with an app-only warning for every late conflict; no
post-copy clipboard write is planned. Overall implementation is not approved.
Preserve the older source worktree until separately reviewed; do not merge its
older OST/architecture wholesale.

## Progress

- [x] (2026-10-13) Record coach approval of explicit checked copy versus immediate Notes-unverified ordinary copy.
- [x] (2026-10-13) Accept 400ms target/750ms verification wait and concurrent publication; exact div/h1/h2/h3 control produced bold Body, not native headings. Fixture HTML restored exactly, probe quit.
- [x] (2026-10-13) Record exact-copy ownership requirement for entire warning replacement; any later copy, including identical text, requires app-only warning.
- [ ] Measure full-path timing and test the approved late-conflict fallback: app warning/diff appears, and the late result never mutates the clipboard or overrides newer state.
- [x] (2026-10-14) Coach superseded conditional clipboard replacement with an app-only warning for all late conflicts; no post-copy clipboard write.
- [x] (2026-10-13) Read clipboard research sources and test single-item HTML, public WebArchive, ordinary Markdown paste and native Paste as Markdown. Only the native Markdown command retained tested semantic heading tiers; fixture restored and probe stopped.
- [x] (2026-10-13) Coach selected Markdown handoff direction and paused for branch/worktree fixup acceptance.
- [x] (2026-10-13) Selectively transfer the latest Markdown evidence and exact-copy clipboard decision into the learner-based integration line without replacing its learner architecture/OST.
- [x] (2026-10-14) Commit contextual design, reconcile current learner/main, run full repository verification and four synthetic suites; no production code changed.
- [x] (2026-10-14) Run isolated clipboard ownership suite (13/13), synthetic Markdown serializer suite (6/6), and native Markdown paste/readback; restore fixture exactly and quit probe.
- [ ] Validate serializer fidelity, platform availability, selection replacement and keyboard access before production acceptance.
- [x] (2026-10-12) Inspect existing Service lifecycle and selected design.
- [x] (2026-10-12) Record provider/data and bootstrap decisions.
- [x] (2026-10-12) Build and run isolated AppKit formatting/storage tests; heading and exact-character assertions fail honestly, other local checks pass.
- [x] (2026-10-12) Test live Notes through agent tooling after explicit inspection approval; full note, identity/reopen, reread freshness and bullet continuation demonstrated; HTML h3 hierarchy not preserved.
- [x] (2026-10-12) Test secure attributed-string archiving as a separate storage candidate; strict formatting and fresh-process restoration pass.
- [x] (2026-10-12) Check standalone probe permission without prompting; Accessibility trust unavailable even outside sandbox.
- [x] (2026-10-12) Inspect Notes's built-in data interface and check existing Automation access without prompting; unsandboxed standalone CLI diagnostic returns OSStatus 0.
- [x] (2026-10-12) Build and sign isolated read-only native API probe; no production code or installed Service changes.
- [x] (2026-10-12) Obtain explicit launch approval, fix the deployment target, and launch the packaged native probe through computer use.
- [x] (2026-10-12) Verify the packaged app's permission-negative path: -1744, no Notes read or consent prompt.
- [x] (2026-10-12) Obtain explicit Notes Automation consent approval; add request button and working Quit menu. Permission subsequently reports available; no broad Accessibility request.
- [x] (2026-10-12) Fix materialization of Notes selection list and verify native HTML/plaintext/identity/date reads with all 70 context lines and end marker.
- [x] (2026-10-12) Verify captured-identity rereads detect edits and still target the fixture after Notes selects another note; non-fixture refusal preserves target.
- [x] (2026-10-12) Restore synthetic note and quit probe; inventory confirms it stopped. The probe's Notes Automation permission remains enabled.
- [x] (2026-10-13 05:31Z) Run standalone synthetic association experiment: 30/30 assertions pass after fixing stale-registry offset handling; no Notes or rich-structure parsing involved.
- [x] (2026-10-13 local date) Native h3 reading and 20 metadata-only reads verified (1.877 seconds); native editor copy preserves bold/continuing bullets but fails Subheading fidelity.
- [x] (2026-10-13 local date) Nine API-captured snapshot checks pass after duplicate correction and 12/13 → 13/14 renumbering: combined 39/39; three-week Session A remains together.
- [x] (2026-10-13 local date) Restore the synthetic fixture after cleanup disturbed formatting; captured-ID reread verifies completeness/styles. Quit the probe.
- [x] (2026-10-13 local date) Record side-conversation boundary guidance without changing probes or test results: high-confidence native hierarchy, trailing Parking Lot inclusion, and always-available compact adjustment.
- [x] (2026-10-13 local date) Record approved scope-change policy and run separate synthetic boundary experiment: 24/24 pass; expansion preserves edits, protected shrinking is blocked, ownership/undo remain safe. Native tracking/UI not tested.
- [x] (2026-10-13) Hierarchy/typo/Parking Lot/skeleton policy: 13 synthetic plus six captured-native assertions, 19/19 pass; classification stays distinct from identity.
- [x] (2026-10-13) Native rapid edits show two body changes with unchanged formatted AND native dates; candidate shared safety-read coordinator passes 15/15 injected tests.
- [x] (2026-10-13) Large fixture measured: 1,000 lines, full reads 0.227–0.376s, twenty metadata reads 1.939s; restore original fixture and quit probe.
- [x] (2026-10-13) Alternate public exports and public-only native RTF control fail Subheading. Marked private-format diagnostic only; no encoder adopted.
- [x] (2026-10-13) Native 750ms simulated-copy test pastes OLD before copy completes at 0.753s; record required handoff decision.
- [ ] Validate native adjustment controls/keyboard/undo and automatic protected edit regions; models do not prove these interactions.
- [ ] Establish live session anchoring from Notes representations; synthetic text matching alone does not finish this item. Full rich paste, metadata reliability and copy timing also remain unverified.
- [ ] Coach handoff decision: public-rich-copy/manual-style correction or private-format investigation; distinguish explicit checked copy from ordinary immediate copy, or require waiting on every whole-copy path.
- [x] (2026-10-12) Record results and explicitly distinguish passes from untested capabilities.

## Surprises & Discoveries

Continued execution observes native-date/body collisions, not merely a possible
granularity risk. Large-note full reads took 0.227–0.376s; twenty metadata reads
took 1.939s on this host. Sampling can miss transient formatting/Undo states and
is not a change feed. The simulated 750ms copy pasted OLD before completion. Native
Notes' public-only RTF control also becomes bold Body; its separate private flavor
is a keyed archive with Notes classes and note-local cache/attachment state. Do not
turn that diagnostic into an unapproved dependency.

The scope-change fixture protects deleted content as well as visible additions:
an empty edited paragraph still retains its edit evidence. Source correspondence
is supplied explicitly in the toy model; native edit tracking is not established.
Uncertain correspondence blocks shrink, while expansion preserves existing content
and adds only the previewed edge. Undo rechecks current ownership and freshness.

2026-10-13 side-conversation clarification: higher native session-heading levels
are meaningful coach evidence, and a final Parking Lot is useful scratchpad context.
The text-only experiment does not test that distinction. These corrected cases and
always-available compact adjustment are pending, not additional passing assertions.

After unlock on 2026-10-13, Notes Subheading produced h3 in the API, but the native
editor's standard copy yielded RTF whose headerLevel decoded as 0. Notes identified
its pasted warmup as Body. Bold/continuing bullets passed; full hierarchy did not.
Twenty metadata-only reads took 1.877 seconds, not a production monitor benchmark
or equal-timestamp test. Captured plaintext snapshots pass the renumbering model
with 39/39 combined assertions, not rich-format comparison or confirmation UI.
Cleanup disturbed the fixture and required explicit restoration; original content
and style counts were verified afterward.

The follow-up synthetic association suite initially passed 28/29 assertions. A
fresh confirmation collided with old registry ranges after an earlier body grew.
Ranges must belong to an observation as a group, not merely carry a note identity.
The prototype now rejects a stale registry, re-resolves current verified mappings,
and retains unresolved prior evidence outside the current occupancy map. The
original expected confirmation behavior is preserved; no assertion was weakened.
The expanded suite passes 30/30. This models text-only fixture behavior, not Notes
HTML boundary extraction or supported rich-format equality.

Native continuation on 2026-10-12 local date stopped at a locked Mac. The computer-
use entry point explicitly requested manual unlock. No Notes API/background read,
new app launch, permission request or fixture mutation was attempted in response.

Selecting Notes through computer use was rejected because its initial accessibility snapshot could expose a real note. No real program was changed. Do not retry through another mechanism or bypass the safeguard. Complete local tests; ask the user to foreground a blank test note and authorize Notes inspection for this checkpoint.

The user later explicitly authorized Notes inspection and foregrounded a synthetic test note. Live-agent tests then demonstrated offscreen reading, a note identity stable across detached-window reopen, reread freshness and continuing bullets. HTML h3 normalized to native Heading rather than Subheading. Two identically named Session 1 sections illustrate why session label alone is insufficient. The standalone probe reports no Accessibility trust; no new permission was requested or granted.

RTF round-trip loses header level (2 becomes 0), preserves list metadata, but removes the literal tab/bullet/tab prefix. Bold survives. A sandboxed named-pasteboard write failed; approved unsandboxed execution passes both isolated-pasteboard assertions. A fresh process restores workspace identity, revision, conversation and RTF, not all original formatting. Seed and verify exit 1 for the real formatting failures.

Secure NSAttributedString archiving preserves all four strict formatting assertions and the complete typed snapshot in a fresh process. It is a tested candidate, not a production architecture decision.

The installed Notes scripting dictionary declares selection, identity, HTML/plain text and modification date. Standalone CLI Automation permission query returns -600 in sandbox and 0 unsandboxed without sending a read or requesting consent. A native read-only API probe compiles and signs, but launching newly built unrecognized software was rejected pending explicit user confirmation. Do not bypass that launch gate.

After explicit launch approval, Launch Services rejected the default macOS 28 minimum on a host reporting macOS 27. Rebuilding with `-target arm64-apple-macosx13.0` fixed launch; this is not evidence of testing on macOS 13. The packaged process returns Automation status -1744 and correctly stops without reading Notes or prompting. CLI permission availability did not transfer to the app. New Notes Automation consent remains an explicit approval boundary.

The user subsequently explicitly approved Notes Automation consent. After the request-button action timed out, the next observation showed permission available; no Allow-button action was observed or performed by the agent. Native reads then succeeded. Direct `item 1 of selection` failed; assigning selection to a local list first fixed the scripting specifier error. The read returned all 70 lines, HTML/plain text, identity and date. Captured-identity rereads detected changed HTML and an advanced date after a fixture edit, and continued to read the fixture after Notes selection changed. Read-selected refused the non-fixture note before reading its body.

The original prototype lacked a usable Quit menu. Computer-use access to system quit utilities was unavailable; the user quit it. A standard Quit menu now works and inventory verified final termination. Do not infer that the prototype's read baseline survives quitting: it is intentionally held only in memory.

## Decision Log

Decision, 2026-10-13, bounded research: test native Markdown interpretation as a new
clipboard route because Apple's current user guide documents it; retain HTML/archive
failures and distinguish a missing archive flavor from a valid archive test. No
product handoff or minimum-platform change is adopted solely from this fixture pass.

Decision, 2026-10-13, coach clarification: late session conflicts replace the entire
clipboard with a warning only if that exact scratchpad-copy operation still owns it.
Any later copy, even identical text, prevents replacement and uses the app warning.
Rationale: interrupt risky paste without clobbering subsequent user intent. Native
operation-ownership and guard/write race behavior remain to be tested.

Decision, 2026-10-13, coach: use a 400ms target and 750ms maximum verification wait,
prepare/publish rich clipboard content concurrently, and continue late verification
after a not-verified status. Rationale: faster manual handoff with a bounded wait.
Requested silent late-conflict warning replacement is not resolved: clarify whether
warning replaces or accompanies program text and how subsequent copies are protected.
Exact minimal div-heading control failed; native-style criteria remain unchanged.

Decision: Continue independent tests, then ask for concrete handoff decisions.
Propose public rich copy with manual native-style correction for the first slice,
and an explicit checked-copy command versus ordinary immediate unverified copy.
Neither is adopted. Further private-format research and uniform checked copy with
wait-before-paste are alternatives. Date/author: 2026-10-13, Codex.

Decision: Test body validation uniformly for safety consumers after date collisions,
retaining metadata-only idle ticks and unchanged derived-cache reuse. The injected
15/15 result is a candidate, not production monitoring. Date/author: 2026-10-13, Codex.

Decision: Correct the future boundary contract using coach guidance, while leaving
the existing text-only experiment and its measured results unchanged. Native heading
hierarchy is high-confidence evidence combined with text/surrounding structure;
exact Session spelling is not required. A trailing Parking Lot is retained with
the final scratchpad as ideas, not a new session or automatic cutoff. The coach can
always adjust either endpoint. The leading UI proposal is small top/bottom source-
offset markings opening a compact read-only browser via right-click or discoverable
keyboard commands, with up/down or drag adjustment. Exact shortcuts/display and
edited-scratchpad scope-change handling were unresolved at that review. Subsequent
approval chooses expansion preview preserving edits, shrink blocked by edited or
coach-added regions (no discard override), abutment allowed/overlap refused with
owner identification, and undo of range/content together with freshness/ownership
checks. The assumption that adjustment usually precedes editing remains a field
hypothesis. Rationale: coach structure
and useful ideas should not be lost to an overly literal grammar. Date/author:
2026-10-13, coach clarification recorded in the side conversation.

Decision: Retain the hierarchy failure as an open gate and recommend a bounded
alternative export experiment, not weaker requirements or a production workaround.
Rationale: bold-looking text is not a semantic Subheading. Date/author: 2026-10-13,
Codex. Store only guarded synthetic native observations with a constant synthetic
note ID; no device-specific identity needs to enter reusable evidence.

Decision: Keep the prototype under `spikes/session-scratchpad/`, outside production targets. Rationale: this tests capability, not an approved feature implementation. Date/author: 2026-10-12, Codex.

Decision: Separate rich-text serialization, native clipboard formats, and actual Notes paste semantics. Rationale: formatted fonts alone do not demonstrate an editable heading or continuing bullet list in Notes. Date/author: 2026-10-12, Codex.

Decision: Preserve the existing Option-Command-G Service and installed application. Rationale: no global shortcut or installed production behavior needs changing for these local tests. Date/author: 2026-10-12, Codex.

Decision: Test secure attributed-string archiving without replacing RTF expectations. Rationale: a separate candidate can prove heading/text preservation while retaining evidence that RTF alone fails. Date/author: 2026-10-12, Codex.

Decision: Test Notes-specific Automation before requesting Accessibility access. Rationale: the built-in data interface declares the needed whole-note properties, and a non-prompting standalone permission check returns available outside sandbox. This is a prototype route, not an accepted production adapter. Date/author: 2026-10-12, Codex.

## Outcomes & Retrospective

Current outcome: hierarchy 19/19 (including native snapshots), boundary policy 24/24,
freshness candidate 15/15, previous text association 39/39; new isolated clipboard
ownership 13/13 and synthetic Markdown serialization 6/6. Do not aggregate these
as native UI acceptance. Native Paste as Markdown retained tested heading tiers,
but keyboard route, editor extraction, literal escaping round-trip, platform
availability and full-path copy timing remain open. Strict atomic clipboard warning
replacement is not established and is no longer the chosen behavior. Original
fixture restored and probe quit. Native adjustment/tracking, production permissions/
recovery and implementation approval are pending.

The boundary-change policy has a separate 24/24 synthetic assertion pass. It validates
policy/model snapshots, not native undo, edit tracking, boundary-browser UI, hierarchy
detection or field usability. Earlier 39 association passes remain separate evidence;
do not describe this as 63 native acceptance tests.

Side-conversation documentation update, 2026-10-13: preserved all measured results
while adding corrected boundary criteria and proposed compact adjustment UI.
No source, running probe, Notes fixture, permissions or curriculum state was changed
by this update. Scope-change behavior after scratchpad editing remains unresolved.

2026-10-13 continuation: native access resumed. The suite passes 39/39; h3 is readable
and metadata-only reads are inexpensive on this fixture. Native-editor paste fails
Subheading fidelity. Rich-format anchoring, rapid-edit metadata and copy preflight
remain unproven. The plan remains in progress, with no production implementation.

Follow-up: `AssociationProbe.swift` establishes deterministic synthetic text ranges,
multiweek inclusion, stable local IDs through moves/renumbering, and guarded manual
confirmation. It also exposed and corrected stale-registry offset handling. Live
Notes representation/format extraction, timestamp experiments and keyboard handoff
remain pending manual Mac unlock; do not claim this entire plan complete.

Results are recorded in `docs/design/SCRATCHPAD_CAPABILITY_CHECKPOINT.md`. The RTF suite remains honestly red; the separate secure-archive suite is green. The native access gate is passed for the synthetic fixture after explicit Notes Automation consent: complete HTML/plaintext reads, identity/date retrieval, changed-baseline detection and target preservation across selection changes. The initial permission-negative path also remains evidence. Full copy hierarchy fidelity, session anchoring, production permission onboarding and real scratchpad recovery remain unresolved. Do not silently substitute clipboard import for whole-note access or claim the entire feature is implemented. Recommend a separate read-only Notes Automation context adapter while retaining existing Service invocation/autocomplete and clipboard handoff.

## Context and Orientation

The working checkout is a reusable design worktree on `codex/contextual-program-assistance`, not the learner checkout. `docs/design/SESSION_SCRATCHPAD.md` describes the approved bounded working-copy direction. Production `Sources/GymAssistantNotesService/main.swift` in the learner checkout has a synchronous autocomplete Service and an asynchronous library-review branch. The Service sends/receives plain text, not the complete note. Returning from a Service before opening a long-lived window is an observed existing code pattern, not proof of durable note targeting.

The prototype uses AppKit, macOS's native text/clipboard framework, and ApplicationServices for Notes Automation permission queries. Ordinary reads check permission without prompting; only the explicit consent button can prompt, after separate user approval. RTF means rich text format. An attributed string holds formatting as well as characters. A scratchpad snapshot is one atomically replaced local file containing formatted text, workspace identity, revision, and synthetic conversation messages; atomic replacement avoids splitting text and transcript across separate saves. The alternative secure archive encodes native attributed-string objects while requiring secure coding. Neither candidate is a finalized storage architecture.

## Plan of Work

Continued experiments: `HierarchyProbe.swift` parses constrained HTML fixture blocks
and separates hierarchy boundary detection from classification; `FreshnessProbe.swift`
uses an injected shared reader/clock. Extend `NativeNotesProbe.swift` with public
HTML/RTFD controls, marked clipboard diagnostics, twenty-second captured body/date
sampling, measured reads and a simulated delayed-copy button. Keep them outside
production targets. The XML parser resolves no external entities. Clipboard diagnosis
instantiates no private Notes classes and opens no referenced cache files. Edits in
Notes remain through computer use; scripts read captured, title/marker-guarded data.
Save synthetic results only in the temporary checkpoint folder. No private-format
encoder or changed production handoff behavior follows from these experiments.

Add `spikes/session-scratchpad/BoundaryAdjustmentProbe.swift` outside production
targets. Use synthetic paragraphs and explicit protected source fragments, including
deleted-fragment evidence and zero-length anchors for coach additions. Preview one
endpoint change against note/observation/workspace revision. Expansion inserts only
added edge content; shrinking refuses protected/uncertain regions. Identify adjacent
owners; refuse overlap. Preserve baseline/conversation. Apply content/range together;
undo refuses stale/occupied ranges or later edits. This is a policy experiment,
not selection of the production edit-tracking scheme.

The follow-up association experiment is standalone
`spikes/session-scratchpad/AssociationProbe.swift`, using synthetic strings only.
Recognize paragraph-aligned Session labels with numeric or letter/alphanumeric
identifiers and optional colon/dash suffix; Week labels stay within their session.
Use UTF-16 ranges bound to a SHA-256 observation digest and synthetic NoteID.
Match unchanged distinctive body text while excluding only the outer label;
identical/empty/changed content remains unresolved, and duplicates are exposed for
correction. Include closed workspaces in the one-to-one mapping. Manual confirmation
must match note/digest, current registry observation and paragraph boundaries;
reject stale, occupied and overlapping targets without touching scratchpad or
content baseline. The test covers exact ranges, multiweek sessions, bulk renumbering,
moves/insertions/deletions, ambiguous bodies, and failed confirmation invariants.
The parser is text-only: native hierarchy ambiguity and rich formatting still need
their own fixture evidence. Do not move this toy implementation into production.

Next boundary experiment must cover the corrected product rules, not merely add
spelling variants to the text grammar. Use native hierarchy as strong evidence for
session versus nested Warmup/week headings; surface ambiguous classification for
compact confirmation. Include a misspelled higher-level session title and a trailing
peer-level Parking Lot retained inside the final scratchpad. That parking lot is
attached non-session context and must not seed a new-session skeleton. Prototype
always-available boundary adjustment through compact source-range controls with
keyboard access; define/preview effects on an edited scratchpad without discarding
coach edits or changing identity. No UI mutation, new prototype code or live test
is authorized by this side-conversation documentation change itself.

First create `spikes/session-scratchpad/CapabilityProbe.swift`. Use only synthetic program content. Encode/decode formatted text; inspect bold, heading metadata and list metadata separately. Put the encoded content on a uniquely named test pasteboard rather than the user's clipboard. Save a typed snapshot atomically and verify it in a second process. Do not assert that a process restart is equivalent to reopening a complete app window or surviving all crash timings.

Also support `archive-seed` and `archive-verify` modes using `NSKeyedArchiver.archivedData(withRootObject:requiringSecureCoding:)` and `NSKeyedUnarchiver.unarchivedObject(ofClass:from:)` with NSAttributedString. Apply the original strict assertions to this candidate without weakening the RTF suite. The `permissions` mode calls `AXIsProcessTrusted()` only: it must not prompt or read another process's UI.

The `automation-permissions` mode checks Notes get-data permission with `askUserIfNeeded: false` and sends no read event. Build `NativeNotesProbe.swift` with `NativeProbe-Info.plist` into a separate temporary app named Gym Assistant Notes Capability Probe, using explicit target `arm64-apple-macosx13.0`. It uses the Notes data API for read-only selection/id/body/plaintext/date retrieval after a non-prompting preflight; it refuses non-fixture titles and missing end markers. Materialize selection into a local list before taking item 1. Expose read-selected, reread-captured and explicit access-request buttons, keeping the baseline in memory, with a standard Quit menu. Perform all native UI interaction through computer use. Launch and Notes Automation consent approvals have been given; only the explicit request action may ask for consent. Use no Service registration or installed app modification. Commands and actual native results are recorded in `docs/design/SCRATCHPAD_CAPABILITY_CHECKPOINT.md`.

After the user clears the access gate, create a uniquely named Notes test note through computer use. Test whole-note retrieval including an end marker beyond the visible viewport; note identity across switching/reopen; duplicate session labels; external text edits without changing the scratchpad; manual rich paste including continuing a list and inspecting the heading menu. A production-process read adapter still needs its own permission test: computer-use access alone does not establish that the gym-assistant executable has Notes access. Do not grant new macOS access without confirmation.

## Concrete Steps

Run the additional local experiments from this worktree:

    xcrun swiftc -target arm64-apple-macosx13.0 -module-cache-path /private/tmp/gym-assistant-scratchpad-checkpoint/module-cache spikes/session-scratchpad/HierarchyProbe.swift -o /private/tmp/gym-assistant-scratchpad-checkpoint/hierarchy-probe
    /private/tmp/gym-assistant-scratchpad-checkpoint/hierarchy-probe native /private/tmp/gym-assistant-scratchpad-checkpoint/native-hierarchy.json
    xcrun swiftc -target arm64-apple-macosx13.0 -module-cache-path /private/tmp/gym-assistant-scratchpad-checkpoint/module-cache spikes/session-scratchpad/FreshnessProbe.swift -o /private/tmp/gym-assistant-scratchpad-checkpoint/freshness-probe
    /private/tmp/gym-assistant-scratchpad-checkpoint/freshness-probe

Observed exit 0: hierarchy 19/19, freshness 15/15. The native-hierarchy artifact is
guarded API capture of Session 12/Sesion 13, native lower-level Warmup headings and
trailing peer-level Parking Lot. Synthetic mode alone has 13 assertions. Compile
the native probe with `-swift-version 6` added to its existing build command.

The twenty-second sampler reads both formatted and native date values while CUA
edits the fixture; preserve separate rapid-edit-watch.json and format-undo-watch.json
copies. The 750ms delayed-copy button stages OLD then schedules NEW; immediately
paste only into this fixture. It simulates preflight latency, not an actual Notes
read. Add 1,000 labeled performance lines for measured reads, then restore and
verify the original fixture. Do not record private IDs/cache paths in reusable docs.

Run the separate boundary-policy experiment from this worktree:

    xcrun swiftc -target arm64-apple-macosx13.0 -module-cache-path /private/tmp/gym-assistant-scratchpad-checkpoint/module-cache spikes/session-scratchpad/BoundaryAdjustmentProbe.swift -o /private/tmp/gym-assistant-scratchpad-checkpoint/boundary-probe
    /private/tmp/gym-assistant-scratchpad-checkpoint/boundary-probe

Observed exit 0 with 24/24 synthetic assertions; no app, Notes, clipboard or provider
access. Native keyboard/edit-tracking/undo acceptance remains pending.

The updated native probe has a rich editor and standard Edit menu. Use Load native
rich fixture, Command-C and Inspect synthetic clipboard (refuses text without
COPY PROBE), then manually paste into the named fixture through computer use.
Inspect Notes' selected style and press Return in its list. This replaces the
normal clipboard with synthetic text; earlier clipboard contents are not saved
or inspected. The metadata button performs 20 sequential captured-ID date reads
with a title guard and no body/plaintext properties.

Native reads save typed synthetic HTML/plaintext/date evidence to
`/private/tmp/gym-assistant-scratchpad-checkpoint/native-fixture.json`, replacing
the real note ID with synthetic-fixture. Preserve copies as native-before.json,
native-collision.json and native-after.json during renumbering; run:

    /private/tmp/gym-assistant-scratchpad-checkpoint/association-probe native /private/tmp/gym-assistant-scratchpad-checkpoint/native-before.json /private/tmp/gym-assistant-scratchpad-checkpoint/native-collision.json /private/tmp/gym-assistant-scratchpad-checkpoint/native-after.json

Observed exit 0 with 39/39 combined assertions. This local mode reads the guarded
snapshots, not Notes. Restore the synthetic fixture and verify before quitting.
Recorded successes do not prove behavior for arbitrary real notes.

From this worktree run:

    mkdir -p /private/tmp/gym-assistant-scratchpad-checkpoint
    xcrun swiftc -module-cache-path /private/tmp/gym-assistant-scratchpad-checkpoint/module-cache -framework AppKit -framework ApplicationServices spikes/session-scratchpad/CapabilityProbe.swift -o /private/tmp/gym-assistant-scratchpad-checkpoint/probe
    /private/tmp/gym-assistant-scratchpad-checkpoint/probe seed /private/tmp/gym-assistant-scratchpad-checkpoint/snapshot.json
    /private/tmp/gym-assistant-scratchpad-checkpoint/probe verify /private/tmp/gym-assistant-scratchpad-checkpoint/snapshot.json
    /private/tmp/gym-assistant-scratchpad-checkpoint/probe archive-seed /private/tmp/gym-assistant-scratchpad-checkpoint/archive-snapshot.json
    /private/tmp/gym-assistant-scratchpad-checkpoint/probe archive-verify /private/tmp/gym-assistant-scratchpad-checkpoint/archive-snapshot.json
    /private/tmp/gym-assistant-scratchpad-checkpoint/probe permissions /private/tmp/gym-assistant-scratchpad-checkpoint/unused.json
    /private/tmp/gym-assistant-scratchpad-checkpoint/probe automation-permissions /private/tmp/gym-assistant-scratchpad-checkpoint/unused.json

For the local association experiment, run from this same worktree:

    xcrun swiftc -target arm64-apple-macosx13.0 -module-cache-path /private/tmp/gym-assistant-scratchpad-checkpoint/module-cache spikes/session-scratchpad/AssociationProbe.swift -o /private/tmp/gym-assistant-scratchpad-checkpoint/association-probe
    /private/tmp/gym-assistant-scratchpad-checkpoint/association-probe

Observed exit 0, with 30/30 named synthetic assertions. This executable reads no
files or apps and writes no persistent data. It does not test live Notes boundaries.

Both invocations must emit individual capability checks and return nonzero on a failed required assertion. Record any formatting loss as a failed capability, rather than adjusting expectations to produce a pass. Use computer use only for subsequent native Notes interaction.

## Validation and Acceptance

Boundary policy requires preserving edits during previewed expansion and refusing
shrinking across edited/added/deleted or uncertain source regions. Exact abutment
identifies its owner; overlap is refused. Content/range undo is one operation and
cannot erase later edits or steal newly occupied ranges. Validate in native UI later;
the standalone model does not prove that UI. Field hypothesis: most adjustment occurs
before editing, making this restriction acceptable. It is not a measured finding.

The 2026-10-13 boundary correction adds pending evidence requirements: hierarchy-
aware recognition must not silently swallow a misspelled session title; trailing
parking-lot ideas remain in the final scratchpad; and either endpoint can always
be adjusted unobtrusively, including with discoverable keyboard commands. Scope
changes preserve workspace identity and coach edits. These are not existing passes.

Local evidence must establish text and bold preservation, explicitly report heading/list metadata fidelity, and establish formatted text plus conversation restoration in a fresh process. Only synthetic data may be saved. Live acceptance additionally requires full-note access with stable association, actual Notes paste semantics, and truthful external-change detection. User-visible close/relaunch/crash recovery and the new Service branch remain implementation acceptance work unless separately exercised in a native prototype. No API connectivity or model quality claims are possible from this checkpoint.

## Idempotence and Recovery

Repeated seed/verify overwrites only the named synthetic snapshot. Use no Notes deletion or real program edits. No automatic permission grants, installed Service changes, production edits, pushes, or curriculum progress changes. Design/evidence commits are separate reviewed checkpoints, not a side effect of rerunning a probe. Leave any live test note clearly labeled until the user requests recoverable removal.

## Artifacts and Notes

Revision note, 2026-10-13: completed the native-snapshot text association experiment
and direct metadata measurement. Rich clipboard hierarchy failed honestly; native
timestamp/cache and delayed-copy tests remain pending. Restored the synthetic note
and quit the probe. This is not implementation approval or tutorial advancement.

Save sanitized results in `docs/design/SCRATCHPAD_CAPABILITY_CHECKPOINT.md`, including exact commands, failed or unavailable capabilities, and the next access requirement. Do not record real note identifiers or contents in reusable files.

## Interfaces and Dependencies

Use system Swift, Foundation/CryptoKit for synthetic association, AppKit and ApplicationServices without new packages. Define Codable `Snapshot` and `Message` types. Keep probes standalone; do not add them to `Package.swift`, resolver code, or the Notes Service. Native pasteboard tests use `NSPasteboard.withUniqueName()` so the normal clipboard is not modified. The native app's NSAppleScript sends Notes data-read commands only, not UI actions or mutations; ordinary read preflights never request consent. The separate explicit request action uses `askUserIfNeeded: true` only after user consent approval.

Revision note, 2026-10-12: initial bounded plan recorded access rejection, then local RTF failures, a passing secure-archive candidate and live-agent evidence. Native launch approval led to a deployment-target fix and permission-negative evidence. After explicit Notes Automation consent approval, native reads and captured-target change detection passed, including switched selection and non-fixture refusal. Session anchoring and full copy fidelity remain unproven. Permission is enabled only for the test probe; production implementation and production access have not been approved by this checkpoint.

Revision note, 2026-10-12: originally assigned PLAN 009 in the main-based source
worktree to avoid collision with learner PLAN 004 (keyboard autocomplete). It was
renumbered PLAN 011 after the library-edit merge used PLAN 009 and PLAN 010. The user
accepted the read-only adapter recommendation now recorded in ADR 004. The native
access gate passed; this plan remains in progress because
session anchoring is unproven. The separate implementation proposal does not turn
that outstanding test into a pass or authorize production work.

Revision note, 2026-10-12 local date: continued the approved synthetic checkpoint,
added the standalone association suite and observation-scoped registry requirement,
and recorded 30/30 passes plus the initial failure. Live continuation awaits manual
Mac unlock. This is neither production implementation nor tutorial advancement.

Revision note, 2026-10-13: native continuation passed captured-plaintext association
and direct metadata measurement, but failed Subheading clipboard fidelity. Native
timestamp/cache and delayed-copy tests remain pending. The fixture was restored
and app inventory confirmed the probe stopped. Production work is not authorized.

Revision note, 2026-10-13, side-conversation correction: recorded heading hierarchy
as strong evidence, trailing Parking Lot inclusion and always-available boundary
adjustment with a compact browser/keyboard-access proposal. Added future validation
without changing existing test results or authorizing parent-thread execution.

Revision note, 2026-10-13, approved shrink/expand rule: record blocked protected-region
shrinking (no discard override), previewed expansion preserving edits, ownership
checks and atomic undo. Added the separate 24/24 synthetic policy experiment. Native
UI/edit tracking and the usual-before-editing field hypothesis remain unverified.

Revision note, 2026-10-13, autonomous continuation: record native date collisions,
large-note cost, hierarchy/native snapshots, shared-consumer candidate tests, public
hierarchy failures and delayed-copy race. Fixture restored. Handoff choices remain
explicit; no production approval, private-format dependency or tutorial advancement.

Revision note, 2026-10-13, research follow-up: read the Nathan Craddock plain-string
article fully, found Apple's documented Markdown paste route, and tested public
single-item HTML, validated WebArchive and both Markdown paste commands. Record the
native Markdown success with platform/serialization/keyboard limits. Restored the
synthetic fixture exactly; production handoff adoption remains an explicit gate.

Revision note, 2026-10-14: committed the approved design package and reconciled
the library-edit merge without losing learner architecture or OST. The repo's full
verification passed. Isolated ownership checks distinguish later identical copies
but reveal a non-atomic cross-process replacement gap. Synthetic Markdown emission
passes its limited fixture. Native Notes accepted the menu command again; captured
API readback verified heading tiers. Restored the test note byte-for-byte and quit
the probe. No production handoff implementation or tutorial advancement follows.

Decision/revision, 2026-10-14: after the cross-app guard/write race was explained,
the coach chose the app-only late-conflict fallback. Checked-copy publication
remains unchanged; subsequent verification only changes Gym Assistant's warning
and diff state, never clipboard contents. This supersedes the 2026-10-13 conditional
replacement decision. Validate stale-result routing and unchanged clipboard under
no-copy, identical-recopy, unrelated-copy, and later-scratchpad-copy cases. No
production code or tutorial progress changed.
