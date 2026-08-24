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

## Opportunity: maintain a trustworthy exercise library without interrupting work

The library loses value if adding a genuinely new exercise is cumbersome or if
unmatched wording accumulates without a quick review path.

### Solutions and experiments

- **Now:** finish and manually verify the selected-text workflow for linking an
  existing exercise or creating a genuinely new one without leaving Notes.
- **Next after baseline autocomplete:** use a reusable exercise-identity review
  workflow to stage and import the personal exercise library. The import adapter
  must share candidate evidence, explicit link/create/separate/defer decisions,
  and provenance with later hygiene workflows rather than implement a disposable
  batch deduplicator.
- **Later:** after a program is complete, reuse the identity-review workflow to
  review unmatched exercise wording and
  quickly mark each item as a confirmed alias, a new exercise, or intentionally
  unresolved.
- **Later:** provide a dedicated duplicate-review or merge workflow. Similarity
  alone must not establish identity.

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

Client performance history and load recommendations remain outside the initial
product scope until explicitly approved.

## Horizon summary

**Now** completes the already-started new-exercise workflow and records the product
redirection. **Next** proves keyboard autocomplete from an empty Notes cursor, then
builds the reusable identity-review workflow, imports the personal library, and
reaches an explicit useful-product pause gate. Conservative transformations extend
autocomplete only if field use justifies continuing. **Later** contains
completed-program hygiene, intent-based retrieval, blocks, programming tendencies,
contextual pairing, and progression relationships. **Future** contains
client-specific history and load-aware assistance.

Ideas may be added to this tree without changing active success criteria. Each idea
must remain an opportunity or candidate solution until the user explicitly moves
it into the active slice.
