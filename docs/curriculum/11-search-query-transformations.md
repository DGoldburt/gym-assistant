# Exercise 11 — Extend Conservative Transformations in Autocomplete

## Why we're doing this

After field-testing autocomplete against the imported personal library, the user
may find that compact programming vocabulary still requires avoidable typing or
confirmed aliases. Examples might include `KB` and `kettlebell`, or `SL`,
`single-leg`, and `1-leg`.

The shared candidate-ranking component already makes transformations accepted as
identity-review evidence available to autocomplete. This exercise happens only if
field evidence justifies continuing development and considers the smallest new
transformation set worth adding through that shared mechanism rather than creating
a second transformation system.

## Codex skill

- reusing normalization mechanics without conflating domain meanings
- specifying conservative deterministic behavior with adversarial fixtures
- measuring whether added matching behavior reduces real input

## Skills practiced

- `frame-work` — Frame a bounded task
- `verify` — Build an evidence-producing delivery loop
- `set-boundaries` — Separate search evidence from durable identity knowledge

## Product-scope guard

This exercise improves autocomplete retrieval only. A reused transformation may
contribute ranking evidence, but it must not establish an alias, change exact
confirmed-name lookup, merge exercises, or write to the exercise library. Movement
taxonomy, semantic similarity, learned ranking, program context, and client history
remain outside the slice.

The existing normalizer's safe text-processing mechanics may be reused, but its
identity contract must not be broadened silently. Search-query transformation and
confirmed-name normalization remain explicit domain operations with different
consequences.

## Entry condition

Do not begin this exercise automatically. First inspect the Exercise 10 import and
field-test evidence. Continue only when observed searches show that deterministic
transformations would materially reduce input or avoid unnecessary identity aliases.
If baseline autocomplete is already useful enough, pause development instead.

## Task A — Approve reuse in autocomplete

Use evidence from real autocomplete searches and the Exercise 10 review vocabulary
to propose the smallest additional transformation set worth introducing. For every
transformation, show intended matches, protected non-matches, token boundaries,
punctuation behavior, ranking impact, and the reason it is conservative enough for
search.

Include fixtures for collisions and modifiers. In particular, prove that expanding
a short token cannot erase meaningful distinctions such as bilateral versus
unilateral, supported versus unsupported, stance, implement, direction, or body
position.

### STOP / REVIEW — Transformation contract

Inspect the field evidence, complete proposed reuse set, and fixture table. Remove
transformations whose observed benefit does not outweigh ambiguity. Decide whether
the accepted transformations remain ranking evidence only and whether their
behavior remains understandable.

Teach back: Why is `KB` helping retrieve `Kettlebell RDL` different from declaring
that every occurrence of `KB` is a confirmed name for that exercise?

## Task B — Extend the shared transformations

Add the approved transformations to the shared candidate-ranking component through
an explicit policy. Autocomplete may use evidence that is more permissive than
identity review, but it must not duplicate similarity mechanics or transformation
vocabulary. Do not route transformed queries through the library's exact
alias-ownership path.

Run the unchanged Exercise 09 search and Notes workflow evidence, then add the
approved compact queries. Compare result ordering and keystrokes before and after
transformations, and verify that every protected non-match remains protected.

### STOP / REVIEW — Transformation evidence

Inspect the implementation boundary, complete fixture report, regression tests,
real autocomplete examples, and keystroke comparison. Decide whether the small
vocabulary creates enough efficiency to retain and whether any proposed expansion
should remain future work.

Teach back: What evidence would justify adding another deterministic transformation
instead of a user-confirmed alias or a future exercise attribute?

After the user approves the reflection and checkpoint, append learning evidence,
update justified skill confidence and progress, and advance to Exercise 12.
