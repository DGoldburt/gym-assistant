# Clarify alias identity and expose consistent decision guidance

This living ExecPlan follows PLANS.md. Maintain Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective at each handoff.

## Purpose / Big Picture


Coaches can decide whether wording is an alias or a separate exercise using one
short rule available beside Edit and Import Review decisions. Review must not
offer short-/long-lever Copenhagen or resistant RNT/base comparisons as linkable
prescriptions. Tempo-bearing wording remains explicitly confirmable without loss.

## Plan Status


In progress. The user approved this bounded implementation on 2026-10-14 and
specified that RNT means resistance/remedial execution, not a tempo prescription.
Prepare a learner/main-only PR; stop before merge or production installation.

## Progress


- [x] (2026-10-14) Inspect current policy, fixtures, UI, and repository instructions; create isolated learner/main-based worktree.
- [x] (2026-10-14) Record approved policy and RNT clarification; explain why contradictory test expectations will change.
- [x] (2026-10-14) Implement shared guidance/popovers and bounded execution-conflict rules; retain prior confirmed aliases and add symmetry/no-write/tempo regressions.
- [x] (2026-10-14) Run full verification: 107 tests, 37 resolver cases, 11 identity-review cases and all five stages pass; inspect scoped diff.
- [ ] Publish learner-only PR; no merge or installation yet.
- [ ] Obtain isolated manual UI acceptance and one bounded independent review before merge approval.

## Surprises & Discoveries


ReviewRelationshipPolicy explicitly classified Copenhagen lever length and RNT as
prescription differences before the generic protected-modifier rule. That is the
observed contradiction, not a failing test to suppress. Existing confirmed-name
lookup is authoritative and must not be invalidated by this policy revision.

Recognized variation comparisons must also agree on their base wording: otherwise
an RNT observation can manufacture non-linkable candidates for unrelated exercises.
Bounded base comparison and a regression prevent that pollution. The fixture-count
assertion intentionally changes from eight to eleven because three cases were
added; all-case disposition assertions remain intact.

## Decision Log


Decision: interchangeable execution wording is alias material; implement, load
position, assistance and execution progressions define separate identities.
Rationale: predictable editing and recognizable progression choices in future
history. Date/Author: 2026-10-14 / User.

Decision: tempo, including negatives, remains prescription; existing full wording
may remain an explicitly confirmed alias. RNT resistance is a separate variation.
Rationale: retain wording without introducing a structured prescription model or
erasing live names. Date/Author: 2026-10-14 / User.

Decision: use one reusable AppKit popover control with accessible label/tooltip
and Command-? entry, and one shared copy string in the core.
Rationale: consistent discoverability without permanently enlarging the editor.
Date/Author: 2026-10-14 / Codex within approved UI scope.

## Outcomes & Retrospective


Implementation is complete locally. Automated verification passed all five stages
with 107 tests, 37 resolver cases and 11 review cases (zero candidate-caused writes),
including the final keyboard-focus refinement. Manual UI acceptance
and independent review remain pending. Existing production data is untouched.
No reusable main, curriculum records, schema, migration, or history feature change
belongs to this slice. Other worktrees continue independently; overlapping policy
or AppKit edits require explicit reconciliation at integration.

## Context and Orientation


An exercise has a stable ID; its confirmed names are aliases. Search proposes
matches but never establishes identity. ExerciseIdentityReview.swift supplies
read-only relationship evidence and explicit Link/Create decisions for imported
observations. Tests/Fixtures/identity-review-cases.json specifies their expected
linkability. GymAssistantNotesService/main.swift owns AppKit Edit and Review UI.
LibraryMaintenance.swift contains shared presentation policy. ADR 004 records
the new decision; prior plans and learner reflections remain historical evidence.

## Plan of Work


Milestone 1 records ADR 004 and updates current PRODUCT/ARCHITECTURE guidance.
Update review relationship policy before generic fuzzy fallback, replacing the
two contradictory exceptions with execution conflicts. Add tested implement,
load-position and assistance comparisons, and preserve tempo/negative comparisons
as human-confirmable prescriptions. Test both directions, zero identity writes,
and exact lookup of already-confirmed names. No general prescription parser is
required; unknown wording remains a human judgment rather than invented certainty.

Milestone 2 adds a retained AliasPolicyHelp controller per maintenance/review
controller. Its info button shows a transient, selectable-text popover with the
same shared string in Edit, Merge target search and Import Review. Give it the
accessible label Alias or separate exercise?, hover tooltip and Command-? shortcut.
Close restores the preceding keyboard focus. Opening guidance never commits a
decision or changes selection. Keep existing shortcuts/navigation intact.

Milestone 3 runs scripts/verify, inspects the whole diff for private material and
unrelated files, and publishes an isolated learner/main PR. Compare the base again
before integration. Manual popover acceptance and bounded independent review are
remaining gates, not evidence supplied by unit tests. Do not merge or install yet.

## Concrete Steps


From this worktree repository root run swift test, then ./scripts/verify and
git diff --check. Expect all five stages, unchanged resolver fixtures, revised
identity-review fixtures and new regressions to pass. Record actual totals below.
Inspect git diff learner/main...HEAD before publication; it must contain only this
policy/UI slice and its tests/docs. No PROGRESS, SKILLS or LEARNING_LOG changes.

## Validation and Acceptance


Short-Lever Copenhagen versus Long-Lever Copenhagen and Touch-Down with RNT versus
Touch-Down are visible non-linkable conflicts in review. Touch-Down with 5 sec
negative versus Touch-Down remains linkable only with confirmation. DB/Dumbbell
synonyms remain linkable, unlike KB/DB implement differences. Existing confirmed
aliases still resolve exactly, even when they predate this policy. Tests cover
symmetry and preservation; fixture generation must produce zero identity writes.
Manually open Edit and Import Review with synthetic data, invoke the info icon by
pointer and keyboard, verify identical readable copy, close by Escape, and confirm
query, selection, decision state and keyboard navigation are unchanged. Include
Merge's attached sheet. No live Notes/library data is needed for this trial.

## Idempotence and Recovery


Opening/dismissing guidance is read-only. This change modifies no persisted names,
exercise IDs, receipts or source text. Ordinary code reversal restores previous
policy with no data migration; existing questionable aliases need later deliberate
manual corrections. Keep production installation separate from PR integration.

## Artifacts and Notes


Baseline worktree: alias-policy-guidance from learner/main at 4d0cec7. The user
explicitly excluded reusable main updates. Verification and UI/review results
must be recorded at handoff; do not label unrun UI checks passed.

## Interfaces and Dependencies


Use Foundation, AppKit and existing Swift Testing/fixture runners only. Add shared
AliasIdentityGuidance.text and adapter-local AliasPolicyHelp. Keep relationship
classification in ReviewRelationshipPolicy, not in button actions. No dependencies,
prescription storage, exercise-family type, automatic cleanup or background jobs.

Revision note — 2026-10-14: Recorded approved bounded follow-up and resistant RNT
clarification before implementation; current scope remains learner-only.
