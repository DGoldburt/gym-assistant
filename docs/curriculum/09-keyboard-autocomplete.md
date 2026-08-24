# Exercise 09 — Keyboard Autocomplete from an Empty Notes Cursor

## Why we're doing this

The primary product outcome is faster program writing. When the user already has
an exercise in mind, the assistant should complete it with less input than typing
the full name and without requiring provisional text, a selection, or a mouse.

## Codex skill

- turning a product decision into an interaction contract
- separating search selection from identity confirmation
- verifying an end-to-end keyboard workflow in the real host application

## Skills practiced

- `frame-work` — Frame a bounded task
- `verify` — Build an evidence-producing delivery loop
- `set-boundaries` — Keep adjacent product opportunities out of the active slice

## Product-scope guard

This exercise searches only preferred display names and already-confirmed exercise
names. It does not add search-only abbreviation transformations, create aliases,
create exercises, search by movement pattern or exercise attributes, recommend
pairings, inspect the surrounding program, insert blocks, or use client history.

The AppKit Service adapter accepted by ADR 001 remains the architecture direction.
This exercise extends it to invocation without selected text and verifies that
extension during implementation; it does not repeat the earlier architecture
spike or require a new ADR.

## Task A — Approve the autocomplete interaction and ranking contract

Propose the smallest interaction that begins with an empty Notes insertion point.
The user invokes the assistant, the query field receives focus, typing updates a
short ranked list, Up/Down changes selection, Return inserts the selected preferred
display name at the original cursor, and Escape leaves Notes unchanged.

Define a transparent baseline ranker over the persisted library. Prefer normalized
prefix matches over token-prefix matches and broader lexical matches. A confirmed
name may make its owning exercise discoverable, but the result must display and
insert that exercise's preferred display name. Search must not write a confirmed
name or otherwise mutate exercise identity.

Propose measurable budgets for system latency, mouse use, interaction count, text
integrity, focus restoration, and keystroke savings on a small set of realistic
exercise queries. The first test deliberately excludes non-identity deterministic
query transformations.

### STOP / REVIEW — Autocomplete contract

Inspect the complete interaction, rank ordering examples, empty-query behavior,
no-result behavior, cancellation path, insertion semantics, test queries, and
measurement budgets. Decide whether the contract is both useful and smaller than
the adjacent opportunities preserved in the Opportunity Solution Tree.

Teach back: Why does selecting a result prove intent to insert an exercise but not
necessarily prove that the query text is an alias for that exercise?

## Task B — Implement existing-name search

Implement persisted-library candidate retrieval and deterministic ranking behind
an application/domain boundary independent of Apple Notes. Cover preferred names,
confirmed names, duplicate suppression by exercise identity, deterministic ties,
empty queries, and no-result queries with automated tests.

### STOP / REVIEW — Search evidence

Inspect the tests and query examples, including a result found through a confirmed
name but displayed by its preferred name. Confirm that the search performs no
library writes and that ranking behavior is understandable before connecting it
to the Notes adapter.

Teach back: Which behaviors belong to search, and which still belong to identity
resolution?

## Task C — Complete and manually verify the Notes writing loop

Connect existing-name search to the AppKit Service adapter. Invoke it from Notes
without selected text and verify automatic query focus, keyboard navigation,
insertion at the original cursor, cancellation integrity, return of Notes focus,
and repeated use across realistic program lines.

Compare full-name typing with autocomplete using the approved keystroke and timing
method. Record permission, shortcut, clipboard, lifecycle, or insertion limitations
discovered during real use without retroactively reframing this task as an
architecture spike.

### STOP / REVIEW — Autocomplete evidence

Inspect automated results, manual Notes evidence, timings, keystroke comparisons,
insertion accuracy, cancellation, and focus behavior. Decide whether autocomplete
measurably improves program writing and whether any observed adapter limitation
requires a bounded correction or an ADR 001 revisit trigger.

Teach back: What did the real Notes workflow reveal that the domain search tests
could not establish?

After the user approves the reflection and checkpoint, append learning evidence,
update justified skill confidence and progress, and advance to Exercise 10.
