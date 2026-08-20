# PLAN-001 — Prove the Apple Notes interaction is fast and reliable

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds. Maintain this plan in accordance with the convention in the repository-root `PLANS.md`.

## Purpose / Big Picture

Determine whether a macOS integration can receive selected text from Apple Notes, present one lightweight keyboard-operated interaction, and return replacement text and keyboard focus to Notes quickly and reliably enough for repeated strength-program writing. The experiment uses an obvious deterministic transformation instead of exercise-resolution logic so that it tests only the interaction boundary.

The code is intentionally disposable. If the Notes interaction is not viable, the project should learn that before investing in the exercise library, resolver, persistence, or production interface.

## Plan Status

Approved. The learner approved this hybrid plan at Exercise 01's `STOP / REVIEW — Spike plan` checkpoint on 2026-08-19.

## Progress

- [x] (2026-08-20 03:47Z) Compare regular prompting, Plan mode, and a regular-prompt control without `PLANS.md`; approve the deliberate hybrid recorded here.
- [ ] At Exercise 02's tooling gate, verify the active macOS and Xcode environment without installing or creating anything.
- [ ] Select the smallest viable native mechanism, evaluating no more than two mechanisms.
- [ ] Build one disposable interaction with keyboard-operated Replace and Cancel actions.
- [ ] Verify one exact replacement and one cancellation before performance measurement.
- [ ] Run five controlled cold-start trials.
- [ ] Run twenty consecutive warm replacement trials and two additional warm cancellation trials.
- [ ] Apply the evidence and architecture gates and record pass, fail, or inconclusive.

## Surprises & Discoveries

- Observation: The planning comparison itself revealed that a text-only round trip was too small a prototype because it would leave the feasibility of an MVP interaction untested.
  Evidence: The regular-prompt candidate omitted an interaction; Plan mode surfaced it; the learner required the approved hybrid to include it.

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

## Outcomes & Retrospective

Implementation has not started. At completion, state whether the Notes interaction passed, failed, or remained inconclusive; name the tested mechanism or mechanisms and evidence; and say whether Exercise 03 should retain, replace, or reject the Notes-adapter hypothesis.

## Context and Orientation

Apple Notes remains the user's workout-writing workspace. The proposed companion should receive selected text, allow a lightweight confirmation or choice, replace the selection, and return focus with minimal interruption. Apple Notes is only an adapter: exercise identity, matching, and persistence must remain independent from it and are outside this experiment.

The repository contains product, architecture, curriculum, and planning documents but no application project. Full Xcode was installed after Exercise 01's initial inspection, but Exercise 02 must verify the active environment instead of relying on that observation. Installation, project creation, and implementation must not begin before the Exercise 02 tooling checkpoint authorizes them.

The disposable interaction receives selected plain text from the active note and automatically receives keyboard focus. `Return` activates Replace and returns `GA-SPIKE: ` followed by the exact selected text to the same range in the same note. `Escape` activates Cancel, leaves the note byte-for-byte unchanged, and returns focus to Notes. Neither path may require a mouse or manual application switch.

A cold trial starts with Notes open and test text selected while the disposable integration component is not resident. A warm trial follows a successful priming invocation while the component remains available. Do not restart the Mac or close Notes merely to manufacture a cold start; document the safe, repeatable component reset used instead.

For each measured replacement, capture three timestamps: shortcut invocation, interaction ready for keyboard input, and replacement visible with focus returned to Notes. Also capture the learner's confirmation timestamp. Compute system-controlled latency as:

    (interaction ready - shortcut invocation)
    + (replacement visible - confirmation)

This excludes the learner's decision interval. Retain full shortcut-to-visible-replacement time only as supplementary workflow evidence.

## Constraints and Non-Goals

Use only the minimum disposable artifact needed to test the Notes boundary. Do not implement or design a database, persistence, canonical exercise records, normalization, aliases, fuzzy matching, client history, performance history, load recommendations, exercise blocks, a full exercise chooser, production styling, settings, packaging, or permanent product architecture.

Do not replace Apple Notes with another editor. Do not update `docs/ARCHITECTURE.md` or create an architecture decision record; Exercise 03 owns the durable architecture decision. Do not turn the spike into the application.

Prefer facilities supplied by macOS and the already-installed Xcode toolchain. Do not add a third-party dependency. Stop for tutorial approval before installing or upgrading Xcode or another tool.

## Plan of Work

### Milestone 1 — Pass the Exercise 02 tooling and mechanism gate

From the repository root, inspect the environment with the read-only commands in `Concrete Steps`. Record the macOS version, active developer directory, Xcode version, branch, and existing learner-state changes.

Evaluate native mechanisms in this order. First consider a Shortcuts or Automator Quick Action that can receive selected Notes text, run from one keyboard shortcut, automatically focus a Replace/Cancel interaction, replace the same selection, and return focus. If it cannot satisfy the complete interaction, consider one minimal AppKit Service provider using the verified Xcode environment. Select the first mechanism that credibly satisfies every behavior; record why any rejected mechanism failed. Do not evaluate a third mechanism.

The tooling gate passes only when the active toolchain is usable and one mechanism has a credible route to selection capture, automatic focus, Return/Escape handling, same-range replacement, and focus restoration. Stop for explicit approval if installation or external setup is required. Report the gate as inconclusive if neither mechanism is credible without broader investigation.

### Milestone 2 — Build the disposable interaction

After the tooling gate passes, create only the selected spike artifact under `spikes/notes-interaction/`. Add `spikes/notes-interaction/EVIDENCE.md` with exact setup, invocation, reset, measurement, and cleanup instructions. If a native workflow cannot be exported into the repository, retain only safe evidence and exact recreation steps.

Use a scratch note containing no private client information. Prove one Replace round trip and one Cancel round trip before collecting performance data. If text is lost, sent to another note or range, focus is not restored, or a mouse or manual app switch is required, change only the integration mechanism; do not compensate with product features.

### Milestone 3 — Measure five cold trials

Use `SL RDL` as the selected input for every cold trial. Before each attempt, restore the scratch note, select the exact text, reset only the spike component using the documented safe method, and confirm that it is not resident when observable. Invoke the shortcut, press Return when the interaction is ready, and record the four timestamps, exact output, selected range, returned focus, permissions, and anomalies.

Every cold trial must succeed. Each trial's system-controlled latency must be no more than 3,000 milliseconds.

### Milestone 4 — Measure repeated warm use

Prime the component once and keep it resident. Run five replacement trials for each of these inputs, for twenty trials total: `Front Squat`; `SL RDL`; `A1 Front Squat — 3 × 5`; and a three-line block of exercise names. Restore and select the exact input before every trial. Capture the same evidence as for cold trials without resetting the component.

Sort the twenty system-controlled latency values. The median is the midpoint of positions 10 and 11; the nearest-rank p95 is position 19. Run two additional warm Cancel trials with Escape. These cancellation trials are integrity checks and do not enter the replacement latency distribution.

## Concrete Steps

At the start of Exercise 02, work from `/Users/dan/Documents/D/dev/gym_assistant` and run:

    sw_vers
    xcode-select -p
    xcodebuild -version
    git status --short --branch

Expect these commands to report the environment without changing it. Stop at Exercise 02's tooling checkpoint before creating a project or spike files.

After that checkpoint passes and the disposable spike exists, inspect its inventory with:

    git status --short
    find spikes/notes-interaction -maxdepth 3 -type f -print

Expected status contains only approved spike artifacts plus the learner's documented curriculum state. It must contain no generated build output, credentials, private note content, unrelated curriculum edits, or application project outside `spikes/notes-interaction/`.

In `spikes/notes-interaction/EVIDENCE.md`, retain one row per attempt with trial class and number, input category, shortcut-to-ready milliseconds, decision interval milliseconds, confirmation-to-replacement milliseconds, computed system-controlled milliseconds, full workflow milliseconds, exact-output result, same-note/range result, focus result, and anomalies. Mark interrupted measurements invalid with the reason and a new attempt number; never relabel a genuine invocation, focus, integrity, or latency failure as invalid.

## Validation and Acceptance

The Notes interaction passes only if one configured keyboard shortcut receives selected Notes text; the lightweight interaction focuses automatically; Return replaces the intended range with the exact deterministic output; Escape changes nothing; focus returns to Notes; and neither path requires a mouse or manual app switching.

All five cold trials must succeed with system-controlled latency no greater than 3,000 milliseconds each. All twenty warm replacements must succeed with median system-controlled latency no greater than 1,000 milliseconds and p95 no greater than 2,000 milliseconds. Both Cancel checks must leave the note unchanged. There must be zero wrong-note replacements, unintended-range replacements, text-loss events, focus-restoration failures, or repeated permission prompts.

Screenshots or screen recordings must show the interaction and returned Notes state. The evidence file must contain the timestamp-derived measurements, environment output, mechanism choice, permission observations, failure records, and reproducible setup. If this evidence becomes disproportionately expensive, stop and report which criterion caused the burden rather than silently weakening it.

If the first mechanism fails, preserve its evidence and test the second. Pass the architecture gate if either mechanism satisfies every criterion. Reject the current Notes-adapter hypothesis if both mechanisms receive a fair test and fail. Report inconclusive if tooling, permissions, or environmental failures prevent a fair test without additional approval.

## Stopping Conditions

Stop immediately before installing or upgrading tools, testing a third mechanism, creating product architecture, expanding the prompt into a full chooser, adding production UI or packaging, or implementing resolver, aliases, persistence, client or performance history, load recommendations, or exercise blocks.

At the end, return to the Exercise 02 architecture checkpoint with the tested mechanisms, cold and warm measurements, integrity results, evidence paths, and pass/fail/inconclusive recommendation. Do not proceed into Exercise 03 automatically.

## Idempotence and Recovery

Use a dedicated scratch note so repetition cannot damage real programming notes. Restore the exact input before each attempt. Keep the deterministic prefix obvious and manually reversible. If a trial is interrupted by an unrelated notification or operator mistake, preserve it as invalid with the reason and repeat it under a new attempt number.

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

This spike creates no product API, schema, domain type, persistence format, or reusable resolver interface. Its only temporary behavioral contract is selected plain text in and either no change on Cancel or `GA-SPIKE: <selected text>` on Replace, followed by focus returning to Apple Notes.

Use only macOS-provided integration facilities and, if the tooling gate approves it, the already-installed Xcode toolchain. Adding a third-party dependency fails the scope gate.

Revision note (2026-08-20): Recorded the Exercise 01 approved hybrid. It combines the regular candidate's cold/warm thresholds, Plan mode's lightweight interaction, the `PLANS.md` living-plan structure, and the learner's requirement to exclude human decision time from system-latency acceptance.
