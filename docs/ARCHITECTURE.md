# Architecture

Status: the Notes adapter direction is validated by ADR 001. The initial
exercise-identity persistence boundary, deterministic normalization and
normalized-name lookup, scored candidate generation, explicit suggestion
confirmation, read-only autocomplete
search, empty-cursor Notes autocomplete interaction, and the reusable exercise-
identity review core are implemented. Personal-library import, search-query
transformations, blocks, tendencies, and client history remain later slices or
design hypotheses.

Observation ingestion is separated from identity review by
[ADR 002](decisions/002-non-blocking-observation-ingestion.md). The complete source
may be stored with provenance while identity decisions remain incremental,
dismissible, and resumable.

## Architectural principle

Apple Notes is an input/workspace adapter. It must not contain the core business logic.

Conceptual structure:

    Apple Notes --> AppKit macOS Service adapter --> Exercise Search --> Exercise Library
                       |                                  + Durable Name Knowledge
                       +--> selected-text hygiene -----------------------+
                                                                         |
    Personal-library source ------+                                      |
    Completed program(s) later ---+--> Observation Ingestion/Store ------+--> Exercise Identity Review
                                  |                                              |
                                  +--> Exercise-observation extractor (later)    +--> Resolver evidence
                                                                                 +--> Exercise Library writes

    Manual library-audit adapter (later) --> Exercise Identity Review of existing IDs

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
deduplicated results, keyboard alternate-name expansion, exact cursor insertion,
raw-query
fallback, and cancellation without writes. The Service owns no ranking or identity
rules. Packaging, signing, and distribution outside the local development install
remain open concerns.

### Exercise library
Responsibilities:
- stable opaque exercise identity
- durable exercise names owned by one exercise identity
- exactly one durable name per exercise with the preferred/default display role
- globally unambiguous exact normalized-name ownership

The initial Swift package persists this boundary in SQLite. A deferred composite foreign key prevents an exercise from committing without an existing preferred name owned by that exercise. Human-facing output uses the preferred name, optionally with a short UUID prefix for diagnostic disambiguation; bare or name-derived IDs are not the ordinary interface.

The library's current normalizer is deliberately minimal and supports only the
normalized-name lookup persistence contract. Fuzzy similarity may rank review
candidates but cannot establish identity. Semantic name-ownership inference,
contextual ownership, variant
relationships, program/client context, taxonomy, and history remain outside this
boundary.

### Resolver
Responsibilities:
- deterministic normalization
- normalized-name lookup across all durable exercise names
- scored candidate generation with supporting evidence
- candidate relationship policy
- workflow-independent resolver results

The resolver layers are:

    Input text
        |
        v
    Deterministic normalization
        |
        v
    Normalized-name lookup across all durable exercise names
        |
        +-- match --> Exercise identity
        |             evidence: normalized-name match
        |             score: 1.000
        |
        +-- no match --> Scored candidate generation
                             |
                             +-- lexical similarity
                             +-- morphological similarity
                             +-- explicit equivalence rules
                             |
                             v
                        Candidates scored below 1.000
                             |
                             v
                        Candidate relationship policy
                             |
                             +-- linkable
                             +-- compatible prescription difference
                             +-- protected/non-linkable conflict

Deterministic normalization removes only differences that are guaranteed cosmetic.
It is limited to case, whitespace, and one trailing period or exclamation point;
other punctuation remains meaningful. For example, ` FRONT   SQUAT! ` and
`Front Squat.` normalize to the same lookup key. Normalization does not
singularize words, correct spelling, expand abbreviations, or encode exercise
vocabulary.

Normalized-name lookup compares that key with every durable exercise name. A
preferred name and an alternate name are the same persisted kind of name; the
preferred flag only selects the default display and insertion wording. A lookup
match returns the owning exercise identity with `normalized-name match` evidence
and score `1.000`.

Scored candidate generation runs only when normalized-name lookup finds no match.
Each generated candidate carries the evidence supporting its score. Lexical
similarity covers token overlap, containment, prefix similarity, and edit
similarity. Morphological similarity covers narrowly scoped linguistic forms such
as `Jump` and `Jumps`. Explicit equivalence rules cover reviewed vocabulary such as
`DB` and `Dumbbell`, `1-legged` and `1-leg`, or `Australian Row` and
`Aussie Pull-up`. Approval of such a rule authorizes candidate scoring, not durable
identity. No non-authoritative signal or combination of signals may score `1.000`;
the shared scorer caps such results below `1.000`, and the fixture harness reports
an authoritative-score leak if a review candidate reaches the reserved score.

Candidate relationship policy annotates or constrains a generated comparison; it
does not manufacture similarity. A compatible prescription difference, such as
`Touch-Down with RNT` versus `Touch-Down`, may remain linkable while preserving the
observed wording as a durable selectable name. A protected identity conflict, such
as `Lateral Lunge` versus `Reverse Lunge`, is excluded from ordinary suggestions or
shown explicitly as non-linkable evidence in an identity-review interface. The
fixture harness reports a protected candidate leak separately from an automatic
false merge.

Representative layer contracts and fixtures are:

- deterministic normalization and normalized-name lookup: `Front Squat!` matches
  stored `Front Squat`; ` FRONT   SQUAT ` matches stored `Front Squat`; a stored
  `SL RDL` alternate name returns its owning exercise
- scored candidate generation: `Paloff Press` suggests `Pallof Press` from lexical
  evidence; `Box Jumps` suggests `Box Jump` from morphological evidence;
  `Australian Row` suggests `Aussie Pull-up` from an explicit equivalence rule
- candidate relationship policy: `Touch-Down with RNT` and `Touch-Down` carry a
  compatible prescription annotation; `Lateral Lunge` and `Reverse Lunge` carry a
  protected, non-linkable conflict

The morphology examples and any new explicit equivalence rules describe the
evidence category and required fixture behavior; each rule still requires separate
approval and implementation before the resolver uses it.

An explicit confirmation boundary turns an accepted suggestion into a durable
exercise name through the library's existing ownership-checked persistence API.
Rejection performs no write. The next lookup of that observed wording therefore
uses normalized-name lookup rather than scored candidate generation.

The resolver supplies identity evidence about wording that already exists. It is
separate from autocomplete search, which retrieves an exercise for insertion and
does not by itself create identity knowledge.

The workflows interpret the same resolver results differently:

                              Shared resolver
                                    |
            +-----------------------+-----------------------+
            |                       |                       |
            v                       v                       v
    Autocomplete search      Selected-text flow      Import/completed-program
                                                     observation processing

    Normalized match         Normalized match        Normalized match
    ranks first at 1.000     resolves without        recognizes the existing
                             opening review          exercise and avoids review

    Other candidates         Other candidates        Other observations enter
    rank below 1.000         enter identity review   identity review
            |                       |                       |
            v                       +---- Link/Create/Defer-+
    User selects wording
    for insertion; no
    identity write

Here, exercise identity review means the interactive Link, Create, or Defer
decision workflow for unresolved observed wording. Normalized-name lookup is a
resolver operation used before that interaction, not a separate workflow.

For example, in the **import or completed-program observation-processing
workflow**:

    Observation: Box Jumps
        |
        v
    Deterministic normalization
        |
        v
    Normalized-name lookup: no match
        |
        v
    Scored candidate: Box Jump
    evidence: morphological similarity plus lexical similarity
    score: below 1.000
        |
        v
    Exercise identity review: Link / Create / Defer

### Autocomplete search

The core autocomplete search reads all durable exercise names from the library and
returns at most one result per stable exercise identity. A normalized-name match
ranks first with score `1.000`; all other scored candidates rank below it. A result
exposes the preferred/default name and the exercise's other durable names so the UI
can insert any of them deliberately. Search performs no library writes. Search and
identity review use the same underlying scored candidate generator and explicit
equivalence evidence. Autocomplete may display candidates at a lower minimum score
than identity review because selecting a search result inserts wording but does not
create a durable name relationship. Known protected identity conflicts are
excluded by both. New equivalence rules require separate evidence and approval
before becoming part of the shared generator.

Empty-query and unmatched-query insertion behavior belongs to the application/UI
workflow, not this domain search component. Autocomplete is fully read-only: Return
inserts the selected durable name, and no autocomplete action changes the internal
preferred-name pointer. Only an identity-review workflow can persist a durable
exercise-name relationship. The preferred-name constraint remains an internal
fallback that prevents a nameless exercise; changing it is deferred until a
library-maintenance workflow demonstrates a user need.

### Exercise identity review

Responsibilities:
- accept an observed exercise name with source and provenance
- use normalized-name lookup before opening review
- gather scored candidates with visible supporting evidence for unresolved wording
- expose meaningful modifier conflicts instead of hiding uncertainty
- support explicit link, create, keep-separate, and defer decisions
- apply approved identity writes through the exercise library's persistence boundary
- preserve enough decision provenance and deferred state for later audit

The review component coordinates evidence and authoritative user decisions. A
normalized-name match recognizes an existing identity without opening interactive
review or writing a new name. Scored similarity, morphology, explicit equivalence
rules, prescription relationships, and AI-produced source files may surface
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
Copenhagen, as linkable with confirmation because both durable names remain
selectable. Fixture-established identity conflicts, such as lateral versus
reverse lunge, are visible but non-linkable. There is no separate Exercise Family
entity; the stable Exercise and its durable names are the current grouping
envelope.

The identity review is independent of the source adapter. Its first adapter stages
a personal-library source. Import and completed-program adapters supply durable
observations to the same non-blocking queue and preserve their own ingestion record,
occurrence evidence, and provenance. Pending or deferred observations do not enter
autocomplete and do not block program writing. The reviewer may dismiss and resume
the queue; each explicit identity decision is independently transactional and
idempotent.

Exercise 10 exposes this queue through a separate Gym Assistant review window. The
existing autocomplete panel contains a visible, keyboard-operable Review Library
action, so the learner can enter review without Terminal or another global
shortcut. Opening review releases the Notes Service request; the review window can
then stay open independently. Closing it preserves queue position and returns focus
to Notes. Administrative ingestion, backup, dry-run, and diagnostics remain in the
local command-line runner.

Autocomplete and observation review share one AppKit ranked-candidate chooser for
identity-deduplicated rows, winning-name presentation, name disclosure, selection,
and evidence presentation. The collapsed row displays the highest-scoring durable
name rather than always displaying the preferred name. Expanding it shows every
other durable name without exposing the internal preferred/default designation.
Match reasons use compact labels and the collapsed row reports the number of aliases
without repeating a confirmed-alias label on every durable name. Their controllers
remain separate: autocomplete owns its query and read-only insertion result, while
observation review owns provenance,
queue state, and explicit Link/Create/Skip transactions. Autocomplete begins with
no selected candidate so Return preserves and inserts the query; Down Arrow
deliberately selects the top result. Review may preselect its top candidate because
Link remains a separate explicit action. The chooser reserves Left and Right Arrow
for alias disclosure; review-specific Back and Skip use Command-Z and Command-S.
An autocomplete request also self-cancels after 105 seconds, before the synchronous
Service's 120-second deadline, so an abandoned chooser returns Notes cleanly instead
of producing a Service timeout.

Gym Assistant remains an accessory application and does not enter the Dock or
Command-Tab switcher. A rejected Task C experiment temporarily promoted it to a
regular application, but that caused a distracting launch bounce and still could
not restore Notes after the learner consulted another app. The synchronous Service
request prevents Notes from accepting ordinary programmatic activation while
autocomplete is open. Leaving a chooser open across application switching therefore
requires either a different asynchronous insertion adapter or explicit
Accessibility control; window ordering alone cannot provide it.
Autocomplete remains owned by the synchronous Notes Service invocation that opened
it. Live testing shows Notes queues another invocation until the first returns and
does not redirect the pending output after a cross-note attempt. Supporting several
simultaneous note-bound autocomplete windows therefore requires a different
asynchronous insertion adapter with a durable note-and-cursor context; it is not a
window-management change and must be spiked before replacing the safe Service path.

The personal-library adapter owns CSV parsing, row validation, source fingerprinting,
and import reporting. It must not own candidate semantics or identity rules. A later
completed-program adapter may use a reusable observation extractor before staging;
that extractor identifies exercise-like wording in mixed program text, preserves
verbatim evidence and location, and makes no durable name or exercise-identity decision.

Manual library-audit adapters may reuse candidate evidence while presenting two
existing exercise IDs and audit-specific Merge or Keep Separate operations. Merging
IDs that already own durable names or downstream references remains a separate future
operation; it is not equivalent to linking a staged observed name.

### Observation ingestion and provenance

Observation ingestion and identity resolution are separate lifecycles. A source
may be ingested transactionally even while some or all observations remain pending.
Later Link or Create decisions atomically update one observation and the exercise
library; Defer records an intentional postponement without creating identity.

One observation can occur in more than one note, import, or completed program, so
provenance must not be flattened into a single adapter/reference string. The minimal
durable relationship is an ingestion record, a staged observation, and one or more
occurrence/evidence records that connect the observation to source locations and
counts. This provenance belongs to the observation workflow, not as additional
required fields on `Exercise` or `ExerciseName`.

Extraction and identity review have different ground truth. Extraction asks whether
and where program text contains an exercise observation. Identity review asks what
stable exercise, if any, owns that preserved wording. Task A extraction decisions
can train and test the future extractor. Task C Link/Create/Defer outcomes can reveal
useful error clusters, but they must not be relabeled automatically as extraction
truth; especially, Defer may indicate identity uncertainty, unsuitable wording, or
an extraction-boundary problem and requires reason review.

The private extractor-feedback exporter joins the Task A extraction audit to all
current Task C observation outcomes by source fingerprint and deterministically
normalized reviewed wording. It reports unmapped audit rows rather than guessing,
includes occurrence provenance and initial candidate snapshots, and publishes a
direct skipped-observation index. Review decisions accumulate in SQLite; the
owner-readable private packet is a regenerable snapshot and never enters Git.

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
