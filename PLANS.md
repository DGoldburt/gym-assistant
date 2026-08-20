# Durable Plans

This file describes how to store approved plans that must survive beyond one Codex task or chat.

# Codex Execution Plans (ExecPlans):

This document describes the requirements for an execution plan ("ExecPlan"), a design document that a coding agent can follow to deliver a working feature or system change. Treat the reader as a complete beginner to this repository: they have only the current working tree and the single ExecPlan file you provide. There is no memory of prior plans and no external context.

`PLANS.md` is a project convention, not a special Codex filename. Codex reads it when `AGENTS.md`, `PROGRESS.md`, or the current task points to it. Interactive Plan mode is used to investigate and make decisions without changing tracked files; an approved result may then be recorded here for future sessions.

## When a durable plan is appropriate

Use this file when work:

- spans multiple checkpoints or sessions
- contains architecture or migration decisions
- has important exclusions or approval gates
- needs evidence-based acceptance criteria

Keep a small, obvious task in its task prompt instead of adding ceremony here.

For a planning A/B experiment, use the same convention and requested sections in both candidate drafts. Keep both drafts read-only and out of this file until the user chooses or synthesizes an approved plan; only that approved result is recorded as an active plan.

## How to use ExecPlans and PLANS.md

When authoring an executable specification (ExecPlan), follow PLANS.md _to the letter_. If it is not in your context, refresh your memory by reading the entire PLANS.md file. Be thorough in reading (and re-reading) source material to produce an accurate specification. When creating a spec, start from the skeleton and flesh it out as you do your research.

When implementing an executable specification (ExecPlan), proceed autonomously within the currently authorized scope instead of prompting the user for routine "next steps." Explicit approval gates and the tutorial's `STOP / REVIEW` checkpoints take precedence: never cross one, start the next tutorial task, or commit merely because the ExecPlan has another milestone. Keep all sections up to date at every stopping point, resolve low-risk ambiguities that do not change scope, and commit only when the current repository or tutorial instructions authorize it.

When discussing an executable specification (ExecPlan), record decisions in a log in the spec for posterity; it should be unambiguously clear why any change to the specification was made. ExecPlans are living documents, and it should always be possible to restart from _only_ the ExecPlan and no other work.

When researching a design with challenging requirements or significant unknowns, use milestones to implement proof of concepts, "toy implementations", etc., that allow validating whether the user's proposal is feasible. Read the source code of libraries by finding or acquiring them, research deeply, and include prototypes to guide a fuller implementation.

## Requirements

NON-NEGOTIABLE REQUIREMENTS:

* Every ExecPlan must be fully self-contained. Self-contained means that in its current form it contains all knowledge and instructions needed for a novice to succeed.
* Every ExecPlan is a living document. Contributors are required to revise it as progress is made, as discoveries occur, and as design decisions are finalized. Each revision must remain fully self-contained.
* Every ExecPlan must enable a complete novice to implement the feature end-to-end without prior knowledge of this repo.
* Every ExecPlan must produce a demonstrably working behavior, not merely code changes to "meet a definition".
* Every ExecPlan must define every term of art in plain language or do not use it.

Purpose and intent come first. Begin by explaining, in a few sentences, why the work matters from a user's perspective: what someone can do after this change that they could not do before, and how to see it working. Then guide the reader through the exact steps to achieve that outcome, including what to edit, what to run, and what they should observe.

The agent executing your plan can list files, read files, search, run the project, and run tests. It does not know any prior context and cannot infer what you meant from earlier milestones. Repeat any assumption you rely on. Do not point to external blogs or docs; if knowledge is required, embed it in the plan itself in your own words. If an ExecPlan builds upon a prior ExecPlan and that file is checked in, incorporate it by reference. If it is not, you must include all relevant context from that plan.

## Formatting

Format and envelope are simple and strict. When in a Codex chat context, each ExecPlan must be one single fenced code block labeled as `md` that begins and ends with triple backticks. Do not nest additional triple-backtick code fences inside; when you need to show commands, transcripts, diffs, or code, present them as indented blocks within that single fence. Use indentation for clarity rather than code fences inside an ExecPlan to avoid prematurely closing the ExecPlan's code fence. Use two newlines after every heading, use # and ## and so on, and correct syntax for ordered and unordered lists.

When writing an ExecPlan to a Markdown (.md) file where the content of the file *is only* the single ExecPlan, you should omit the triple backticks.

Write in plain prose. Prefer sentences over lists. Avoid checklists, tables, and long enumerations unless brevity would obscure meaning. Checklists are permitted only in the `Progress` section, where they are mandatory. Narrative sections must remain prose-first.

## Guidelines

Self-containment and plain language are paramount. If you introduce a phrase that is not ordinary English ("daemon", "middleware", "RPC gateway", "filter graph"), define it immediately and remind the reader how it manifests in this repository (for example, by naming the files or commands where it appears). Do not say "as defined previously" or "according to the architecture doc." Include the needed explanation here, even if you repeat yourself.

Avoid common failure modes. Do not rely on undefined jargon. Do not describe "the letter of a feature" so narrowly that the resulting code compiles but does nothing meaningful. Do not outsource key decisions to the reader. When ambiguity exists, resolve it in the plan itself and explain why you chose that path. Err on the side of over-explaining user-visible effects and under-specifying incidental implementation details.

Anchor the plan with observable outcomes. State what the user can do after implementation, the commands to run, and the outputs they should see. Acceptance should be phrased as behavior a human can verify ("after starting the server, navigating to [http://localhost:8080/health](http://localhost:8080/health) returns HTTP 200 with body OK") rather than internal attributes ("added a HealthCheck struct"). If a change is internal, explain how its impact can still be demonstrated (for example, by running tests that fail before and pass after, and by showing a scenario that uses the new behavior).

Specify repository context explicitly. Name files with full repository-relative paths, name functions and modules precisely, and describe where new files should be created. If touching multiple areas, include a short orientation paragraph that explains how those parts fit together so a novice can navigate confidently. When running commands, show the working directory and exact command line. When outcomes depend on environment, state the assumptions and provide alternatives when reasonable.

Be idempotent and safe. Write the steps so they can be run multiple times without causing damage or drift. If a step can fail halfway, include how to retry or adapt. If a migration or destructive operation is necessary, spell out backups or safe fallbacks. Prefer additive, testable changes that can be validated as you go.

Validation is not optional. Include instructions to run tests, to start the system if applicable, and to observe it doing something useful. Describe comprehensive testing for any new features or capabilities. Include expected outputs and error messages so a novice can tell success from failure. Where possible, show how to prove that the change is effective beyond compilation (for example, through a small end-to-end scenario, a CLI invocation, or an HTTP request/response transcript). State the exact test commands appropriate to the project’s toolchain and how to interpret their results.

Capture evidence. When your steps produce terminal output, short diffs, or logs, include them inside the single fenced block as indented examples. Keep them concise and focused on what proves success. If you need to include a patch, prefer file-scoped diffs or small excerpts that a reader can recreate by following your instructions rather than pasting large blobs.

## Milestones

Milestones are narrative, not bureaucracy. If you break the work into milestones, introduce each with a brief paragraph that describes the scope, what will exist at the end of the milestone that did not exist before, the commands to run, and the acceptance you expect to observe. Keep it readable as a story: goal, work, result, proof. Progress and milestones are distinct: milestones tell the story, progress tracks granular work. Both must exist. Never abbreviate a milestone merely for the sake of brevity, do not leave out details that could be crucial to a future implementation.

Each milestone must be independently verifiable and incrementally implement the overall goal of the execution plan.

## Living plans and design decisions

* ExecPlans are living documents. As you make key design decisions, update the plan to record both the decision and the thinking behind it. Record all decisions in the `Decision Log` section.
* ExecPlans must contain and maintain a `Progress` section, a `Surprises & Discoveries` section, a `Decision Log`, and an `Outcomes & Retrospective` section. These are not optional.
* When you discover optimizer behavior, performance tradeoffs, unexpected bugs, or inverse/unapply semantics that shaped your approach, capture those observations in the `Surprises & Discoveries` section with short evidence snippets (test output is ideal).
* If you change course mid-implementation, document why in the `Decision Log` and reflect the implications in `Progress`. Plans are guides for the next contributor as much as checklists for you.
* At completion of a major task or the full plan, write an `Outcomes & Retrospective` entry summarizing what was achieved, what remains, and lessons learned.

# Prototyping milestones and parallel implementations

It is acceptable—-and often encouraged—-to include explicit prototyping milestones when they de-risk a larger change. Examples: adding a low-level operator to a dependency to validate feasibility, or exploring two composition orders while measuring optimizer effects. Keep prototypes additive and testable. Clearly label the scope as “prototyping”; describe how to run and observe results; and state the criteria for promoting or discarding the prototype.

Prefer additive code changes followed by subtractions that keep tests passing. Parallel implementations (e.g., keeping an adapter alongside an older path during migration) are fine when they reduce risk or enable tests to continue passing during a large migration. Describe how to validate both paths and how to retire one safely with tests. When working with multiple new libraries or feature areas, consider creating spikes that evaluate the feasibility of these features _independently_ of one another, proving that the external library performs as expected and implements the features we need in isolation.

## Skeleton of a Good ExecPlan

    # <Short, action-oriented description>

    This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

    If PLANS.md file is checked into the repo, reference the path to that file here from the repository root and note that this document must be maintained in accordance with PLANS.md.

    ## Purpose / Big Picture

    Explain in a few sentences what someone gains after this change and how they can see it working. State the user-visible behavior you will enable.

    ## Plan Status

    Use one of:

    - Proposed
    - Approved
    - In progress
    - Complete
    - Rolled Back
    - Superseded

    Do not mark a plan Approved until the user explicitly approves it.

    ## Progress

    Use a list with checkboxes to summarize granular steps. Every stopping point must be documented here, even if it requires splitting a partially completed task into two (“done” vs. “remaining”). This section must always reflect the actual current state of the work.

    - [x] (2025-10-01 13:00Z) Example completed step.
    - [ ] Example incomplete step.
    - [ ] Example partially completed step (completed: X; remaining: Y).

    Use timestamps to measure rates of progress.

    ## Surprises & Discoveries

    Document unexpected behaviors, bugs, optimizations, or insights discovered during implementation. Provide concise evidence.

    - Observation: …
      Evidence: …

    ## Decision Log

    Record every decision made while working on the plan in the format:

    - Decision: …
      Rationale: …
      Date/Author: …

    ## Outcomes & Retrospective

    Summarize outcomes, gaps, and lessons learned at major milestones or at completion. Compare the result against the original purpose.

    ## Context and Orientation

    Describe the current state relevant to this task as if the reader knows nothing. Name the key files and modules by full path. Define any non-obvious term you will use. Do not refer to prior plans.

    ## Plan of Work

    Describe, in prose, the sequence of edits and additions. For each edit, name the file and location (function, module) and what to insert or change. Keep it concrete and minimal.

    ## Concrete Steps

    State the exact commands to run and where to run them (working directory). When a command generates output, show a short expected transcript so the reader can compare. This section must be updated as work proceeds.

    ## Validation and Acceptance

    Describe how to start or exercise the system and what to observe. Phrase acceptance as behavior, with specific inputs and outputs. If tests are involved, say "run <project’s test command> and expect <N> passed; the new test <name> fails before the change and passes after>".

    ## Idempotence and Recovery

    If steps can be repeated safely, say so. If a step is risky, provide a safe retry or rollback path. Keep the environment clean after completion.

    ## Artifacts and Notes

    Include the most important transcripts, diffs, or snippets as indented examples. Keep them concise and focused on what proves success.

    ## Interfaces and Dependencies

    Be prescriptive. Name the libraries, modules, and services to use and why. Specify the types, traits/interfaces, and function signatures that must exist at the end of the milestone. Prefer stable names and paths such as `crate::module::function` or `package.submodule.Interface`. E.g.:

    In crates/foo/planner.rs, define:

        pub trait Planner {
            fn plan(&self, observed: &Observed) -> Vec<Action>;
        }

If you follow the guidance above, a single, stateless agent -- or a human novice -- can read your ExecPlan from top to bottom and produce a working, observable result. That is the bar: SELF-CONTAINED, SELF-SUFFICIENT, NOVICE-GUIDING, OUTCOME-FOCUSED.

When you revise a plan, you must ensure your changes are comprehensively reflected across all sections, including the living document sections, and you must write a note at the bottom of the plan describing the change and the reason why. ExecPlans must describe not just the what but the why for almost everything.

## Active plans

### PLAN-001 — Prove the Apple Notes interaction is fast and reliable

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds. Maintain this plan in accordance with the convention in the preceding sections of `PLANS.md`.

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
