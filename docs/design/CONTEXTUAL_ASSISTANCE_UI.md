# Contextual assistance: interaction proposal

Status: proposed, 2026-10-10. No production UI or success criteria are approved here.
Evidence IDs refer to [the evidence package](CONTEXTUAL_ASSISTANCE_EVIDENCE.md).

2026-10-12: the user selected **session scratchpad with margin conversation**,
with manual incorporation of chat suggestions and read-only library decoration.
[Current design direction and unresolved boundaries](SESSION_SCRATCHPAD.md)
supersede the first-iteration recommendation and actionable-proposal controls below.
The earlier exploration remains for evidence and comparison, not as an active contract.

## Initial sidecar exploration (archived)

Start with a compact keyboard-invoked companion beside Notes, even at an empty
cursor. One input accepts either an exercise fragment or a programming question.
Keep deterministic autocomplete and contextual conversation distinct behind that
entry: typing a fragment need not trigger a hosted model or a long conversation.
The contextual experience must not make autocomplete slower.

For repeated follow-ups, expand the same conversation to a sidecar, leaving Notes
visible. This is not a second program editor. Preserve the draft location and
conversation when expanding, returning to Notes, or taking an explanatory detour.
The mockup compares compact and sidecar layouts; neither is usability-validated.
Its scope selector loads synthetic review scenarios; it is not a requirement to
classify every question before asking. The production input should remain free-form.

2026-10-11 review: the user found no meaningful difference between these layouts.
They should not be treated as distinct design approaches. The
[conversation sidecar](artifacts/README.md) is preserved as a historical design
artifact. The approaches below change the interaction model, not merely its width.

## Visible context and destination

Header: active note/session, with a small inspectable context summary. Separately
show each proposal's destination, operation, and before/after text.

Example: “Considering Session 14” does not mean “Replacing Session 14.” A response
can consider the session while replacing only B2. Broader history appears only if
authorized and actually available; no claim that importing history automatically
provides live session awareness.

Context preview identifies included note regions, profile entries, library records,
and any approved history. Explain missing/stale context. Don't send additional
client material merely because a question sounds broader.

## Conversation and proposals

Answers are concise, with a few candidates and reasons tied to the job. Allow a
plain follow-up such as “Not behind her—continue overhead and combine with a squat.”
Corrections update intent; they do not create aliases. Advice-only answers are valid.

Each proposal independently supports Apply, Edit, Dismiss, and a follow-up. Editing
changes a small proposed text region, not the entire note. Display the target before
application. An unknown destination requires an explicit choice, not an arbitrary
cursor fallback. Verify the target against the current note; block stale replacement
and offer refresh/review. After applying, reread Notes before the next response.

For a session-wide equipment change, show separate local edits and dependencies.
Do not apply the whole bundle when one candidate is chosen. Coordinated multi-range
transactions remain a future candidate, not the proposed first-slice baseline.

## Proposed keyboard contract

- Invocation focuses the input without selected text; the app's actual invocation
  shortcut must be chosen against existing macOS/Notes bindings.
- Return sends the question or accepts a highlighted deterministic completion;
  clearly distinguish these modes. Shift-Return adds a line in chat.
- Native Tab/Shift-Tab reaches context, proposals, Edit, Apply, Dismiss, and follow-up.
- Command-Return applies the currently reviewed proposal, never an unseen candidate
  or an entire response. Do not intercept this while editing multiline text unless
  the action is visibly indicated.
- Escape dismisses optional feedback, then the companion, restoring Notes focus.
- Proposal navigation shortcuts and return-focus behavior need a real keyboard
  trial; labels in the mockup are hypotheses, not implemented Notes shortcuts.

## Learning without an interrogation

Only when the rationale remains genuinely ambiguous, show a small optional row
beside the recent decision: “Why this one?” with two or three prepared hypotheses
and Skip. A hypothesis may be corrected or ranked; free text is optional. Don't
ask again about explicit intent such as avoiding machines. Don't ask about execution
merely because Notes does not establish performance.

Remembering is separate from applying: “For this session” versus “A coaching
preference.” Preserve confidence, exceptions, source, and date. Offer inspect/edit/
remove controls for learned preferences in a later profile surface. Research findings
can challenge a preference visibly but never rewrite it in the background.

## Keep the first experiment narrow

Test one active note, short-lived conversation, no repeated pasting, exercise or
contiguous-block proposals, editable before application, refreshed context, and
stale-target protection. Broad reasoning is possible without broad editing.

Cycle planning, durable preference learning, unsolicited context-aware suggestions,
background literature review, and coordinated multi-range edits remain future design
directions. The mock's optional rationale row illustrates that direction, not a
requirement silently added to the first slice. Client-history work remains separate.

## Evaluation scripts and evidence to collect

| Trial | Inspect | Failure condition |
| --- | --- | --- |
| E1, fill B2 from session context | Correct the movement twice; inspect B2 target; edit then apply | Loses purpose, overwrites another slot, or treats wording correction as identity |
| E3, changed recorded dose | Supply an updated note after training | Infers accepted recommendation or global load preference from overlap |
| E6, revise conditioning | Follow up, edit Notes externally, ask review again | Reasons from obsolete text or duplicates existing core work |
| E7, reduce equipment | Choose one of several local substitutions | Applies unrelated changes or claims all equipment was removed |
| Advice detour | Ask for a cue and return to B2 | Forces an edit or loses the original discussion |
| Ambiguous rationale | Skip hypotheses, or confirm one only for this session | Blocks programming or silently establishes global memory |
| Target conflict | Change the destination before applying | Silently overwrites the changed range |
| E10/E14, local exclusion | Exclude a pattern in one slot or because of yesterday's work | Converts it into a permanent exercise ban or removes a valid neighboring slot |
| E11/E12, assessment wording | Review a baseline/retest or observation prompt without reported results | Invents a measured finding or writes planned tests into observed client history |
| E13, coach-originated draft | Ask for alternatives after supplying a complete draft | Credits unchanged coach selections as accepted assistant recommendations |
| E15, repeated slot labels | Choose a destination in a note with several blocks/versions/weeks | Treats a bare slot label as unique or silently repairs unrelated note structure |
| E16, setup uncertainty | Review a movement whose cueing setup can be mistaken for resistance | Critiques an assumed mechanism as established fact without checking |

Collect time/keystrokes to a usable edit, context-correction burden, target errors,
scope corrections, and voluntary rationale usefulness. Do not log raw note content
by default. Compare against current Notes + ChatGPT workflow before deciding that
the prototype is faster. No success-rate claims follow from this mockup alone.

## Distinct approaches after live reconciliation (2026-10-11)

These are prose proposals only. No new visuals or implementation were created.
E4–E7 now have live note outcomes; see the evidence package for the boundaries of
what those outcomes establish.

### A. Scoped working copy / scratchpad

Invocation with a selection seeds a working copy of that text; without a selection,
offer the current block/session as a clearly identified default. Show the wider
reasoning context separately. The user and assistant can revise this temporary
version together, move candidates between slots, and compare against Notes before
applying. Notes stays authoritative until an explicit reviewed application.

Best fit: reshape a block, reconcile several suggestions, or review equipment-list
changes together with exercise changes (E7). Keep draft additions distinguishable
from original text. A whole-note clone should not be the default merely because
context includes the whole note.

Risk: diverging documents and an accidental replacement editor. Use a snapshot
base, visible unsaved/proposed state, and explicit discard/apply. If Notes changes,
show the conflict rather than automatically resyncing away work or overwriting.
A future multi-range application needs a separate safety design; a scratchpad does
not make this engineering problem disappear.

### B. Conversation with actionable exercise mentions

Keep the natural ChatGPT-like exchange. Exercise mentions are keyboard-focusable,
visually distinguishable spans or chips, but remain part of a readable answer.
An exercise occurrence offers an action menu: target a slot (for example B1), annotate
its role or constraint, reject this candidate in context, request/perform a modification,
or compare alternatives. Pointer interaction is optional, never required.

An action refers to the particular occurrence and its associated prescription,
not every appearance of that exercise in the conversation. Confirm a destination
and resulting text before inserting/replacing. “Reject this option” differs from
“avoid this exercise for this client” or “change my coaching preference.”
Known-library identity and model-proposed/unknown wording are distinguishable;
selecting a mention does not establish an alias or create an exercise.

Best fit: E1's progressive clarification, E4's reinterpretation, and E5's selective
use of two ideas rather than an entire answer. Retain optional group actions for a
pair, progression, or block: a skill sequence can be meaningful as a unit even when
its exercise names are independently actionable.

Risk: too many controls and treating program writing as name picking. Keep the
action menu hidden until focus/selection, provide keyboard cycling, and retain
the suggested dosage, pairing, purpose, and local explanation with each candidate.
Names alone would miss E6's placement and pacing decisions.
E10–E16 reinforce this: retain load side, implement/setup, coaching cues, preparation
versus test versus main-work role, and the associated clock or week progression.
Do not make every field a required form. Surface the details that matter to the
particular decision and preserve their text in the editable proposal.

Where a slot label repeats, show enough destination hierarchy to disambiguate
note → block/version → session → region/slot → week. This is a targeting safeguard,
not approval to implement cycle editing. A selection may already resolve the region;
do not force users through a hierarchy picker when the destination is unambiguous.

For rationale capture, retain what the coach already stated and its local scope.
Only unresolved intent warrants the optional hypotheses. Assessment prompts should
remain prompts until the coach reports an observation; do not ask whether an exercise
was performed merely to fill a provenance gap. Consequential setup ambiguity may
need a compact clarification before giving a critique, independently of memory capture.

### C. Proposal tray / change review

Conversation remains ordinary prose. Selected ideas become a small tray of proposed
changes with target, operation, editable text, and dependencies. The user can collect,
compare, revise, and discard before applying. Selecting an idea is not applying it.

Best fit: E7's equipment consolidation, where the recorded result touches a list
and multiple blocks. Show explicitly whether related edits are being deferred.
Risk: extra bookkeeping for a simple B2 insertion. Keep single-candidate application
fast; a tray should appear only when the user is collecting or coordinating changes.

### Working recommendation, not a decision

Start the next design discussion with **B**: it most closely matches the observed
collaboration and selective incorporation. Let an actionable mention grow into a
small editable proposal, preserving explanation and prescription. **A** is a
deliberate “work on this block” mode when text manipulation becomes the main job;
**C** is an optional review layer for coordinated changes, not a permanent dashboard.

Do not implement all three now. Compare two concrete tasks before selecting a first
slice: correcting/filling one slot (E1), and consolidating equipment across regions
(E7). Ask whether the user primarily wants to discuss possibilities, manipulate a
working draft, or collect decisions at each stage. Invocation selection should set
an initial editing scope, not become a requirement for contextual assistance.
