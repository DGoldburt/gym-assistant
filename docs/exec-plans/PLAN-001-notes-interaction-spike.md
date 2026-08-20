# PLAN-001 — Prove the Apple Notes interaction is fast and reliable

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds. Maintain this plan in accordance with the convention in the repository-root `PLANS.md`.

## Purpose / Big Picture

Determine whether a macOS integration can receive selected text from Apple Notes, present one lightweight keyboard-operated interaction with three hard-coded exercise choices, and return the chosen exercise and keyboard focus to Notes quickly and reliably enough for repeated strength-program writing. The fixed choices avoid exercise-resolution logic so that the experiment tests only the interaction boundary.

The code is intentionally disposable. If the Notes interaction is not viable, the project should learn that before investing in the exercise library, resolver, persistence, or production interface.

## Plan Status

Complete. The learner approved this hybrid plan at Exercise 01's `STOP / REVIEW — Spike plan` checkpoint on 2026-08-19, approved the Automator-first mechanism boundary at Exercise 02's tooling gate, and passed the architecture gate on 2026-08-20 after the AppKit fallback satisfied every approved runtime criterion.

## Progress

- [x] (2026-08-20 03:47Z) Compare regular prompting, Plan mode, and a regular-prompt control without `PLANS.md`; approve the deliberate hybrid recorded here.
- [x] (2026-08-20 05:01Z) At Exercise 02's tooling gate, verify macOS 26.6, Xcode 26.6, Swift 6.3.3, the macOS 26.5 SDK, and the installed Apple automation apps without installing or creating anything.
- [x] (2026-08-20 05:01Z) Select an Automator Quick Action as the smallest viable native mechanism; retain one minimal AppKit Service provider as the only fallback.
- [x] (2026-08-20 09:18Z) Build one disposable interaction with a keyboard-operated three-choice list and Cancel behavior; preserve the failed Automator attempt, then build, register, and assign Control-Option-Command-G to the verified AppKit fallback.
- [x] (2026-08-20 09:08Z) Verify one exact replacement and one cancellation before performance measurement using only the disposable Notes scratch note.
- [x] (2026-08-20 12:50Z) Run five controlled cold-start trials; 5/5 passed with a 480.0 ms maximum system-controlled latency.
- [x] (2026-08-20 12:54Z) Run twenty consecutive warm replacement trials and two additional warm cancellation trials; all passed, warm median was 130.5 ms, nearest-rank p95 was 192.9 ms, and both cancellations were unchanged.
- [x] (2026-08-20 13:10Z) Apply the evidence and architecture gates: pass the AppKit fallback, retain the Notes-adapter hypothesis, and carry the shortcut and identical-text ambiguity into Exercise 03 as limitations.

## Surprises & Discoveries

- Observation: The planning comparison itself revealed that a text-only round trip was too small a prototype because it would leave the feasibility of an MVP interaction untested.
  Evidence: The regular-prompt candidate omitted an interaction; Plan mode surfaced it; the learner required the approved hybrid to include it.

- Observation: The expected Command Line Tools-only environment had changed before Exercise 02; the full developer environment was already installed and selected.
  Evidence: macOS 26.6 (`25G72`) reported Xcode 26.6 (`17F113`), Apple Swift 6.3.3, `/Applications/Xcode.app/Contents/Developer`, and the macOS 26.5 SDK. No installation was required.

- Observation: An Automator Quick Action has a smaller supported route to the experiment than a custom AppKit service.
  Evidence: Apple's Automator documentation explicitly supports Text or Rich Text input with output replacing selected text, macOS Services support keyboard shortcuts, and the installed `Choose from List` action accepts and returns strings. Notes-specific focus and cancellation behavior remain unproven until the experiment.

- Observation: The Automator Quick Action failed the complete interaction contract despite two bounded corrections.
  Evidence: `Get Specified Text` produced one combined list item; three distinct strings fixed the rows but the built-in chooser had no Cancel control and did not respond to Escape or Command-period in the validation run. A `Run AppleScript` chooser added Replace and Cancel inside Automator, but repeated invocation from Notes did not present the dialog. The selected scratch text remained unchanged.

- Observation: The AppKit fallback satisfies the unmeasured interaction contract, including keyboard navigation and focus restoration.
  Evidence: Notes exposed `Gym Assistant Exercise Chooser (AppKit)` after Launch Services registration. In the rebuilt focused-table version, Down moved the highlight from Front Squat to Single-Leg Romanian Deadlift; Return replaced only `SL RDL` with `Single-Leg Romanian Deadlift`; Escape left `SL RDL` unchanged; and both paths returned focus to the Notes body. This smoke evidence preceded shortcut assignment and timed trials.

- Observation: The AppKit fallback passed the approved automated performance and integrity gates with substantial margin.
  Evidence: Five fresh-launch trials passed with a maximum 480.0 ms system latency. Twenty resident trials passed with a 130.5 ms median and 192.9 ms nearest-rank p95. Two cancellation checks were unchanged, and all 27 accepted rows reported exact output, same-note/range integrity, and returned Notes focus. The settled timestamp is a documented one-frame proxy followed by independent UI assertions, not direct video-frame analysis.

- Observation: Measurement automation required its own falsification and recovery work.
  Evidence: A standalone helper stopped before trials because it lacked Accessibility access; a stale provider produced no events; and app-targeted Command-Q could not prove cold reset. Those attempts are preserved in `AUTOMATION_CALIBRATION.jsonl`. The accepted cold build instead required a fresh application-launch event per row and self-terminated after its settled event.

Add implementation discoveries here, including unexpected Notes behavior, focus changes, permission prompts, latency outliers, or mechanism limitations. Preserve failed and invalid trials rather than silently deleting them.

## Decision Log

- Decision: Include one lightweight interaction after text capture and before replacement.
  Rationale: The MVP will require some interaction, and learning late that it cannot remain frictionless would be expensive. A disposable Replace/Cancel prompt tests that boundary without building a production chooser.
  Date/Author: 2026-08-19 / Dan Goldburt and Codex.

- Decision: Separate cold-start and warm-use acceptance.
  Rationale: Startup cost and repeated programming use have different performance characteristics; combining them would conceal the experience that matters during repeated use.
  Date/Author: 2026-08-19 / Dan Goldburt and Codex.

- Decision: Apply strict latency thresholds only to system-controlled time.
  Rationale: Human decision time varies and would make a small technical sample noisy. Record the full observed workflow as supplementary usability evidence, but compute acceptance latency as shortcut-to-ready-interaction plus confirmation-to-visible-replacement, excluding the interval spent deciding.
  Date/Author: 2026-08-19 / Dan Goldburt and Codex.

- Decision: Require every cold and warm trial to succeed.
  Rationale: A repeatedly used writing interaction must be trustworthy. A single wrong-note, wrong-range, text-loss, or cancellation failure is more important than an average latency result.
  Date/Author: 2026-08-19 / Dan Goldburt and Codex.

- Decision: Evaluate no more than two native integration mechanisms.
  Rationale: The spike resolves one architecture risk; it is not an open-ended survey of macOS automation technologies.
  Date/Author: 2026-08-19 / Dan Goldburt and Codex.

- Decision: Test an Automator Quick Action first and retain a minimal AppKit Service provider as the only fallback.
  Rationale: The Quick Action can accept selected text, expose itself through macOS Services for keyboard invocation, display the installed `Choose from List` action, and request that its output replace selected text without an app project. The AppKit fallback requires a macOS app target, an `NSServices` declaration, and pasteboard handling, so it is justified only if the smaller mechanism fails on Notes-specific behavior.
  Date/Author: 2026-08-19 / Dan Goldburt and Codex.

- Decision: Supersede the provisional `GA-SPIKE:` Replace/Cancel prompt with the three fixed choices from Exercise 02: Front Squat, Single-Leg Romanian Deadlift, and Aussie Pull-up.
  Rationale: The three-choice interaction is still deterministic and disposable, tests the actual selection friction required by the exercise, and introduces no exercise identity or resolver logic. Return accepts the highlighted choice; Escape cancels and must leave the note unchanged.
  Date/Author: 2026-08-19 / Dan Goldburt and Codex.

- Decision: Limit the first experiment to the verified macOS 26.6 machine.
  Rationale: Current Apple documentation and the installed first-party components establish a credible local route, but they do not prove behavior on other OS versions. Wider compatibility, signing, notarization, and distribution are outside this architecture spike.
  Date/Author: 2026-08-19 / Dan Goldburt and Codex.

## Outcomes & Retrospective

The Automator mechanism failed the complete interaction contract and remains preserved as negative evidence. The AppKit Service-provider fallback passed every approved performance, cancellation, integrity, and focus gate: 5/5 cold at a 480.0 ms maximum, 20/20 warm at a 130.5 ms median and 192.9 ms nearest-rank p95, 2/2 unchanged cancellations, and zero integrity or focus failures.

The learner judged the real shortcut workflow quick, painless, and suitable for repeated program writing, so the architecture gate passed and the Notes-adapter hypothesis proceeds to Exercise 03. The main usability limitations are the awkward Control–Option–Command–G chord and the lack of visible confirmation when replacement text is identical to the selection. The automated endpoint used a documented one-frame settled proxy followed by independent UI assertions; this evidence limitation is far from either performance boundary but must remain visible in the ADR. Exercise 03—not this plan—owns the durable architecture decision and falsifiable revisit triggers.

## Context and Orientation

Apple Notes remains the user's workout-writing workspace. The proposed companion should receive selected text, allow a lightweight confirmation or choice, replace the selection, and return focus with minimal interruption. Apple Notes is only an adapter: exercise identity, matching, and persistence must remain independent from it and are outside this experiment.

The repository contains product, architecture, curriculum, and planning documents but no application project. Full Xcode was installed after Exercise 01's initial inspection, but Exercise 02 must verify the active environment instead of relying on that observation. Installation, project creation, and implementation must not begin before the Exercise 02 tooling checkpoint authorizes them.

The disposable interaction receives selected plain text from the active note and automatically focuses a list containing exactly Front Squat, Single-Leg Romanian Deadlift, and Aussie Pull-up. `Return` accepts the highlighted exercise and replaces the selected text in the same range of the same note with that exact exercise name. `Escape` cancels, leaves the note byte-for-byte unchanged, and returns focus to Notes. Neither path may require a mouse or manual application switch.

The approved first mechanism is an Automator Quick Action configured to receive Text in Apple Notes and to replace selected text with its output. It uses only macOS-provided actions. Xcode is not required for this mechanism. The verified full Xcode installation is a ready fallback toolchain only: if the Quick Action fails fairly, create one minimal macOS AppKit app target that advertises an `NSServices` text processor, exchanges text through `NSPasteboard`, and presents the same fixed chooser. Local experimentation requires no distribution work; signing, notarization, and support beyond macOS 26.6 remain out of scope.

A cold trial starts with Notes open and test text selected while the disposable integration component is not resident. A warm trial follows a successful priming invocation while the component remains available. Do not restart the Mac or close Notes merely to manufacture a cold start; document the safe, repeatable component reset used instead.

For each measured replacement, capture three timestamps: shortcut invocation, interaction ready for keyboard input, and replacement visible with focus returned to Notes. Also capture the learner's confirmation timestamp. Compute system-controlled latency as:

    (interaction ready - shortcut invocation)
    + (replacement visible - confirmation)

This excludes the learner's decision interval. Retain full shortcut-to-visible-replacement time only as supplementary workflow evidence.

## Constraints and Non-Goals

Use only the minimum disposable artifact needed to test the Notes boundary. Do not implement or design a database, persistence, canonical exercise records, normalization, aliases, fuzzy matching, client history, performance history, load recommendations, exercise blocks, a full exercise chooser, production styling, settings, packaging, or permanent product architecture.

Do not replace Apple Notes with another editor. Do not update `docs/ARCHITECTURE.md` or create an architecture decision record; Exercise 03 owns the durable architecture decision. Do not turn the fixed three-item chooser into a searchable or production exercise chooser, and do not turn the spike into the application.

Prefer facilities supplied by macOS and the already-installed Xcode toolchain. Do not add a third-party dependency. Stop for tutorial approval before installing or upgrading Xcode or another tool.

## Plan of Work

### Milestone 1 — Pass the Exercise 02 tooling and mechanism gate

From the repository root, inspect the environment with the read-only commands in `Concrete Steps`. Record the macOS version, active developer directory, Xcode version, branch, and existing learner-state changes.

The completed investigation selected an Automator Quick Action. Apple's current macOS guidance confirms that Services can operate on selected document text and have keyboard shortcuts; Apple's Automator guidance explicitly provides an “Output replaces selected text” option for Text or Rich Text Quick Actions; and the installed `Choose from List` action accepts and returns strings. This is a credible route, not proof of Apple Notes behavior. If it cannot satisfy the complete interaction in a fair test, consider one minimal AppKit Service provider using the verified Xcode environment. Do not evaluate a third mechanism.

The tooling gate passes only when the active toolchain is usable and one mechanism has a credible route to selection capture, automatic focus, Return/Escape handling, same-range replacement, and focus restoration. Stop for explicit approval if installation or external setup is required. Report the gate as inconclusive if neither mechanism is credible without broader investigation.

### Milestone 2 — Build the disposable interaction

After the tooling gate passes, create only the Automator Quick Action artifact under `spikes/notes-interaction/`. Configure it to accept selected text in Apple Notes, present the three fixed exercise strings through `Choose from List`, and replace the selected text with the chosen string. Add `spikes/notes-interaction/EVIDENCE.md` with exact setup, invocation, reset, measurement, and cleanup instructions. If the workflow cannot be exported into the repository, retain only safe evidence and exact recreation steps.

Use a scratch note containing no private client information. Prove one choice-and-replacement round trip and one Cancel round trip before collecting performance data. If text is lost, sent to another note or range, focus is not restored, or a mouse or manual app switch is required, change only the integration mechanism; do not compensate with product features.

### Milestone 3 — Measure five cold trials

Use `SL RDL` as the selected input for every cold trial and choose Single-Leg Romanian Deadlift. Before each attempt, restore the scratch note, select the exact text, reset only the spike component using the documented safe method, and confirm that it is not resident when observable. Invoke the shortcut, press Return when the interaction is ready, and record the four timestamps, exact output, selected range, returned focus, permissions, and anomalies.

Every cold trial must succeed. Each trial's system-controlled latency must be no more than 3,000 milliseconds.

### Milestone 4 — Measure repeated warm use

Prime the component once and keep it resident. Run five replacement trials for each of these inputs, for twenty trials total: `Front Squat`, choosing Front Squat; `SL RDL`, choosing Single-Leg Romanian Deadlift; `A1 Front Squat — 3 × 5`, choosing Aussie Pull-up; and a three-line block of exercise names, choosing Front Squat. Restore and select the exact input before every trial. Capture the same evidence as for cold trials without resetting the component.

Sort the twenty system-controlled latency values. The median is the midpoint of positions 10 and 11; the nearest-rank p95 is position 19. Run two additional warm Cancel trials with Escape. These cancellation trials are integrity checks and do not enter the replacement latency distribution.

## Concrete Steps

At the start of Exercise 02, work from `/Users/dan/Documents/D/dev/gym_assistant` and run:

    sw_vers
    xcode-select -p
    xcodebuild -version
    swift --version
    xcrun --show-sdk-path
    xcrun --sdk macosx --show-sdk-version
    git status --short --branch

These commands reported macOS 26.6 (`25G72`), `/Applications/Xcode.app/Contents/Developer`, Xcode 26.6 (`17F113`), Apple Swift 6.3.3, the macOS SDK path, macOS SDK 26.5, and branch `tutorial/exercise-02`. The SDK is present and usable even though its version is one minor release behind the installed OS. The selected Automator mechanism needs no Xcode capability; these results prove that the AppKit fallback has a full macOS app toolchain without adding unrelated tools. Stop at Exercise 02's implementation-readiness checkpoint before creating the workflow, project, or spike files.

After that checkpoint passes and the disposable spike exists, inspect its inventory with:

    git status --short
    find spikes/notes-interaction -maxdepth 3 -type f -print

Expected status contains only approved spike artifacts plus the learner's documented curriculum state. It must contain no generated build output, credentials, private note content, unrelated curriculum edits, or application project outside `spikes/notes-interaction/`.

In `spikes/notes-interaction/EVIDENCE.md`, retain one row per attempt with trial class and number, input category, shortcut-to-ready milliseconds, decision interval milliseconds, confirmation-to-replacement milliseconds, computed system-controlled milliseconds, full workflow milliseconds, exact-output result, same-note/range result, focus result, and anomalies. Mark interrupted measurements invalid with the reason and a new attempt number; never relabel a genuine invocation, focus, integrity, or latency failure as invalid.

## Validation and Acceptance

The Notes interaction passes only if one configured keyboard shortcut receives selected Notes text; the three-choice list focuses automatically; Return replaces the intended range with the exact highlighted exercise name; Escape changes nothing; focus returns to Notes; and neither path requires a mouse or manual app switching.

All five cold trials must succeed with system-controlled latency no greater than 3,000 milliseconds each. All twenty warm replacements must succeed with median system-controlled latency no greater than 1,000 milliseconds and p95 no greater than 2,000 milliseconds. Both Cancel checks must leave the note unchanged. There must be zero wrong-note replacements, unintended-range replacements, text-loss events, focus-restoration failures, or repeated permission prompts.

Screenshots or screen recordings must show the interaction and returned Notes state. The evidence file must contain the timestamp-derived measurements, environment output, mechanism choice, permission observations, failure records, and reproducible setup. If this evidence becomes disproportionately expensive, stop and report which criterion caused the burden rather than silently weakening it.

If the first mechanism fails, preserve its evidence and test the second. Pass the architecture gate if either mechanism satisfies every criterion. Reject the current Notes-adapter hypothesis if both mechanisms receive a fair test and fail. Report inconclusive if tooling, permissions, or environmental failures prevent a fair test without additional approval.

## Stopping Conditions

Stop immediately before installing or upgrading tools, testing a third mechanism, creating product architecture, expanding the fixed list into a searchable or production chooser, adding production UI or packaging, or implementing resolver, aliases, persistence, client or performance history, load recommendations, or exercise blocks.

At the end, return to the Exercise 02 architecture checkpoint with the tested mechanisms, cold and warm measurements, integrity results, evidence paths, and pass/fail/inconclusive recommendation. Do not proceed into Exercise 03 automatically.

## Idempotence and Recovery

Use a dedicated scratch note so repetition cannot damage real programming notes. Restore the exact input before each attempt. The three fixed replacement strings are obvious and manually reversible. If a trial is interrupted by an unrelated notification or operator mistake, preserve it as invalid with the reason and repeat it under a new attempt number.

Do not classify a genuine invocation, focus, replacement, cancellation, or latency failure as an invalid trial. Keep generated build output untracked. Removing the disposable spike must not affect product files because no product implementation may depend on it.

## Artifacts and Notes

The final evidence summary should report:

    Mechanism: <tested mechanism>
    Cold trials: <n>/5 successful
    Cold maximum system latency: <n> ms
    Warm trials: <n>/20 successful
    Warm system latency median / p95: <n> ms / <n> ms
    Cancel checks: <n>/2 unchanged
    Integrity and focus failures: <n>
    Recommendation: pass / fail / inconclusive

Retain short screenshot or recording filenames, permission observations, and failure transcripts. Do not commit private note content, credentials, signing identities, or machine-specific secrets.

## Interfaces and Dependencies

This spike creates no product API, schema, domain type, persistence format, or reusable resolver interface. Its only temporary behavioral contract is selected plain text in and either no change on Cancel or the exact chosen value from Front Squat, Single-Leg Romanian Deadlift, and Aussie Pull-up on Return, followed by focus returning to Apple Notes.

Use the macOS-provided Automator Quick Action facility first. Use the already-installed Xcode toolchain only for the single AppKit Service-provider fallback if the Quick Action fails fairly. Adding a third-party dependency fails the scope gate.

Revision note (2026-08-20): Recorded the Exercise 01 approved hybrid. It combines the regular candidate's cold/warm thresholds, Plan mode's lightweight interaction, the `PLANS.md` living-plan structure, and the learner's requirement to exclude human decision time from system-latency acceptance.

Revision note (2026-08-20): Recorded the Exercise 02 Task A mechanism decision and Task B environment evidence. The plan now starts with an Automator Quick Action on the verified macOS 26.6 machine, retains one AppKit Service-provider fallback, and aligns the disposable interaction with Exercise 02's three hard-coded choices while preserving the approved latency and integrity gates.
