# Session scratchpad with margin conversation

Design direction selected by the user, 2026-10-12. Refines the contextual-assistance
candidate; not approval to implement or replace the active tutorial slice.
The user chose the OpenAI API and approved transmission of all note and profile
information on 2026-10-12. The user approved the product
boundaries below on 2026-10-12. Remaining implementation gates are listed at the end.

This supersedes the actionable-proposal first-iteration recommendation in
[the earlier interaction exploration](CONTEXTUAL_ASSISTANCE_UI.md) and the proposed
apply/edit/dismiss contract in [the original design](CONTEXTUAL_PROGRAM_ASSISTANCE.md).
The six 2026-10-11 mock-ups are [frozen historical comparisons](artifacts/README.md),
not current specifications.
[The evidence package](CONTEXTUAL_ASSISTANCE_EVIDENCE.md) remains applicable.

## Selected direction

One freely editable **session scratchpad**, with natural margin conversation.
The scratchpad is session-scoped even when the conversation concerns one exercise,
pair, preparation drill, or conditioning block. The associated entire program note
is available as context; it is not duplicated into an editable whole-note clone.

The user edits the session manually. Chat produces text, not actionable edit
proposals. No Apply, Accept, Reject, target-slot menus, proposal tray, or separate
proposal editor in the first iteration. Ordinary selection and copy remain useful.
Questions and free-form corrections require no mode or category selection.

The assistant must read the changed scratchpad before answering follow-ups so the
user does not repeatedly paste the scratchpad draft. This eliminates the central
context-sharing friction without requiring a structured program builder.

Minimal decoration distinguishes exercise wording with a confirmed library match
from wording with **no confirmed match**. The latter does not assert that the
exercise is absent: the wording may describe an existing exercise without a known
alias, or a distinct variant. Fuzzy/model similarity cannot establish identity.
Decoration should remain readable and accessible without an action popup; identity
status must not depend on color alone. Exact visual styling remains to be tested.

## One active scratchpad per training session

Ownership rule approved by the user:

- Keep one persistent scratchpad draft for an associated note/session, shared by its
  conversations. Opening another conversation resumes that scratchpad rather than
  creating another editable copy.
- Autosave the scratchpad locally. Closing/hiding the window ends visibility,
  not the scratchpad. Reopening restores the scratchpad, conversations, and unfinished work.
  Clear/delete is a separate deliberate action with recovery semantics to decide.
- While working there, the scratchpad is the active working text for the session and Notes holds
  its last recorded version. The user should not edit both independently and expect
  silent synchronization.
- Notes remains the recorded program destination. This is a bounded working-copy
  exception to the initial product's Notes-only-editor principle, not a new program
  management system. The user approved this bounded working-copy direction.

The workspace has identity independent of session title or conversation ID. The
coach clarified that duplicate peer session headings usually indicate a forgotten
number increment. Expose the issue and let the coach correct Notes; do not require
an elaborate duplicate-label recovery mechanism. Preserve the active scratchpad
while association is unclear and reuse it after correction/confirmation.

Heading correction may renumber the entire subsequent session sequence. Keep stable
local session/workspace identities, not a registry keyed by heading numbers. Verify
all affected associations against the fresh note, including closed workspaces;
unchanged distinctive session content can support one-to-one relocation, while
identical/changed cases need confirmation. A corrected label alone cannot establish
identity or change scratchpad text. Do not bind old Session 13's workspace to a new
Session 13 that actually contains old Session 12's program.

Lettered sessions with three weeks of progressions are intentional (E10), not
duplicate sessions. The coach confirmed one scratchpad should contain the entire
lettered session and all three weeks. Do not split by week, flatten prescriptions,
or force numeric session labels. Repeated week labels within different session
parents are not duplicate peer session headings. More general block/version
ambiguity (E15) still needs confirmation, not an invented association. The exact
boundary-reading mechanism remains an implementation proposal.

Boundary correction, 2026-10-13: the coach normally gives session titles a higher
heading level than Warmup/nested sections. Treat native heading hierarchy as
high-confidence boundary evidence, combined with text and surrounding structure;
do not require the exact spelling Session. A misspelled Sesion title must not be
silently swallowed into the previous session because the text-only prototype misses
it. Formatting is strong boundary evidence, not proof of durable session identity.
Ambiguous classification/association still needs unobtrusive confirmation.

Parking Lot exception approved by the coach: include a trailing Parking Lot and
its ideas in the final session's scratchpad. It is attached non-session context,
not another workspace or a forced end boundary, even if styled as a peer heading.
Keep it available to assistance; exclude it from the new-session headings-only
skeleton. This supersedes the side-conversation suggestion to cut it off.

The coach can always adjust either boundary, even when detection is confident.
Leading UI proposal: small top/bottom markings showing offsets in the source note,
with right-click or discoverable keyboard/menu commands opening a compact read-only
note browser for up/down or drag endpoint adjustment. Avoid a permanent extra pane
or routine modal confirmation. Exact keys and offset display remain proposed.
Approved scope-change rule: preview added Notes content on expansion and insert it
at the corresponding edge while preserving all existing edits. Shrinking may remove
only untouched content; block an endpoint that would cut into edited or coach-added
regions. Do not offer confirmation to discard those edits. Uncertain correspondence
blocks destructive shrinking rather than guessing. Boundaries may abut another
workspace but must never overlap it; identify the adjacent/obstructing owner.
Make the range and content change one undoable operation, preserving conversation,
workspace identity and Notes. Hypothesis for field validation: boundary adjustment
normally happens before editing, so this conservative limitation will be acceptable.

External Notes changes cannot silently replace the scratchpad or be overwritten by
it. Native fixture rereading and change detection passed; production reconciliation
and flagging edits in Notes while a scratchpad is active are not implemented or
verified. Flag a changed recorded session
without overwriting the scratchpad or silently merging. If reading is unavailable,
say so; do not show a false "unchanged" or synchronized state. The app does not
write into Notes automatically in this iteration. Manual paste can still overwrite
user text, so copying is not a guarantee against a mistaken paste. Automatic merge
is not required. A conflict display, if needed, replaces a view rather than stacking
multiple editors.

## Starting or resuming

Entry reuses the existing Option-Command-G autocomplete shortcut and branches from
the chooser; it does not introduce another global shortcut or silently classify a
search query as a chat prompt. Keep the ordinary autocomplete interaction intact.
Recommended local branch: a visible, keyboard-accessible **Program session…** action
that releases the synchronous Service request before opening/resuming the workspace.
Its exact local key binding and shortcut-to-editor keystroke budget remain to be
confirmed in the implementation plan.

Inside that branch, offer **Work on latest session** or **New session**. An existing
active scratchpad for the resolved session is resumed, not recreated.
Selection in Notes may help identify the session but must not narrow the scratchpad
to a fragment. "Latest" may mean last in note order rather than most recently edited;
when structure is ambiguous, show the proposed session before starting.

Approved new-session skeleton: **headings only** from the previous session. Do not
carry forward exercise selections, prescriptions, warmup content, loads, dates,
test outcomes, symptoms, or observations. Preserve the existing heading structure;
do not invent a mandatory A/B or conditioning format. Habitual warmup content waits
for reusable library-block insertion, not duplication in this slice.

Past conversations about this session are accessible through a quiet conversation
history entry. They are not permanently featured beside the editor. A brief optional
return cue may identify an unresolved question after a break; it is not a persistent
"Where we left off" panel or a recap of every past chat. It must agree with the
current scratchpad and link to its underlying conversation, not turn an inferred
acceptance into fact. The transcript itself remains accessible.

Remove the permanent "Context we were using" panel. Decisions and corrections stay
in the conversation. This does not remove necessary warnings for unavailable/stale
note context or the separate privacy decision about sending it to a model.

## Context freshness

At each prompt, capture the current scratchpad revision rather than reusing text
from the previous turn. Assemble context from that active session, the surrounding
program note, and relevant session conversations. Substitute the working session
for its older recorded version in the assembled program; do not present competing
versions as equally current. For a new session, add it as an explicitly unsaved
session, not a replacement for the prior session.

If the scratchpad changes while a response is being generated, the response may be
based on the earlier revision. Do not lock the editor or claim it used later text.
Approved handling: a compact **"Scratchpad changed"** indication with an option to
ask again using the updated scratchpad draft. Do not automatically restart the
response or lock the editor. Follow-up prompts must use the new revision. In the
product interface and current design prose, call this the **scratchpad** or
**scratchpad draft**, never an unqualified "draft" that could mean text in Notes.

The whole associated note being **available** is distinct from uploading its entire
contents on every turn. Context-size limits and sensitive client material still
require a model/privacy decision. No silent substitution of transcript memory for
the actual program, and no claim that every historical detail was included when it
was not. Obtaining the complete active note without repeated user sharing passed the
native fixture checkpoint, but is not implemented in production; the current Service
does not supply that context.

## One handoff surface

Delete the duplicated Review Change / Compare with Notes surfaces from the mock.
The ordinary view has one session editor and one conversation.

Approved review update: a compact **Compare with Notes** diff toggle temporarily
replaces the editor with a read-only comparison of the scratchpad and its latest
automatically read Notes session. It is not another stacked full copy, a refresh
button, or an Apply/Merge control. Return to the same editor/content/undo state when
the toggle is off. New sessions are additions, not replacements. Keep the baseline
internally for external-change detection, but compare with current Notes when
available. Unavailable reading shows explicitly last-known context and its check
time, never a false current/synchronized state. The toggle is part of this candidate
slice, not a request to create another mock-up or to implement production UI now.

Approved: rich **Copy scratchpad** as the initial handoff, with deliberate manual
paste into the correct Notes location. Use a copy icon floating in the upper-right
of the scratchpad pane, not a separate labeled action button or handoff panel.
Retain ordinary selection/Command-C, including editor Command-A then Command-C.
A whole-scratchpad copy shortcut must be discoverable without a mouse. The plan
proposes Command-Shift-C shown in the Edit menu and icon tooltip/accessibility name;
standard Command-C copies the current selection, not the entire scratchpad.

Copying establishes only that text was copied, not that it was pasted into Notes or
that Notes and scratchpad agree. There is no Check Notes action: automatic captured-
note monitoring performs comparison/reconciliation, and whole-scratchpad copy also
checks freshness as the last app-controlled checkpoint before manual paste. Warn
about external Notes edits relative to the confirmed baseline, uncertain association,
or unavailable checking, and offer the diff. Copy remains available with an honest
warning; a successful check cannot prevent a subsequent edit before manual paste.
Only matching correctly associated text and supported formatting can establish
agreement. Otherwise retain an honest not-verified state, with differences visible
through the toggle. Manual selection-copy/paste can be recognized without requiring
an app-specific copy receipt. No automatic scratchpad replacement or Notes writes.
Copy must be **rich text** and preserve the Notes-like bullets, bold, and heading
formatting. This implies an editable formatted scratchpad, not only a plain textarea
with a styled preview. Notes paste fidelity for these formatting features must be
tested; selecting a serialization format alone does not prove semantic headings or
list behavior survives. Plain text may accompany rich text for compatibility but
must not be presented as satisfying the approved rich-text handoff. Do not rely on the original invocation cursor hours
later or silently paste into the currently focused application.

Notes monitoring must be efficient for large notes. The implementation proposal uses
metadata-only checks for the captured note, changed-body caching/coalescing, and
reuse of parsed context/diffs when unchanged. Chat, diff, and whole-scratchpad copy
share one freshness policy. Native sampling now demonstrates body changes with
unchanged native dates. The candidate safeguard revalidates bodies for chat, diff
and checked-copy, reusing parsed caches and sharing covering reads; idle checks stay
metadata-only. The remaining copy semantics decision is not a prompt-only freshness
exception. Suspend timer reads while hidden/asleep and
refresh automatically on resume. No full body processing, tokenization, or model
calls on unchanged monitoring ticks; polling is local Notes access, not an API
conversation. Metadata reliability and large-note costs need synthetic verification;
do not claim the native checkpoint proved this optimization. Cadence/backoff details
remain proposed in [the implementation plan](SESSION_SCRATCHPAD_IMPLEMENTATION_PLAN.md).

[The Notes monitoring contract](NOTES_MONITORING_CONTRACT.md) specifies invocation
triggers and the impact of body edits, heading renames/bulk renumbering, insertions,
deletions, and permission/read failure. Reads/caches are shared per captured note;
new observations revalidate association without changing workspace identities or
automatically accepting Notes changes into the scratchpad.

Observed implementation boundary: the existing autocomplete Service runs a modal
chooser, returns replacement text on its request pasteboard, and has a 120-second
deadline (with chooser cancellation at 105 seconds). The existing library-review
path returns from the Service before opening an independent window. Neither this
pattern nor clipboard copying proves durable note/session targeting or asynchronous
write-back. Long-lived chat must release the original Service request. Direct Notes
write-back, complete-note reading, and conflict detection require scoped capability
testing and an ADR if they change the adapter architecture. This does not require
reopening ADR 001 for the already-working autocomplete workflow.

## Integration points, not extra first-iteration features

Capability review, 2026-10-13: tested public RTF/RTFD/HTML clipboard paths do not
preserve native Subheading, including Notes' own public-only RTF control. A simulated
750ms async copy pasted old contents before completion. The current full-fidelity/
uniform-copy contract therefore requires a handoff decision; do not silently relax
it. Proposed first-slice alternatives are public rich copy with manual native-style
correction. The coach accepted an explicit checked-copy icon/shortcut separate from
ordinary instant Command-C on 2026-10-13; ordinary copy is Notes-unverified at export.
The native-style fallback is not adopted. Accepted timing is a 400ms target/750ms
verification wait, with parallel rich preparation/publication and continued late
verification. Accepted late conflicts replace the entire clipboard with warning text
only while the exact copy operation still owns it. Any later copy, even identical
text, prevents replacement; warn in the app instead. Native ownership/race tests
remain pending; see the monitoring contract.
Private-format research or checked delay on all whole-copy paths are alternatives,
not authorization to write Notes or add a private dependency. See the latest
[capability evidence](SCRATCHPAD_CAPABILITY_CHECKPOINT.md).

Research follow-up, 2026-10-13: native Edit → Paste as Markdown passed tested semantic
heading tiers, bullets and bold on the current macOS 27 fixture. This is a promising
alternative to public rich paste with manual heading correction, not yet an adopted
handoff. Ordinary Markdown paste, single-item HTML and public WebArchive failed.
The coach selected this Markdown handoff direction on 2026-10-13. Next validate a
faithful scratchpad serializer, explicit platform behavior and keyboard route;
the fixture pass does not approve untested behavior or production implementation.
No Notes write-back or private dependency is implied.

Workstream handoff, 2026-10-13: the opinionated thread paused further capability
work for the branch/worktree fixup. Its Markdown evidence and exact-copy clipboard
ownership clarification have now been selectively transferred into this learner-based
`codex/contextual-learner-integration` worktree. The main-based worktree remains a
preserved source; neither its older architecture/OST nor this design package has
been merged or approved for production.

**Coach preferences are discoverable, read-only, and available to assistance in the
first slice.** Use the authored philosophy, the user-approved seed, and existing
research as a versioned profile, distinguishing authored/confirmed preferences from
inferred evidence and contextual exceptions. Offer a quiet Programming preferences
entry, not another permanent editor panel. Inspection should expose preference
wording and source/provenance sufficiently to understand why it may influence an
answer. It does not offer edit, remove, or confirm-new-preference controls, and the
model must not change the profile. Private personal sources must not be hardcoded
into reusable product code; reusable samples remain synthetic or empty templates.

How this read-only profile is packaged locally and how much of its source evidence
is exposed require a small implementation decision, not a new preference-learning
system. Discoverability must not imply scientific validation: coaching tendencies
can be challenged in conversation without editing their stored profile.

Future exercise-mention actions may include history, add to library, ask in side
chat, or add comment. Mouse, popup, and keyboard behavior are unresolved. The current
iteration decorates mentions only; it does not implement those actions or add
client-history/load-recommendation behavior. Later history should use the existing
workstream's actual contracts rather than introduce a parallel history model.

A future rationale comment belongs to an **exercise occurrence in a program/session**,
not just a canonical exercise. The same exercise can occur twice with different jobs.
Scratchpad and chat can offer views of that one annotation; they must not create
duplicate comments. An unlinked occurrence should be able to retain rationale
without forcing an identity decision. How annotations survive arbitrary text edits
and whether they are exported to Notes remain design questions, not current schema
requirements.

Preference learning must preserve coach-originated program text, assistant-mentioned idea,
later scratchpad inclusion/change, and reconciled Notes text as different evidence.
Detecting inclusion is useful temporal evidence, not proof of causal acceptance.
An exercise may already be in mind, be independently selected, or change during
training. Later disappearance is not necessarily rejection. This first iteration
must not silently confirm preferences; richer provenance capture is a future design
requirement, not approval for keystroke surveillance or a new analytics subsystem.
Richer provenance capture, preference learning without interrogation, and inspect/
edit/remove controls for learned preferences are explicitly a later slice. The
first slice exposes the existing profile read-only; it does not learn a new one.

## Candidate evaluation, not approved success criteria

1. Review a session recorded in Notes, edit the scratchpad freely, and ask a follow-up
   without re-sharing the scratchpad. Verify the response uses its latest revision.
2. Start a new session from a previous session's structure without carrying forward
   old exercise choices, prescriptions, or assessment results accidentally.
3. Half-plan a session, close the window, and return after a long break. Restore the
   same scratchpad and access the relevant conversation; do not create a competing copy.
4. Copy a rich-text session and paste manually into Notes. Verify bullets, bold and
   headings remain usable; copy alone must not claim reconciliation.
5. Conditional on proven reading capability: change the recorded Notes session
   externally while its scratchpad is active. Flag the change without discarding
   either version. If reading is unavailable, expose that limitation rather than
   pretending to detect external changes. App-driven Notes overwrites are excluded.
6. Read chat with familiar, unlinked, and ambiguously named exercises. Decoration
   is truthful; nothing creates an alias, library exercise, or preference.
7. Ask about one slot while relying on the whole session/program. Context and editing
   scope stay distinct; no form entry or scope classification is required.
8. Invoke from the existing autocomplete shortcut, branch into the scratchpad and
   return without breaking autocomplete insertion, cancellation or library review.
9. Find the read-only coaching profile and its provenance. Conversations and
   scratchpad edits must not change it or silently create learned preferences.
10. Edit the scratchpad during response generation. Show "Scratchpad changed" and
    ensure the next question uses the revised scratchpad without locking the editor.

## Remaining implementation gates

**Capability evidence, not more UI scope:** test complete-note access, reliable
session association across reopen, read freshness/external-change visibility and
rich-text paste fidelity in Notes. Distinguish read-only Accessibility/context
access from direct write-back. Select an initial-import fallback only if needed
and explicitly approved; it must not silently weaken the no-repeated-sharing goal.
Record the capability outcome and any architecture choice before dependent work.

Checkpoint update, 2026-10-12: agent-mediated live Notes tests demonstrate offscreen
whole-note availability, note identity across window reopen, reread freshness and
HTML paste with continuing bullets. They do not establish the native app's access,
session anchors or complete heading hierarchy fidelity. A secure attributed-string
archive preserves the local formatting fixture where RTF alone does not. The Notes
built-in data interface and non-prompting Automation diagnostic suggest a narrower
native reading route. After explicit launch and Notes Automation consent approvals,
the isolated native reader retrieved the full fixture as HTML/plaintext with note
identity and date. Captured-identity rereads detected external edits and stayed on
the original note after Notes selection changed; the non-fixture guard also passed.
This clears the native read/change-detection gate for the fixture, not production
permission onboarding, session anchors, full copy fidelity or scratchpad recovery.
The user accepted a read-only Notes Automation context adapter alongside the existing
Service in [ADR 004](../decisions/004-read-only-notes-context.md).
See [the capability report](SCRATCHPAD_CAPABILITY_CHECKPOINT.md).

**Provider and data boundary:** settled: OpenAI API; all note and profile information
may leave the device for assistance. Credential storage, model/cost controls,
local/provider retention and deletion still need implementation decisions. The
capability checkpoint uses synthetic content and makes no paid API requests.
ChatGPT subscription reuse or API access to past ChatGPT conversations is not assumed.

**Context bootstrap and session selection:** settled: initial assistance uses the
selected note, new workspace conversations and the existing coaching profile.
Do not import historical conversations in this slice. Historical research remains
evidence for the fixed profile/design, not a runtime transcript-import feature. The implementation
must handle long notes honestly and expose missing context, without an arbitrary
silent cut-off. Agree how an ambiguous "latest session" is resolved.

**Recovery and acceptance:** specify local durable storage for formatted scratchpads
and session conversations, close/relaunch/crash behavior, and explicit deletion.
Recommend no deletion UI or automatic eviction in the first slice. Choose measurable
acceptance criteria, particularly shortcut-to-scratchpad effort, no repeated context
pasting, restoration after a break, truthful decoration, read-only profile, and rich-
text handoff. Failure/offline behavior preserves the scratchpad and allows copying.

**Execution boundary:** explicitly sequence this candidate relative to the current
workstreams, approve its implementation criteria, and record an ExecPlan under
`docs/exec-plans/` using `PLANS.md`. An ADR is needed for new durable workspace/model/
context-access boundaries, not for the already-proven autocomplete interaction.
The product approvals above do not silently advance tutorial progress. The later
provider/data approval authorizes note/profile transmission but does not finalize
API credentials, retention, model selection, or feature implementation.

## Approved product decisions, 2026-10-12

One active persistent scratchpad per training session; clipboard/manual-paste handoff;
external-change detection and reconciliation pending reading capabilities; read-only
discoverable existing coach preferences; "Scratchpad changed" freshness handling;
rich-text copy preserving bullets/bold/headings; new-session headings only; habitual
warmup insertion deferred to library blocks; entry branches from the existing
autocomplete shortcut. Remaining gates above are not decisions already settled here.

Additional approvals: OpenAI API with note/profile transmission, bounded capability
checkpoint, and no historical conversation import. Checkpoint evidence is tracked
in [the capability report](SCRATCHPAD_CAPABILITY_CHECKPOINT.md) and
[its bounded plan](../exec-plans/PLAN-011-scratchpad-capability-checkpoint.md).

Review clarifications, 2026-10-12: copy icon with ordinary selection copy and a
discoverable shortcut; diff view toggle instead of Check Notes; automatic efficient
Notes monitoring; coach-corrected duplicate peer session labels; one scratchpad for
an entire lettered session including all three progression weeks. These settle UI
and scope constraints, not the remaining plan/sequence or performance claims.

The adapter direction is now an accepted architecture decision. No mock-up,
production code, tutorial progress, active-slice success criteria, or client-history
feature was changed. [The implementation proposal](SESSION_SCRATCHPAD_IMPLEMENTATION_PLAN.md)
separates approved product boundaries from remaining implementation choices.
