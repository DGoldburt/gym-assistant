# Session-scratchpad capability checkpoint

Date: 2026-10-12. Status: **native whole-note reading and captured-target change detection passed; formatting and session-anchor limits recorded**.
This is evidence from a disposable prototype, not production implementation or
approval to advance the tutorial. See [the bounded ExecPlan](../exec-plans/PLAN-011-scratchpad-capability-checkpoint.md).

## Decisions recorded

The user chose the OpenAI API and permitted all note and profile information to
leave the device for assistance. The first slice uses the associated note, current
scratchpad, existing coaching profile and new workspace conversations. It does not
import historical conversations. Existing historical research still informs the
profile and product design.

No API credentials were accessed and no paid API request was made. Model, budget,
credential storage and retention implementation remain unsettled. A proposed
default is locally owned conversation history and foreground Responses requests
with `store: false`, without hosted conversation objects or web tools. That is not
a zero-retention promise: official documentation distinguishes application-state
storage, abuse monitoring and other exceptions. See [OpenAI data controls](https://developers.openai.com/api/docs/guides/your-data).

## What ran

Standalone `spikes/session-scratchpad/CapabilityProbe.swift` uses system Swift and
AppKit. It is not referenced by the production package. Its fixture contains only
synthetic session text. It creates an attributed heading, bold exercise-slot label,
and bullet-list paragraph, then serializes them as RTF. It tests a native rich-text
editor without opening a window, a uniquely named pasteboard (not the normal user
clipboard), and a typed atomic snapshot containing workspace identity, revision,
RTF and a synthetic conversation message. A second process reloads that snapshot.

From the design worktree:

    mkdir -p /private/tmp/gym-assistant-scratchpad-checkpoint
    xcrun swiftc -module-cache-path /private/tmp/gym-assistant-scratchpad-checkpoint/module-cache -framework AppKit -framework ApplicationServices spikes/session-scratchpad/CapabilityProbe.swift -o /private/tmp/gym-assistant-scratchpad-checkpoint/probe
    /private/tmp/gym-assistant-scratchpad-checkpoint/probe seed /private/tmp/gym-assistant-scratchpad-checkpoint/snapshot.json
    /private/tmp/gym-assistant-scratchpad-checkpoint/probe verify /private/tmp/gym-assistant-scratchpad-checkpoint/snapshot.json

Compilation passed. Seed needs normal macOS pasteboard-service access; the sandboxed
run could not write the isolated board. The same synthetic probe with approved
unsandboxed execution passed both isolated-board assertions. Neither run accessed
Notes or the normal clipboard. Seed and verify both correctly exit **1** because
the strict heading and character-preservation assertions fail; they are not green
test suites. No expectations were weakened to hide those failures.

A second storage candidate uses secure native attributed-string archiving instead
of RTF. It keeps the same strict text/bold/heading/list assertions, saves the typed
snapshot atomically, and reloads it in a second process:

    /private/tmp/gym-assistant-scratchpad-checkpoint/probe archive-seed /private/tmp/gym-assistant-scratchpad-checkpoint/archive-snapshot.json
    /private/tmp/gym-assistant-scratchpad-checkpoint/probe archive-verify /private/tmp/gym-assistant-scratchpad-checkpoint/archive-snapshot.json
    /private/tmp/gym-assistant-scratchpad-checkpoint/probe permissions /private/tmp/gym-assistant-scratchpad-checkpoint/unused.json

Archive seed and verify exit **0**. Text, bold, header level 2, list metadata,
workspace ID, revision and conversation all pass. The original RTF verify still
exits **1**, retaining its two failed assertions. The permission diagnostic calls
`AXIsProcessTrusted()` without a prompt or any Notes read. It reports **unavailable**
in both sandboxed and approved unsandboxed execution. This is the standalone
probe's effective permission, not the installed gym-assistant application's status.

## Results and limits

| Capability | Observed result | What it does not establish |
| --- | --- | --- |
| Native formatted editing | PASS: NSTextView accepts an edit | Full scratchpad UI, autosave, keyboard branch or usable layout |
| RTF bold | PASS: bold trait survives decoding | Notes paste styling |
| RTF list metadata | PASS: one text-list object survives | Actual Notes list continuation or identical appearance |
| RTF heading metadata | FAIL: header level 2 decodes as 0 | A larger bold font is not proof of a semantic heading |
| Exact RTF character round-trip | FAIL: literal tab/bullet/tab prefix is removed | Does not prove the rendered list is missing; list metadata remains |
| Isolated rich clipboard | PASS: RTF/plain-text types accepted; RTF bytes retrieved intact | Normal Copy session action and Notes receiving it |
| Local save/reload | PASS: atomic snapshot; second process restores workspace ID, revision, conversation and RTF | Recovery of all formatting, app close/relaunch/crash behavior, concurrent-window ownership |
| Secure attributed-string archive | PASS: exact text, bold, heading/list metadata and conversation restored in a second process | Storage migrations, security against malicious files, full app recovery or cross-version compatibility |
| Whole-note reading | PASS via agent tooling and separately via packaged native app: 70 context lines and end marker; native HTML/plaintext/id/date retrieval | Installed production app's permission, arbitrary note lengths, locked notes or attachments |
| Note identity across window reopen | PASS: same Notes identity; test edits preserved | Durable session anchoring inside that note or account/device migration |
| Duplicate session labels | OBSERVED: two identical Session 1 labels remain distinct sections | Label alone is not a reliable session identity |
| External Notes changes and reconciliation | PASS for native captured-target reread: changed HTML and advanced modification date, same identity | Production polling/notifications, conflict UI, reconciliation or concurrent edits |
| Actual Notes rich paste | PARTIAL PASS: HTML yields native Heading, bold and continuing bullets; h3 is normalized to Heading, not Subheading | Full hierarchy fidelity, app-generated export or RTF paste behavior |
| Standalone native read permission | UNAVAILABLE: no Accessibility trust, including unsandboxed execution | Installed production application's permission status; no grant was requested |
| Notes Automation permission diagnostic | AVAILABLE for standalone CLI probe outside sandbox: OSStatus 0 | Permission for a separately packaged app, successful Notes data retrieval or adapter correctness |
| Packaged native read-only probe | PASS after explicit consent approval: native reading, changed-baseline detection and captured-target reads after switching Notes selection | Production packaging/permission onboarding, live scratchpad conflict UI or durable session anchors |
| Non-fixture selection guard | PASS: Read selected refuses a different selected note; subsequent captured-target reread still succeeds | A production access policy; this is a synthetic-probe safeguard only |
| New shortcut branch | UNTESTED | Existing production library-review branch returns the Service before opening its window, but no new branch was added |

For the failed character assertion, input contains `\t•\tOverhead preparation`;
RTF decoding returns `Overhead preparation` with a text-list object. This is a
representation change worth understanding, not an accepted silent normalization.
All other fixture text remains visible in the decoded synthetic output, including
the end marker.

## Consequences for implementation

Do not choose RTF alone as the complete durable scratchpad representation based on
this probe. The secure attributed-string archive is a viable local candidate for
the fixture, not an approved production storage choice. It is distinct from the
clipboard format. An implementation still needs format/schema versioning, recovery
and migration tests, and bounded secure decoding of locally owned data.

HTML handoff demonstrated real Notes headings and continuing bullets. The default
HTML h3 did not preserve Subheading hierarchy, so explicit export styling and a
heading/subheading round-trip test remain necessary. Do not declare full copy-format
fidelity based on this partial pass. No new UI or plain-text fallback is justified
by this result.

The existing Service supplies plain text, not whole-note context. The isolated
native app demonstrates that Notes Automation can obtain complete fixture content
and reread a captured note independently of current selection. Recommend a separate
read-only Notes context adapter, retaining the existing Service for invocation and
autocomplete and rich clipboard/manual paste for handoff. The user accepted this
direction in [ADR 004](../decisions/004-read-only-notes-context.md) on 2026-10-12;
the production adapter is not implemented. Production
permission onboarding, session association and conflict behavior still need explicit
contracts. No import fallback or repeated-context-pasting workflow is substituted.

## Live Notes test, 2026-10-12

Initially the computer-use safeguard rejected selection of Notes because its
automatic accessibility snapshot could expose real note content before reaching a
synthetic fixture. The agent did not retry via another API, grant permissions,
inspect Notes databases, or change any real program. The user subsequently explicitly
authorized Notes inspection and prepared a blank detached **Gym assistant capability
test** note. That cleared the agent access gate, not the native executable gate.

The agent pasted a synthetic HTML program containing two sessions, 70 numbered
context paragraphs, h2 session headings, h3 Warmup headings, a strong A1/B1 label,
unordered lists and an end marker. The initial cursor shortcut inserted before the
title rather than after it; the agent replaced only the confirmed synthetic test
note with the complete titled fixture and verified the title and content. This is
evidence not to assume cross-application cursor shortcuts or rely on an old cursor.

At scroll position 0 the complete accessibility representation still included
all 70 distinct context lines and the final marker. The screenshot showed only
the top portion. Notes's formatting popover selected **Heading** for the h2 session
line; it also selected Heading for h3 Warmup, exposing the hierarchy normalization.
Bold A1 and bullet appearance were verified. Pressing Return after the second
pasted bullet and typing **Added bullet after paste** produced another native bullet.

The agent captured the pre-edit state, replaced **Synthetic press** with **Synthetic
row — external change**, and reread it. The fresh read reflected the edit while the
captured state did not change. This is a freshness demonstration, not implemented
scratchpad reconciliation. Closing the detached window and reopening its list row
preserved the same note identity, changed text, new bullet and end marker. Finally,
both session headings were renamed **Session 1**; each section retained its different
content. No native stable session anchor was established by this test.

The agent inspected only as needed and edited only the synthetic note. The note is
left available, not deleted. Real note titles were visible after closing its window;
none are recorded in this reusable report. The tool's formatted accessibility
representation is not assumed to be the raw API or serialization available to our
app. All computer interaction used the authorized computer-use interface.

## Native data API candidate and app-process evidence

Inspection of the installed Notes application's own scripting dictionary at
`/System/Applications/Notes.app/Contents/Resources/Notes.sdef` establishes that it
declares selected notes, note identity, HTML body, plaintext and modification date.
This was interface evidence before native testing. The subsequent runtime tests
below establish successful fixture reads. The narrower candidate is Notes-specific
Automation, rather than broader Accessibility access; choosing it for production
still requires a recorded architecture decision.

The CLI probe's `automation-permissions` mode constructs a Notes target descriptor
and calls `AEDeterminePermissionToAutomateTarget` for a get-data event with
`askUserIfNeeded: false`. It sends no get-data event. Sandboxed execution returned
OSStatus -600; approved unsandboxed execution returned **0**. Do not mislabel the
sandbox error as a denied user permission. No consent prompt or permission grant
was performed by that diagnostic. The separate packaged application's permission
and reads were subsequently tested as described below.

Prepared `spikes/session-scratchpad/NativeNotesProbe.swift` and
`NativeProbe-Info.plist` as an isolated native app, not part of production targets.
The app contains **Read selected synthetic note**, **Reread captured note**, and
**Request Notes Automation access** buttons. Each read checks existing permission without prompting and
stops unless it is available. It uses only read operations, refuses selected notes
whose title is not **Gym assistant capability test**, and validates the synthetic
end marker. It reports completeness and changed-baseline status without writing
Notes, using an API command to show/switch Notes, or persisting Notes content.
Only the explicit access-request button may ask for consent. Reread uses the captured note identity rather than the current
selection. Title/end-marker guards are test-fixture restrictions, not a proposed
production targeting strategy.

Build from this design worktree:

    mkdir -p '/private/tmp/gym-assistant-scratchpad-checkpoint/Gym Assistant Notes Capability Probe.app/Contents/MacOS'
    cp spikes/session-scratchpad/NativeProbe-Info.plist '/private/tmp/gym-assistant-scratchpad-checkpoint/Gym Assistant Notes Capability Probe.app/Contents/Info.plist'
    xcrun swiftc -parse-as-library -target arm64-apple-macosx13.0 -module-cache-path /private/tmp/gym-assistant-scratchpad-checkpoint/module-cache -framework AppKit -framework ApplicationServices spikes/session-scratchpad/NativeNotesProbe.swift -o '/private/tmp/gym-assistant-scratchpad-checkpoint/Gym Assistant Notes Capability Probe.app/Contents/MacOS/NativeNotesProbe'
    codesign --force --sign - '/private/tmp/gym-assistant-scratchpad-checkpoint/Gym Assistant Notes Capability Probe.app'

Compilation and ad-hoc signing passed. The computer-use safeguard initially
rejected launch pending explicit approval; the agent did not bypass it. The user
then explicitly approved running this exact probe against the synthetic note.

The first approved launch failed with `kLSIncompatibleSystemVersionErr`. Inspection
found that the compiler's default binary minimum was macOS 28.0 while the host
reported 27.0. Rebuilding the same source with explicit deployment target
`arm64-apple-macosx13.0` produced a verified minimum of 13.0 and the app launched
through computer use. This fixes a prototype build assumption, not production
deployment support; no claim is made that the app was tested on macOS 13.

Clicking **Read selected synthetic note** returned:

    Native Notes Automation access unavailable (OSStatus -1744).
    No Notes read event or permission prompt sent.
    Explicit approval is needed before requesting new access.

This is a verified permission-negative path from the actual packaged process.
Unlike the standalone command-line check, its existing Automation permission was
not available at that point. No app-process content was retrieved before consent.
The two permission results must not be conflated.

The user explicitly approved requesting and approving **Notes Automation permission
for Gym Assistant Notes Capability Probe**, bundle identifier
`org.gymassistant.notes-capability-probe`. The OS permission permits controlling
Notes and is not restricted to one note or read-only operations. This prototype's
code is restricted to read-only synthetic-fixture inspection, but that restriction
is not an OS-enforced permission boundary. No broad Accessibility permission was
requested. The original prototype lacked a working Quit menu; computer-use access
to the system quit utilities was unavailable, so the user quit the probe. The agent
added a standard Quit menu and an explicit access-request button, then rebuilt the
same app. Clicking the request button timed out in computer use while consent was
pending; the next observation showed **Notes Automation permission available**.
The agent did not observe or click a macOS Allow button, so the report does not
attribute that dialog action to the agent. Actual subsequent reads verify that
permission became available. It remained available across a same-identity rebuild
and relaunch in this test; this is not proof of arbitrary production upgrade behavior.

The first native read failed because direct `item 1 of selection` did not materialize
the Notes selection list correctly. The probe was fixed to assign `selection` to a
local list before choosing its one note; the explicit non-fixture guard and end-marker
checks were preserved. After rebuilding, the read returned:

    PASS Native read-only Notes API access
    Context lines present: 70/70
    End marker: present
    HTML bytes: 4603; plain-text characters: 3591
    Captured target and baseline
    Identity matches baseline: true
    Native reread marker: false

Through computer use, the agent appended **NATIVE REREAD CHECK** to the synthetic
exercise line. **Reread captured note** then reported all 70 lines/end marker,
4627 HTML bytes, 3613 plaintext characters, an advanced modification date, the same
note identity, changed HTML relative to the unchanged captured baseline, and the
new marker. The native app itself did not write this edit into Notes.

The agent closed the fixture's detached window and selected a different existing
note without editing it. Captured-target reread still retrieved the original fixture.
**Read selected synthetic note** refused the new selection with **Refusing
non-fixture note**, before accessing its body. A subsequent captured-target reread
succeeded again with the original identity and changed-baseline status, demonstrating
that a refused selection does not replace the target. No private content or identity
of the other note is recorded in this reusable evidence.

The synthetic note was restored and the probe quit normally. Computer-use inventory
confirmed it was no longer running. Notes Automation permission remains enabled for
this probe; it has not been granted to the production app. The test proves native
complete-fixture reading, selected-note identification and captured-identity rereads,
including change detection after edits and switching selection. It does not implement
session-level anchoring, automatic polling, conflict UI or reconciliation.

## Follow-up synthetic association experiment, 2026-10-12

The standalone `spikes/session-scratchpad/AssociationProbe.swift` compiled with
system Swift, Foundation and CryptoKit, targeting arm64/macOS 13, and ran entirely
on synthetic text. No Notes access, clipboard access or production code change.

    xcrun swiftc -target arm64-apple-macosx13.0 -module-cache-path /private/tmp/gym-assistant-scratchpad-checkpoint/module-cache spikes/session-scratchpad/AssociationProbe.swift -o /private/tmp/gym-assistant-scratchpad-checkpoint/association-probe
    /private/tmp/gym-assistant-scratchpad-checkpoint/association-probe
    RESULT 30/30 synthetic association assertions passed; no live Notes or rich-structure parsing tested

Passes cover complete lettered three-week sessions, exact UTF-16 ranges (including
emoji before subsequent sections), descriptive/alphanumeric labels, incidental
text rejection, bulk renumbering/moves/insertion, closed-workspace identity, duplicate
exposure, ambiguous/empty/changed/deleted sections, and explicit confirmation with
stale note/observation/registry and occupied/overlapping/invalid range rejection.
Confirmation preserves scratchpad and prior content baseline.

Initial result was 28/29: valid confirmation was falsely rejected against old ranges
after a body-length change. Registry ranges now share the observation digest, fresh
verified mappings are re-resolved together, and unresolved prior evidence is kept
separately. The original expected behavior was retained and a stale-registry negative
test added. This is a useful correction to the proposed monitoring contract.

This proves a synthetic text model, **not** parsing Notes HTML/rich hierarchy,
native boundary confirmation UI, metadata timing, full Heading/Subheading paste,
or whole-copy keyboard latency. The live session-anchor gate remains open.
Computer use returned a locked Mac and requested manual unlock; no alternate
Notes access, native launch or permission request followed. `git diff --check`
passed; production feature tests were not run for this standalone prototype.

## Live continuation, 2026-10-13

The user unlocked the Mac and resumed the synthetic checkpoint. No new consent,
Service registration, production changes, paid API request or real-program edit.
The same approved probe bundle was rebuilt/signed and operated through computer
use. Its reads still refuse other titles and require the synthetic end marker.
Added a native rich editor with standard Edit-menu Copy/Paste/Select All commands,
a synthetic-clipboard inspector, and a metadata-only measurement button. Clipboard
inspection refuses payloads without COPY PROBE; actual Command-C uses the normal
clipboard, unlike the earlier isolated-pasteboard serialization tests.

Changing the first synthetic Warmup to native Subheading through Notes' Format
menu produced `<h3>Warmup</h3>` in the API HTML, alongside h2 session headings.
Thus native hierarchy can be read; this is not proof it survives clipboard export.

Twenty sequential metadata-only reads of the captured fixture took **1.877 seconds**;
all dates equaled the baseline. The script requested name for the fixture guard
and modification date, not body/plaintext. This measures direct sequential API
cost on one small note, not 20 production-monitor ticks, large-note responsiveness,
shared-cache behavior, equal-timestamp edits or UI-thread acceptability.

The native editor fixture used header levels 2/3, bold text and an NSTextList.
Standard Command-C produced RTF/plain-text clipboard flavors. Decoding its RTF
gave warmup headerLevel **0**, font size **17**. After manual paste into the test
note, Notes' Format popover identified that warmup as **Body**, not Subheading.
Bold and bullets were visible; pressing Return in the pasted list produced another
native bullet with COPY PROBE continued bullet. This handoff is a **partial pass**,
not full heading/subheading fidelity. Do not weaken the approved requirement or
claim all clipboard representations have been exhausted.

The probe saved title/end-marker-guarded fixture snapshots locally under
`/private/tmp/gym-assistant-scratchpad-checkpoint/`, replacing the real note ID
with synthetic-fixture. Captures included unique Session 12/13, a temporary 13/13
collision, the corrected 13/14 sequence and Session A with Weeks 1–3. Bodies were
not edited during renumbering. The standalone association experiment ran against
these API-captured plaintext observations:

    /private/tmp/gym-assistant-scratchpad-checkpoint/association-probe native /private/tmp/gym-assistant-scratchpad-checkpoint/native-before.json /private/tmp/gym-assistant-scratchpad-checkpoint/native-collision.json /private/tmp/gym-assistant-scratchpad-checkpoint/native-after.json
    RESULT 39/39 association assertions passed; production and rich-structure parsing not tested

Nine native-snapshot checks supplement the 30 synthetic assertions: expected ranges,
native h3 reading, all three weeks together, duplicate exposure, four stable IDs,
correct body-based relocation including a modeled closed workspace, and exclusion
of only outer heading text. These are not real persisted app workspaces, native
confirmation UI or rich-format-aware identity comparison.

Cleanup selection unexpectedly disturbed formatting/one label in the synthetic
fixture. It was restored explicitly from the original known synthetic content and
verified through UI and captured-ID reread: 70/70 context lines, original two
Session 1 labels, end marker, bold/bullets, h1:1/h2:4/h3:0, 4627 HTML bytes and
3613 plaintext characters. Only this fixture was changed. The probe was quit.
The normal clipboard retains synthetic copy-test text; no previous clipboard
contents were saved or inspected. Do not treat cleanup as a successful arbitrary
rich-text range-editing capability.

Remaining: a bounded alternative-export experiment for full native hierarchy,
rapid/format-only/undo timestamp behavior, shared monitoring/cache tests and the
copy-preflight keyboard race. Live plaintext association is demonstrated on this
fixture, but complete session anchoring and the capability plan remain open.

## Boundary scope-change experiment, 2026-10-13

The coach approved previewed expansion preserving existing edits, protected-region
shrinking with no discard override, abutment/owner identification without overlap,
and undo of range/content together. Record the assumption that adjustment usually
happens before editing as a field hypothesis, not evidence.

`spikes/session-scratchpad/BoundaryAdjustmentProbe.swift` is a separate disposable
Foundation/CryptoKit model, outside production targets. It supplies source-fragment
correspondence and protected flags explicitly, including deleted-content evidence
and anchored additions; no native edit tracker has been implemented.

    xcrun swiftc -target arm64-apple-macosx13.0 -module-cache-path /private/tmp/gym-assistant-scratchpad-checkpoint/module-cache spikes/session-scratchpad/BoundaryAdjustmentProbe.swift -o /private/tmp/gym-assistant-scratchpad-checkpoint/boundary-probe
    /private/tmp/gym-assistant-scratchpad-checkpoint/boundary-probe
    RESULT 24/24 synthetic boundary-policy assertions passed; no native editor/undo or automatic edit tracking tested

Observed exit 0. Assertions cover preview/no mutation, top/bottom expansion retaining
edits, untouched shrink, refusal across edited/deleted/added or uncertain regions,
owner-labeled abutment/overlap, stale Notes/scratchpad preview refusal, atomic model
undo and refusal of stale/occupied/later-edited undo. Neither Notes nor clipboard
was accessed, and no production code/curriculum progress changed.

These 24 assertions are separate from the earlier 39 association checks. They do
not prove native boundary controls, edit detection, rich formatting, keyboard
interaction, undo-manager behavior, or field usefulness. Full clipboard hierarchy,
rapid-edit freshness and delayed-copy timing remain open.

## Continued capability execution, 2026-10-13

The coach asked to continue autonomously until input is genuinely required. Work
remained within PLAN 011: synthetic probes, the named fixture, and read-only Notes
API operations. No production code, API calls, Service installation, Git commit,
tutorial progress or new OS permissions.

### Corrected hierarchy and freshness evidence

`HierarchyProbe.swift` reads constrained native-style HTML without resolving external
entities. Its 13 synthetic assertions cover native hierarchy, spelling-independent
peer boundaries, unconfirmed classification, multiweek grouping and attached Parking
Lot/skeleton exclusion. Six additional assertions run against a real captured fixture
whose Warmup sections were assigned native Subheading in Notes, with Session 12,
Sesion 13 and a peer-level Parking Lot. Combined **19/19** pass. Unknown classification
is not durable identity. Arbitrary HTML, native adjustment-browser UX and automatic
edit tracking remain unproved; the separate boundary model remains **24/24**.

    xcrun swiftc -target arm64-apple-macosx13.0 -module-cache-path /private/tmp/gym-assistant-scratchpad-checkpoint/module-cache spikes/session-scratchpad/HierarchyProbe.swift -o /private/tmp/gym-assistant-scratchpad-checkpoint/hierarchy-probe
    /private/tmp/gym-assistant-scratchpad-checkpoint/hierarchy-probe native /private/tmp/gym-assistant-scratchpad-checkpoint/native-hierarchy.json

The read-only native sampler captured **98 snapshots in 20 seconds**, with two body
transitions at approximately 9.890 and 10.073 seconds. Both occurred with unchanged
formatted modification dates **and unchanged native date values**. Metadata equality
therefore demonstrably fails as a body-version guarantee. Text was entered/removed
only through Notes UI; the sampler sent read events only. A fast format/Undo window
observed no transitions; a dwell window observed one transition, with a later reread
restoring the original unbolded marker. These samples can miss transient UI changes
and do not establish an API change-feed or a guaranteed UI/API settling interval.

The 1,000-line extension was counted from the captured API plaintext: 1,000 performance
lines, approximately 56,000 plaintext characters and 68KB HTML. Two full native
body/id/date reads took **0.376 and 0.227 seconds**. Twenty sequential metadata-only
reads took **1.939 seconds**. Do not treat these few host-specific samples as an SLA.

`FreshnessProbe.swift` tests a candidate safeguard with injected readers: metadata-
only shared idle ticks, body validation for every safety-consumer class, sharing
covering reads and reusing parsing/diffs if content is unchanged. A consumer arriving
after body capture waits for a later read. Failure retains last-known context with
unavailable status; monitoring makes no model calls or tokenization passes. **15/15**
pass on a synthetic 1,000-line body. This is not production scheduling or native
performance acceptance.

    xcrun swiftc -target arm64-apple-macosx13.0 -module-cache-path /private/tmp/gym-assistant-scratchpad-checkpoint/module-cache spikes/session-scratchpad/FreshnessProbe.swift -o /private/tmp/gym-assistant-scratchpad-checkpoint/freshness-probe
    /private/tmp/gym-assistant-scratchpad-checkpoint/freshness-probe

### Public export and keyboard findings

Additional actual paste tests retained failures: RTFD-only export, explicit h2/h3
HTML, adjacent h3/h4 HTML, and canonical Notes-shaped h2/h3 HTML did not preserve the
required native Subheading. Bold/bullets and visual heading cues are partial evidence,
not semantic-style fidelity. The canonical appended headings appeared as bold body
paragraphs in the API. This is not proof that every possible public representation
fails on every supported host.

A native Notes Subheading copied through Command-C included public RTF plus
`com.apple.notes.richtext`. Public RTF decoded with headerLevel 0, font size 13 and
HelveticaNeue-Bold. Re-pasting only those unchanged public RTF bytes yielded bold
Body, not native Subheading: the control rules out assuming a better ordinary RTF
serializer alone will preserve these styles.

Only the marked synthetic private clipboard payload was diagnosed. It was a keyed
archive containing Notes-specific `ICNotePasteboardData`/`ICDataPersister` classes,
encoded attributed-text data and note-local attachment/cache references. No private
Notes database or frameworks were accessed; no referenced cache files were opened,
classes instantiated, or private encoder introduced. The diagnostic artifact stays
in temporary storage and contains fixture-local identity; do not add it to reusable
Git. This dependency would need explicit design approval before further engineering
or production adoption.

A native delayed-copy experiment staged known OLD/NEW synthetic clipboard text.
Immediate keyboard paste inserted **OLD**, while the scheduled copy completed
after **0.753 seconds**. This simulated a delay within the proposed one-second
preflight budget; it did not measure an actual Notes preflight. It demonstrates
that a Copying badge cannot prevent pasting previous clipboard contents before an
asynchronous copy finishes.

The probe's recapture diagnostic also needed a correction: compare the previous
date before assigning the new baseline. Otherwise recapture could falsely report
same-date change. This correction does not invalidate the independently recorded
sampler's native date/body pairs. The final source compiles in Swift 6 mode.

### Research follow-up and native Markdown breakthrough, 2026-10-13

The [Nathan Craddock article](https://nathancraddock.com/blog/writing-to-the-clipboard-the-hard-way/)
was read in full. It demonstrates plain-string clipboard access through Lua,
Objective-C, C and Zig; its footnote explicitly limits the examples to strings.
It does not discuss native Notes heading mapping or require HTML plus plaintext.

[Apple's current Notes guide](https://support.apple.com/guide/notes/import-export-and-print-notes-not201900c07/mac)
documents formatted Markdown paste. This supplied a materially different, supported
lead. A maintained [Notes integration's own report](https://github.com/sweetrb/apple-notes-mcp/blob/main/README.md)
also distinguishes HTML's bold-only headings from Notes-native Markdown interpretation;
its Shortcuts/import route is not adopted or executed here. The WebKit SDK's public
WebArchive data API and [webArchive UTI](https://developer.apple.com/documentation/uniformtypeidentifiers/uttype-swift.struct/webarchive)
justify a separate representation control, not an assurance Notes accepts it.

All controls were performed through the disposable native probe and manual Notes UI
against only the synthetic fixture, on the current macOS 27 host. No private formats,
extra permissions, third-party installations, Notes API writes or production changes.

| Control | Actual publication / invocation | Observed native result |
| --- | --- | --- |
| Single-item HTML | One NSPasteboardItem; plaintext first, UTF-8 HTML Data; one writeObjects call; both modern/legacy types visible | FAIL native headings: Title/Heading/Subheading became bold div Body; h1:1/h2:4/h3:0 unchanged |
| Plain Markdown, ordinary paste | One plaintext item; Command-V | FAIL interpretation: literal #/##/### and list/bold markers; headings unchanged |
| Plain Markdown, native command | Same plaintext Markdown; Edit → Paste as Markdown | PASS tested semantic tiers: API returned actual h1/h2/h3 for labeled lines, ul/li bullets and bold A1; AX showed Title/Heading/Subheading rather than literal markers |
| WebArchive | Public WebArchive generated from HTML, com.apple.webarchive plus plaintext, both modern/legacy archive types verified; Command-V | FAIL native headings: plain div Body; headings unchanged |

An initial legacy WebArchive type setter did not publish the archive flavor; its
plain-text paste is not an archive-capability result. The corrected modern UTI setter
was checked for success and the actual flavor inventory verified before rerunning.
WebArchive is a deprecated public SDK API (Swift 6 compile succeeds with that warning),
not a recommended production dependency. No unsupported Notes encoder was involved.

The Markdown fixture included # Title, ## Heading, ### Subheading, body text, two
bullets and bold A1. Native readback returned h1:3/h2:6/h3:2 including the unchanged
baseline: extra heading-tag counts are line-break markup inside those paragraphs,
not duplicated labeled headings. Each labeled heading appears once in plaintext.
Representative returned fragment: `<div><b><h3>COPY PROBE MD Subheading</h3></b>…</div>`.
The Markdown test's HTML was 5199 bytes, plaintext 3739 characters; ordinary Markdown
paste was 4912/3757, single-item HTML 4802/3708, validated WebArchive 4781/3708.
Sanitized synthetic snapshots remain in temporary storage under markdown-native-paste,
markdown-ordinary-paste, single-item-html-paste and webarchive-uti-paste JSON filenames.

This is a promising first-slice handoff candidate, NOT accepted product behavior or
full-fidelity acceptance. It changes the coach's paste action and requires a faithful
rich-scratchpad-to-Markdown serializer, escaping/literal-text/blank-line tests,
coexisting rich-format tests if retained for other destinations, and explicit platform
availability behavior. No keyboard shortcut for Paste as Markdown was verified;
the menu command was observed and invoked. The documented shortcut list does not
establish a binding for it. Older supported hosts, arbitrary rich content, unknown
paragraph styles, tables/attachments, and selection replacement are untested.
Markdown import/Shortcuts are alternatives but broader than clipboard/manual paste;
private Notes representation research still requires explicit authorization.

Undo restored the fixture byte-for-byte to the captured HTML baseline: 4627 bytes,
3613 plaintext characters, 70/70 context lines and end marker, identity unchanged.
The probe was quit and app inventory confirmed it stopped. Clipboard was left with
marked synthetic WebArchive/plaintext; the pre-test clipboard was not backed up.
Documentation diff checks pass. Production implementation and curriculum progress
remain unchanged; no public-format manual-style fallback was silently accepted.

Latest clarification, 2026-10-13: the coach approves replacing the entire clipboard
with a warning only while it belongs to the exact scratchpad-copy operation. Any
subsequent copy, including identical text, requires leaving clipboard untouched and
warning in the app. Per-operation identity/changeCount guard is a candidate, not
native race-proof evidence; test identical recopy and guard/write concurrency.

The second supplied heading explanation was source-checked. Our div control already
published both public.html and public.utf8-plain-text; missing plaintext cannot
explain its failure. The cited [macos-pasteboard issue](https://github.com/chbrown/macos-pasteboard/issues/8)
concerns Chrome/TextEdit, not native Notes heading tiers. The cited
[Notes extension report](https://github.com/anthropics/claude-ai-mcp/issues/924)
concerns add/update writes and explicitly says nesting h1 in div made no difference.
The [clipboard article](https://nathancraddock.com/blog/writing-to-the-clipboard-the-hard-way/)
and [Swift example](https://nilcoalescing.com/blog/CopyStringToClipboardInSwiftOnMacOS/)
describe general clipboard writing, not verified native-heading preservation.
Thus these sources do not establish the supplied guarantee. The Python example
uses sequential pasteboard setters, not a conditional/atomic multi-format commit;
our earlier native control also used sequential setters (HTML first, then text).
A further packaging control could use one NSPasteboardItem populated with UTF-8 HTML
data and plaintext, then writeObjects once, checking actual published types/bytes.
That exact variant is not tested and must not be reported as passed or impossible.
No dependency installation or pasted third-party code was executed.

The coach then selected pursuing Markdown handoff as the next design direction.
This does not approve production handoff or waive the serializer, keyboard,
selection-replacement and platform checks above.

### Decision boundary and recovery

Earlier update, 2026-10-13: accepted target 400ms and limit 750ms for verification
waiting, with rich preparation/publication concurrent with the Notes read. Continue
late verification; the requested silent clipboard warning replacement was then unresolved
due to warning-only paste and subsequent-copy overwrite risks. Full-path timing is
not measured. These decisions supersede the earlier timing proposal below.

The exact div control was executed, not merely inferred from similar tests. The
native probe published only public.html plus plaintext, no CSS/RTF, containing
`<div><h1>COPY PROBE DIV Title</h1></div>`, the same wrapper around h2 Heading and h3
Subheading, and a p Body control. Manual Command-V appended it in the named synthetic
note. Native API reread returned `<div><b>…</b></div>` for all three heading candidates
and `<div>…</div>` for Body. Heading counts stayed h1:1/h2:4/h3:0; HTML grew from 4627
to 4798 bytes, text from 3613 to 3704 characters. Thus the exact recipe failed
native Title/Heading/Subheading fidelity on this host. Format-menu inspection was
attempted, but AX exposed no selected-style mark and screenshot was unavailable;
the native API structure is the decisive evidence, not an inferred menu checkmark.
Synthetic before/after JSON snapshots remain in temporary storage. Undo restored
HTML byte-for-byte to the captured baseline (4627 bytes, 3613 characters, 70/70 context
lines, end marker, same note identity). App inventory confirmed the probe exited.
Clipboard still contains marked synthetic public.html/plaintext, not private data.
Native probe Swift 6 compilation and documentation diff checks pass; no production
code, real program or tutorial progress changed.

Update, 2026-10-13: the coach accepted explicit checked copy, separate from immediate
ordinary Command-C, and requested timing evidence and an acceptable upper bound.
Proposed, not approved: 500ms normal target on the tested 1,000-line fixture and
1,000ms maximum end-to-end app wait; timeout publishes rich content with an explicit
Notes-not-verified warning. Existing 227–376ms body reads exclude export/publication;
full-path timings and injected slow/hung-reader tests remain pending. The native-
heading/manual-correction fallback below remains unapproved.

The coach supplied a hypothesis that exact `<div><h1>…</h1></div>` / h2 / h3 wrappers,
without CSS and declared as `public.html`, preserve native paragraph styles. The
[linked Stack Overflow discussion](https://stackoverflow.com/questions/59341657/apple-script-how-to-i-append-the-clipboard-with-formatting-preserved-to-a-note)
was inspected: it concerns converting clipboard text and assigning the Notes HTML
body through AppleScript, not this public.html paste mapping or a guaranteed div
wrapper rule. Do not treat the supplied explanation as established evidence.
Existing similar canonical/heading tests failed, but the exact minimal wrapper
control is pending: publish public.html plus plain fallback only, no competing RTF;
paste into the synthetic fixture, inspect native styles and reread API h1/h2/h3;
restore the fixture afterward. No automatic body assignment or private format.

Original proposals before the update above: for the first slice, use public rich copy
with honest native-heading limitations/manual Notes style correction, rather than
depend on the private format. For copy semantics, distinguish an explicit checked
copy icon/shortcut (wait for Copied) from immediate standard Command-C (unverified
until an asynchronous check completes). These relax parts of the prior full-fidelity/
uniform-copy contract; only the checked-versus-ordinary distinction is now approved.
Alternatives are further private-
format investigation and retaining checked delay for all whole-copy paths with an
explicit wait-before-paste requirement. Neither authorizes Notes write-back.

The fixture was restored: original two Session 1 headings, 70 context lines, end
marker, bold/bullets, h1:1/h2:4/h3:0, 4627 HTML bytes and 3613 plaintext characters.
All experimental headings, typo, Parking Lot, performance lines and copy-race text
were removed from this test note. A corrected captured-ID read verified restoration.
The probe was quit; no production app was changed. Clipboard was left with marked
public synthetic RTF/text only, not the private Notes payload. No pre-test clipboard
contents were saved. File diagnostics and raw fixture artifacts remain temporary.

## Remaining implementation contracts

Final verification for this continuation: the prior association suite still passes
39/39; hierarchy/native fixture 19/19, boundary model 24/24 and candidate freshness
model 15/15. Fresh-process secure archive verify passes its six assertions. Original
RTF verify still exits 1 for the same text/heading losses; no expectations were
weakened. The final native source compiles in Swift 6 mode. Nine-document link/
whitespace/basic-private-material checks and `git diff --check` pass. Application
inventory confirms the probe stopped. Production feature tests were not run because
none were implemented. The reusable package was subsequently committed on the
learner-based contextual integration branch; capability gates remain open.

The read-only context-adapter direction is accepted in ADR 004. Review
[the proposed implementation plan](SESSION_SCRATCHPAD_IMPLEMENTATION_PLAN.md) and
agree its criteria before dependent production work. Distinguish stable note
identity from identifying a session inside its editable body; repeated Session 1
labels cannot serve as a durable key. User-visible close/relaunch/crash recovery,
full heading/subheading export fidelity and the new Service branch remain unverified.
Production permission denial/revocation must expose unavailable context rather than
reuse another note silently. No paid API or model-quality test ran in this checkpoint.

The design package was committed as `72b1020` and reconciled with the then-current
`learner/main` as `e443f37` on `codex/contextual-learner-integration`. No production code, installed
application, mock-ups, tutorial progress or real Notes program was changed.
ADR 004 records the subsequently accepted direction, not production behavior.
The synthetic Notes test note was populated and modified as
described above. Temporary outputs contain only synthetic fixtures.

## Follow-up handoff tests, 2026-10-14

The standalone `ClipboardOwnershipProbe.swift` used only an isolated, uniquely
named pasteboard. Its 13/13 assertions passed for uninterrupted warning
replacement, an identical later recopy, an unrelated later copy, two successive
scratchpad copies, and a simulated copy inserted between ownership checks.
Operation UUID plus `changeCount` distinguishes copies even when text is identical.
It does **not** implement the accepted strict warning-replacement contract: the
public pasteboard API exposes no atomic compare-and-write, so another process can
copy after the final check but before the warning write. Do not ship this routine.
Use an app-only late-conflict warning when exact ownership cannot be guaranteed;
changing the product contract needs coach approval.

The standalone `MarkdownHandoffProbe.swift` passed 6/6 synthetic serializer
assertions for heading tiers, literal punctuation escaping, bold exercise labels,
leading whitespace, terminal newline and rejection of embedded newlines. It starts
from typed blocks, not real attributed-string extraction, and does not prove
escaped literals or spacing survive native Notes paste. Both probes remain outside
production targets. The isolated pasteboard test needed normal macOS pasteboard
access; its sandboxed write failed and the approved unsandboxed run passed.

On the current macOS 27 host, the native probe published plain Markdown and Notes
showed an enabled **Edit → Paste as Markdown** command. Invoking it on the synthetic
note produced h1:3/h2:6/h3:2 in a captured-target API reread (baseline
h1:1/h2:4/h3:0), with the labeled tiers, bullet and bold label visible. No keyboard
shortcut was verified. One Undo removed the paste; a second Undo unexpectedly
removed part of the pre-test final line, so the agent restored that line explicitly.
Final captured-target reread matched the exact pre-test HTML (4,649 bytes) and
plain text (3,624 characters), with 70/70 context lines, end marker, same identity,
and h1:1/h2:4/h3:0. The synthetic note remains available. The general clipboard
contains only the marked synthetic Markdown published for this test; no previous
clipboard contents were saved or restored.

Apple's [current Notes guide](https://support.apple.com/guide/notes/import-export-and-print-notes-not201900c07/mac)
documents formatted Markdown paste. The [macOS 26 guide](https://support.apple.com/guide/notes/not201900c07/4.13/mac/26)
documents Markdown file import/export but does not establish clipboard-command
availability; absence from that page is not evidence the command is absent.
Supported-platform behavior and keyboard-only invocation remain open tests.
The test probe was quit; app inventory confirmed it stopped.
