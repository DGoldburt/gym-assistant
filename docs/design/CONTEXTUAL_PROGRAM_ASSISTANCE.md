# Contextual Program Assistance

Status: proposed design exploration. This document records product evidence,
working hypotheses, and decisions still required. It does not approve an
implementation or change the active product slice.

2026-10-12 design update: [session scratchpad with margin conversation](SESSION_SCRATCHPAD.md)
is the user-selected direction. It replaces this document's proposed first-slice
apply/edit/dismiss behavior with manual session editing, fresh scratchpad context,
and minimal library decoration. OpenAI API use and note/profile transmission were
subsequently approved; credential, retention, model/spend, and optional web choices
remain open. Draft ownership and handoff were refined in the selected scratchpad
design; the earlier proposal below is historical.

Research package added 2026-10-10:
[representative evidence and philosophy/profile boundaries](CONTEXTUAL_ASSISTANCE_EVIDENCE.md)
and [keyboard-first interaction proposal](CONTEXTUAL_ASSISTANCE_UI.md). The private
companion retains the Training Philosophy source and approved personal preference
seed. These additions refine the proposed design without promoting it to Now.

## User outcome

While writing a program in Apple Notes, the user can ask the kind of contextual
programming questions currently asked in ChatGPT without repeatedly pasting the
program or manually telling the assistant which suggestions were adopted. The user
can selectively apply, revise, or reject suggestions, and the next exchange reasons
from the resulting Notes draft.

Apple Notes remains the authoritative editor and program document. The Gym
Assistant supplies context, conversation, and proposed edits; it does not become a
second program editor or silently change the note.

## Evidence and current friction

A private review of recent programming conversations found the same loop across an
individual program, a youth program, and a group-class program:

1. The user supplies a current program draft and asks a programming question.
2. The assistant reasons across the draft, prior work, equipment, symptoms or other
   constraints, and offers several alternatives.
3. The user accepts some ideas, rejects or modifies others, and manually edits Notes.
4. The user must then resupply the changed draft before the conversation can continue
   accurately.

Private program text, client identity, health details, and links used as evidence
must remain outside this reusable design branch.

## Design question 1: what does accepting a suggestion mean?

The evidence is sufficient to reject a narrow "choose an exercise and insert it at
the cursor" model. The accepted unit varies: it can be one exercise, a pairing, a
complete block, a replacement for existing text, or an edited version of the
assistant's suggestion. The intended location may be the invocation cursor, a named
slot such as B2, an existing block, or another unfilled part of the note.

The working hypothesis is an **editable text-edit proposal**. A proposal is a
reviewable change to the current Notes snapshot, not an exercise-identity decision.
It contains:

- the proposed text;
- an explicit target anchored to the Notes snapshot used to generate it;
- an operation such as insert or replace;
- a short explanation of why it fits;
- optional references to stable exercise IDs when a proposed exercise is already in
  the local library.

The user may apply the proposal unchanged, edit it and then apply it, dismiss it, or
ask a follow-up question. Multiple proposals in one answer remain independently
actionable so accepting one does not accept all of them. Before applying any
proposal, the adapter must verify that its target still matches the relevant Notes
snapshot. A changed target requires regeneration or deliberate user resolution.

This hypothesis deliberately separates four meanings:

- Applying text says, "put this in this program."
- Linking an alias says, "this wording has this durable exercise identity."
- Creating an exercise says, "add a new durable library identity."
- Rejecting a proposal says only, "not this suggestion in this context."

### Questions to validate with interaction examples

- Is editing inside the proposal surface faster than inserting into Notes and
  editing there?
- Should the first slice allow only one contiguous insert or replacement per
  proposal, or does a useful block routinely require a coordinated multi-location
  change?
- When no reliable target can be inferred, should the assistant copy proposed text,
  insert at the invocation cursor, or ask the user to choose a destination?
- What minimum visual diff is needed for a block replacement to feel safe without
  turning the companion into an editor?

## Design question 2: what runs the conversational reasoning?

The current Gym Assistant has no chat model. Its implemented behavior is local,
deterministic exercise-library and resolver logic connected through a Notes adapter.
Adding conversation therefore requires an explicit model-provider and data-boundary
decision.

The leading prototype hypothesis is a hosted model through the OpenAI Responses API,
behind a provider-neutral `ProgrammingAssistant` boundary owned by the application
layer. The reason to prototype with a hosted OpenAI model is that the desired
behavior was observed in ChatGPT, and the Responses API supports multi-turn input,
structured output, and explicit tools. A local model remains a worthwhile later
privacy/offline experiment, but it should not be assumed capable enough until the
same representative programming cases are evaluated against both options.

The model's knowledge source is not a choice between "exercise library" and "the
web." The proposed context order is:

1. The current Notes snapshot and cursor or selected target are authoritative for
   the program being edited.
2. Locally retrieved exercise-library records supply known identities, preferred
   display names, and aliases. The first prototype should retrieve relevant records
   locally rather than upload the entire library as a hosted knowledge base.
3. Approved program or client context may be added later through separate,
   inspectable context providers.
4. The model may use its general pretrained knowledge to generate programming ideas.
   Suggestions not found in the local library must be visibly distinguishable and
   must not create library identities automatically.
5. Live web search is off by default. A later explicit "search the web" action may
   enable it for research-oriented questions and must expose sources. Ordinary
   program completion should not silently browse.

This order preserves the broad reasoning that makes the existing conversations
useful without pretending the personal library contains all useful exercise
knowledge. It also prevents general model knowledge from overriding the user's
actual program or confirmed exercise identities.

### Privacy and deployment questions

Program notes may contain names, symptoms, medical context, and training history.
Before an API prototype sends real notes, the design must settle:

- which note regions are transmitted and shown in a context preview;
- whether names or other direct identifiers are redacted locally;
- whether the first test uses only synthetic or deliberately de-identified programs;
- where the API credential lives and whether the single-user app calls a hosted
  service directly or through a small backend;
- whether conversation state is stored locally, by the provider, or reconstructed
  for each request;
- retention settings, deletion behavior, usage cost, failure behavior, and an
  offline/no-send mode.

The initial OpenAI API evaluation should set response storage deliberately rather
than rely on defaults. API data is not used to train OpenAI models by default, but
default abuse-monitoring and application-state retention still require an informed
privacy decision before real client material is transmitted.

## Proposed first-slice boundary

The smallest slice worth testing is one active Notes document and one short-lived
programming session. From an empty cursor, the user asks a free-form question. The
assistant receives a previewed Notes snapshot and a locally retrieved subset of the
exercise library, returns conversational advice plus zero or more editable proposals,
and lets the user apply one proposal with the keyboard. The next request refreshes
the Notes snapshot so the assistant sees the accepted change.

The slice does not include durable client history, load recommendations, automatic
web research, automatic library creation, autonomous note edits, or a general-purpose
replacement for ChatGPT.

## Success criteria requiring approval

Candidate criteria for the first slice are:

- After beginning a programming session, the user does not copy and paste the
  current program into the assistant.
- The user can ask a contextual question and inspect proposals without using the
  mouse.
- One proposal can add an exercise or a contiguous block, or replace one contiguous
  range, at a visible target.
- The user can edit proposed text before applying it.
- Applying one proposal changes only its reviewed target in Notes.
- The next request uses the revised Notes content without the user narrating the
  accepted change.
- A stale target cannot be silently overwritten.
- Applying or rejecting a proposal creates no implicit exercise identity, alias, or
  global preference.
- Web access remains visibly off unless the user explicitly invokes it.

These are candidates, not approved success criteria. The next design checkpoint is
to review representative accept, edit-before-accept, replace, and block-insertion
examples, then choose the first proposal operations and the model/privacy experiment.

## Decisions still required

1. Promote contextual program assistance from a Next candidate to the active slice,
   and decide whether it precedes the client-history workstream.
2. Approve the first proposal operations and the user interaction for editing before
   apply.
3. Approve a hosted OpenAI API prototype, a local-model comparison, or another model
   provider experiment.
4. Approve the context preview, redaction, retention, credential, cost, and web-access
   boundaries before using real program notes.
5. After those decisions, record any ADR-level choices and write a self-contained
   ExecPlan before implementation.
