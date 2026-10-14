# Initial offline scratchpad implementation checkpoint

Date: 2026-10-14. Partial PLAN 013 implementation, not a completed feature or live
Notes acceptance. The native test uses a synthetic Session 18, an empty synthetic
profile and a deliberately delayed fake assistant. No Notes reading, Service
registration, exercise-library access or provider/network request occurs.

## What works in this increment

Foundation-only workspace/request types keep stable identities, ordered conversation,
the unsent composer and captured scratchpad revisions separate. Context assembly
replaces only the paragraph-aligned, explicitly associated synthetic source region;
it preserves surrounding note text and rejects stale/oversized inputs. The request
gate refuses concurrent submissions and ignores stopped/older request completions.
Profile evidence retains scope, exceptions and confirmation status without writing
preferences. This does not prove a real model follows those distinctions.

Secure attributed-string snapshots validate content and identity before promotion
and reopening, preserving a prior valid copy. Fault-injection tests cover save phases,
corruption, wrong schema, mismatched archive/text, stale revision and directory failure.
Recovery exposes a prior valid snapshot but preserves damaged files; resaving over
damaged slots is deliberately blocked. The recovery interaction is not complete.

Native observations: edited B2 to Dowel squat, submitted a question at revision 12,
then quit/relaunched into the same text, conversation and unsent composer. A 15-second
fake request kept Send disabled, refused Enter without losing follow-up text, and
Stop left the follow-up editable with the prior reply marked cancelled. Later edits
to the scratchpad during generation marked the older response Scratchpad changed;
composer typing alone did not after the fix. Closing and Window-menu reopening
preserved the same scratchpad and composer. In-place comparison showed a single
changed text hunk and restored editing when toggled off.

The copy icon produced Copied—Notes not verified; read-only clipboard checking
confirmed the expected Markdown heading without printing contents. The normal
clipboard now contains synthetic test Markdown. No actual Notes paste from this
editor was tested. Format tests cover headings, bold, disc lists and literal markers;
unsupported links/emphasis/attachments fail rather than silently flatten. Original
spacing and arbitrary formatting still require native Notes acceptance.

The final build also exposes Copy Markdown for Notes in Edit; Command-Shift-C
invoked it while the scratchpad had focus. The final app was quit after testing;
its synthetic state is retained locally for resuming. Full verification passes
all five deterministic stages and 134 package tests in 17 suites. These counts do
not prove correctness or replace the missing native Notes integration tests.

## Defect found through native testing

Typing a follow-up while generation ran falsely displayed Scratchpad changed. The
revision did not advance, but textDidChange updated the warning for either view.
Restrict the warning to actual editor changes. The new ScratchpadWindowTests regression
checks typing, editor change, disabled Send, Stop and preservation of unsent text.
Corrected native behavior was observed. Passing tests are evidence, not proof of
correctness. UI layout/accessibility and large-content behavior need further review.

## Reproduce locally

From the feature checkout, run scripts/verify, then:

    bash app/scratchpad-development/build.sh

Open the printed temporary app using native computer-use tools or manually. The
separate synthetic store is Application Support/GymAssistantScratchpadDevelopment;
do not delete it as routine test cleanup. Quit/relaunch deliberately retains test
state. No installation or change to the installed Gym Assistant is needed.

## Still outstanding

Further implementation and native evidence, 2026-10-14:

- Structured session detection retains peer-level typo boundaries for confirmation,
  all weeks in a lettered session, and trailing Parking Lot context. Set-level
  association compares complete supported body structure across saved anchors,
  surfaces duplicate labels, and rejects stale/overlapping confirmations. Repeated
  identical reads retain a coach-confirmed manual association.
- Saved boundary protection retains deletion, insertion and formatting evidence.
  Legacy edited snapshots without correspondence are conservative: expansion is
  possible, destructive shrink is blocked. These optional development-snapshot
  fields are not a shipped production migration contract.
- Native synthetic Command-Shift-B opens the read-only note browser. Shift-Down
  expands the highlighted edge; Command-Return incorporates only added source text,
  preserving the edited B2 and unsent composer. Reopen restores the expanded scope.
  Unsafe shrink is refused. Escape cancels. Source ownership and fresh-read checks
  are tested as components, not integrated into live boundary editing yet.
- Initial native undo failed because its before-image aliased live text. Save
  validation rejected the mismatch. The test process was stopped with its last
  valid snapshot preserved, then rebuilt. Independent attributed-string copies and
  controlled undo registration fixed it; native retry restored scope/formatting,
  retained B2, and saved revision 23. The regression also verifies redo and reload.
- The shared note-context pool loads closed-workspace anchors without unarchiving
  their rich text, retains one context/monitor per NoteID, and orders asynchronous
  observations so a delayed delivery cannot overwrite newer state. Optional chat
  integration waits for fresh Notes, preserves follow-up typing, and supports Stop
  during the read. The installed Service is not wired to this path.
- Programming Preferences is a read-only window with explicit evidence kind,
  confirmation, source, scope and exceptions. The synthetic app still has an empty
  profile; private philosophy/seed packaging is outstanding. The private companion
  was located outside Git; none of its content was added to reusable source.
- A development-only menu now explicitly requests Notes Automation access and
  verifies the selected note only when its title is Gym assistant capability test.
  The initial non-prompting read correctly reported missing permission. An explicit
  access request was triggered; native adapter success is pending the separate
  development app's permission grant. No note write, provider call or installation
  occurred. This supersedes the initial blanket statement that the development
  executable contains no Notes-access path: ordinary synthetic launch still does
  not read Notes.

All five repository verification stages passed after this further increment. The
current native test app is left running awaiting its explicit Automation request;
the synthetic scratchpad is saved at revision 23. The installed Gym Assistant,
real Notes content and client-history worktree were not modified.

Follow-on implementation, 2026-10-14: `NotesContextReader` now supplies the native
read-only adapter, and `NotesRefreshCoordinator` supplies shared refresh execution.
They are deliberately not wired into the synthetic window yet. The adapter requests
no consent during reads, uses one serial worker queue across instances, and limits
Apple events with a two-second script timeout. This is not a measured wall-clock
deadline or a guarantee that a native call can be forcibly cancelled. Permission
onboarding and real Notes execution remain untested for this adapter.

Injected tests verify metadata-only unchanged ticks, no hidden reads, delayed body
coalescing, same-date edits, formatting-only invalidation, unchanged-content cache
identity reuse, later-consumer freshness, suspension, wrong-note refusal, retained
last-known data and backoff. A tick queued during a failing read initially could
bypass the newly established backoff; clear that queued idle work and preserve
explicit consumer retries. The regression exercises that ordering. No test reads
real Notes, calls a model, changes the clipboard or modifies a scratchpad baseline.
Window lifecycle/registry ownership, status delivery and checked-copy timing still
need integration and native acceptance.

Verification for this follow-on: all five repository stages passed with the first
eight refresh tests; after the queued-tick correction, all nine refresh tests passed
in 0.512 seconds. The native adapter compiled, but no real Notes request was made.

Production Notes capture/permission onboarding/metadata monitoring, actual session
association and protected boundary browser, real profile inspection, exact library
decoration, headings-only new-session flow and actual Notes handoff/diff. Recovery
repair controls, app-level crash durability and supported macOS versions are not
established by this checkpoint. Live API defaults/limits remain a separate approval.
Client-history worktree is untouched. Legacy-worktree archive remains blocked by
another chat's ownership; mockups are already preserved here byte-for-byte.
