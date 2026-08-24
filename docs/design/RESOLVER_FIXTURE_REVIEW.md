# Resolver Fixture Review — Exercise 05 Task A

Status: proposed for learner review. The machine-readable source is [`Tests/Fixtures/resolver-cases.json`](../../Tests/Fixtures/resolver-cases.json).

These cases define product behavior before resolver implementation. `MUST_MATCH` is intentionally limited to an already confirmed name or a cosmetic normalization of one. Similarity alone never creates identity.

## Normalization assumptions for this exam

The fixtures safely assume that a future deterministic normalizer removes case differences; leading, trailing, or repeated whitespace; and a trailing period or exclamation point used as sentence punctuation. Thus ` FRONT   SQUAT `, `Front Squat!`, and `Front Squat.` may resolve to a stored `Front Squat` name. This task records that contract but does not implement the Exercise 06 normalizer.

This is a narrow terminal-punctuation allowlist, not a rule to strip all punctuation. Punctuation remains meaningful in names such as `1.5-Rep Squat`, `A1`, and slash-separated alternatives. No abbreviation, spelling, or semantic transformation is automatically assumed. Cases such as `SL RDL`, `DB Floor Press`, and `1-arm DB Row` appear in `MUST_MATCH` only because the fixture explicitly supplies them as already confirmed names.

## MUST_MATCH — 10

| Query | Existing exercise vocabulary | Why automatic resolution is safe |
| --- | --- | --- |
| `SL RDL` | Confirmed alias of `Single-Leg Romanian Deadlift` | Durable alias ownership already exists. |
| `1-leg RDL` | Confirmed alias of `Single-Leg Romanian Deadlift` | Numeric wording is authoritative only because it was confirmed. |
| `  single   leg rdl ` | Confirmed `Single Leg RDL` | Only case and repeated whitespace differ. |
| ` FRONT   SQUAT ` | `Front Squat` | Only case and spacing differ. |
| `DB Floor Press` | Confirmed alias of `Dumbbell Floor Press` | The abbreviation was confirmed. |
| `KB Deadlift` | Confirmed alias of `Kettlebell Deadlift` | The equipment abbreviation was confirmed. |
| `1-arm DB Row` | Confirmed alias of `One-Arm Dumbbell Row` | Numeric and equipment abbreviations were confirmed. |
| `chin-up` | `Chin-Up` | Only case differs. |
| `Front Squat!` | `Front Squat` | A trailing exclamation point used as sentence punctuation is cosmetic. |
| `Front Squat.` | `Front Squat` | A trailing period used as sentence punctuation is cosmetic. |

## MUST_NOT_MATCH — 17

| Query | Must remain distinct from | Protected meaning |
| --- | --- | --- |
| `RDL` | `Single-Leg Romanian Deadlift` | unilateral versus bilateral |
| `B-Stance RDL` | `Single-Leg Romanian Deadlift` | assisted stance versus fully unilateral |
| `Single-Leg Squat` | `Single-Leg Romanian Deadlift` | squat versus hinge |
| `Paused Back Squat` | `Back Squat` | pause prescription |
| `Deficit Deadlift` | `Deadlift` | range of motion |
| `Incline Dumbbell Bench Press` | `Dumbbell Bench Press` | bench angle |
| `Half-Kneeling Landmine Press` | `Standing Landmine Press` | body position |
| `Strict Press` | `Push Press` | absence or use of leg drive |
| `Chest-Supported Row` | `Bent-Over Row` | torso support |
| `Goblet Squat` | `Barbell Front Squat` | loading implement |
| `Supinated-Grip Row` | `Neutral-Grip Row` | grip orientation |
| `Banded Deadbug` | `Deadbug` | added band resistance or assistance |
| `Banded Anti-Rotation Deadbug` | `Banded Deadbug` | rotational stability demand |
| `High-to-Low Cable Fly` | `Low-to-High Cable Fly` | non-bench line-of-pull angle |
| `Lateral Lunge` | `Reverse Lunge` | frontal-plane versus sagittal-plane movement |
| `Box Squat` | `Squat to Target` | weight transfer and target-contact intent |
| `Short-Lever Copenhagen Plank` | `Long-Lever Copenhagen Plank` | lever length, adductor loading, and progression level |

These are the most costly category to get wrong: an automatic false merge would establish or reuse the wrong stable identity and could later contaminate history.

## SUGGEST_REVIEW — 10

| Query | Candidate | Why confirmation remains necessary |
| --- | --- | --- |
| `Kickstand RDL` | `B-Stance RDL` | Usage often overlaps but may encode different stance conventions. |
| `Australian Row` | `Aussie Pull-up` | Likely the same pattern, but not yet authoritative. |
| `Bulgarian Split Squat` | `Rear-Foot-Elevated Split Squat` | Common usage overlaps while setup conventions can differ. |
| `Paloff Press` | `Pallof Press` | Likely misspelling, but similarity is not ownership. |
| `Nordic Hamstring Curl` | `Nordic Curl` | Common overlap still requires confirmation. |
| `Landmine Rainbow` | `Landmine Rotation` | Informal names may hide technique differences. |
| `Short-Lever Copenhagen Plank` | `Copenhagen Plank` | Unqualified wording does not establish long-lever identity unless explicitly defined. |
| `Single-Arm Overhead Carry` | `One-Arm Overhead Carry` | Plausible synonym that has not yet been confirmed. |
| `Copenhagen` | `Copenhagen Plank` | A likely omitted suffix is not authoritative identity. |
| `Coppenhagen` | `Copenhagen Plank` | A likely misspelling plus omitted suffix requires confirmation once; a confirmed typo becomes a durable alias and resolves automatically thereafter. |

## Scope boundary

This task contains fixture data only. It does not implement normalization, exact lookup, fuzzy similarity, candidate ranking, or a fixture runner. Task B adds the runner; Exercises 06 and 07 implement deterministic and fuzzy resolver behavior.

## Review questions

1. Does any proposed automatic match assume more than confirmed-name ownership plus the explicit case-and-whitespace normalization contract?
2. Which `MUST_NOT_MATCH` pair would be most damaging to merge automatically?
3. Should any `SUGGEST_REVIEW` pair be omitted from candidate generation entirely? Conversely, do you already know from your own vocabulary that any pair is the same identity and should be represented separately as an explicitly pre-confirmed `MUST_MATCH` fixture?
4. Are important modifiers missing—especially stance, range of motion, tempo, pause, body position, bench angle, grip, support, or loading implement?
