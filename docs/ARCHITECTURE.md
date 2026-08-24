# Architecture

Status: initial design hypothesis. Expect this document to evolve through the tutorial.

## Architectural principle

Apple Notes is an input/workspace adapter. It must not contain the core business logic.

Conceptual structure:

    Apple Notes --> macOS adapter --> Exercise Search --> Exercise Library
                       |                                  + Alias Knowledge
                       +--> selected-text hygiene --+
                                                   |
    Personal-library file --> Import adapter ------+--> Exercise Identity Review
                                                   |           |
    Completed-program review adapter (later) ------+           +--> Resolver evidence
    Manual library-audit adapter (later) ----------+           +--> Exercise Library writes

    Saved Blocks / Programming Tendencies / Client History (later)
        reference stable Exercise Library identities

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

The resolver supplies identity evidence about wording that already exists. It is
separate from autocomplete search, which retrieves an exercise for insertion and
does not by itself create identity knowledge.

### Exercise identity review

Responsibilities:
- accept an observed exercise name with source and provenance
- gather review candidates and visible evidence from exact lookup, deterministic
  transformations, lexical similarity, and other explicitly approved signals
- expose meaningful modifier conflicts instead of hiding uncertainty
- support explicit link, create, keep-separate, and defer decisions
- apply approved identity writes through the exercise library's persistence boundary
- preserve enough decision provenance and deferred state for later audit

The review component coordinates evidence and authoritative user decisions. It
must not infer an alias, merge identities, or choose a preferred name solely from
a score, transformation, or AI-produced source file. Keeping two similar exercises
separate is an explicit valid outcome, not a failed match.

The identity review is independent of the source adapter. Its first adapter stages
a personal-library import. That adapter owns source parsing, row validation, dry-run
preview, transactional and idempotent batch behavior, and import reporting. It must
not own candidate semantics or identity rules.

Later completed-program hygiene and manual library-audit adapters may supply their
own occurrence context while reusing the same candidate evidence and decision
boundary. Merging two exercise IDs that already own aliases or have downstream
references is a separate future operation; it is not equivalent to linking a
staged observed name before import.

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
