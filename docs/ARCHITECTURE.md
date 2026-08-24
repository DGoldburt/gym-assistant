# Architecture

Status: the Notes adapter direction is validated by ADR 001. The initial exercise-identity persistence boundary is implemented; resolver, blocks, tendencies, and client history remain design hypotheses that will evolve through the tutorial.

## Architectural principle

Apple Notes is an input/workspace adapter. It must not contain the core business logic.

Conceptual structure:

    Apple Notes --> AppKit macOS Service adapter --> Exercise Search --> Exercise Library
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
- preserve the selected range, cancellation integrity, and natural focus return

Must not own:
- duplicate matching logic
- canonical identity rules
- persistence rules

The adapter direction is accepted in [ADR 001](decisions/001-notes-integration.md). The Exercise 02 spike validates the AppKit Service/pasteboard interaction shape but is not production code. Packaging, signing, distribution, shortcut design, and identical-text feedback remain open implementation concerns.

### Exercise library
Responsibilities:
- stable opaque exercise identity
- one required, owned preferred display name per exercise
- durable confirmed names that act as aliases
- globally unambiguous exact normalized-name ownership

The initial Swift package persists this boundary in SQLite. A deferred composite foreign key prevents an exercise from committing without an existing preferred name owned by that exercise. Human-facing output uses the preferred name, optionally with a short UUID prefix for diagnostic disambiguation; bare or name-derived IDs are not the ordinary interface.

The library's current normalizer is deliberately minimal and supports only the exact-lookup persistence contract. Fuzzy similarity, semantic alias inference, contextual ownership, variant relationships, program/client context, taxonomy, and history remain outside this boundary.

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

## Validated architecture risk

The macOS Service interaction was tested in actual Apple Notes usage on macOS 26.6. The AppKit fallback passed the approved cold, warm, cancellation, integrity, and focus gates; the Automator Quick Action did not satisfy the complete contract.

This supports retaining Notes as the initial workspace while keeping the resolver and domain logic independent. Revisit the decision using ADR 001's falsifiable triggers rather than treating one successful spike as permanent proof.
