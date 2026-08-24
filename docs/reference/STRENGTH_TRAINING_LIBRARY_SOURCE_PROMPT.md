# Strength Training Notes Exercise-Source Prompt

Use this prompt to ask ChatGPT to prepare source evidence from the Apple Notes
folder `Strength Training`. The output is deliberately not an import-ready set of
canonical exercises. Exercise identity, alias grouping, and duplicate decisions
belong to Gym Assistant's exercise-identity review workflow and require user
confirmation.

## Prompt

> Review every program note available to you in my Apple Notes folder named
> `Strength Training` and prepare a high-recall inventory of exercise wording for
> a later Gym Assistant import review.
>
> This is an extraction task, not an exercise-identity or data-cleaning task. Do
> not decide that two names are aliases. Do not choose canonical names. Do not
> merge, correct, standardize, expand, rename, or deduplicate different observed
> strings, even when they appear obviously equivalent. For example, preserve
> `SL RDL`, `1-leg RDL`, and `Single-Leg Romanian Deadlift` as three separate
> observed strings. Do not infer that similarly named exercises are the same, and
> do not infer that differently named exercises are different.
>
> Include every line or line fragment that plausibly names a programmed exercise,
> mobility drill, warm-up movement, carry, conditioning movement, or exercise
> variation. Bias toward inclusion. When a line is ambiguous, include it and mark
> it for human review instead of excluding it. Do not treat sets, reps, loads,
> tempo, coaching cues, section headings, or client names as part of an observed
> exercise name, but preserve the complete source line so I can audit your
> extraction.
>
> Return UTF-8 CSV with exactly these columns:
>
> `observed_name_verbatim,source_note,source_line_verbatim,occurrence_count,extraction_status,extraction_note`
>
> Use one row for each distinct verbatim exercise-name string within a source note.
> `occurrence_count` is the number of exact occurrences of that same string in
> that note. `extraction_status` must be either `plausible_exercise` or
> `needs_human_review`. Keep `extraction_note` short and use it only to explain
> extraction uncertainty, such as whether a phrase is a heading, cue, or exercise.
>
> Do not add columns for canonical name, alias, duplicate group, exercise ID,
> movement pattern, equipment, or recommended merge. Do not produce a cleaned
> exercise library. Before returning the CSV, report the number of notes reviewed,
> any notes you could not access, and the number of extracted rows so I can check
> coverage.

## Required human checks

Before using the output, the user inspects:

- whether every intended note was accessible and reviewed;
- a sample of source lines against the original Notes;
- every `needs_human_review` row;
- whether exercise modifiers were preserved in `observed_name_verbatim`;
- whether headings, coaching cues, sets, reps, loads, or client names leaked into
  the proposed exercise wording.

ChatGPT's output is source evidence only. The exercise-identity review workflow
later decides whether an observed name links to an existing exercise, creates a
new exercise, remains separate from a similar exercise, or is deferred.
