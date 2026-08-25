# Exercise 09 Task C evidence

Date: 2026-08-24

## Scope and method

The locally installed `Gym Assistant` AppKit Service was exercised in a disposable
Apple Notes note. The trials used the Notes **Services > Gym Assistant** menu so UI
automation could type into and navigate the panel; the automation interface cannot
dispatch the macOS global keyboard shortcut. A physical-shortcut check therefore
remains a learner checkpoint requirement.

The retained screenshot, `autocomplete-panel.jpeg`, contains only the Gym Assistant
window. No Notes sidebar, client content, or private note titles are retained.

## Observed interactions

| Query | Inserted text | Evidence exercised |
| --- | --- | --- |
| `fro` | `Front Squat` | preferred-name prefix |
| `copen` | `Copenhagen Plank` | preferred-name prefix |
| `coppen` | `Copenhagen Plank` | fuzzy misspelling retrieval |
| `kick` | `B-Stance RDL` | confirmed-alias retrieval, deduplicated by exercise |
| `tall kneel` | `Tall Kneeling Bottoms-Up KB Press` | ordered token-prefix retrieval |
| `kick`, Right, Down | `Kickstand RDL` | deliberate confirmed-alias insertion |
| `Novel March` | `Novel March` | unmatched query returned without a library write |
| `front`, Escape | no change | cancellation integrity |

The five matched queries were approximately 63–73 percent shorter than the stored
text they inserted, so all five exceeded the 40 percent keystroke-reduction target.
The disposable note's surrounding brackets and lines were preserved, each accepted
choice was inserted once at the original cursor, and focus returned to Notes.

## Timing and reliability

- 20 warm invocations: 20/20 succeeded; median provider-received-to-panel-ready
  latency was 22.83 ms, nearest-rank p95 was 32.29 ms, and maximum was 35.18 ms.
- 5 cold process launches: 5/5 succeeded; app-launch-to-panel-ready measurements
  were 83.17–106.05 ms.
- 28 query updates: search-plus-table-refresh proxy median was 0.82 ms, p95 was
  1.86 ms, and maximum was 1.94 ms.
- 8 accepted insertions: insertion-event-to-service-return proxy maximum was
  6.96 ms.
- At least 25 automated cancellation repetitions left the disposable note unchanged;
  the required five cancellation trials therefore passed.

These timings come from process and service event boundaries in `events.jsonl`.
Cold launch does not include physical shortcut dispatch, query-update timing is a
search-and-refresh proxy rather than a rendered-frame measurement, and service
return is a focus-restoration proxy rather than direct visual focus instrumentation.
They are suitable regression evidence but do not replace the learner's usability
judgment. At the first physical-shortcut checkpoint, insertion succeeded but Notes
did not regain an active caret after the inserted text. That acceptance failure is
being corrected and must be retested; the earlier focus proxy did not detect it.

## Integrity and safety

The exercise-name database was snapshotted before and after the trials. Both
snapshots contained the same four exercises and five names, including the one
confirmed alias; there were zero exercise, alias, or preferred-name writes. There
were zero observed wrong-note, wrong-position, surrounding-text, or duplicate-
insertion failures.

An initial real-UI trial exposed an AppKit integration defect: the search field's
field editor consumed Return and arrow commands before the field subclass received
`keyDown`. Handling those commands at the `NSSearchFieldDelegate` boundary fixed
the failure, and the successful trials above use that corrected implementation.

Selected text continues to expose the existing review Service alongside the new
autocomplete Service. This compatibility check does not provide enough field-use
evidence to decide whether selected text should later enter replacement search.

## Automated verification

- Swift package: 33 tests across 7 suites passed.
- Resolver fixture exam: all 37 cases passed with zero false merges and zero
  protected-candidate leaks.
- Service property list, ad-hoc signature, and installed bundle were validated.

## Final checkpoint

The learner confirmed that Option-Command-G opens the panel, Return inserts at the
original cursor, immediate continued typing occurs after the inserted name, the
complete workflow is preferable to full-name typing in 5/5 matched scenarios,
`test` stays unmatched, every incremental Copenhagen query including `copp` remains
useful, and Escape closes the panel. The qualitative acceptance criterion was not
inferred from automated timings or keystroke counts.

The first complete-workflow preference result was 3/5 even though search succeeded
5/5, because Control-Option-Command-G required the learner to move a hand and look
down. The learner estimated 5/5 with an easier shortcut. Option-Command-G was
therefore approved for a focused retest; the acceptance threshold was not weakened.
Option-Command-G subsequently passed and raised the learner's complete-workflow
preference to 5/5. During that retest, the learner also found that the unrelated
short query `test` surfaced Tall Kneeling Bottoms-Up KB Press. This field-discovered
false suggestion became a regression case; short single-token fuzzy queries now
require stronger edit evidence while prefix and containment search remain unchanged.
The first correction exposed a discontinuity where `cop`, `coppe`, and `coppen`
found Copenhagen Plank but four-character `copp` did not. Progressive field input
therefore became an additional regression sequence. Short fuzzy evidence now also
compares a query with same-length candidate-token prefixes, retaining `copp` as a
one-edit prefix typo without readmitting unrelated `test`.

The same incremental trial exposed an Escape failure after extended inspection.
The event log showed that Escape changed the query to empty but emitted no
`autocomplete_cancelled` or service-return event: `NSSearchField` had consumed the
key as a clear action, and the panel remained after the 30-second Service timeout.
The panel now intercepts Escape before field handling and the autocomplete Service
allows a two-minute interaction window. Both changes require final physical retest.
