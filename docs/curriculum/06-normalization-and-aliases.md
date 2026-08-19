# Exercise 06 — Deterministic Normalization and Alias Lookup

## Why we're doing this

Use deterministic knowledge before fuzzy inference.

## Codex skill

- layered problem solving
- deterministic transformations
- small implementation loops
- test-guided refinement

## Skills practiced

- `verify` — Build an evidence-producing delivery loop

## Resolver order

Start with:

1. exact canonical match
2. exact alias match
3. normalized canonical/alias match
4. explicit abbreviation expansion where safe

Potential normalization:
- case folding
- whitespace normalization
- punctuation normalization
- hyphen normalization

Potential explicit abbreviations:
- DB → dumbbell
- KB → kettlebell
- RDL → Romanian deadlift
- OH → overhead

Be cautious with ambiguous abbreviations such as `SL`.

## Task

Implement only deterministic stages.

Run the fixture suite.

### STOP / REVIEW

Inspect the implementation diff, fixture report before and after, and any newly unresolved or regressed cases:
- which fixtures now pass
- which remain unresolved
- whether any MUST_NOT_MATCH cases were damaged

Question:

> Why is it better for an uncertain case to remain unresolved than to be incorrectly merged?

Decide whether deterministic behavior is stable and whether any rule encodes an unsafe identity assumption.

Teach back: How did the fixture loop constrain Codex more effectively than the instruction "make normalization good"?

After the user approves the reflection and checkpoint, append learning evidence, update justified skill confidence and progress, and advance to Exercise 07 only when deterministic behavior is stable.
