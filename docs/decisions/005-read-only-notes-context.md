# ADR 005 — Read Notes context separately from the writing Service

Status: accepted direction, 2026-10-12. The user approved the recommendation after
the synthetic capability checkpoint. This is not production implementation approval.
Numbers 001–003 are already used in the learner implementation; this design
record does not replace those decisions.

## Context

Autocomplete uses a synchronous macOS Service to return exercise text at the Notes
cursor. A session scratchpad with margin conversation must remain usable for hours,
read the entire associated program note, and notice external changes. Neither the
Service's plain-text pasteboard nor the original insertion cursor provides that
long-lived context. Notes remains the recorded program destination; the scratchpad
is its bounded, session-scoped working copy.

## Decision

Retain the existing Service for invocation and autocomplete. Add a separate,
read-only Notes Automation adapter for program context. Automation is macOS's
permission-controlled inter-application data interface; this adapter reads Notes
data, not screen pixels or general Accessibility UI state.

At workspace entry, capture one selected note's opaque identity. Read its complete
HTML body, plain text, and modification date. Subsequent reads use that captured
identity, never whichever note happens to be selected later. Ambiguous selection,
unavailable notes, errors, and revoked permission are explicit unavailable states,
not permission to switch targets. Note identity is not session identity. Session
association inside the editable note requires a separate tested contract.

Ordinary reads check access without prompting. Production onboarding offers an
explicit request for Notes Automation permission; access granted to the test probe
does not grant access to the production app. Do not require broad Accessibility
permission for this route. Signing, packaging, and permission declarations must be
verified on the actual production app identity.

Return from the synchronous Service before opening the long-lived scratchpad
window. For the explicitly chosen Program session branch, capture the selected
Notes identity before opening the independent workspace. The chooser may already
have focus: Notes' data selection is not the foreground application's selection.
Bound that non-prompting capture and present any failure or consent requirement in
the independent window; never keep a Service waiting throughout conversation or
prompt for Notes access during ordinary autocomplete.

Expose typed note snapshots and failures to the workspace. The adapter does not
own exercise identity, library writes, model reasoning, session editing, or workspace
persistence. The resolver and library remain independent of Notes.

External Notes changes cannot silently replace the scratchpad or be overwritten by
it. Keep the last confirmed baseline separate from fresh observations and show
changed/unavailable context honestly. Use deliberate manual copy and paste for the
initial handoff; the exact formatting route remains under capability testing. The
adapter has no Notes write methods. Copy is not
proof of paste or reconciliation; checking the captured note/session is separate.
No automatic merge or direct Notes write-back is authorized.

## Evidence

[The capability report](../design/SCRATCHPAD_CAPABILITY_CHECKPOINT.md) records a
native AppKit probe reading all 70 synthetic context lines and an offscreen end
marker, plus HTML, plain text, identity, and date. Rereading the captured identity
detected an external edit and stayed on the fixture after Notes selection changed.
The probe refused a non-fixture selection before reading its body. Permission denial
was observed before explicit consent; permission availability and actual reads were
observed afterward. No broad Accessibility grant was obtained.

The learner implementation's library-review branch returns from the Service before
opening an independent window. That is lifecycle evidence, not proof of scratchpad
persistence or session targeting. The probe's baseline existed only in memory.
Duplicate Session 1 labels demonstrated that labels alone cannot anchor a session.
RTF storage and HTML heading export showed formatting losses; secure attributed-
string archiving passed the local fixture but is not selected by this ADR.

## Alternatives considered

Selected Service text alone would require repeated sharing and cannot supply whole-
note context. General Accessibility extraction is a broader permission/UI-dependent
route; the narrower Notes data interface has sufficient initial evidence to prefer
it. Reading Notes' private database is not required or selected. Direct Notes writes
would add wrong-target and reconciliation risks and conflict with the approved
manual-paste first iteration. None is an automatic fallback after failure.

## Consequences

This adds a read-context boundary alongside, not instead of, autocomplete. Test
production consent, captured-target reads, permission failure, session association,
and conflict behavior. Model requests use the active scratchpad instead of the older
recorded session; surrounding note context remains available. OpenAI API use and
transmission of note/profile information are separately approved. No historical-chat
import, preference learning, library mutation, or client-history implementation
follows from this ADR.

## Known limitations

The fixture establishes capability on the tested host, not all supported macOS
versions, device/account migration, deleted/moved notes, or distribution. No
production adapter, continuous monitoring, session-anchor recovery, complete rich-
text handoff, or user-visible crash recovery was tested. Polling frequency, storage
format, provider settings, and acceptance criteria remain proposed contracts.

## Revisit triggers

Revisit if supported Notes/macOS versions cannot provide complete context and stable
captured-target reads, production permission/packaging is impractical, session
association is too burdensome, or external edits cannot be surfaced truthfully.
Fallbacks that weaken no-repeated-sharing or introduce Notes writes need approval.

## UI clarification after review, 2026-10-12

Separate copy from verification in meaning, not through separate action buttons.
The coach chose a floating copy icon/ordinary selection copy plus a discoverable
shortcut, and a diff-view toggle. Automatic Notes monitoring performs comparison;
whole-scratchpad copy also checks freshness and warns about external Notes edits
relative to the confirmed baseline or unavailable verification. Chat, diff, and
whole-copy share the cache policy, including a to-be-tested safeguard for edits
that may not change reported metadata. A check cannot prevent an edit after copy;
there is no Check Notes command. This does not authorize Notes writes or equate
copy with paste. Metadata-first monitoring and large-note caches are proposed
implementation details requiring their own evidence, not capabilities proven here.

## Handoff clarification after capability testing, 2026-10-13

The floating icon and explicit whole-scratchpad shortcut are checked-copy paths;
ordinary Command-C remains immediate and Notes-unverified at export. The coach
accepted a 400ms target and a 750ms maximum verification wait, with clipboard
publication concurrent with Notes checking and a truthful warning on timeout.
For a late session conflict, replace the clipboard with warning text only while
the exact scratchpad-copy operation still owns it; any later copy, including
identical text, requires an app-only warning. Native ownership races remain to
be tested. On the tested macOS 27 fixture, Notes' Paste as Markdown retained
native heading tiers, bullets, and bold where ordinary paste did not. The coach
selected that handoff direction for further testing, not production acceptance.
Serializer fidelity, keyboard access, platform availability, and full-path timing
remain open. These choices do not alter the read-only Notes adapter decision.

## Late-conflict handoff update, 2026-10-14

The coach approved the fallback after the isolated pasteboard experiment: late
verification that finds a conflict updates Gym Assistant's visible warning and
diff state but never replaces or clears the clipboard. This supersedes the
conditional clipboard-warning replacement described in the 2026-10-13
clarification above. It protects subsequent copies without claiming an atomic
cross-app pasteboard operation. The already-published program copy remains
available; a warning in Gym Assistant cannot stop a paste that already happened
or guarantee the coach sees it while in Notes. Checked-copy timing and truthful
not-verified status are unchanged.

## Planning lifecycle clarification, 2026-10-15

The coach approved separating active editing ownership from retained planning
evidence. Explicitly setting aside a scratchpad preserves its full content,
conversation and original source evidence but releases its active claim and closes
its editor. Schema 3 records an optional set-aside date; older snapshots remain
active without eager migration. Persist and validate before releasing ownership,
retain the previous snapshot, and reject stale-editor overwrites/reactivation.
Historical references may share one uniquely verified session region without
competing for ownership; uncertain locations remain labeled at note level.

Previous planning is a reference browser whose primary reuse path is ordinary
copy/paste directly into Notes. Neither browsing nor set-aside writes Notes.
Batch association repair is deferred. Explicit verified Notes-to-scratchpad
replacement with prior-content preservation remains approved but not implemented.
