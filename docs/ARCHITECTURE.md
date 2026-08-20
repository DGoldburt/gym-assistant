# Architecture

Status: the Notes adapter direction is validated by ADR 001; downstream domain boundaries remain design hypotheses that will evolve through the tutorial.

## Architectural principle

Apple Notes is an input/workspace adapter. It must not contain the core business logic.

Conceptual structure:

    Apple Notes
        |
        v
    AppKit macOS Service adapter
        |
        v
    Exercise Search / Resolver
        |
        +--> Exercise Library
        |
        +--> Alias Knowledge
        |
        +--> Saved Blocks
        |
        +--> Programming Tendencies (later)
        |
        +--> Client History (future, not implemented)

## Boundaries

### Notes integration layer
Responsibilities:
- receive selected text
- invoke library/search workflows
- display a lightweight chooser
- optionally return replacement/insertion text
- preserve the selected range, cancellation integrity, and natural focus return

Must not own:
- duplicate matching logic
- canonical identity rules
- persistence rules

The adapter direction is accepted in [ADR 001](decisions/001-notes-integration.md). The Exercise 02 spike validates the AppKit Service/pasteboard interaction shape but is not production code. Packaging, signing, distribution, shortcut design, and identical-text feedback remain open implementation concerns.

### Exercise library
Responsibilities:
- canonical exercise records
- preferred display names
- aliases
- durable user-confirmed identity relationships

### Resolver
Responsibilities:
- normalization
- exact alias lookup
- candidate generation
- confidence/ranking
- distinguishing automatic matches from suggestions requiring confirmation

### Blocks
Responsibilities:
- reusable groups of exercises
- display/insertion formatting
- later ranking based on context/history

### Future client history
Must reference canonical exercise IDs rather than exercise-name strings.

## Validated architecture risk

The macOS Service interaction was tested in actual Apple Notes usage on macOS 26.6. The AppKit fallback passed the approved cold, warm, cancellation, integrity, and focus gates; the Automator Quick Action did not satisfy the complete contract.

This supports retaining Notes as the initial workspace while keeping the resolver and domain logic independent. Revisit the decision using ADR 001's falsifiable triggers rather than treating one successful spike as permanent proof.
