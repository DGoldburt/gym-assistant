# Exercise 08 workflow evidence

Date: 2026-08-24
Environment: macOS 26.6, Apple Notes 4.13, locally built ad-hoc-signed `Gym Assistant.app`
Safety scope: only the note `Gym Assistant Exercise 08 — disposable` and the dedicated Gym Assistant SQLite library were changed.

## Result

The final adapter passed the four required Notes workflows. Interaction counts begin when resolver results are available and exclude opening the macOS Services menu. Latencies come from `events.jsonl` on one wall clock.

| Case | Selected input | Result | Deliberate actions | Relevant latency | Saved state | Returned Notes text and focus |
| --- | --- | --- | ---: | ---: | --- | --- |
| Obvious existing | `Front Squat` | Deterministic exact match | 0 | 21.0 ms service received → returning | No write | `Front Squat`; invoking Strength Training window and note body focused |
| Ambiguous | `Short-Lever Copenhagen Plank` | `Copenhagen Plank` shown as review candidate; cancelled | 1 Escape | 137.9 ms received → results ready; 16.1 ms cancel → returning | No alias or exercise | Input unchanged; invoking note body focused |
| Truly new | `Tall Kneeling Bottoms-Up KB Press` | Created from the prefilled one-field form | 2 Returns, 0 typing | 25.9 ms received → results ready; 22.7 ms save confirm → returning | One exercise and one preferred `userConfirmed` name | Identical selected text returned; invoking note body focused |
| Mistaken new | `Kickstand RDL` | Linked to existing `B-Stance RDL` | 1 Return | 36.8 ms received → results ready; 23.0 ms link confirm → returning | No new exercise; `Kickstand RDL` stored as a non-preferred `userConfirmed` alias | `B-Stance RDL`; invoking note body focused |

The new-exercise save-to-return result is 477.3 ms below the approved 500 ms limit. The case met the maximum two-action budget, required no typing, used one inline transition, and required no mouse.

## Persisted records

The final database inspection showed:

    5E6F787A  B-Stance RDL                       preferred userConfirmed
    5E6F787A  Kickstand RDL                      alias     userConfirmed
    9BAF55E6  Front Squat                        preferred userConfirmed
    D17C620F  Copenhagen Plank                   preferred userConfirmed
    D9ACDEE5  Tall Kneeling Bottoms-Up KB Press  preferred userConfirmed

`Short-Lever Copenhagen Plank` was absent, proving cancellation did not establish identity. The eight-character UUID prefixes are diagnostic labels only.

## Screenshots and logs

- `review-candidate.png` shows the real review panel with Copenhagen Plank and Create New Exercise as separate choices.
- `create-form.png` shows the same panel's one-field `Name` creation state.
- `events.jsonl` contains the complete setup, invalid exploratory invocation, accepted trials, and screenshot-only cancellation flow.

## Invalid and corrective evidence

The first setup invocation exceeded the Service's 30-second timeout because the operator paused to inspect accessibility state. The database write completed, but Notes rejected the late Service response; it is not counted as an acceptance trial.

The first exact-match exploration revealed that explicitly activating the first running Notes application could surface the wrong Notes window when multiple windows were open. The adapter removed that call and now relies on the native Services return. The final exact-match run returned to the invoking Strength Training window and focused disposable note body.

The first keyboard setup registered the app bundle from `/private/tmp`. It worked only as development-session state and disappeared after a computer restart: Gym Assistant was absent from both Notes → Services and Keyboard Shortcuts → Services. The rebuilt app was installed at `/Users/dan/Applications/Gym Assistant.app`, registered from that persistent location, and its native Service metadata declared `⌃⌥⌘G`. After Notes restarted, the learner manually confirmed both the Services menu item and shortcut worked.

## Friction and limitations

- The persistent Gym Assistant Text Service and `⌃⌥⌘G` shortcut passed a learner-run Notes trial. The UI automation can send keys to an application but cannot invoke global Service shortcuts, so this human evidence is the authoritative invocation result.
- Creating an exercise whose preferred text is identical to the selected text leaves the note visually unchanged. Persistence and focus were proven through the event log and database, but the user still lacks a lightweight success acknowledgement.
- The candidate panel uses only preferred names discovered from the persisted library. It does not yet search aliases as display candidates or expose preferred-name promotion.
- These are four targeted trials, not a repeated performance distribution. Exercise 11 remains responsible for the broader verification harness.
