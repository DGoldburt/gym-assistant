# Test recoverable autocomplete windows and context-safe Notes insertion

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`,
`Decision Log`, and `Outcomes & Retrospective` must be kept current as work proceeds.
Maintain this document in accordance with `PLANS.md` at the repository root.

## Purpose / Big Picture

First test whether a small presentation change can make the existing synchronous
autocomplete recoverable by keyboard after switching applications. The learner
reports that the standalone Review Library window is recoverable; this is a useful
comparison, but it differs in both window type and Service lifecycle. A hidden
ordinary window (a temporary window shim) alongside autocomplete is a hypothesis
to test, not a proven fix. If synchronous presentation succeeds, retain the existing
macOS insertion mechanism and stop before the Accessibility work.

If presentation alone fails and the learner approves proceeding, this spike will
determine whether Gym Assistant can stop holding an Apple
Notes Service call open while its chooser is visible. The candidate interaction returns
the Service call immediately, lets the learner switch to another application for several
minutes, and shows the relevant Gym Assistant panel again when the original disposable
note is active. A confirmed choice may write only to the exact Notes editor and selection
captured at invocation; stale or ambiguous context must produce no write.

This is a retained architecture spike, not the current implementation priority and not
permission to replace the current integration. The learner chose to keep the existing
synchronous Service and monitor focus friction before spending more time on this issue.
If later evidence justifies reopening the work, this plan preserves the proposed
experimental path and its safety gates. It does not authorize an Accessibility permission
prompt, a System Settings change, production implementation, new exercise-identity
behavior, or access to real training notes.

## Plan Status

Proposed.

## Disposition

Deferred by the learner on 2026-10-02. Retain this plan as the restart artifact; do not
begin its permission gate or implementation milestones until a later foreground decision
explicitly reactivates it.

## Progress

- [x] (2026-10-01) Inspect the synchronous Service lifecycle, application activation,
  modal windows, timeout, and captured focus evidence.
- [x] (2026-10-01) Define the proposed Accessibility boundary, safety invariants,
  permission gate, comparison trials, and rejection criteria.
- [x] (2026-10-02) Choose to retain the synchronous Service, defer this spike, and keep
  gathering focus-friction evidence through the weekly evaluator.
- [x] (2026-10-06) Retain window-shim, inline editing, and extended-timeout ideas as deferred experiments; library editing uses the existing Review Library handoff.
- [ ] Obtain explicit approval to run the presentation experiment with disposable notes.
- [ ] Compare a regular autocomplete window and a hidden ordinary-window shim with the current panel and standalone Review Library control.
- [ ] Decide whether presentation alone satisfies keyboard recovery and safe insertion; stop here if it does.
- [ ] If needed, obtain separate approval for the asynchronous spike and Accessibility access.
- [ ] Build a metadata-only Notes Accessibility capability probe using disposable notes.
- [ ] Build the parallel asynchronous invocation and pending-context prototype.
- [ ] Run permission, normal insertion, stale-context, cancellation, multiple-invocation,
  focus-return, timeout, failure-injection, and synchronous-control trials.
- [ ] Decide whether to promote, revise, or reject the asynchronous adapter direction.

## Surprises & Discoveries

- Observation: The 2026-10-08 disposable-note test retained a middle-of-line caret
  across Edit→close→fresh Notes Service, and confirmed insertion between the
  existing markers. Cursor insertion is not lost; the completed Service cannot
  receive another response merely by reopening a selector. The user requested
  investigating Command-L as a selector-return shortcut. Automatic Notes-side
  re-invocation or a retained insertion-context adapter remains unimplemented,
  distinct from the tested manual fresh-Service path. No new permission or
  production lifecycle change was approved or performed.

- Observation: Review Library outlives the Service and has no autocomplete deadline.
  Evidence: `openLibraryReview()` stops the modal loop; `runModal()` invalidates
  its timer; `autocompleteExercise` schedules the review window after returning.
  Its reported keyboard recovery therefore cannot yet be attributed to window type.

- Observation: The current autocomplete Service is synchronous even when the learner is
  doing work that naturally leaves Gym Assistant.
  Evidence: `ExerciseAutocompletePanel.runModal()` starts a 105-second deadline and calls
  `NSApp.runModal(for:)`; the Service returns its pasteboard response only after that loop
  stops.
- Observation: Application activation is a request, not a guarantee of the window stack
  the learner expects.
  Evidence: the adapter calls `NSApp.activate(ignoringOtherApps:)` and later activates the
  invoking application. Field use still required Notes “Show All Windows” to recover the
  relevant context, and recent evidence includes both returned and failed-return focus
  cases.
- Observation: Accessibility can address another application's UI, but every reference
  is fallible and permission-gated.
  Evidence: macOS exposes process trust checks, application and UI-element references,
  attribute reads and writes, observers, and per-element messaging timeouts. Calls may
  also report disabled access, invalid elements, unsupported attributes, or an
  unresponsive target. Each outcome therefore needs an explicit no-write path.
- Observation: A general “return to Notes” operation is insufficient when multiple notes
  share one Notes process and sometimes one window.
  Evidence: the learner wants a pending assistant associated with the note that invoked
  it. The spike must validate editor, selection, and bounded surrounding context rather
  than trusting only the Notes process identifier or window title.

## Decision Log

- Decision: Keep synchronous window presentation experiments in this deferred plan;
  library editing adopts the existing Review Library Service-return lifecycle.
  Rationale: The feature needs a consistent parent window for editing and adding,
  while focus recovery and mid-search editing require separate measured experiments.
  Date/Author: 2026-10-06 / Learner.

- Decision: Keep the current synchronous Notes Service and defer the asynchronous
  Accessibility spike.
  Rationale: Focus recovery remains real friction, but it is not currently important
  enough to justify a new permission boundary and context-safe insertion mechanism. The
  plan and field evidence preserve the issue without forcing implementation now.
  Date/Author: 2026-10-02 / Learner.
- Decision: Keep deferred focus cases under exception-based weekly monitoring and
  consider a fixing batch only after materially repeated or worsening evidence receives
  foreground human review.
  Rationale: Deferral should reduce interruption, not erase the issue. An unchanged run
  produces only a compact status; detailed evidence returns to view only when it grows.
  The evaluator may accumulate occurrences and timing evidence, but only the learner may
  change a disposition or approve a fixing batch.
  Date/Author: 2026-10-02 / Learner.

- Decision: Run an additive spike beside the existing synchronous Service rather than
  replacing it.
  Rationale: The current pasteboard return delegates replacement-range integrity to
  macOS and remains the recovery path. The experiment must earn permission to replace
  that safety property.
  Date/Author: 2026-10-01 / Learner and Codex.
- Decision: Ask for Accessibility access only after an in-product explanation and an
  explicit learner action during the future spike.
  Rationale: Trust is a material system permission. Startup, installation, tests, and
  ordinary use must not prompt for it opportunistically.
  Date/Author: 2026-10-01 / Codex proposal.
- Decision: Retain context only in memory and never persist Notes text, note titles, or
  surrounding content.
  Rationale: Revalidation needs a bounded fingerprint of the original editor context,
  not a new store of private program text. The pending record may hold a one-way hash of
  a small range around the insertion point and must erase it on completion or expiry.
  Date/Author: 2026-10-01 / Codex proposal.
- Decision: Allow at most three pending experimental invocations, keyed by captured Notes
  context, with a 15-minute expiry.
  Rationale: This is enough to test the learner's two-note workflow and a short exercise-
  video detour without turning the spike into a general window manager. Reinvoking the
  same context focuses its existing panel; a fourth distinct context is refused safely.
  Date/Author: 2026-10-01 / Codex proposal.
- Decision: Never navigate Notes to a different note automatically in the spike.
  Rationale: If the learner activates another note, its pending panel may be visible but
  commit remains disabled. The learner must return to the original disposable note before
  validation can succeed. This avoids guessing from titles or sidebar text.
  Date/Author: 2026-10-01 / Codex proposal.
- Decision: Do not add simulated keystrokes, clipboard replacement, AppleScript, or a
  second broad permission as fallback mechanisms.
  Rationale: The spike tests one question: whether the Notes accessibility element
  supports a context-safe selected-text write. Adding another mechanism would obscure
  the result and widen permissions.
  Date/Author: 2026-10-01 / Codex proposal.
- Decision: Review the field ledger every Monday after the existing 09:00 local scheduled
  evaluator run, beginning 2026-10-05.
  Rationale: Weekly review prevents continuous interruption while keeping unresolved
  evidence visible. The schedule remains read-only except for mechanical ledger updates;
  human dispositions still require the separate foreground setter.
  Date/Author: 2026-10-01 / Codex proposal.
- Decision: Consider another bounded resolver batch when three related resolver signals
  have been explicitly accepted, or immediately when one accepted safety signal concerns
  a wrong identity write or a protected conflict that is linkable.
  Rationale: Repeated friction benefits from batching; identity corruption deserves a
  lower threshold. Meeting either trigger starts planning and review, not automatic code
  modification.
  Date/Author: 2026-10-01 / Codex proposal.

## Outcomes & Retrospective

The plan now includes a presentation experiment before the asynchronous insertion
proposal. Both remain deferred; no window shim or timeout change has been tested.
The current
synchronous architecture remains in use and no Accessibility permission has been sought.
The unresolved focus evidence remains in the private ledger, deferred cases remain on a
weekly watchlist, and later occurrences can strengthen or weaken the case for reopening
the work. Moving on therefore does not claim the interaction is fixed or forgotten. If
selected later, this plan is the complete restart artifact.

## Context and Orientation

`Sources/GymAssistantNotesService/main.swift` is the Notes adapter. Its two macOS Service
methods receive either an empty insertion point or selected text through `NSPasteboard`.
The current autocomplete panel calls `NSApp.runModal(for:)`, waits for a choice, puts the
chosen text on the Service pasteboard, returns from the Service, and asks Notes to become
active. This synchronous control path is valuable because macOS owns the original Notes
selection and performs the replacement after the method returns. It is awkward for a
long-lived chooser because the Service request remains outstanding and the accessory
application's window and Notes do not behave like one tab-switchable unit.

`Sources/GymAssistantCore/` contains exercise identity and search behavior. The spike
must not modify that behavior. A candidate string is supplied to the new adapter only
after the existing workflow has produced it.

Accessibility is the macOS API by which an authorized assistive application can inspect
and operate another application's user-interface elements. An `AXUIElement` is a
temporary reference to one such element. It may become invalid when a note, window, or
application changes. The relevant API can check whether Gym Assistant is trusted, find
the focused Notes element, inspect supported and settable attributes, observe focus
changes, set an attribute, and bound interprocess calls with a messaging timeout. The
spike must treat invalid, unsupported, disabled, timed-out, or incomplete calls as normal
failure states that cause no write.

The private field ledger currently retains seven focus-friction cases across resolved,
deferred, new, and reproduced states. Recent evidence includes a returned autocomplete
interaction that remained open for roughly 22–30 seconds and a cancellation where focus
did not return. The learner has also reported needing Notes “Show All Windows” after
switching away. These observations justify the spike but do not prove Accessibility is
the right implementation.

A pending invocation means an in-memory request that has returned from the macOS Service
but has not inserted or been cancelled. Its context snapshot contains a request UUID,
creation and expiry times, Notes process identifier, a non-content window token, an
accessibility element reference or reproducible element path, selected range, invocation
mode, and a one-way hash of a bounded amount of surrounding text. Raw surrounding text
and note titles must never be logged or persisted.

## Plan of Work

### Milestone 0: Test synchronous window recovery without changing insertion

After reactivation, use a separately built experimental app and disposable notes.
In `Sources/GymAssistantNotesService/main.swift`, vary one presentation condition
at a time: the current modal panel, a regular window serving the same chooser,
and the current panel accompanied by a hidden ordinary window created during the
Service invocation. Keep the Service outstanding and return insertion through its
existing pasteboard path. Compare with the standalone Review Library window,
explicitly recording that its Service has already returned. Do not assume a hidden
window will create a recoverable app/window entry; measure it.

Test keyboard switching away and back, retained query and selection, insertion at
the original caret, cancellation, repeated invocation, and cleanup of every helper
window. Use a synthetic no-write editor to test opening another window during the
same invocation and returning to refreshed autocomplete without another shortcut.
This editor exercises presentation only and changes no exercise identity.

If testing a longer interaction, change both `NSTimeout` in
`app/notes-service/Info.plist` and the local watchdog in the experimental build;
candidate values are 300000 milliseconds and 285 seconds. The deadline is measured
from invocation and never reset by editing. Verify ordinary quick insertion and
expiry without unresponsive-Service alerts. Longer waiting does not itself prove
focus recovery. Retain the production 120-second/105-second settings meanwhile.

Run `swift test` for regressions, then five keyboard detours per presentation
condition using invented text. Record outcomes in
`spikes/notes-focus-recovery/EVIDENCE.md`. A candidate passes only if all five detours
recover through the learner's ordinary keyboard switcher, preserve query/selection,
and permit correct insertion or cancellation without Dock menus or Show All Windows.
One wrong-location insertion rejects it. If a candidate passes, present its evidence
and stop before Milestone 1; promotion remains a separate foreground decision.

### Milestone 1: Isolate the adapter contract and build a no-write capability probe

Add a small Notes-insertion boundary under `Sources/GymAssistantNotesService/` or a new
adapter target without moving search or identity logic into it. Define typed pending-
context and validation results. Add fake implementations so permission denial, invalid
elements, context drift, timeouts, unsupported writes, and rollback failures can be
tested without controlling Notes.

Create a disposable probe under `spikes/notes-focus-recovery/`. Before any system prompt,
the experimental UI explains why Accessibility is needed, what it can inspect, that the
current Service remains available, and how to cancel. Only an explicit Enable action may
call the trust check with the system-prompt option. Denial or later revocation disables
the experiment without affecting the existing Service.

With permission granted, use two disposable Notes documents containing invented marker
text. Record only attribute names, value types, settable flags, errors, and timings. Do
not record values, note titles, or screenshots. The milestone passes only if the focused
editor exposes a selected range plus a supported selected-text or equivalent bounded
write. If the only viable operation replaces the complete note value, reject the design
rather than risk formatting or unrelated content.

### Milestone 2: Return the Service immediately and preserve a revalidatable context

Add a separately named experimental Service entry and shortcut. Capture the Notes
context before activating Gym Assistant, enqueue a `PendingNotesInvocation`, and return
from the Service with the pasteboard unchanged. Show a nonmodal experimental panel whose
draft and search results use the existing autocomplete workflow.

Test a nonactivating or floating panel configuration that can remain visible while Notes
is active. Listen to application and Accessibility focus changes so a panel becomes
commit-enabled only while its captured disposable-note context is active. The design
must not hide Notes from ordinary Command-Tab navigation, bounce the Dock, or require
“Show All Windows.” If macOS cannot support this window relationship reliably, preserve
the evidence and reject this presentation rather than layering more activation calls.

Maintain at most three pending contexts. A repeated invocation from the same validated
context focuses its existing panel. Different disposable-note contexts receive separate
panels. Expired, cancelled, closed-note, and terminated-Notes contexts are removed with
no write.

### Milestone 3: Validate immediately before insertion and verify or roll back

On confirmation, first require the original Notes process to exist and the original
editor context to be active. Re-read the focused window, element role, selected range,
and bounded context fingerprint. A changed note, range, nearby text, closed window,
restarted Notes process, invalid element, unsupported attribute, revoked permission, or
messaging timeout returns a visible stale-context result and writes nothing.

For a valid context, set only the selected-text attribute or another probe-proven bounded
attribute. Then read the affected range back and verify the exact insertion and expected
new caret. If verification fails while the same element and range remain provable,
select the inserted range and restore the original selected text. If rollback safety
cannot itself be proven, stop immediately, show a recovery warning, and retain diagnostic
error codes without content. Any real partial-write or unprovable rollback fails the
promotion gate.

Cancellation closes only that pending request and never touches Notes. After successful
insertion or cancellation, Notes must be active, the intended editor must be focused,
and successful insertion must leave the caret at the end of the inserted text.

### Milestone 4: Compare the experiment with the synchronous control

Run the existing synchronous Service and the experimental path from the same disposable
Notes setup. The comparison measures system-controlled time from confirmation to verified
caret, not human search or video-watching time. Preserve invented test cases and aggregate
results under `spikes/notes-focus-recovery/`; never preserve real Notes content.

Promote the direction only if the experimental path passes every safety and focus gate
and its permission burden remains acceptable to the learner. Otherwise retain the
current Service, record which capability failed, and consider a narrower presentation
fix or a different writing-interface boundary in a later decision.

## Concrete Steps

When reactivated, begin with Milestone 0 and a separate experimental app bundle.
No Accessibility access is needed for its window and synchronous-pasteboard trials.
Proceed to the following asynchronous steps only after their separate approval.

Work from the repository root on the branch selected by the future tutorial task. Before
editing, run:

    git status --short --branch
    swift test

Add unit tests for the typed context coordinator and fake Accessibility adapter. Run:

    swift test
    swift run ResolverFixtureRunner Tests/Fixtures/resolver-cases.json
    swift run IdentityReviewFixtureRunner Tests/Fixtures/identity-review-cases.json

Build the probe and a temporary, separately named experimental app bundle. Do not replace
`/Users/dan/Applications/Gym Assistant.app` until automated tests pass. The learner then
explicitly approves and performs the Accessibility permission step. Use only disposable
notes with unique invented markers.

Record a concise trial matrix in `spikes/notes-focus-recovery/EVIDENCE.md`. It must include
twenty ordinary insertions; five cancel-without-write trials; five Safari-or-other-app
detours followed by Command-Tab to Notes; changed-note, changed-selection, edited-context,
closed-note, and restarted-Notes stale cases; permission denial and revocation; a
15-minute expiry; two simultaneous note contexts; a refused fourth context; and injected
adapter failures that exercise verification and rollback.

Re-run the current synchronous path five times after the experiment. Expect no wrong-note,
wrong-range, cancellation, focus, or text-loss failures in the control.

## Validation and Acceptance

The presentation gate requires the Milestone 0 keyboard-recovery trials and zero
incorrect insertion or cancellation writes. Record whether the hidden-window shim
actually helps and whether any benefit depends on a visible regular window. An
extended timeout must pass an expiry trial and must not leave helper windows or
an active insertion action after cancellation. The following gates apply only if
the asynchronous direction is subsequently activated.

The permission gate passes when installation and launch do not prompt; Enable explains
the access first; denial leaves the current Service usable; one approval enables the
probe; and revocation produces a no-write error. Repeated prompts caused by the local
signing or installation strategy are recorded as a product limitation and block
promotion until resolved.

The capability gate passes only when Notes exposes a bounded selected-text write. Reading
or replacing the entire note is not acceptable. The spike must not log or save note
titles, raw note text, selected text, or context windows.

The safety gate requires zero wrong-note, wrong-range, unexpected-text, or changed-after-
cancellation outcomes. Every stale-context case must refuse the write. Every injected
failure must either leave Notes unchanged or complete a proven rollback. One partial or
ambiguous write rejects promotion.

The interaction gate requires all five detours to return through ordinary Command-Tab to
Notes with the correct pending panel visible in front, without Dock menus or “Show All
Windows.” Two pending disposable notes must remain distinct and only the panel whose
captured context is currently valid may commit. Expiry and the fourth-context limit must
be clear and leave Notes unchanged.

All twenty ordinary insertions must succeed. Confirmation-to-verified-caret latency must
have a median no greater than 1,000 ms and nearest-rank p95 no greater than 2,000 ms. The
caret must finish after the inserted text and Notes must be active. These thresholds match
the product's existing low-friction expectation without counting human decision time.

The regression gate requires all Swift tests and both fixture runners to pass with zero
new identity writes, false merges, protected leaks, or ordering failures. The synchronous
control must still pass five real Notes trials.

## Idempotence and Recovery

Presentation variants run in a separate experimental bundle. Close and release any
helper window on insertion, cancellation, error, or expiry. Keep the installed
production app available as the control and do not change its registered timeout
while testing experimental settings.

Automated tests use fakes and disposable databases. Capability and UI trials use only
disposable notes and may be repeated after clearing pending contexts. Re-running the same
context must focus its existing request rather than duplicate it.

The experimental Service has a separate name and shortcut, so failure does not remove the
current Service. If the prototype hangs, terminate only its process; pending contexts are
memory-only and disappear without writing. If permission is denied or revoked, leave the
system setting unchanged and continue with the synchronous control. At the end of the
spike, remove the experimental app and its Accessibility entry unless the learner
explicitly approves promotion. Never automate System Settings changes.

If an insertion cannot be verified, do not retry against a newly focused element. Attempt
rollback only against the still-proven original context. Preserve error names, timings,
and pass/fail outcomes—not Notes content—then require a fresh invocation.

## Artifacts and Notes

Create `spikes/notes-focus-recovery/EVIDENCE.md` for the approved future execution. Keep
raw invented fixtures beside it if useful. The evidence summary should show permission,
capability, safety, focus, concurrency, expiry, latency, rollback, and synchronous-control
results. It must explicitly state any untested behavior.

Apple's relevant platform behavior is incorporated into this plan: Accessibility trust
is process-specific and promptable; accessibility elements can become invalid; attribute
support and writability must be queried; interprocess calls may time out or fail; and
application activation is attempted rather than guaranteed. Implementation must branch
on observed capabilities and error codes rather than assuming them.

## Interfaces and Dependencies

Use AppKit and ApplicationServices already supplied by macOS. Add no third-party package.
Keep accessibility types inside the Notes adapter target; `GymAssistantCore` must not
import AppKit or ApplicationServices.

Define equivalents of these adapter-local types, refining names only if tests justify it:

    struct PendingNotesInvocation {
        let id: UUID
        let createdAt: Date
        let expiresAt: Date
        let mode: InvocationMode
        let context: NotesContextSnapshot
    }

    struct NotesContextSnapshot {
        let processIdentifier: pid_t
        let windowToken: NotesWindowToken
        let selectedRange: NSRange
        let surroundingContextHash: Data
    }

    enum NotesContextValidation {
        case valid(ValidatedNotesTarget)
        case stale(StaleContextReason)
        case permissionRequired
        case unavailable(NotesAdapterError)
    }

    protocol NotesContextAccessing {
        func captureFocusedContext(mode: InvocationMode) -> Result<NotesContextSnapshot, NotesAdapterError>
        func validate(_ snapshot: NotesContextSnapshot) -> NotesContextValidation
        func replaceSelection(in target: ValidatedNotesTarget, with text: String) -> NotesInsertionResult
    }

Milestone 0 uses AppKit and the existing synchronous Service only. Its helper-window
owner must create and release the experimental window without adding persistence
or an Accessibility dependency. The following interfaces belong only to the later
asynchronous milestones.

`PendingInvocationCoordinator` owns the three-request bound, duplicate-context behavior,
expiry, cancellation, and state transitions. `AccessibilityNotesContextAdapter` owns all
AX calls and content hashing. The existing autocomplete and identity workflows supply
candidate text but know nothing about AX elements or pending windows.

Revision note — 2026-10-01: Initial proposed plan written from Exercise 11 focus evidence
and the current synchronous Service implementation. No Accessibility prompt, permission
change, or prototype implementation was performed.

Revision note — 2026-10-02: The learner chose to retain the synchronous architecture and
defer this plan. Added the deferred disposition, exception-based monitoring decision,
and restart conditions; no spike implementation or permission change was performed.

Revision note — 2026-10-06: Added a deferred synchronous presentation milestone for
the learner's hidden-window shim, regular-window comparison, inline return to
autocomplete, and coordinated Service/watchdog extension. This tests the smaller
focus hypothesis before Accessibility work. Library editing uses the established
standalone Review Library handoff and keeps these experiments outside its scope.
