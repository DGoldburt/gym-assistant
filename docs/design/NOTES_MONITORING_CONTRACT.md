# Notes monitoring and session association

Status: proposed implementation contract, 2026-10-12. Records the coach's approved
automatic-refresh/diff interaction and the requirement to survive session-heading
renumbering. It does not approve production implementation or declare the remaining
native capabilities tested. Complements the self-contained
[implementation proposal](SESSION_SCRATCHPAD_IMPLEMENTATION_PLAN.md).

## What monitoring owns

One read-only monitor per captured Notes note identity supplies observations to
that note's open session workspaces. It owns refresh scheduling, freshness, and
cached Notes content. It never edits Notes or a scratchpad, creates new workspaces
because a heading changed, or calls the model. Whole-scratchpad copy is also a
pre-handoff safety checkpoint, not merely export; copy, diff, and chat share the
freshness policy below. None is an automatic synchronization/write request.

A local SessionID and WorkspaceID are stable identities. A heading such as Session
12 is a mutable label and location clue, not a registry key. Renaming Session 12 to
Session 13 must not turn its workspace into a new one, collide with the workspace
previously labeled Session 13, or automatically rename either scratchpad's text.
The note's opaque identity still bounds all association; changing Notes selection
does not retarget a workspace.

Maintain three distinct things: the live editable scratchpad, the last confirmed
session baseline in Notes, and the latest observed Notes snapshot. A fresh observation
is not permission to replace the scratchpad or erase the baseline. A response also
records which Notes observation and scratchpad revision informed it.

## When it is called

The following timings are proposals to verify, not measured performance promises.

| Trigger | Read/work performed | Effect on the workspace |
| --- | --- | --- |
| Ordinary autocomplete | None from this monitor | Autocomplete is unchanged; no Notes permission prompt. |
| Program session entry | Bounded, non-prompting selection capture; full read after access is available | Capture one note identity; open/resume a workspace only after resolving the chosen session. Release the Service before onboarding or long-lived work. |
| Open/resume a workspace after a break | Full captured-note read | Revalidate all affected stored session associations before trusting their locations; restore the existing scratchpad regardless of read failure. |
| Visible workspace idle tick | Metadata-only check, proposed every five seconds | If unchanged, no body read, parsing, diff, tokenization, or model work. If changed, schedule one coalesced full read. |
| Return from Notes/app reactivation | Immediate metadata check, shared with any pending read | Detect edits without a Check Notes command; full read if changed. A previously suspended monitor performs a full resume read. |
| Changed metadata | Body fetch after proposed 500 ms quiet interval, with a two-second maximum coalescing delay | Recompute association and affected diffs, show changes, and verify matches when safe. Do not overwrite scratchpads. |
| Submit a chat prompt | Shared freshness check: check metadata and fetch changed/missing/uncertain body context as needed | Resolve target and assemble context with the current scratchpad replacing that session's recorded text. Hold only the request, not the editor, if association/read freshness is unresolved. |
| Scratchpad edit | Local revision/save; update comparison against cached Notes | No Notes read or model call solely because of typing. Existing replies may get Scratchpad changed. |
| Copy icon, whole-copy shortcut, or editor select-all/Command-C | Shared freshness check before whole-scratchpad handoff, then rich export | Warn about external Notes edits/uncertain association or unavailable checking before/with copy completion; expose the diff. Copy remains available, but never claims safe paste or reconciliation. |
| Ordinary partial-text copy or chat selection copy | Copy only the selected range; no handoff preflight | Preserve standard copy behavior; do not turn copying a phrase into a Notes interaction. |
| Open the diff toggle | Shared freshness check; update comparison or label cached Notes last-known while pending/unavailable | No separate Check Notes action or model call. Monitoring continues independently. |
| Manual paste/edit in Notes | Discovered by normal automatic refresh | Verify against the correctly associated session; copying alone is not evidence. |
| Hide/close the last visible workspace for a note, sleep, or quit | Suspend timer reads; flush local scratchpads; quit cancels requests | Keep workspace identities/baselines. Resume with a full read. No idle reading of every stored note. |

There is at most one native read in flight for a note, shared by its workspaces.
Polling, reactivation, prompt, copy, and diff requests join/upgrade that work rather
than start duplicate reads. A consumer needs a validated observation, not an old
completion assumed current merely because a read was already in flight. Discard
stale results; if another change arrives, obtain a newer observation before making
freshness claims. Errors back off automatic retries, keep the last-known timestamp
visible, and retry on reactivation or a new prompt. Avoid an endless immediate
retry loop while the coach is actively editing Notes.

## Shared freshness check and copy-time safety

Idle checks remain metadata-only. The 2026-10-13 experiment demonstrated body changes
with unchanged native dates, so metadata equality cannot validate a safety-consumer
body cache. Candidate safeguard: read body/id/date together for chat, diff and checked
whole-copy, sharing a read only when it covers each request. Reuse parsed context/diffs
when the body is unchanged; no monitoring model/tokenization work. This is an injected
coordinator candidate, not production scheduling. The checked-versus-ordinary-copy
interaction is accepted below; no prompt-only freshness exception.

Modification date is not a revision counter. The Notes dictionary exposes a date,
and the current AppleScript probe returns it as text. Apple's date representation
uses whole seconds. A 20-second native sampling experiment recorded 98 snapshots and
two body transitions with equal formatted dates AND equal native date values. This
is observed, not merely plausible. Formatting/Undo sampling also tested the API,
but can miss transient changes; it is not a change feed. On the 1,000-line fixture,
body reads took 0.227–0.376 seconds and twenty metadata reads took 1.939 seconds,
not latency guarantees. The candidate coordinator passes 15/15 injected tests for
metadata-only idle ticks, shared safety reads, same-date edits, cache reuse and honest
unavailability. See [Apple's date representation](https://developer.apple.com/library/archive/documentation/AppleScript/Conceptual/AppleScriptLangGuide/reference/ASLR_classes.html).

At whole-scratchpad copy, compare the observed Notes session against the last
confirmed Notes baseline to detect external edits; ordinary scratchpad-versus-Notes
differences alone are not proof of an external edit. If current Notes already matches
the scratchpad, report the verified match rather than warn about an overwrite that
would not change it. If Notes independently changed, surface Notes changed—review
differences before pasting and make the existing diff toggle immediately available.
Uncertain association or read failure produces an explicit Notes could not be
verified warning, not a clean/safe claim. Preserve both versions. No modal merge,
automatic write, new primary button, or guarantee about the later paste.

Accepted 2026-10-13: the floating icon and discoverable whole-scratchpad shortcut
perform checked copy; wait for Copied before pasting. Ordinary Command-C, including
Command-A/Command-C, remains immediate and Notes-unverified at export. A later
background check cannot retroactively make an earlier paste checked. Partial-text
and chat copy remain immediate. A simulated 750ms preflight pasted OLD contents
before completion at 0.753 seconds; the distinction is intentional, not a guarantee
that the app can prevent early paste in Notes.

Accepted timing, 2026-10-13: target 400ms, maximum verification wait 750ms. Start rich
preparation/publication concurrently with Notes verification for the captured
scratchpad revision; clipboard publication does not wait for Notes. Distinguish
preparing content from Copied—checking Notes. If verification is still pending at
750ms and publication succeeded, show Copied—Notes not verified and continue the
verification in the background. Never say Copied before publication succeeds. If
export itself exceeds 750ms, show preparation still pending rather than falsely
claiming completion; this misses the timing criterion and needs performance evidence.
If the scratchpad changes, indicate Scratchpad changed. Use off-main-thread reading
so an unresponsive Notes event cannot lock the editor; no permission prompt inside
copy. Instrument total time, publication time, read time, export time and outcome
without content. Test normal, slow/hung readers and large exports. Existing body-read
samples are not full-copy timings or an OS scheduling guarantee.

Accepted late-conflict behavior, 2026-10-13: replace the entire clipboard with a
plain warning only if it still belongs to that exact scratchpad-copy operation.
Any subsequent copy, even identical text, permanently invalidates replacement for
the older operation; then leave the clipboard unchanged and show the warning in
the app. Always show the app conflict state as well. Candidate ownership evidence
is a per-copy identifier plus the pasteboard changeCount captured after successful
publication; text equality alone is never sufficient. Recheck generation and active
copy identity immediately before replacement, with no suspension between guard and
write. A changed generation must not regain ownership if content later matches.
No continuous clipboard-content surveillance is needed: check operation ownership
when the late result arrives. Native identical-recopy, later-different-copy, multiple
scratchpad copies and stale-result tests are required. The standard pasteboard API
does not offer an exposed conditional compare-and-write operation; cross-process
changes between guard and write remain a capability risk, not a proven guarantee.
If ownership cannot be established safely, use the app warning only; never guess.
Late results must remain tied to the captured revision/association and distinguish
an external session change from the coach's own paste; changes outside the session
do not count as a session conflict. Continuing verification does not make a paste
that already occurred retroactively checked.

Even a successful check cannot prevent a Notes edit between copying and manual
paste. This is the last app-controlled opportunity to warn, not conflict-free
write-back. The safety path covers the icon and explicit whole-copy shortcut, not
ordinary Command-C. Only operation-scoped clipboard ownership checks are required.

## What an edit can change

| Observed edit in the captured note | Association impact | Context, diff, and coach-visible impact |
| --- | --- | --- |
| Edit a different session or surrounding program prose | Keep this workspace's session if still unambiguous; update derived offsets | Refresh surrounding context. Do not modify the scratchpad or misattribute the other session's edits to it. |
| Edit text/formatting within the confirmed session | Same session if its boundary remains reliable; otherwise review | Show current Notes versus scratchpad and retain the baseline. A matching manual paste may reconcile automatically; differences remain differences, not silent adoption. |
| Rename one session heading | Reassociate the existing SessionID only with adequate evidence or coach confirmation | Show the new recorded label; keep the scratchpad heading/text unchanged. The diff exposes any heading mismatch. |
| Increment/renumber many session headings | Resolve all affected associations as a set; never look up workspaces by the new numbers | Preserve every WorkspaceID and scratchpad. Publish only verified one-to-one mappings; unresolved mappings need a concise association review. |
| Insert or reorder sessions | Offsets/order change, not existing SessionIDs | Existing workspaces follow verified sessions. A newly observed section is not automatically a new workspace or scratchpad. |
| Delete a session, split/merge sections, or change bodies as well as labels | May remove the target or make the old boundary ambiguous | Keep the scratchpad and baseline; mark association unresolved and pause target-dependent context/reconciliation. Ask the coach to identify the retained target or keep the scratchpad unassociated. |
| Introduce duplicate peer session labels | Expose the heading issue; keep stored identities | Coach may correct Notes, including renumbering every affected heading. Apply the same reassociation checks afterward; correction is not proof of identity. No automatic header repair. |
| Edit a week inside a lettered multiweek session | Remains within the one lettered session unless boundaries themselves change | Retain all three weeks in the same scratchpad/context scope. Do not create week workspaces or treat repeated week headings in different sessions as duplicate session labels. |
| Switch selection to another note | None | Continue reading captured NoteID; no implicit workspace switching. |
| Note unavailable/deleted or permission revoked | Target cannot currently be verified | Keep editing/copy available. Label cached Notes/diff last-known; do not claim unchanged or reconciled. |

## Reassociation after renumbering

Before applying a changed snapshot, retain the prior confirmed associations for
every stored workspace belonging to that NoteID, including ones not currently
visible. Resolve against the same fresh snapshot as a group. Reading the note once
does not require loading or decoding every inactive scratchpad; the stored baseline
and association evidence suffice.

Use the previously confirmed session body and supported structure as evidence,
with only the outer session label excluded for a heading-only rename. Preserve
week labels, prescriptions, and other text in that comparison. A digest can locate
candidates cheaply; compare actual supported content before accepting a match.
Unchanged distinctive body content plus consistent session boundaries can support
automatic relocation when the match is unique in both directions. Adjacent session
content/order can corroborate; labels or ordinal position alone cannot establish
the mapping. Do not use fuzzy/model similarity to silently resolve an uncertain
session identity.

For example, old Session 12/body X and Session 13/body Y becoming Session 13/body X
and Session 14/body Y retain their original local SessionIDs and workspaces. The
numeric collision is harmless because headings are not keys. If X and Y are both
empty or identical, or content changed enough to obscure the relationship, do not
guess by matching 13 to 13 or by shifting every ID by one. Show old/new labels and
short excerpts so the coach can confirm which existing workspace belongs where.

Require one-to-one association: two existing SessionIDs cannot automatically bind
to one new section. Apply a verified mapping as one registry update, not sequential
renames that overwrite another entry. Preserve unresolved workspaces and the prior
baseline; do not partly bind the same section elsewhere. Unaffected verified
workspaces can continue. Resolving one ambiguous workspace does not authorize
discarding or duplicating another. Confirmation changes the association, not the
scratchpad text. Closed workspace associations must also be revalidated before
their next use, even if provisional evidence was recorded while they were closed.

Detect duplicates and surface the numbering problem, but do not depend on the
coach's fix being local. A correction may rename the entire subsequent sequence.
Association review and heading correction are therefore separate concerns. This is
a bounded deterministic/confirmation path, not a demand for an elaborate recovery
engine supporting every malformed note.

## Proposed executable association contract

This is a proposed fixture contract for the next capability experiment, not a
claim that real note formats have all been recognized or an approved restriction
on how the coach writes sessions. Test it before adopting a production recognizer.

The tested text-only prototype starts with paragraph-aligned session labels: a standalone paragraph beginning
with the case-insensitive word Session, whitespace, and an identifier consisting
of digits or letters optionally followed by digits. An optional colon or dash
introduces a descriptive suffix. Thus Session 13, Session A, and Session E10 are
fixture candidates; an exercise sentence mentioning a session is not. Session
range starts at that paragraph and ends immediately before the next peer session
paragraph, or note end. Week labels never start sessions. This is tested prototype
scope, not the corrected product contract below.

Coach correction, 2026-10-13: native heading hierarchy is high-confidence boundary
evidence because session titles are normally higher-level than Warmup/nested content.
Combine formatting, text and surrounding structure; finding a boundary and classifying
its section as a session are separate judgments. A typo such as Sesion must not make
a strongly indicated boundary disappear. Text similarity may suggest classification,
not silently establish identity. Missing/conflicting structure needs compact coach
confirmation or manual adjustment, not a forced spelling repair. The prototype does
not implement this correction; existing passes do not prove hierarchy/typo handling.

Parking Lot is an explicit exception: trailing parking-lot ideas stay inside the
final session scratchpad range even if its heading has a peer/higher-level style.
Treat it as attached non-session context, not a new session or automatic cutoff.
Include it once in whole-note context assembly. Its changes still require normal
external-change/diff/copy safeguards. Exclude its heading and ideas from new-session
skeleton generation. The coach remains free to adjust the range to include/exclude it.

Represent each candidate as NoteID, observation digest, paragraph-aligned UTF-16
range (start inclusive, end exclusive), displayed label, supported rich content,
and adjacent paragraph evidence. Every range belongs to that exact observation.
An anchor retains local SessionID, the last confirmed range/label, confirmed body
and supported structure with only its outer label excluded, plus adjacent evidence.
Offsets, hashes, labels, and order are evidence, never independent identity proofs.
Match actual supported content after digest filtering and enforce uniqueness in
both directions across all stored anchors. Duplicate peer labels still require
coach correction; automatic matching does not hide the heading issue.

For an unresolved association, show the existing workspace label/excerpt beside
candidate current sections in the read-only preview, or allow a paragraph range.
The coach selects a section and confirms that this existing workspace belongs to
it; no exercise/intent form or merge action is introduced. The confirmation payload
contains existing SessionID, captured NoteID, observation digest and selected range.
Validate against the same observation and the one-to-one registry before applying.
The registry's active ranges must belong to that same observation too. Recompute
verified mappings together; retain unresolved anchors' old evidence separately,
not as occupied ranges in a newer snapshot. An edit changing body length can
otherwise make old offsets falsely overlap a valid confirmation. Reject a stale
registry before using its offsets, even if the confirmation itself is fresh.
If a newer observation arrives, revalidate the selected content or ask again; never
reuse stale offsets. Reject occupied targets without discarding either workspace.
Confirmation updates association evidence only, not scratchpad text or the confirmed
Notes-content baseline. A content-baseline update still requires the separate
verified-match/explicit-content-decision rule below.

Always permit boundary adjustment, not only unresolved cases. Leading UI candidate:
small source-range markings at the top/bottom of the scratchpad pane, with right-click
and discoverable keyboard/menu entry to a compact read-only note browser. Allow up/down
or drag endpoint movement without a mouse-only dependency or permanent extra pane.
Offsets belong to the observed source note, not scratchpad lines or soft-wrapped
screen rows; exact display and keys remain proposed. Apply the same note/observation
freshness and one-to-one range checks. Moving a boundary preserves workspace identity.
Approved scope-change behavior: preview expansion's added Notes content against a
fresh observation, then insert only that edge content while preserving the existing
scratchpad. Shrink only untouched regions. Prevent shrinking into edited or
coach-added regions; explain the blocking region, with no discard-edits confirmation
or override. Keep evidence for deletions as well as visible edits. If reordering or
replacement makes correspondence uncertain, refuse destructive shrink rather than
infer source positions from scratchpad offsets. This is bounded edit protection,
not richer preference-learning provenance or keystroke analytics.

No overlap with another workspace is allowed; exact abutment is allowed. Identify
the workspace owning an abutting/obstructing range in the adjustment browser.
The content and range change must undo together, preserving conversation and local
identity. Undo must revalidate freshness/ownership too: restoring an old range is
not permission to overlap a workspace that subsequently occupied it. Expansion
preview is not acceptance of unrelated edits to existing content or its baseline.
Neither operation writes Notes. Hypothesis, not established evidence: coaches
normally adjust boundaries before editing, making protected-region limits low cost.

Fixtures must assert exact ranges for numbered and lettered/multiweek sessions,
descriptive suffixes, unsupported labels/manual ranges, incidental Session text,
duplicate corrections/bulk renumbering, identical content, changed confirmation
snapshots, and occupied targets. Synthetic success is not proof that every historical
note uses this grammar; report unsupported examples and seek approval for any
material expansion rather than introducing a fuzzy fallback.

Add pending fixtures for higher-level session/lower-level warmup headings, misspelled
session titles, a trailing peer-level Parking Lot retained in the final scratchpad,
and always-available keyboard adjustment. Validate skeleton exclusion and no loss
of scratchpad edits on scope change. These are requested future criteria, not tests
passed by the existing 39 assertions. Add expansion-preview, edited/deleted/added
region protection, uncertain correspondence, exact abutment/owner, atomic undo and
stale/occupied undo tests. No discard confirmation is an alternative to protection.

## Impact on requests and reconciliation

If association is reliable, assemble the fresh whole note with this session's
recorded range replaced by the current scratchpad. Keep other sessions' observed
updates. A new unrecorded session is an addition. If association is uncertain, do
not replace a guessed range, include the recorded and scratchpad versions as equally
current, or mark a match. Preserve editing/copy and request a concise association
decision before the next dependent model request.

If a relevant Notes change is observed while a model response is in flight, retain
the response's actual input versions and indicate changed Notes context. Do not
automatically restart or charge for another response. The next prompt uses the
latest reliably associated observation and scratchpad revision. If only headings
changed, update recorded labels/locations after verification, not the scratchpad
or prior transcripts. A changed label can still produce a visible heading diff.

Automatic reconciliation requires a reliable session association and equal text
and supported formatting. A successful read is not a successful reconciliation;
neither a copy event nor a manual heading correction is one. Update the confirmed
baseline only on a verified match or a separately explicit baseline decision.
The diff defaults to latest observed Notes versus the scratchpad; retain baseline
history internally for warnings. Unsupported/paste-normalized formatting remains
not verified. Cached unavailable context always has a last-known label/time.

## Efficiency and verification

Cache one full body/parsed representation per captured note; distribute it to
subscribed workspaces. Reuse unchanged-body parsing, session candidates, and diff
results by content digest/revision. No full-note retrieval on an unchanged idle
tick, no note-library enumeration, no repeated tokenization, and no provider call
from any monitoring trigger. A user prompt can send approved context to the model;
monitoring itself never does. Local character/token length influences body/parsing
cost and request limits, not a reason to turn polling into model work.

Measure metadata responsiveness and counts with injected readers/timers. After
initialization, 20 unchanged ticks on a synthetic large note should perform
metadata reads only. Two visible workspaces on that same note should share those
reads. Changed ticks coalesce into bounded body fetches; chat, diff, and whole-copy
share freshness checks and cache revalidation rules. Freeze/refuse unreliable observations
rather than silently falling back to full-body polling every five seconds.

Test bulk renumbering with several already-saved workspaces, a temporary duplicate
during numbering correction, identical/empty sessions, an inserted earlier session,
and concurrent content changes. Assert stable IDs, one-to-one mapping, preservation
of all scratchpads, truthful paused/changed states, and coach confirmation when
evidence is insufficient. Test metadata/read failure, hidden/resume behavior, and
automatic matching and external-edit warnings after all whole-copy paths. Test that
unchanged metadata does not cause unconditional per-prompt body reads once the
timestamp/cache safeguard is established. Test stale/unavailable checks and copy
completion timing, including immediate keyboard handoff. These are required future observations,
not tests passed by the original probe.
