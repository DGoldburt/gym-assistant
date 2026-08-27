# Exercise 11 — Field Feedback Loops and Resolver Improvement

## Why we're doing this

Exercise 10 made the product useful enough to generate real field evidence, including
resolver-ordering surprises and cross-application focus friction. Fixing every report
as it appears would make development reactive and obscure whether the product is
improving. This exercise builds a bounded loop that collects evidence during ordinary
use, evaluates mechanical failures automatically, preserves subjective signals with one
action, and turns an approved batch into regression fixtures.

The learning objective is to understand how professional continuous-improvement loops
separate collection, evaluation, prioritization, intervention, and comparison. The loop
may run unattended, but it may not silently make product or identity decisions.

## Codex skill

- designing privacy-conscious local product instrumentation
- converting field observations into replayable evaluation cases
- distinguishing unattended evidence collection from autonomous product changes
- measuring whether a bounded intervention improved selected signals

## Skills practiced

- `frame-work` — Frame a bounded task and stopping rule
- `verify` — Build an evidence-producing delivery loop
- `set-boundaries` — Separate automatic evaluation from human product judgment
- `record-decisions` — Preserve dispositions so findings are not forgotten

## Starting state

Exercise 10 imported a private observation source into a resumable identity-review
queue and preserved extraction and review feedback. Field use then exposed at least
these reproducible signals:

- wording containing `DL` may not be classified as a hinge, allowing a squat candidate
  to escape protected-conflict treatment
- an exact `DB` to `Dumbbell` transformation is review evidence rather than automatic
  identity, has no displayed numeric score, and may rank below weaker lexical evidence
- lexical rows can appear out of score order because mixed evidence types do not have a
  complete, stable ordering contract
- leaving the synchronous Gym Assistant review window and returning to Notes is common
  enough that the current focus limitation is materially annoying

## Product-scope guard

This exercise instruments and improves an already-approved product slice. It does not
silently establish exercise identity, broaden the deterministic name normalizer, add
movement taxonomy, implement client history, or let a scheduled agent edit or merge the
product unattended. Deciding whether `DB` expansion may ever establish identity remains
a separate explicit product decision; current behavior requires human confirmation once
and then relies on the durable confirmed alias.

The first improvement batch is limited to approved candidate classification, ordering,
and evidence presentation. New findings enter the durable queue rather than expanding
the active batch. The Notes focus issue receives its own ExecPlan because replacing the
synchronous Service boundary with asynchronous, context-safe insertion has a larger
permission and architecture surface.

## Reference model

Ryan Lopopolo's *Harness engineering* describes a team shifting scarce human attention
from direct implementation and repeated QA toward making the application, logs, metrics,
repository knowledge, and constraints legible to agents. Repeated human taste becomes
documentation, tooling, fixtures, or mechanically enforced invariants; background tasks
perform targeted cleanup, while humans still prioritize work and translate user feedback
into acceptance criteria. This exercise applies that pattern at personal-project scale,
without assuming the article's organizational throughput or autonomy is automatically
appropriate here.

OpenAI's scheduled-task guidance says to test a prompt manually before scheduling it,
review its first runs, use the narrowest sandbox permissions, and prefer an isolated Git
worktree when a task may change files. Scheduled runs appear in a durable inbox. Exercise
11 therefore starts with a read-only evaluator, makes unchanged runs quiet, and withholds
code or exercise-library mutation from the schedule.

## Task A — Define the field-signal contract

Inspect the Exercise 10 reports and current candidate pipeline. Define the smallest
private local event record that reconstructs what the user saw without requiring a
written bug report: workflow, observation or query, ordered exercise identities and
matched names, evidence kind, score when one exists, linkability, selection rank,
decision, Skip or Back action, timing, and application deactivation or return signals.
Retain source wording only in a private ignored location and never place personal Notes
content in Git.

Specify two complementary inputs. Passive capture records every eligible interaction.
A one-action **Flag this result** control snapshots the current interaction as
subjectively troublesome without demanding a category or explanation. Define automatic
checks for score-order inversions, a deterministic transformation ranked below lexical
evidence, and a known protected conflict presented as linkable.

Define a durable disposition ledger with `new`, `reproduced`, `accepted-for-batch`,
`deferred`, and `resolved` states. Every entry needs a stable case identifier, first and
last observation time, occurrence count, current disposition, and any regression-fixture
reference. This ledger—not chat memory—prevents findings from being forgotten.

### STOP / REVIEW — Feedback-loop contract

Inspect the event schema, privacy boundary, flag interaction, automatic checks, metrics,
ledger states, and fixed first batch. Decide whether collection is low-friction enough
to leave enabled and whether the loop distinguishes objective anomalies from subjective
annoyance.

Teach back: Why can evidence collection and evaluation run unattended while prioritizing
or changing exercise identity still requires a foreground gate?

## Task B — Implement capture, replay, and unattended evaluation

Implement the approved local event store, flag action, deterministic evaluator, and a
single command that produces a bounded summary. The summary reports at least top-result
selection rate, median selected rank, Skip and Back rates, flags, score-order violations,
protected-conflict leaks, and application deactivation/return evidence. Empty runs and
repeated evaluation must be safe and must not duplicate ledger occurrences.

Create replay fixtures for the accepted Exercise 10 examples. A replay is a frozen input
and expected safety or ordering property, not a frozen copy of the user's private
library. Prove that the collector cannot write aliases, create exercises, or mutate
review decisions.

Run the evaluator manually before scheduling it. Once its output is accurate and
reviewable, configure the smallest unattended cadence available locally. A scheduled
task may read the private event store and update an isolated report or ledger, but it
must not change source code, the live exercise library, success criteria, or issue
dispositions. Its inbox should report only new or materially changed signals and say
clearly when no action is needed. Keep the computer and desktop app requirements,
sandbox permissions, and recovery procedure explicit.

### STOP / REVIEW — Running feedback loop

Inspect a real interaction record, a flagged record, the generated report, a repeated
idempotent run, and the unattended-task configuration. Trigger one run manually before
accepting the schedule. Decide whether another person or agent could discover every open
finding from durable state without relying on this conversation.

Teach back: What makes this an operating feedback loop rather than telemetry that merely
accumulates?

## Task C — Improve one bounded resolver batch

Apply only the batch approved in Task A. Add `DL` adversarial cases and correct protected
classification without treating arbitrary abbreviations as identity. Define a total,
stable ordering across transformation, prescription, conflict, and lexical evidence;
within a scored tier, higher scores must never appear below lower scores. Make categorical
evidence understandable without inventing a misleading score. Preserve visible,
non-linkable protected conflicts in identity review.

Replay the baseline and compare the same metrics before and after. New observations are
captured and triaged for a later batch; they do not extend Task C. Do not declare broad
resolver quality from a few examples.

### STOP / REVIEW — Measured resolver improvement

Inspect the before/after replay, unchanged identity-write protections, complete candidate
ordering, and remaining field ledger. Decide whether the approved batch improved the
target signals without causing a protected-candidate leak or silently establishing an
alias.

Teach back: Why is a fixed batch plus before/after replay more informative than repairing
each annoying result immediately?

## Task D — Plan the focus-recovery spike and move on

Use captured deactivation and return evidence to write a self-contained ExecPlan for an
asynchronous Notes adapter spike. The plan must compare the current synchronous Service
with an Accessibility-backed, context-safe insertion path; address permission onboarding,
stale-note and stale-selection safety, cancellation, multiple pending invocations, focus
restoration, timeout behavior, and rollback. Planning does not authorize Accessibility
permission changes or implementation.

Record an explicit review cadence for the unresolved field ledger and a threshold for
starting another improvement batch. The default is periodic batch review, not continuous
interruption. Do not create a scheduled code-fixing loop until the read-only evaluator
has run successfully several times and a future checkpoint separately approves broader
authority.

### STOP / REVIEW — Durable continuation

Inspect the focus-spike plan, open-field-signal ledger, next review date or threshold,
scheduled evaluator behavior, and stopping rule. Decide whether Exercise 11 can end
without losing unresolved issues and whether the focus spike is the next product
priority.

Teach back: How does the durable ledger and scheduled read-only evaluation let you move
on without either forgetting issues or allowing an unattended agent to make product
decisions?

## Optional map connection

Connect this exercise to `AGENTIC_AI_MAP.md` under delivery loops and advanced
capabilities. The useful progression is manual workflow, deterministic evaluator,
observed unattended runs, and only then a reusable skill or more autonomous scheduled
task. Automation is transport for a proven loop, not a substitute for defining the loop.

After the user approves the final reflection and checkpoint, append learning evidence,
update justified skill confidence and progress, and advance to Exercise 12.
