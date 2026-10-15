# Opportunity Solution Tree

Status: living product-discovery artifact. Horizon labels express sequencing, not
delivery commitments. Moving an opportunity into the active slice requires an
explicit product-scope decision and its own success criteria.

An Opportunity Solution Tree connects a desired product outcome to user needs or
problems, then to candidate solutions and experiments. This tree preserves the
larger product direction while keeping the current implementation slice narrow.

## Desired outcome

Help the user write high-quality strength-training programs faster while keeping
Apple Notes as the primary writing workspace. Reduce keystrokes, mouse movement,
repeated lookup, repeated construction, and avoidable cognitive load.

## Evidence

A review of prior exercise-selection questions found recurring needs involving
movement categories and exercise attributes, existing-program context, equipment,
client constraints, pairings, progressions, substitutions, and concise candidate
lists. The review also found explicit exercise-name recall, but routine completion
needs are likely underrepresented because a user would not normally ask a chat
assistant to autocomplete text.

This evidence supports a product direction broader than name matching: the useful
assistant eventually helps retrieve, choose, combine, and review exercises. It
does not justify implementing every opportunity now.

A later review of individual, youth, and group-class programming conversations
exposed a repeated handoff: the coach supplies a draft, considers several ideas,
manually incorporates some into the program, and must supply the revised draft
before continuing. This handoff is an opportunity in its own right, beyond faster
exercise-name entry.

## Opportunity: continue a programming conversation around the current program

The assistant should reason from the program being written and continue from the
coach's edits without repeated context sharing. The selected design direction is
one persistent scratchpad for a session, with free-form conversation beside it.
The coach edits useful ideas into the scratchpad. Apple Notes remains the recorded
program destination, with the scratchpad as a bounded working copy.

### Sub-opportunity: resume programming without losing unfinished thinking

This belongs to contextual assisted programming, not a separate product direction.
The coach needs visible working context and recoverable rationale without maintaining
every old scratchpad as an active editing claim on Notes.

- **Now, approved in PLAN 013:** resume the scratchpad, expose current Notes
  differences, and offer explicit replacement of scratchpad text only for a verified
  session region. Preserve conversation and recoverable prior content. Changed Notes
  alone does not prove the scratchpad obsolete.
- **Now, approved in PLAN 013:** provide quiet **Previous planning…** access to
  read-only scratchpads/conversations. Show reliable session associations separately
  from uncertain **Other planning for this note**. Setting work aside releases active
  ownership without erasing historical evidence. Batch association repair is deferred.
- **Now, approved in PLAN 013:** carry a clearly trailing Parking Lot into each new
  scratchpad so the coach sees existing ideas. Otherwise include an empty heading;
  do not merge ambiguous sections. The coach consolidates manually after pasting.
- **Later:** retrieve relevant unfinished ideas and rationale for another session,
  without interpreting them as commitments, rejections or learned preferences.

### Other solutions and experiments

- **Now, approved in PLAN 013:** resume one scratchpad for an associated
  session, read its current text before each follow-up, and supply the associated
  program note as context. Enter this workspace from the existing autocomplete
  shortcut without changing autocomplete's ordinary interaction. See
  [the selected interaction direction](design/SESSION_SCRATCHPAD.md).
- **Now, approved in PLAN 013:** let the coach manually edit the scratchpad
  in response to conversational suggestions. Show minimal, truthful distinction
  between wording with a confirmed library match and wording without one. Keep
  the existing coaching profile discoverable and read-only.
- **Now, accepted adapter direction:** capture one Notes document
  identity for read-only context under [ADR 005](decisions/005-read-only-notes-context.md),
  flag external changes, and use a reviewed manual handoff back to Notes. Session
  association, rich-text fidelity, and recovery remain open in the
  [implementation plan](exec-plans/PLAN-013-session-scratchpad.md).
- **Later:** use approved program structure, programming history, client context,
  and an explicit coaching profile as additional evidence. Preference learning,
  unsolicited suggestions, and broader cycle reasoning remain separate candidates.

Including an idea in the scratchpad does not confirm an alias, create an exercise,
establish a global preference, or make an unused suggestion permanently unwanted.
OpenAI API use and transmission of note/profile information were approved for this
design. Credential handling, retention settings, model and spend choices, and
optional web access still need decisions before live provider integration.

## Opportunity: maintain a trustworthy exercise library without interrupting work

The library loses value if adding a genuinely new exercise is cumbersome or if
unmatched wording accumulates without a quick review path.

### Solutions and experiments

- **Now:** finish and manually verify the selected-text workflow for linking an
  existing exercise or creating a genuinely new one without leaving Notes.
- **Next after baseline autocomplete:** ingest the personal exercise source into a
  durable, resumable observation queue. Review enough observations to establish a
  useful autocomplete library without requiring the complete queue to be resolved.
  The import adapter must share candidate evidence, explicit link/create/defer
  decisions, and provenance with later hygiene workflows rather than implement a
  disposable batch deduplicator.
- **Later:** after a program is complete, run a reusable exercise-observation
  extractor over mixed program text, preserve source evidence, and send plausible
  observations to the same non-blocking identity-review queue.
- **Later:** evaluate extractor quality against Task A boundary decisions and review
  Task C outcome clusters—especially deferred observations—without treating an
  identity disposition as automatic extraction ground truth.
- **Later model-enhanced candidate:** extract candidate exercise wording from pasted
  workouts, completed programs, or instructional videos. Show each candidate beside
  its source passage or video location and likely existing-library matches, then
  stage it in the same resumable identity-review flow. The model may prepare and
  rank evidence, but may not confirm aliases, create exercises, or merge identities.
  Video extraction still depends on the separate instructional-segment design below.
- **Now, implementation awaiting integration:** provide a small Edit Library
  workspace. Approved navigation reaches it from autocomplete alongside Add
  Exercises as peer routes without cross-navigation. Add Exercises starts with creation
  from scratch and offers Import as a suboption. Review candidates is a child of
  Import, whose button carries a pending-review count, with **To review** and **Skipped** as the only
  additions views, without multiple end-user queues.
  Existing-exercise management should support deliberate duplicate merges and
  separating an incorrectly linked alias into its own exercise with an audit trail.
  The autocomplete chooser may provide a keyboard action that opens management for
  the selected stable exercise identity rather than searching by display text.
- **Later, unsequenced:** let the user submit additional exercise sources—initially
  pasted text or a URL, and eventually a photographed notebook page—through source
  adapters that preserve provenance and feed extracted observations into the same
  **To review** additions flow. Image transcription and correction remain a later
  experiment within this solution, not a requirement of the first import path.
- **Later, unsequenced:** import exercises from an instructional video link,
  including YouTube links encountered while browsing. First design and implement
  instructional segments attached to durable alias IDs, allowing multiple segments
  per alias and proposed start/end timestamps. Then implement source extraction
  and human correction/identity confirmation. Before confirmation, segments remain
  candidate source evidence. Neither model extension nor extraction belongs to
  the current CSV/library-edit slice.
- **Later, unsequenced:** process video/image/feed sources asynchronously, preserving
  work when the window closes and updating the shared review queue as candidates
  arrive. Processing progress is separate from the pending-review badge. Implement
  each source adapter through a separately scoped plan rather than building a
  general job system in the CSV slice.
- **Later, unsequenced:** schedule WOD ingestion from a verified workout source,
  for example the [Old City CrossFit workout page](https://oldcitycrossfit.sites.zenplanner.com/leaderboard-day.cfm?date=2026-02-07).
  Access/feed availability remains unverified. Preserve URL/date as source
  provenance, stage observed names in the same queue, and avoid treating workout
  occurrence as instructional-video evidence. Frequency and extraction policy
  need later design; this entry creates no schedule or network integration.

Similarity may propose a duplicate or an incorrectly linked alias, but must not
merge or separate exercise identities without an explicit reviewed action.

## Opportunity: retrieve a known exercise with minimal input

The user often has an exercise in mind and should not need to type its full display
name, select provisional text, or move to the mouse.

### Solutions and experiments

- **Next:** invoke the assistant from an empty Notes cursor, type a partial known
  name, choose with the keyboard, and insert the preferred display name.
- **Only after importing and field-testing the personal library:** if observed use
  justifies continuing development, reuse conservative identity-review
  transformations such as `KB`/`kettlebell` and `SL`/`single-leg` for autocomplete
  ranking without storing every expansion as an identity alias.
- **Later:** learn ordering from explicit user preferences or transparent usage
  evidence without obscuring why a result ranked highly.

## Opportunity: find an exercise from programming intent rather than its name

The user may know the needed role or quality—such as hinge, unilateral, explosive,
isometric, low-coordination, or easily overloaded—without having chosen an exact
exercise.

### Solutions and experiments

- **Later:** search or filter by major movement pattern.
- **Later:** add a deliberately small, evidence-backed exercise-attribute model.
- **Later:** retrieve alternatives that preserve selected qualities while changing
  an unsuitable quality.

Do not treat movement categories or training qualities as aliases. Their source of
truth and editing workflow require a separate design decision.

## Opportunity: choose an exercise that fits the program so far

The user may need a complementary B2, a missing movement pattern, a non-repeating
choice, or an exercise that fits available equipment and desired fatigue.

### Solutions and experiments

- **Later:** search and insert explicitly saved exercise blocks.
- **Later:** show transparent co-occurrence, frequency, and recency from imported
  programming history.
- **Later:** recommend pairings and identify repeated or missing patterns using the
  visible program context.

Observed co-occurrence is evidence about programming behavior, not an exercise
identity relationship or an automatically saved block.

## Opportunity: account for an individual client's constraints and history

Exercise selection may depend on discomfort, movement tolerance, goals, recent
programming, progression state, or training/load history.

### Solutions and experiments

- **Later:** represent progression and regression relationships separately from
  aliases.
- **Future:** support constraint-aware candidate review with visible rationale and
  appropriate human judgment.
- **Future:** associate clients, dates, exercises, sets, reps, loads, and notes with
  stable exercise IDs.
- **Preferred next product-slice candidate after contextual assistance:** extract
  possible session dates, exercise wording, prescriptions, and client links from
  existing notes or photographed notebook pages. Keep source passages or image
  regions and uncertainty visible for correction before creating history. Once
  history is reviewed, summarize relevant prior work on request, distinguishing
  recorded plans from work only presumed or confirmed to have occurred.

Planning conversations/scratchpads, session text recorded in Notes, and performance
annotations are distinct evidence. Extracted session history is a structured
interpretation requiring review, not a synonym for the source text. Preserve source
links and uncertainty as Notes evolves; an unused suggestion is not necessarily a
rejection, nor is a prescription proof of performance. Historical association must
not require an obsolete scratchpad to retain an active editing claim.

Client performance history and load recommendations remain outside the initial
product scope until explicitly approved.

## Relationship between the extraction candidates

Library and history extraction both turn unstructured source material into
reviewable, provenance-linked candidates. They may reuse source capture, model
evaluation, and evidence-display patterns. They have different destinations:
exercise observations go to identity review; proposed sessions and client links
need a separate history-correction workflow. Confirming an exercise alias does not
confirm a session date, client, prescription, or performance, and confirming a
history record does not silently add an alias. Shared extraction machinery is a
design hypothesis, not a reason to build a general ingestion platform now.

## Horizon summary

The original **Now** and **Next** sequence led through new-exercise entry,
autocomplete, and reusable identity review. Those numbered tutorial exercises are
complete. Contextual program assistance is now approved for bounded offline
implementation under PLAN 013; live API use and rollout retain their explicit gates.
The separate bounded client-history workstream is unchanged. **Later** retains completed-
program extraction, library hygiene, intent-based retrieval, blocks, programming
tendencies, contextual pairing, and progression relationships.

The coach's preferred following slice is history extraction and review; this advances
its discovery priority from the original Future horizon. Model-enhanced library
extraction is an adjacent candidate without a committed order relative to history.
Load-aware assistance remains Future. This is a horizon preference, not approval of
history implementation, client-history schema, image processing, or load recommendations.
Each needs its own success criteria and evidence before entering the active slice.

Reconciled with local `learner/main` at b5d9916 on 2026-10-15: preserve its newer
library/history extraction directions alongside this branch's contextual-assistance
opportunity. Do not restore the older completed-tutorial horizon as current work.

Ideas may be added to this tree without changing active success criteria. Each idea
must remain an opportunity or candidate solution until the user explicitly moves
it into the active slice.
