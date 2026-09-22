# Gym Assistant Signal Review

This file is the version-controlled source of truth for the scheduled field-feedback
review. The deployed Codex automation configuration is an operational copy. Review and
approve changes here before updating that configuration.

## Schedule

- Name: `Gym Assistant signal review`
- Cadence: daily at 09:00 local time
- Environment: local `gym_assistant` project
- Evaluator: `/Users/dan/Applications/Gym Assistant.app/Contents/MacOS/FieldFeedbackReport`
- Foreground disposition writer: `/Users/dan/Applications/Gym Assistant.app/Contents/MacOS/SetFieldFeedbackDisposition`

The evaluator binary is packaged by `app/notes-service/build.sh`. Invoking the installed
binary avoids requiring an unattended task to compile the Swift package or write compiler
caches. The local machine and Codex desktop app must be running for the task to execute.

The trusted project rule `.codex/rules/field-feedback.rules` permits only the installed
`FieldFeedbackReport` executable prefix to run outside the workspace sandbox. It does not
permit `swift`, a shell, or the Gym Assistant Service executable. Because Codex command
rules are prefix rules, future arguments to this exact executable would also match; the
current evaluator accepts no operational arguments. Review the rule and evaluator together
if command-line options are added later.

## Deployed prompt

Run the verified Gym Assistant field-feedback evaluator outside the workspace sandbox by
executing `/Users/dan/Applications/Gym Assistant.app/Contents/MacOS/FieldFeedbackReport`
through its approved project-local `allow` rule. Request elevated execution for this exact
command so Codex evaluates `.codex/rules/field-feedback.rules`; do not first run it inside
the sandbox. This approved rule is the intended permission path, not a new permission
broadening.

This task may read the private Gym Assistant field-interaction store and may update only
its separate private signal ledger. Do not reproduce private record contents except for
the narrowly bounded signal evidence defined below.

For each open signal, present its stable case ID, category, occurrence count, disposition,
first and last observation dates, and the evaluator's bounded supporting evidence. A
focus-friction case may show workflow, outcome, focus-loss count, return result, and
return-to-outcome timing, but not exercise text. A ranking anomaly or explicit user flag
may show the affected query or observation and at most five candidate rows plus a
selected or highlighted row outside that bound. This narrow private evidence is allowed
because it is necessary for the user to make the foreground disposition decision. Do not
read unrelated Notes or seek additional client/program context outside the captured Gym
Assistant evidence.

An explicit Report Issue event may also have a private panel-only PNG keyed by event ID.
When the evaluator lists one, inspect it and include the panel image or a concise account
of its decision-relevant visible state in the review case. Context already visible inside
the private Gym Assistant panel—including an `Observed in` field—is authorized review
evidence and must not cause the image to be withheld or escalated as a privacy failure.
The capture must contain only the Gym Assistant window, never the Notes window or full
screen. Do not copy screenshots into the repository, automation memory, or another
durable location.

Report Issue is intentionally a one-action capture and does not ask the user to explain
what was surprising. Treat absent prose as expected, not as missing telemetry. Infer the
most likely concern from ordering, scores, selection, aliases, and screenshot state;
label that inference as an AI hypothesis with confidence. If the concern remains
ambiguous, say so once and invite an optional rationale with the user's queued decision.

Do not modify repository source files, tests, documentation, Git state, the live exercise
library, exercise identity, product success criteria, or the human-controlled signal
dispositions `acceptedForBatch`, `deferred`, and `resolved`.
Never invoke `SetFieldFeedbackDisposition` during an unattended run. It is a separate
foreground-only authority that requires explicit user approval and interactive
confirmation.

Always summarize the open `new` and `reproduced` ledger entries by signal category,
occurrence count, and disposition, even when replay adds no new occurrences. “Replay was
quiet” means only that the evaluator found no new event IDs; it does not mean that no
findings await human review. Also report the bounded aggregate interaction metrics.
Raise open findings for human review without proposing or applying a fix.

Also summarize the evaluator's separate **Accepted batch queue**. These entries are no
longer open disposition work, but their stable IDs and bounded evidence must remain
visible as read-only inputs to the next approved intervention. Do not mix them back into
the interactive disposition deck and do not interpret acceptance as authority to fix.

Present the evaluator's interaction-trend Markdown table. It compares the latest ten
interaction events with the preceding ten and includes sample sizes. Do not compute a
moving average across report runs: unchanged replays would overweight the same events.
Call out insufficient samples, especially when selection-rate denominators are small.

Reduce the reviewer's cognitive load. Begin with a two-to-four sentence **AI assessment**
that identifies the most consequential pattern, distinguishes safety or correctness from
friction, and recommends the next human review action with a confidence qualifier. This
is advisory analysis, never a disposition or authorization to fix the product. Then show
a compact index of every open case by stable ID, category, occurrence count, and current
disposition so none can be forgotten.

Use the available Visualize capability to render the open cases as one inline interactive
card deck in the automation result. Follow the visualization skill's file and content-
reference contract exactly; emit the native visualization reference, not its raw text in
a code block. Order cards by strongest safety/correctness evidence, repeated user flags,
other user flags, then friction. Each card is expanded one at a time and includes:

- `Signal X of N`, stable case ID, category, occurrences, dates, and disposition.
- The AI hypothesis and confidence.
- Bounded structured evidence and the panel screenshot when present.
- A compact optional-rationale field.
- One locally selected decision:

- **Accept for batch** — include it in a bounded improvement batch.
- **Defer** — preserve it but intentionally postpone action.
- **Resolve** — close it while retaining evidence and history.
- **Keep open** — make no ledger change.

Previous and Next controls change cards locally without starting a Codex turn. Preserve
the current card, tentative decisions, and rationales in visualization widget state. Show
the metrics comparison table above the deck. A final **Review queued decisions** control
uses `window.openai.sendFollowUpMessage` to send one concise proposed batch containing
stable IDs, tentative dispositions, and rationales back to the automation task. It must
not claim or imply that the ledger was updated.

The visualization may embed the private panel screenshots needed for this single-user
review in its task-owned local visualization file. Keep that file outside the repository
and automation memory. Do not include unrelated Notes content beyond what is already
visible inside the captured Gym Assistant panel. If Visualize is unavailable or cannot
render, fall back to one structured Markdown batch and explicitly report the rendering
limitation rather than reverting to a multi-turn sequential walkthrough.

When the visualization sends the proposed batch, show one consolidated list of case IDs,
transitions, and rationales. Invoke the separate interactive setter once only after the
user gives final confirmation of that complete batch. The setter queues the same changes
and performs one atomic ledger save after its own `APPLY` confirmation. Never treat an
AI assessment, local card selection, submitted proposal, or recommendation as final
authorization.

Escalate malformed or incompatible records, evaluator failure, a protected-conflict leak,
unstable replay, or a materially repeated user or focus-friction signal. Never request,
add, or use any permission beyond the existing exact evaluator rule; report any other
sandbox failure for human review.

## Authority boundary

The evaluator may append or atomically replace only files in the private field-feedback
store under Gym Assistant Application Support. Its normal durable write is
`signal-ledger.json`. It has no dependency on `ExerciseLibrary` and must never open or
change the live exercise database.

The scheduled agent may automatically classify a mechanically repeated occurrence as
`reproduced`. Only the user may authorize `acceptedForBatch`, `deferred`, or `resolved`.
The automation reports findings; it does not implement fixes.

After the user confirms a complete disposition batch in a foreground Codex conversation,
invoke the installed `SetFieldFeedbackDisposition` executable with no arguments through
its separate project rule. Supply each stable case ID, approved disposition, and optional
rationale to its interactive queue; submit a blank case ID to finish, then type `APPLY`
only after verifying the printed batch against the user's instruction. The executable
rejects automatic states and arguments, then records the whole batch and its rationales
in one atomic ledger save. Do not edit `signal-ledger.json` directly.

## Verification and recovery

Before deploying a prompt change, run the evaluator manually and then repeat it unchanged.
The second run must say that replay was quiet. Review the first scheduled runs after any
prompt, binary, permission, or cadence change.

If execution fails, preserve the failure in the automation run history and stop. Do not
grant broader access or substitute another command silently. Rebuild and reinstall Gym
Assistant if the packaged evaluator is missing. Deleting private interactions or the
ledger is outside this procedure and requires explicit approval.

Validate the project rule explicitly from the repository root:

    codex execpolicy check --pretty \
      --rules .codex/rules/field-feedback.rules \
      -- "/Users/dan/Applications/Gym Assistant.app/Contents/MacOS/FieldFeedbackReport"

The strictest decision must be `allow`. Repeat with `swift run FieldFeedbackReport` and
with the Service executable; neither command may match this rule.

Separately check the no-argument `SetFieldFeedbackDisposition` executable. Its own rule
allows the executable prefix; like every Codex prefix rule it also matches trailing
arguments, so the executable must reject all arguments before opening the ledger. Verify
that rejection directly. The unattended automation is forbidden from invoking the
setter even though a foreground Codex task may do so after explicit approval.
