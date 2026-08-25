# Deliver the Notes new-exercise workflow

This ExecPlan is a living document maintained according to `PLANS.md` at the repository root.

## Purpose / Big Picture

After this change, a coach can select exercise text in Apple Notes, invoke the Gym Assistant Service, immediately reuse an exact known name, review and link an ambiguous name, or create a genuinely new exercise through one prefilled `Name` field. The workflow returns the chosen preferred display text to the same Notes selection and stores only explicitly accepted identity relationships.

## Plan Status

Complete. Exercise 08 Task B passed after automated workflow verification, four manual Notes cases, persistent installation, and learner confirmation of the physical shortcut.

## Progress

- [x] (2026-08-24) Approved the two-action, zero-required-typing creation budget and exact-match bypass.
- [x] (2026-08-24) Inspected the preserved AppKit spike, core library, resolver, confirmation boundary, and package structure.
- [x] (2026-08-24) Added a core workflow that classifies exact, reviewable, and new inputs against persisted exercises.
- [x] (2026-08-24) Added focused regression tests for the four required cases.
- [x] (2026-08-24) Added a production-facing AppKit Service adapter and local bundle build script without modifying the spike.
- [x] (2026-08-24) Ran 22 package tests and the 37-case resolver fixture exam successfully.
- [x] (2026-08-24) Ran the four cases in the disposable Notes scratch note and recorded actions, latency, saved records, returned text, focus, screenshots, and friction.
- [x] (2026-08-24) Installed the provider persistently in the user Applications folder; the learner confirmed it appeared in Notes Services and that `⌃⌥⌘G` invoked it.
- [x] (2026-08-24) Passed the Exercise 08 Task B review after learner confirmation of the persistent Service and physical shortcut.

## Surprises & Discoveries

- Observation: The existing AppKit Service is a preserved spike compiled directly with `swiftc` and contains three hard-coded choices.
  Evidence: `spikes/notes-interaction/appkit-service/Sources/main.swift` has no dependency on `GymAssistantCore` and `build.sh` compiles only that file.
- Observation: Explicitly activating the first running Notes application can restore the wrong Notes window when several Notes windows are open.
  Evidence: The exact-match manual trial replaced the correct disposable selection, but the subsequent activation surfaced another Notes window. The adapter now relies on the native Services return instead.
- Observation: `swift build --show-bin-path` reports a directory but does not guarantee the product in that directory was rebuilt first.
  Evidence: A UI screenshot still showed the previous button label after source and tests had rebuilt; the bundle script now runs an explicit product build before copying the executable.
- Observation: The desktop UI automation can send app-local key events but cannot invoke a global macOS Service shortcut.
  Evidence: macOS Keyboard settings displayed `⌃⌥⌘G` for Gym Assistant and menu invocation opened the correct candidate panel, while synthetic shortcut attempts did not dispatch the Service.
- Observation: LaunchServices registration from `/private/tmp` is session evidence, not a reboot-safe installation.
  Evidence: After restart, macOS no longer listed Gym Assistant in Notes Services or Keyboard Shortcuts. Installing the same signed bundle under `/Users/dan/Applications` restored discovery, and the learner confirmed the menu item and shortcut worked.

## Decision Log

- Decision: Keep the spike immutable and create a separate executable Notes adapter that depends on `GymAssistantCore`.
  Rationale: Historical evidence should remain reproducible, while the production adapter must reuse—not duplicate—identity and persistence logic.
  Date/Author: 2026-08-24 / Codex
- Decision: Persist the exercise library under the user's Application Support directory and keep UI code free of SQL and matching rules.
  Rationale: Service invocations must share durable state, and architecture requires the Notes adapter to remain replaceable.
  Date/Author: 2026-08-24 / Codex
- Decision: Save only the edited `Name` during creation; do not retain discarded selected wording as an alias.
  Rationale: The learner explicitly rejected interpreting corrected text as another valid name.
  Date/Author: 2026-08-24 / Learner
- Decision: Do not choose or explicitly activate a Notes process/window after the Service callback.
  Rationale: The Service invocation already has an originating application context, while `runningApplications.first` cannot identify the originating Notes window and damaged focus integrity during manual testing.
  Date/Author: 2026-08-24 / Codex
- Decision: Treat a persistent Applications-folder installation plus a post-install Notes trial as required keyboard evidence.
  Rationale: Temporary registration did not survive reboot, while product testing requires a discoverable Service and working shortcut across normal application restarts.
  Date/Author: 2026-08-24 / Learner and Codex

## Outcomes & Retrospective

The core workflow, real AppKit Service, tests, and four manual cases are complete through the Exercise 08 Task B checkpoint. The new-exercise path met its two-action, zero-typing budget and returned 22.7 ms after save confirmation. Manual testing found and corrected wrong-window activation and a temporary-only installation. The persistently installed Service now appears in Notes, and the learner confirmed `⌃⌥⌘G` works. Identical-text success feedback remains a product limitation for review.

## Context and Orientation

`Sources/GymAssistantCore/ExerciseLibrary.swift` owns SQLite exercise identity and confirmed names. `DeterministicExerciseNameResolver.swift`, `ExerciseCandidateGenerator.swift`, and `ExerciseSuggestionConfirmation.swift` own exact matching, review-only ranking, and explicit alias confirmation. `spikes/notes-interaction/appkit-service/` proves the macOS Service and pasteboard interaction but must remain historical evidence. The new adapter belongs in a separate Swift Package executable target and may depend on AppKit plus `GymAssistantCore`.

An exact match means approved normalization finds an existing `ExerciseName`. A review candidate is lexically plausible but cannot establish identity. A new exercise is created only after the user chooses Create and confirms the prefilled or edited `Name`.

## Plan of Work

First add a library query that returns persisted preferred names and a core workflow type that returns explicit outcomes for exact matches and ranked candidates. Keep creation and alias confirmation as explicit commands rather than side effects of lookup. Test exact bypass, ambiguous suggestion, new creation, and mistaken-new linking with temporary SQLite databases.

Then add `GymAssistantNotesService` as an executable target. Its AppKit panel will show ranked existing candidates and a `Create New Exercise…` row. Return on a candidate explicitly confirms the selected text as an alias; Return on Create changes the same panel to one prefilled `Name` field, and a second Return creates the exercise. Escape cancels or returns to the result list without a write. All successful paths replace only the selected pasteboard text and reactivate Notes.

Finally build and register a local ad-hoc-signed app bundle, use only the disposable scratch note, run the four required scenarios, and record a machine-readable event log plus a concise evidence document. Do not record client Notes content.

## Concrete Steps

From `/Users/dan/Documents/D/dev/gym_assistant`, run `swift test` and expect every package test to pass. Run `swift run ResolverFixtureRunner Tests/Fixtures/resolver-cases.json` and expect 37 passes with zero false merges and zero protected-candidate leaks. Build the Service through its repository script, register the resulting bundle, and invoke it through the existing Notes Services shortcut.

## Validation and Acceptance

The obvious-existing case must perform zero writes and return the stored preferred name. The ambiguous case must show a review candidate and persist an alias only after explicit linking. The truly-new case must require at most two deliberate actions, zero typing when unchanged, and no more than 500 ms from save confirmation to Notes return. The mistaken-new case must allow linking to an existing exercise instead, create no new exercise, persist the selected wording as a confirmed alias, return preferred text, and restore Notes focus. All four cases must preserve the selected range and unrelated note content.

## Idempotence and Recovery

Package tests use unique temporary databases. The local Service build is replaceable and ad-hoc signed. Manual evidence must use a dedicated Exercise 08 database or explicitly recorded scratch records so reruns do not affect unrelated user data. If bundle registration or the shortcut fails, preserve the failure and repair setup before counting a trial.

## Artifacts and Notes

The manual evidence will live under `evidence/exercise-08/` or another repository-local Exercise 08 evidence directory and must contain no client content.

## Interfaces and Dependencies

The core workflow will expose typed outcomes rather than dictionaries. The Notes executable will depend on `GymAssistantCore` and AppKit. SQLite remains the only persistence dependency. The adapter may call library queries and explicit create/confirm operations but must not own normalization, scoring, protected-modifier, ownership, or SQL rules.

Revision note (2026-08-24): Created the in-progress plan after inspecting the preserved spike and approved Task A contract so implementation can survive a task restart. Updated it after the first manual trial exposed wrong-window activation from an explicit Notes reactivation call, after completing code and the four menu-invoked Notes cases, and after assigning the keyboard shortcut while preserving the manual global-shortcut verification boundary.
