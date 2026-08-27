# Tutorial Progress

Current exercise: 11
Current task: Task A — Define the field-signal contract
Current task state: not started
Task completion condition: pass Exercise 11 Task A `STOP / REVIEW — Feedback-loop contract`
Completed tasks: Exercise 01 — Tasks A–E; Exercise 02 — Tasks A–C; Exercise 03 — architecture decision; Exercise 04 — Tasks A–B; Exercise 05 — Tasks A–B; Exercise 06 — deterministic normalization and alias lookup; Exercise 07 — Tasks A–C; Exercise 08 — Tasks A–C; Exercise 09 — Tasks A–C; Exercise 10 — Tasks A–C
Remaining tasks: Exercise 11 — Tasks A–D
Most recent checkpoint: Exercise 10 Task C `STOP / REVIEW — Import and useful-product pause gate` (passed)
Relevant skills: frame-work, verify, set-boundaries, record-decisions

## Completed

- [x] 01 — Repository, Git/GitHub, and specification
- [x] 02 — Apple Notes Service architecture spike
- [x] 03 — Review and commit the architecture decision
- [x] 04 — Exercise library data model
- [x] 05 — Resolver fixtures before resolver code
- [x] 06 — Deterministic normalization and alias lookup
- [x] 07 — Fuzzy candidate generation and human confirmation
- [x] 08 — Frictionless new-exercise workflow
- [x] 09 — Keyboard autocomplete from an empty Notes cursor
- [x] 10 — Exercise identity review and personal-library import
- [ ] 11 — Field feedback loops and resolver improvement
- [ ] 12 — Verification harness and agentic manual testing
- [ ] 13 — Independent review and worktrees
- [ ] 14 — Future client-history architecture (design only)

## Planned product-extension exercises

- [ ] 15 — Reusable completed-program observation extractor; begin only when
  explicitly selected after Exercise 10 has preserved the private Task A/Task C
  feedback packet. This planned extension does not advance current tutorial state.

## Current notes

- The repository is initialized locally with repository-local author `Dan Goldburt <8260344+DGoldburt@users.noreply.github.com>`.
- Private SSH remote `origin` is `git@github.com:DGoldburt/gym-assistant.git`;
  GitHub CLI 2.98.0 is installed through the local Miniconda environment.
- Local and remote `main` contain learner-free reusable history through branch-model update `2b4dbe1`. The immutable tag `tutorial-start-v1` still resolves to the original clean root `4161f6f`.
- Local and remote `learner/main` contain merged pull-request commit `feb2e0c` and are the persistent integration target for personal tutorial progress.
- Pull request #1 merged the reviewed `tutorial/exercise-01` state into `learner/main`; local synchronization was verified with a clean working tree.
- `tutorial/exercise-02` was pushed and merged into `learner/main` as `968f6c7`; local and remote `learner/main` were synchronized before creating local `tutorial/exercise-03` from that exact commit. Reusable `main` remains learner-free at `2b4dbe1`.
- Exercise 02 Task A verified macOS 26.6, Xcode 26.6, Swift 6.3.3, the selected full-Xcode developer directory, and the macOS SDK without installing or creating anything.
- Task A approved an Automator Quick Action as the first and smallest mechanism to test on macOS 26.6. A minimal AppKit Service provider is the only fallback if Notes-specific replacement, cancellation, focus, or latency fails.
- The approved Quick Action will offer Front Squat, Single-Leg Romanian Deadlift, and Aussie Pull-up; the selected choice replaces the selected Notes text, while cancellation must leave it unchanged.
- Exercise 02 Task B reverified the environment, aligned `PLAN-001` with the approved mechanism and three-choice contract, and passed implementation readiness without adding tools.
- Exercise 02 Task C preserved the failed Automator attempt and proved the AppKit Service-provider fallback through the real Notes shortcut, three-choice keyboard interaction, exact replacement, cancellation, and focus restoration.
- The AppKit fallback passed 5/5 cold trials with a 480.0 ms maximum, 20/20 warm trials with a 130.5 ms median and 192.9 ms nearest-rank p95, and 2/2 unchanged cancellation checks with zero integrity or focus failures.
- The Exercise 02 architecture gate passed. The learner would use the interaction repeatedly and chose to retain the Notes-adapter hypothesis while carrying forward the awkward shortcut and identical-text replacement ambiguity as limitations.
- Exercise 03 accepted ADR 001: retain Notes through an AppKit Service adapter, keep domain/resolver logic independent, reject Automator for the initial mechanism, and revisit or abandon the approach using explicit quantitative and human triggers.
- `docs/ARCHITECTURE.md` now identifies the Notes adapter direction as validated while leaving downstream domain boundaries as tutorial hypotheses.
- Exercise 04 Task A approved a minimal `Exercise` identity with an opaque UUID and required owned `preferredNameID`, plus durable `ExerciseName` records with globally unique normalized keys and workflow-supplied provenance.
- The approved deferred composite foreign key rejects orphan exercises, nonexistent preferred names, and preferred names owned by another exercise. A separate canonical-name role, contextual ownership, variants, program/client context, taxonomy, and history remain explicitly outside Task B.
- A read-only review of all 57 Notes in the Strength Training folder informed evidence-backed future directions without adding required fields to the initial model.
- Local reusable `main` includes approved success-criteria review guidance at `64bfe51`; local `learner/main` and the current exercise branch are synchronized with it. Nothing from that reusable update was pushed.
- Exercise 04 Task B implemented the approved model as a minimal Swift package backed by SQLite. Six tests pass for creation, confirmed-name lookup, idempotency, conflicting ownership, orphan rejection, and wrong-owner preferred-name rejection.
- The generated schema was inspected directly: schema version 1 contains the approved tables, normalized-name uniqueness, supporting indexes, and deferred composite preferred-name foreign key. Resolver and history behavior remain unimplemented.
- Exercise 05 Task A approved 37 resolver fixtures: 10 `MUST_MATCH`, 17 `MUST_NOT_MATCH`, and 10 `SUGGEST_REVIEW`. They protect confirmed alias ownership, narrowly scoped cosmetic normalization, meaningful programming modifiers, and one-time confirmation for likely misspellings.
- Exercise 05 Task B added a deliberately failing fixture runner. Its no-resolver baseline reports 17 passes, zero false merges, 10 missed expected matches, and 10 candidate-ranking failures; eight package tests pass, including a controlled all-false-merge classification test.
- Exercise 06 implemented exact and cosmetically normalized lookup across confirmed names. The fixture report now has 27 passes, zero false merges, zero missed expected matches, and 10 deliberately unresolved candidate-ranking failures; all 12 package tests pass.
- Exercise 07 Task A approved similarity as ranking evidence only. Candidates with conflicting protected modifiers must be excluded, while possible duplicates remain separate until a future explicit duplicate-review and merge workflow.
- Exercise 07 Task B implemented review-only candidate ranking. The complete 37-case fixture report passes with 10/10 deterministic matches, 17/17 protected exclusions, 10/10 expected top suggestions, and zero false merges or protected-candidate leaks; all 16 package tests pass.
- Exercise 07 Task C persists only accepted suggestions as `userConfirmed` aliases. Accepted, rejected, and repeated-acceptance paths are covered by the standard regression suite; all 18 package tests and the unchanged 37-case resolver exam pass.
- Exercise 08 Task A approved a two-action, zero-required-typing new-exercise budget with one `Name` field, exact normalized-match bypass, edited-name-only persistence, automatic Notes focus restoration, and a 500 ms save-to-return target.
- Exercise 08 Task B implemented and manually tested the four approved Notes workflows. Twenty-two package tests and the 37-case resolver exam pass; the two-action creation path returned 22.7 ms after confirmation.
- Manual testing corrected wrong-window focus behavior and proved that temporary LaunchServices registration was not a durable installation. Gym Assistant is now installed under the user Applications folder with an embedded `⌃⌥⌘G` Service shortcut; the learner confirmed the Notes Services entry and physical shortcut work.
- Exercise 08 Task C approved the product redirection: keyboard autocomplete from
  an empty Notes cursor is the primary writing interaction, while selected-text
  linking and creation remain separate identity workflows.
- ADR 001 now records the no-selection adapter extension and explicitly prevents
  autocomplete selection from creating aliases or exercises. Exercise 08's
  creation description is synchronized with the approved single-`Name` behavior.
- Exercise identity remains foundational because autocomplete depends on a clean,
  complete library, but inserting a search result does not establish identity
  knowledge. Later hygiene, movement search, pairings, blocks, tendencies, client
  context, and load history remain deferred.
- Exercise 09 Task A approved identity-deduplicated autocomplete with preferred-name
  rows, keyboard alias expansion, exact unmatched-query insertion, and read-only
  fuzzy ranking. Search performs no identity writes, and vocabulary transformations
  such as `KB` to `kettlebell` remain field-evidence-gated.
- The approved interaction and measurable latency, integrity, keystroke, and human
  usefulness gates are preserved in `PLAN-004-keyboard-autocomplete.md`.
- Exercise 09 Task B implemented one shared text-candidate ranker used by identity
  review and autocomplete. Autocomplete receives all approved identity-review
  evidence plus a lower fuzzy threshold but has no identity-write operation.
- Search returns one row per stable exercise identity with preferred and confirmed
  names, deterministic evidence tiers, and protected-conflict exclusions. Thirty-two
  tests and all 37 unchanged resolver fixtures pass with zero persistence changes.
- Exercise 09 Task C connected autocomplete to a separate empty-cursor Notes
  Service and passed the complete real-host gate. Option-Command-G produced a 5/5
  learner preference score after the original three-modifier shortcut scored 3/5.
- Manual testing corrected active-caret restoration, an unrelated short-query
  result, an incremental `copp` ranking discontinuity, and Escape behavior that
  could leave a modal panel open past the Service timeout. Thirty-three tests and
  all 37 resolver fixtures pass; search remains read-only with zero identity writes.
- Exercise 10 Task A reviewed all 56 currently visible Strength Training notes and
  staged 1,891 private source observations representing 2,224 occurrences. All 158
  ambiguous extraction rows received explicit boundary decisions; the original
  wording, source evidence, and audit remain private and uncommitted. Four
  cross-note samples matched Notes directly. The older durable count of 57 notes
  remains a recorded coverage limitation, but the current source was accepted as
  complete enough to proceed without making exercise-identity decisions.
- Exercise 10 Task B implemented a source-adapter-independent identity-review core.
  Exact confirmed names reuse identity without writes; transformations,
  bidirectional lexical similarity, prescription differences, and identity
  conflicts provide human-review evidence only. Staged observations support Link,
  observation-text-only Create, and durable Defer; audit-only Keep Separate applies
  to two existing IDs. Forty-three tests, all 37 resolver fixtures, and all six
  review-policy fixtures pass with zero candidate-caused identity writes.
- Exercise 10 Task C ingested 1,891 source records as 1,210 durable observations
  and 2,224 occurrence records. The private feedback packet maps 158/158 extraction
  decisions with zero gaps and indexes all 9 skips. Review-to-autocomplete passed
  in Notes; 58 tests, 37 resolver fixtures, and 6 review-policy fixtures pass.
- Field use retained repeated tab-away friction, missing `DL` protected-conflict
  recognition, and mixed-evidence ordering problems as Exercise 11 signals rather
  than expanding Task C indefinitely.
- Exercise 01 Tasks A–E evidence and approved reflections are recorded in `LEARNING_LOG.md`.
- Task C selected a deliberate hybrid from a regular-prompt plan, a Plan-mode plan, and an isolated regular-prompt control without `PLANS.md`. The approved plan requires a lightweight keyboard interaction, separate cold/warm gates, system-latency measurement excluding human decision time, and a stop before product implementation.
- The temporary post–Task-A root and backup branch were deleted after restoration; obsolete commit `68ecdb2` was pruned and never pushed.

## Relevant durable context

- Skill confidence: `docs/curriculum/SKILLS.md`
- Agentic-AI context and outside ideas: `docs/curriculum/AGENTIC_AI_MAP.md`
- Approved learning evidence: `LEARNING_LOG.md` — 2026-08-18, Exercise 01, Task A; 2026-08-19, Exercise 01, Tasks B–E and Exercise 02, Tasks A–B
- Completed durable plan: `docs/exec-plans/PLAN-001-notes-interaction-spike.md`; evidence is under `spikes/notes-interaction/`
- Accepted architecture decision: `docs/decisions/001-notes-integration.md`

## Next action

Begin Exercise 11 Task A by defining the private field-event schema, one-action
subjective flag, deterministic anomaly checks, baseline metrics, disposition ledger,
and fixed first resolver batch. Keep collection and evaluation unattended-capable,
but retain prioritization, identity changes, and product-scope decisions as foreground
gates.
