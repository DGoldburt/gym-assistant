# ADR 004 — Separate execution variations; preserve prescription wording

Status: accepted 2026-10-14. Implementation authorized for learner/main only;
manual UI acceptance, independent review, merge and installation remain pending.

## Context

The coach found Library Edit useful but inconsistent alias boundaries confusing.
Earlier PLAN-005/007 policy allowed Copenhagen lever lengths and RNT as
prescription-bearing aliases. That grouping obscures progression choices when
looking back at programming. This decision supersedes those current-policy
claims, not their historical evidence, and implements no history feature.

## Decision

The shared UI guidance is:

> Aliases are different wording for the same exercise. Keep implement changes (KB/DB/unweighted), load-position changes (goblet/front-rack), and execution variations (deficit, touch-and-go, assisted/unassisted) as separate exercises. Sets, reps, weight, and tempo—including negatives—are prescriptions, not exercise names. If prescription details appear in a name, you may retain the full wording as an alias after confirmation—for example, ‘Touch-down squat 5 sec negative’ → ‘Touch-down squat’.

RNT in this library means added resistance, a remedial execution distinct from
the progression without RNT. Touch-Down with RNT is not a new alias of Touch-Down.
Short- and long-lever Copenhagen are separate progressions. Tempo, including
negative-only wording by the coach's chosen convention, remains prescription:
this policy does not require distinguishing phase timing from an eccentric-only
variation. Assistance explicitly named in an exercise remains an execution
variation even when a tempo/negative annotation is also present.

Show one discoverable info control with keyboard access beside Edit decisions,
in its Merge target sheet, and in Import Review's Link/Create decision surface.
Guidance is informational and read-only, not a mandatory confirmation step.

## Evidence and enforcement

Review relationship rules formerly overrode protected lever conflicts with a
prescription exception. Revised fixtures classify opposing lever progressions,
RNT/base, explicit KB/DB and goblet/front-rack as non-linkable comparisons;
tempo remains explicitly confirmable. Test both directions and no silent writes.
The matcher recognizes a bounded vocabulary, not arbitrary natural-language
prescriptions; guidance supplies the human rule for unknown cases. Unspecified
implement/load position must not be inferred from absent tokens.

## Consequences and compatibility

Existing confirmed aliases stay authoritative. Do not strip names, split IDs,
rewrite historical observations, change schema or clean the live database.
New review conflicts prevent Link; manual Edit remains an explicit human repair
surface, not an automatic semantic validator of every merge. Add a separate
future task if existing relationships need correction. Preserve the full name
and prescription text when confirming a permissible legacy tempo alias.

## Alternatives considered

A structured prescription or exercise-family model could group progressions and
parse parameters but is unnecessary for predictable editing today. Retaining
the old broad grouping perpetuates ambiguity. A mandatory tutorial/confirmation
would add friction; a concise popover is sufficient for this slice.

## Known limitations and revisit triggers

No general prescription extraction, arbitrary modifier classifier, alias cleanup,
structured progression graph or training-history feature is introduced. Revisit
with concrete confusing wording or observed rule false positives, not a generic
desire for taxonomy. Manual AppKit focus/layout checks remain required.
