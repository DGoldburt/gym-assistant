# Architecture

Status: initial design hypothesis. Expect this document to evolve through the tutorial.

## Architectural principle

Apple Notes is an input/workspace adapter. It must not contain the core business logic.

Conceptual structure:

    Apple Notes
        |
        v
    macOS Service / Quick Action adapter
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

Must not own:
- duplicate matching logic
- canonical identity rules
- persistence rules

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

## Early architecture risk

The macOS Service interaction must feel fast enough in actual Apple Notes usage.

Therefore Exercise 02 is an architecture spike and may produce disposable code.
