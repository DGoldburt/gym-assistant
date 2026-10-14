# Initial offline scratchpad implementation checkpoint

Acceptance update, 2026-10-14: the coach accepts the first handoff adding one blank
separator after a bulleted list before ordinary body text. Other spacing/formatting
changes are not implicitly approved. The importer now normalizes only the two exact
empty system-font heading suffixes observed in the native controls, after the matching
closed heading and before its div ends. A captured-shape regression verifies nine
paragraphs and retained heading/list structure, and rejects nonempty or differently
styled variants. All three importer tests and all five repository verification
stages pass. Rebuilt native round-trip acceptance
remains outstanding; the earlier test evidence below is historical.

Approved spacing-control follow-up, 2026-10-14: the coach explicitly permitted
clipboard replacement and synthetic fixture paste/undo. Three controls compared
single newlines, two-space hard breaks, backslash breaks and list termination.
Native exported HTML confirms single newlines become separate paragraphs with an
extra trailing space; two-space breaks become separate paragraphs without that
space. Blank separators between every body line are unnecessary. Heading and
Subheading tiers and bold text remain native. The exporter now uses single newlines
at heading/body boundaries, two-space breaks between adjacent body paragraphs,
and preserves intentional blank lines. Two added regressions and the corrected
heading-spacing expectation pass; all five repository verification stages pass.

Unresolved acceptance: without a blank separator after a list, the following body
line becomes an extra bullet. With a separator, it is correctly a body paragraph
but has a visible blank line before it. Existing separator behavior is retained,
not newly accepted as exact spacing fidelity. Ask whether that is acceptable for
the first handoff. Reimport also needs tested handling of Notes' empty system-font
wrappers after pasted headings; the current strict importer rejects those attributes.
These controls are not full end-to-end acceptance of the rebuilt exporter.

All test pastes and paragraph insertions were undone; a guarded read of only
Gym assistant capability test confirmed its exported HTML exactly equals the saved
pre-control HTML. No client notes were touched. Clipboard still holds synthetic
spacing-control Markdown; no attempt was made to restore or overwrite later copies.

Latest continuation, 2026-10-14: the coach approved the development app's Notes
Automation dialog. Its explicit native fixture command succeeded: 83 imported
paragraphs, two session regions, metadata identity and captured-ID reread. It did
not edit Notes, persist the note body, change the clipboard or call a provider.
This supersedes the pending-permission statements in the historical evidence below.

Checked copy is now connected when a live note context is supplied to the window.
Publication does not wait for verification; the 700ms timeout timer reserves 50ms
for delivery against the accepted 750ms limit. Late results only update app status.
Three concurrency tests cover timeout/late conflict, superseded copies, publication
failure and cancellation; an injected-reader controller test uses an isolated
pasteboard to verify fresh copy/diff reads and scratchpad preservation after an
equal-date external edit. No test touches the user's general clipboard.
Full verification passed all five stages, including 163 tests in 23 suites.
The rebuilt native app restored revision 23 and Command-Shift-C displayed
Copied—Notes not verified. Unlike the isolated-pasteboard automated tests, this
manual native command did replace the general clipboard with synthetic Markdown.
Pasting that output into the synthetic capability note preserved Heading and
Subheading when the insertion point was a new paragraph, but added blank lines
between ordinary program paragraphs. An initial mid-paragraph paste also joined
the first heading to the preceding text; inserting at a paragraph boundary resolved
that part. Both pastes and the test paragraph insertion were undone. No client note
was edited. A compact-newline clipboard control was rejected by the execution
approval reviewer before running because it would replace the general clipboard;
explicit approval is needed before that control. Do not bypass the rejection or
claim full formatting acceptance. The synthetic scratchpad copy remains on the
clipboard, and the development app retains revision 23.
This is not native latency acceptance or the completed offline slice. Default
development startup remains synthetic; live entry/boundary integration, formatted
diff, profile packaging, decoration and handoff acceptance are still outstanding.

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
