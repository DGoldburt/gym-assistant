# Architecture

Status: the Notes adapter direction is validated by ADR 001. The initial
exercise-identity persistence boundary, deterministic confirmed-name resolution,
candidate generation, explicit suggestion confirmation, read-only autocomplete
search, empty-cursor Notes autocomplete interaction, and the reusable exercise-
identity review core are implemented. Personal-library import, search-query
transformations, blocks, tendencies, and client history remain later slices or
design hypotheses.

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
- receive selected text or an empty-cursor invocation
- invoke library/search workflows
- display a lightweight chooser
- optionally return replacement/insertion text
- preserve the selected range, cancellation integrity, and natural focus return

Must not own:
- duplicate matching logic
- canonical identity rules
- persistence rules

The adapter direction is accepted in [ADR 001](decisions/001-notes-integration.md). The Exercise 02 spike validates the AppKit Service/pasteboard interaction shape but is not production code. The local development Service now uses Option-Command-G; packaging, durable signing, external distribution, and identical-text feedback remain open implementation concerns.

The `GymAssistantNotesService` executable is wired to the real core workflow and
Application Support SQLite library. Its `Gym Assistant: Review Selection` entry
performs deterministic bypass, explicit identity review through a Link Existing
action, and same-panel new-exercise creation. Its separate `Gym Assistant` entry
supports empty-cursor autocomplete: focused query input, at most five identity-
deduplicated results, keyboard alias expansion, exact cursor insertion, raw-query
fallback, and cancellation without writes. The Service owns no ranking or identity
rules. Packaging, signing, and distribution outside the local development install
remain open concerns.

### Exercise library
Responsibilities:
- stable opaque exercise identity
- one required, owned preferred display name per exercise
- durable confirmed names that act as aliases
- globally unambiguous exact normalized-name ownership

The initial Swift package persists this boundary in SQLite. A deferred composite foreign key prevents an exercise from committing without an existing preferred name owned by that exercise. Human-facing output uses the preferred name, optionally with a short UUID prefix for diagnostic disambiguation; bare or name-derived IDs are not the ordinary interface.

The library's current normalizer is deliberately minimal and supports only the
exact-lookup persistence contract. Fuzzy similarity may rank review candidates but
cannot establish identity. Semantic alias inference, contextual ownership, variant
relationships, program/client context, taxonomy, and history remain outside this
boundary.

### Resolver
Responsibilities:
- normalization
- exact alias lookup
- candidate generation
- confidence/ranking
- distinguishing automatic matches from suggestions requiring confirmation

The deterministic slice resolves only exact or cosmetically normalized confirmed
names. Cosmetic normalization is limited to case, whitespace, and one trailing
period or exclamation point; other punctuation remains meaningful. Abbreviations
and corrected spellings establish identity only after they have been stored as
confirmed names.

The candidate-generation slice ranks a supplied candidate vocabulary using lexical
similarity and a small, explicit review-only equivalence vocabulary. It never
returns an automatic identity match. A protected-modifier policy excludes known
conflicts from the review list, and the fixture harness reports a protected
candidate leak separately from an automatic false merge.

An explicit confirmation boundary turns an accepted suggestion into a
`userConfirmed` exercise name through the library's existing ownership-checked
persistence API. Rejection performs no write. The next lookup therefore uses the
deterministic confirmed-name path rather than similarity. Candidate discovery
across the persisted library remains outside this slice.

The resolver supplies identity evidence about wording that already exists. It is
separate from autocomplete search, which retrieves an exercise for insertion and
does not by itself create identity knowledge.

### Autocomplete search

The core autocomplete search reads preferred and confirmed names from the exercise
library, ranks exact, prefix, token-prefix, lexical, and lowest-priority fuzzy text
evidence, and returns at most one result per stable exercise identity. A result
exposes its preferred display name and confirmed aliases so the UI can insert
either deliberately. Search performs no library writes. Search and identity review
use the same underlying text-candidate ranker and the same approved equivalence
evidence; autocomplete adds a more permissive threshold because retrieval is
reversible. Known protected modifier conflicts are excluded by both. New vocabulary
transformations still require separate evidence and approval before becoming part
of the shared ranker.

Empty-query and unmatched-query insertion behavior belongs to the application/UI
workflow, not this domain search component. The Notes adapter consumes this search
through a read-only boundary; only the separate selected-text review workflow can
persist an alias.

### Exercise identity review

Responsibilities:
- accept an observed exercise name with source and provenance
- gather review candidates and visible evidence from exact lookup, deterministic
  transformations, lexical similarity, and other explicitly approved signals
- expose meaningful modifier conflicts instead of hiding uncertainty
- support explicit link, create, keep-separate, and defer decisions
- apply approved identity writes through the exercise library's persistence boundary
- preserve enough decision provenance and deferred state for later audit

The review component coordinates evidence and authoritative user decisions.
Automatic identity reuse is limited to deterministic normalized lookup of an
already-confirmed name and performs no write. Fuzzy scores, abbreviations,
transformations, modifier relationships, and AI-produced source files may surface
evidence but cannot establish identity.

For a staged observation, the implemented decisions are Link, Create, and Defer.
Link adds the preserved observation as an `importedConfirmed` name through an
ownership-checked transaction. Create accepts no editable name and makes the
observation itself the sole initial preferred name, preventing semantic drift
during review. Defer persists the unresolved observation and evidence snapshot
without changing the exercise library. A separate audit-facing Keep Separate
operation records that two existing exercise IDs remain distinct; it is not an
import decision and does not merge or create identities.

Resolver fixture category and human-review disposition are independent.
`MUST_NOT_MATCH` continues to prohibit automatic identity. The review policy may
still expose a prescription-bearing comparison, such as short- versus long-lever
Copenhagen, as linkable with confirmation because both confirmed names remain
selectable aliases. Fixture-established identity conflicts, such as lateral versus
reverse lunge, are visible but non-linkable. There is no separate Exercise Family
entity; the stable Exercise and its confirmed names are the current grouping
envelope.

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
