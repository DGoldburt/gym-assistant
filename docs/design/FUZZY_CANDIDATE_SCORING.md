# Fuzzy Candidate Scoring Proposal

Status: approved for Exercise 07 Task B implementation; no candidate generator is implemented by this decision.

## Identity boundary

- Similarity may rank review candidates but must never establish exercise identity.
- Only deterministic lookup through a durable confirmed name may resolve automatically.
- User confirmation, not score, may create a durable alias relationship.

## Ranking evidence

Candidate ranking may use token overlap, edit similarity, phrase containment, narrowly defined linguistic equivalence, exercise-family overlap, and cosmetic word-order or punctuation tolerance.

## Protected modifiers

Exclude a candidate when its known meaning conflicts with the query on a protected dimension:

- laterality or assistance
- body position
- loading implement
- grip
- angle or line of pull
- range, tempo, or pause
- support or target-contact intent
- plane of motion
- lever length or progression level
- banded loading or anti-rotation intent

Exclusion is intentional: a lower-ranked conflicting candidate could still tempt the user to merge meaningfully different exercises. It is safer to create two exercises and defer possible duplicate detection and merging to a separate, explicitly reviewed future workflow.

## Threshold behavior

- High similarity: rank near the top of the review list.
- Medium similarity: rank lower.
- Low similarity: omit as noise.
- Protected-modifier conflict: exclude regardless of textual similarity.
- No adequate candidate: leave unresolved and allow the later new-exercise workflow.

Numerical weights and thresholds remain implementation hypotheses to calibrate against the fixture suite in Task B.

## Required stress cases

- Incline Press must not imply Flat Press.
- Single-Leg RDL must not imply bilateral or B-Stance RDL.
- Half-Kneeling Press must not imply Standing Press.
- Paused Squat must not imply ordinary Squat.
- Front Squat must not imply Goblet Squat.
