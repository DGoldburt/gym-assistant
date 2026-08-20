# Exercise 02 — Apple Notes Service Architecture Spike

## Why we're doing this

This is an architecture spike: code written primarily to reduce uncertainty, not to become the production feature. Toolchain setup belongs here because it is justified by the macOS integration mechanism being investigated, not by agentic coding in general.

## Skills practiced

- `orient` — Orient before changing
- `frame-work` — Frame a bounded task
- `plan` — Plan in proportion to risk
- `set-boundaries` — Control autonomy safely
- `verify` — Build an evidence-producing delivery loop

## Product experiment

In Apple Notes:

1. type a short string such as `sl`
2. select it
3. invoke the companion action/service
4. see three hard-coded exercise choices:
   - Front Squat
   - Single-Leg Romanian Deadlift
   - Aussie Pull-up
5. choose one
6. return or replace the selected text if the platform supports it cleanly

A keyboard shortcut should be investigated if practical.

## Task A — Investigate the mechanism and toolchain

Read `PLAN-001` from `docs/exec-plans/PLAN-001-notes-interaction-spike.md`, using `PLANS.md` only as its maintenance convention. Without installing software or creating an app, Codex should:

1. inspect macOS version, developer-directory selection, `xcodebuild`, Swift availability, and existing project state
2. use current authoritative documentation to compare supported integration mechanisms
3. distinguish legacy macOS Services mechanisms from current extension or Quick Action mechanisms
4. determine what can receive selected text, return replacement text, show a chooser, and support keyboard invocation
5. identify OS-version, activation, focus, signing, and distribution assumptions
6. propose the smallest supported implementation mechanism
7. state exactly which Xcode capability is required and why
8. update the proposed parts of `PLAN-001` in chat only; do not edit the plan before approval

The expected starting observation is that only Command Line Tools are active and full Xcode is not yet available. Treat that as evidence, not as permission to install anything.

### STOP / REVIEW — Mechanism and tooling gate

Inspect the authoritative sources, toolchain command output, proposed mechanism, and unresolved uncertainties. Decide:

- whether the mechanism can actually receive selected text from Apple Notes
- whether it can return or insert text
- whether it can be keyboard-driven
- whether a chooser requires app activation or awkward focus changes
- which OS versions are assumed
- whether full Xcode is now justified by the selected experiment

Teach back: Why was Xcode deferred until this architecture/tooling gate instead of treated as generic Codex setup?

Codex drafts the checkpoint reflection but must not install Xcode, edit `PLAN-001`, create a project, or update progress before approval.

## Task B — Establish the approved Xcode environment

Only after the mechanism/tooling checkpoint is approved:

1. Have the user install full Xcode through Apple's supported distribution path if it is absent.
2. Select the full Xcode developer directory.
3. Complete any user-controlled license or first-launch steps.
4. Verify `xcodebuild -version`, the selected developer path, Swift availability, and required SDKs.
5. Record only non-sensitive version/path evidence.
6. Update `PLAN-001` with the approved mechanism and verified prerequisites.

Installing Xcode is a large external action. Codex may guide and verify it, but must not bypass user approval or security controls.

### STOP / REVIEW — Implementation readiness

Inspect the Xcode version, selected developer directory, SDK/tool availability, and updated plan. Decide whether the environment now satisfies the selected mechanism's prerequisites without adding unrelated tools.

Teach back: What evidence proves the environment is ready, and which remaining uncertainty can only the actual Notes experiment resolve?

## Task C — Implement the smallest experiment

Only after readiness approval:

- implement the minimum experiment
- hard-code only the three exercises
- avoid persistence
- avoid aliases and fuzzy matching
- avoid blocks, history, and load recommendations
- avoid production architecture and polish
- keep the experiment easy to discard

## Verification

Manually test in Apple Notes and preserve reproducible evidence:

- exact invocation steps
- number of gestures or keystrokes
- whether Notes retains focus naturally
- whether selected text is received correctly
- whether replacement/insertion works
- whether the chooser feels intrusive
- whether a keyboard shortcut materially improves the interaction
- logs or screenshots where they help without exposing private note content

### STOP / REVIEW — Architecture gate

Inspect the actual Notes workflow and its artifacts. Test it repeatedly rather than judging a single successful attempt, then decide:

1. Would I actually use this interaction repeatedly while writing programs?
2. Is it fast and reliable enough?
3. What felt awkward?
4. Does the architecture need modification or rejection?

Teach back: Why is working code insufficient evidence if the interaction still adds friction?

After the user approves the reflection and architecture gate, append learning evidence, update justified skill confidence, update progress, and advance to Exercise 03. Exercise 03—not this exercise—turns the observed result into the architecture decision record.

## Optional map check-in

After this experiment is recorded, offer a brief, non-blocking map check-in: What did the real Notes workflow change in the learner's view of evidence, planning, or agentic manual testing? What would they now do differently before committing to an integration? Preserve a summary in `LEARNING_LOG.md` only if the user asks or approves.
