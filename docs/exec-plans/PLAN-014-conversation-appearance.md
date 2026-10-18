# Clarify conversation and scratchpad presentation

This living ExecPlan follows `PLANS.md`. Maintain Progress, Surprises & Discoveries, Decision Log, and Outcomes & Retrospective as implementation proceeds.

## Purpose / Big Picture

Make the programming window easier to read: warm-colored coach prompts occupy the right side, assistant replies start on the left, and a down-arrow appears when newer conversation content is below the viewport. Show the note title above a clearly bordered scratchpad, rename comparison to “Compare with note”, and strengthen the palette in light and dark appearances. Preserve native selection, copying, exercise annotations, rich-text archives, and offline operation.

## Plan Status

Complete: the coach's slightly brighter Send button and autocomplete appearance extension are implemented and verified on the existing isolated `codex/improve-aesthetics` worktree, with a separate local commit for the extension. Earlier scratchpad milestones remain complete.

## Progress

- [x] (2026-10-18) Inspect clean feature branch, conversation renderer, persistence tests, and synthetic development app.
- [x] (2026-10-18) Implement message presentation, conditional down-arrow, note heading, and surfaces.
- [x] (2026-10-18) Add behavior tests; all five `scripts/verify` stages passed, including 268 tests; inspect synthetic light/dark renderings.
- [x] (2026-10-18) Export review PNGs to the main checkout's `docs/design` folder; prepare the verified feature milestone for a local commit.
- [x] (2026-10-18) Coach accepted the visual direction. Add a muted `actionFill` and shared `filledPrimary` helper for Send, plus `docs/design/DESIGN_GUIDE.md` covering future implementation and integration sequencing.
- [x] (2026-10-18) Raise only the action-fill warmth to `#E49A64` light / `#C38659` dark, preserving prompt fills and borders. Expose a small shared macOS appearance API and apply it only to the autocomplete chooser's presentation.
- [x] (2026-10-18) Add isolated autocomplete rendering that bypasses the normal Service provider and uses a temporary synthetic library. Synthetic keyboard selection, alias expansion/collapse, empty/raw-query states, and unchanged-library checks pass.
- [x] (2026-10-18) Complete light/dark native view review, five-stage verification (268 tests), synthetic autocomplete interaction checks, and export both autocomplete and scratchpad PNGs. Prepare the extension as its own local commit.

## Surprises & Discoveries

`NoteSnapshot` has no separate title field. The canonical note text already includes the Notes title as its first line. Use its first nonempty line for display, with “Untitled note” for an empty note; this needs no persistence or domain-model change.

The development target used `@main` in a file named `main.swift`; adding a second Swift source made Swift reject that combination. Rename the entry source to `DevelopmentMain.swift` without changing startup behavior. Native view bitmap rendering also needs an explicit root background and current drawing appearance to capture system labels and colors faithfully. These changes produced opaque, readable light/dark PNGs without OS screen capture.

## Decision Log

Decision: retain `ExerciseConversationView`, an AppKit text view, and style message ranges with paragraph indents and painted backgrounds. Rationale: preserve continuous text selection, copying, and existing keyboard traversal of exercise mentions. Date/author: 2026-10-18, Codex.

Decision: use warm orange for prompts and scratchpad borders with cool slate conversation surfaces; resolve colors for light and dark appearances. Rationale: bring more of the icon palette into the workspace while retaining readable native text. Date/author: 2026-10-18, Codex.

Decision: following the coach's review, reserve vivid orange for small accents and use muted warm fills (`#CFAF96` light / `#936E57` dark) for filled primary actions. Record the accepted rules in a guide linked from the scratchpad specification and shared appearance source. Recommend integrating after the contextual branch's active overlapping fixes reach a stable checkpoint, before its combined native acceptance. Date/author: 2026-10-18, Codex.

Decision: the next coach review requests more warmth than muted tan while keeping below the original vivid orange. Update only `actionFill` to `#E49A64` / `#C38659`; prompt colors remain unchanged. Dark-label contrast is approximately 9.1:1 light and 6.9:1 dark. Extend autocomplete on this same appearance worktree as a separate commit because it is part of the same product-styling scope. Do not modify the active contextual worktree. Date/author: 2026-10-18, Codex.

## Outcomes & Retrospective

Coach messages now occupy the right side in warm rounded bubbles; assistant messages begin on the left. Conversation updates follow the bottom only when the reader is already there. The conditional arrow jumps to the latest content without changing text selection. The scratchpad shows its note title and session label, a stronger warm border, and the requested “Compare with note” wording in both the control and menu. The composer and conversation surfaces adapt to light/dark appearance. The accepted baseline is documented in `docs/design/DESIGN_GUIDE.md`, linked from the scratchpad specification and the shared appearance source. Send uses a warm middle-ground orange fill with explicit dark label ink; prompt fills and borders are unchanged. Autocomplete reuses the headline, paper surface, border, and native secondary controls, with a full-width insertion hint. The Service module consumes shared macOS appearance helpers without adding a UI dependency to core logic. Existing formatting, annotations, persistence, copy, and comparison checks pass. No live model or Notes UI acceptance was performed, and the installed app was not replaced.

## Context and Orientation

`Sources/GymAssistantMacOS/SessionScratchpadWindowController.swift` creates the two-column window and rebuilds the conversation after messages change. `ExerciseConversationView.swift` adds display-only exercise underlines without modifying stored messages. `GymAssistantAppearance.swift` holds native styles. `Sources/ScratchpadDevelopment/DevelopmentMain.swift` launches a separate synthetic app; `AppearancePreview.swift` provides offline export. Existing native-window tests protect editing, copy, comparison, and storage semantics.

## Plan of Work

Add message ranges to the text view so prompt paragraphs use a right-side inset and rounded warm background, while assistant text stays on the left. Add an AppKit scroll-view subclass that observes viewport/document geometry and offers an accessible jump-to-latest button only when content is below. Preserve the reader's position when responses refresh away from the bottom. Add adaptive surface colors and rounded borders to the scratchpad and composer. Reorganize the header to show the note title, session label, and existing actions without collisions. Update comparison wording in UI and its existing tests because the user explicitly requested the rename.

Add synthetic appearance export support to the development executable, using native view bitmap rendering rather than OS screen capture. Use a fresh temporary store and seeded messages in that mode; export light/dark PNGs without reading real Notes or calling an assistant.

For the autocomplete extension, keep `ExerciseAutocompletePanel` and `RankedCandidateChooser` in `Sources/GymAssistantNotesService/main.swift`; no ranking or insertion code changes are needed. Make only the shared styles needed by the Service executable public in `GymAssistantAppearance`, and provide `searchResultsSurface()`/`backgroundView(frame:)` factories instead of duplicating colors. Opt the autocomplete chooser into the paper/border treatment while leaving other chooser consumers unchanged. Use a 640 × 414-point panel with a headline, supporting copy, native search, results, a full-width status line, and existing maintenance actions. A separate preview delegate selected before constructing `AppDelegate` must avoid the real library and Service registration. Exercise the actual chooser against temporary seeded data and export light/dark content-view PNGs.

## Concrete Steps

Work in `/Users/dan/.codex/worktrees/improve-aesthetics/gym_assistant`. Run `swift test --filter 'ExerciseConversationViewTests|ScratchpadWindowTests'` during development, then `bash scripts/verify`. Build the development executable with `swift build --product ScratchpadDevelopment`; launch the separate development bundle with its appearance-export argument and the destination `/Users/dan/Documents/D/dev/gym_assistant/docs/design`. Inspect the exported PNGs for wrapping, readable colors, header placement, and arrow visibility.

Build the Service with `swift build --product GymAssistantNotesService` and run `.build/debug/GymAssistantNotesService --autocomplete-appearance-preview /Users/dan/Documents/D/dev/gym_assistant/docs/design`. Expect two autocomplete PNG paths and `PASS: synthetic autocomplete search, keyboard selection, alias expansion/collapse, raw-query and empty states; library unchanged`. The export path must be selected before the regular delegate initializes its provider. Run the normal five-stage verifier after code changes, and regenerate the scratchpad PNGs too so the brighter action treatment can be reviewed.

## Validation and Acceptance

Tests must show coach text uses the right-side inset and assistant text uses the left; decoration/copy text and saved messages remain intact. A long conversation must show the down-arrow when scrolled up, hide it at the end, and preserve a scrolled-up reader position on updates. Header tests must show the note's title independently of the session heading. Existing rich-text round-trip, comparison, and request tests must pass. Light/dark PNGs must visibly show the new surfaces and alternating message positions.

## Idempotence and Recovery

Use only a temporary synthetic store for export. Export files have explicit filenames so reruns update only these requested artifacts. Keep installed app and private stores unchanged. All implementation changes remain on the existing isolated feature branch. Do not push or merge.

## Artifacts and Notes

`bash scripts/verify` passed all five stages: 268 tests in 41 suites, 37 resolver fixtures, 11 identity-review fixtures, cleanup regression, and non-installing bundle smoke check. `git diff --check` passed. Three new behavioral tests cover column reflow, conditional arrow/jump selection preservation, and retaining an earlier reading position through a completed offline reply. Existing controller tests also assert the note heading separately from the session heading.

Run `.build/debug/ScratchpadDevelopment --appearance-preview /Users/dan/Documents/D/dev/gym_assistant/docs/design` from the worktree to export the actual native content view using synthetic messages. Inspected final files: `/Users/dan/Documents/D/dev/gym_assistant/docs/design/scratchpad-conversation-light.png` and `/Users/dan/Documents/D/dev/gym_assistant/docs/design/scratchpad-conversation-dark.png`. These are view renders rather than OS desktop captures and intentionally exclude the title bar. The images reside in the main checkout at the user's requested destination; implementation remains on the isolated feature branch.

The autocomplete extension additionally exports `/Users/dan/Documents/D/dev/gym_assistant/docs/design/autocomplete-light.png` and `/Users/dan/Documents/D/dev/gym_assistant/docs/design/autocomplete-dark.png`. Its synthetic interaction check passed and verified unchanged library names after search/navigation. No ranking, identity, insertion, cancellation, or source-association code was changed. Full verification passed with 268 tests in 41 suites, the 37/11 fixture contracts, cleanup regression, and non-installing bundle smoke check. The guide and `docs/ARCHITECTURE.md` document the shared appearance boundary and isolated rendering mode. Live Service focus/caret behavior and Notes insertion still require native acceptance of the combined product build.

## Interfaces and Dependencies

Use existing AppKit and workspace types only. Add a message-presentation range (role plus character range) to `ExerciseConversationView.display`, with an empty default for existing callers. The new conversation scroll view exposes geometry refresh and jump-to-latest methods usable by the controller and tests. Keep colors and borders in the macOS adapter; no domain schema or service changes.

Revision 2026-10-18: created for the requested visual and scrolling follow-up.

Revision 2026-10-18: recorded completed implementation, Swift entry-file rename, native bitmap rendering details, passing verification, and exported review artifacts.

Revision 2026-10-18: capture accepted appearance, quieter Send feedback, durable design guide, and an evidence-based integration recommendation. The contextual worktree was inspected read-only and left unchanged.

Revision 2026-10-18: extend the authorized appearance scope to autocomplete, document the selective shared style API and synthetic preview, and revise action emphasis without changing coach-message styling.

Follow-up verification: all five repository verification stages passed after the guide and muted-fill update. After the final label-contrast correction, all ten focused conversation/controller tests passed and final light/dark PNGs were regenerated; native view review confirms the muted fill and dark label. Calculated normal label contrast against the specified fills is approximately 10.2:1 light and 4.6:1 dark.
