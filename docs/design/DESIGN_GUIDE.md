# Gym Assistant design guide

Status: implementation baseline, based on the coach's accepted scratchpad appearance on 2026-10-18, with a warm Send button between the previous muted tan and vivid orange versions. The autocomplete screen now uses this baseline too. Apply this guide to new and changed screens. Existing library, review, and history screens may need gradual alignment; this document does not authorize redesigning them all at once.

## Intent

Gym Assistant should feel like a calm native writing companion. Apple Notes remains the primary writing workspace. Give the workout space and visual priority, make conversation easy to follow, and keep actions compact. Use warm copper details and paper-like editing surfaces alongside cool slate conversation surfaces. Color should identify a role or an action without competing with the content.

The native scratchpad is the visual reference. Earlier HTML mockups under `docs/design/artifacts/` are historical exploration, not the styling authority. Product behavior remains governed by `docs/PRODUCT.md` and the approved feature specification; this guide governs presentation.

## Shared implementation

Use `Sources/GymAssistantMacOS/GymAssistantAppearance.swift` for semantic colors, typography, and button treatments. Use `WorkspaceSurfaceScrollView` for the editor, comparison, and composer surfaces. Reuse `ExerciseConversationView` for message presentation and `ConversationScrollView` for the conditional down arrow. Keep these concerns in the macOS UI adapter; visual attributes must never become saved workout content or domain-model fields.

Use the existing style helpers before adding local overrides. If a new reusable style is necessary, give it a role-based name in the shared appearance file and update this guide in the same change. Avoid duplicating literal colors in window controllers. A one-off feature should not introduce a second palette or button system.

## Color roles

Hex values below are sRGB. The shared color provider selects a light or dark value from the current macOS appearance. Ordinary content retains system text colors. Filled action labels use the explicit `actionInk` token because the two muted fills are designed for dark text.

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| `accent` | `#FF571F` | `#FF571F` | Small brand accents and native primary/quiet control tint; avoid large filled areas. |
| `inkAccent` | `#9D4828` | `#F3B08C` | Note title and jump-arrow glyph. |
| `actionFill` | `#E49A64` | `#C38659` | Warm filled primary action, currently Send; brighter than muted tan, below vivid brand orange. |
| `actionInk` | `#000000` | `#000000` | Filled primary-action label only; contrast against `actionFill` is approximately 9.1:1 light and 6.9:1 dark. |
| `promptFill` | `#FBE5D8` | `#58392E` | Coach prompt bubbles. |
| `promptBorder` | `#E9B79B` | `#8B5942` | Quiet edge around prompt bubbles. |
| `canvas` | `#EDF0F5` | `#202733` | Conversation background. |
| `paper` | `#FFFCF7` | `#292B30` | Scratchpad, comparison, and composer surface. |
| `paperBorder` | `#BD7955` | `#C58A68` | Scratchpad/composer outline and jump-arrow outline. |
| `.windowBackgroundColor` | System | System | Window background. |
| `.labelColor` | System | System | Main text and ordinary action labels. |
| `.secondaryLabelColor` | System | System | Metadata, section labels, supporting copy. |
| `.separatorColor` | System | System | Quiet conversation-container outline. |

Reserve red for destructive actions or errors and use accompanying words or symbols. Do not infer identity, source verification, selection, or a successful operation solely from color. Status text remains explicit even when accented. Disabled controls keep native disabled behavior instead of becoming a second accent treatment.

Set filled primary-action labels through the shared helper. AppKit's automatic label choice can produce low-contrast white text on a warm fill; the explicit dark attributed title avoids that result. If the action fill changes, recheck the label contrast in both appearances and retain at least 4.5:1 for normal-size text. Prompt bubble colors are independent from action fills: changing the action emphasis must not change saved-message presentation.

## Typography and hierarchy

Use the macOS system font. Use 22-point semibold for a window or note headline, 12-point semibold for compact section labels, 13-point regular for supporting text, 13-point medium/semibold for controls, 15-point regular for conversation and composer text, and 11-point medium for message metadata. Keep capitalization for short section labels only; buttons and help text use ordinary sentence case.

Rich workout text keeps its authored hierarchy and formatting. Do not flatten, recolor, or restyle stored rich text to make it match the UI. New synthetic/example workout text may use a 16-point body, 22–24-point session heading, and 18-point subsection heading. Use adaptive color mapping for the rich editor rather than adding display-only foreground colors to its archive.

The hierarchy is: note title, session/scratchpad label, content, then supporting status. The note title identifies the whole note; the session label identifies the section being edited. Truncate long note titles at the tail and expose the full title in the tooltip. Never display a note identifier as a substitute title.

## Layout and surfaces

Use an approximately 4-point spacing rhythm: 8 between related controls, 12–16 inside surfaces, 16–20 at window edges, and 24–28 between major regions. These are layout defaults, not reasons to disturb established native control dimensions. Preserve enough room for clear text and keyboard focus.

The scratchpad is the flexible main column on the left; the conversation is the supporting column on the right. At the current 1120 × 740-point content size, the scratchpad is 600 points wide and the conversation container is 468 points wide. The current 1060 × 680-point minimum window size must remain usable; verify that labels, source-association actions, comparison, and footer controls do not collide. Grow the writing area as the window grows. Do not shrink body text to fit more UI.

Use 12-point corner radii for editing/composer surfaces, a 1.5-point scratchpad/comparison border, a 1-point composer border, and a quiet 0.75-point conversation-container border. Prompt bubbles use 15-point corner radii and a 0.75-point outline. Prefer these flat fills and outlines to extra shadows, gradients, decorative panels, or saturated full-window backgrounds.

Keep the note title and session label outside the editor. Place Previous planning near the title, and keep its unavailable state visibly disabled. Copy remains a compact, labeled-through-accessibility icon action near the editor's top-right. Supporting state belongs in the footer and must not hide the note title or change editor content.

## Conversation

Coach prompts sit on the right in warm bubbles, occupying roughly the right 80% of the text width. Their text remains left aligned inside the bubble. Assistant responses begin at the left and use the cool background without a competing filled bubble. Keep role, request state, and scratchpad-revision freshness visible as small secondary metadata. A reply based on an earlier scratchpad revision retains its explicit “Scratchpad changed” indication.

Maintain continuous native text selection and copying across the transcript. Exercise annotations remain subtle underlines with text labels available to keyboard users; matching must not silently become a confirmed library relationship. Styling must not add visible punctuation, links, HTML, or color attributes to the stored message text.

The down arrow appears only when conversation content extends below the visible area. It uses a 36-point circular control, a paper fill, a copper outline/glyph, and the accessible name “Jump to latest message”. It floats near the bottom center of the transcript above the composer. Activating it reveals the latest content without changing the selection. Incoming updates follow the end only when the reader is already there; preserve their reading position otherwise. Hide the control when the transcript fits or the reader reaches the bottom.

The composer uses a paper surface with a warm outline. Keep Send and Stop at its lower right. Preserve the established Enter-to-send and Shift-Enter-for-newline behavior and the ability to retain an unsent follow-up. Layout work must not alter request, cancellation, or saving behavior.

## Controls and wording

Use native AppKit buttons, checkboxes, scroll bars, focus rings, menus, and keyboard shortcuts. `primary(_:)` provides the native primary hierarchy without forcing a filled color. Use `filledPrimary(_:)` for a main action that benefits from a warm fill; currently Send uses this treatment. Avoid multiple competing filled primary actions in one region. `secondary(_:)` is for ordinary actions; `quiet(_:)` is for low-emphasis navigation such as Previous planning. Never paint over native disabled, focused, or pressed feedback.

Use “Compare with note” in the visible control and “Compare with Note” in its menu item. Use “scratchpad” for the editable local working copy and “note” or “Notes” for the source. Avoid internal terms such as source range, observation ID, or request gate in normal writing flows. Keep the menu wording and shortcuts consistent with the visible action. Any feature requiring an explicit confirmation keeps that confirmation during visual changes.

## Autocomplete

Autocomplete stays a compact keyboard-first panel, currently 640 × 414 points. Use the shared headline and supporting text above the native search field, the paper result surface with a 1-point copper border and 12-point corners, and secondary Add Exercises/Edit Library controls below. Keep Program session as a secondary action beside the search field. Give insertion/selection hints a full-width line below results so longer raw-query hints remain readable. Preserve native focus rings and selected-row colors; a row selection is not a coach prompt and must not reuse the conversation bubble treatment.

`ExerciseAutocompletePanel` and `RankedCandidateChooser` live in `Sources/GymAssistantNotesService/main.swift`. They reuse the public `GymAssistantAppearance` helpers and `searchResultsSurface()` from the macOS adapter. The appearance option is enabled only for autocomplete; the chooser's other library/review consumers keep their existing presentation until separately requested. The change must leave ranking, result count, preferred/alias identity, initial empty selection, arrow-key navigation, Return/raw-query insertion, Escape, maintenance shortcuts, and Notes handoff intact. Do not turn this panel into a smaller version of the two-column programming window.

Related appearance changes may be implemented on `codex/improve-aesthetics` as separate commits while contextual functionality develops in its own worktree. Preserve that separation until a stable contextual checkpoint is ready to reconcile; use a new learner-application feature branch for a separately scoped redesign or for later work after this branch is integrated. Do not make product styling changes directly on the reusable starter `main` branch.

## Future implementation review

Before changing a screen, read this guide and inspect the shared styles. Apply it to the work already in scope; propose wider redesigns separately. Keep existing domain behavior and saved data intact. Include updates to this guide when a new shared visual rule is approved.

Review both light and dark appearances at the default and minimum window sizes. Check long note titles, long prompts and replies, multiline composer text, empty conversation, pending/stopped/failed replies, stale scratchpad metadata, comparison mode, and session-association controls. Check keyboard focus, selection/copying, arrow visibility after scrolling and resizing, and disabled actions. Use text labels as well as color for meaningful state. Check Increase Contrast/Reduce Transparency settings before claiming accessibility acceptance; an ordinary screenshot does not verify those settings.

Add behavioral tests for changed interaction rules, not tests that merely repeat color constants. Run the relevant existing tests and `bash scripts/verify` before declaring an implementation complete. Use the offline renderer for repeatable light/dark visual review:

    swift build --product ScratchpadDevelopment
    .build/debug/ScratchpadDevelopment --appearance-preview /private/tmp/gym-assistant-design-review

This exports `scratchpad-conversation-light.png` and `scratchpad-conversation-dark.png` from the actual native content view using fresh synthetic data. The images exclude window chrome. They verify visual layout, not live Notes behavior, model quality, or installation. Preserve historical HTML mockups unchanged. Do not use private notes or real client content in shared review images.

For autocomplete, run `swift build --product GymAssistantNotesService`, then `.build/debug/GymAssistantNotesService --autocomplete-appearance-preview /private/tmp/gym-assistant-design-review`. This starts a separate preview delegate before creating the normal Service provider, uses a temporary synthetic library, and exports `autocomplete-light.png` and `autocomplete-dark.png`. It also checks search results start unselected, keyboard selection and alias expansion/collapse, empty/raw-query hints, and read-only library behavior. It does not insert into Notes, register Services, or record field feedback.

## Integration guidance for this baseline

As observed on 2026-10-18, `codex/improve-aesthetics` builds on contextual-assistant commit `ba18bfd`; the styling depends on that work's windows and conversation types. The active contextual worktree has uncommitted changes in overlapping windows and tests. Do not copy whole window files over that work or merge the aesthetics branch directly into an older `learner/main` as an isolated cosmetic update.

Recommended sequence: let the current contextual fixes reach a committed, verified checkpoint; reconcile the styling commits into that contextual integration line by reviewing overlapping changes; run automated verification and a native acceptance pass on the combined build; then review and merge the product slice into refreshed `learner/main` under the repository Git lifecycle. The native pass must cover source association, session-region selection, comparison, copy/paste into Notes, reopen, unsent text, and chat scrolling together. Preserve the contextual fixes as the behavioral authority and this guide as the presentation authority.

This sequencing does not require waiting for every future assistant capability. The stable functional checkpoint is the useful boundary. Keep this guide and its shared implementation on the learner application line; a reusable starter snapshot is a separately approved publication. This document recommends integration; it does not authorize merging, pushing, installing, or messaging another chat.
