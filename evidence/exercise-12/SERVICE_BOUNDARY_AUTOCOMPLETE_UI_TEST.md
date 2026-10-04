# Exercise 12 Task C — Service-Boundary Autocomplete UI Test

Date: 2026-10-03

## Purpose

Exercise one bounded Gym Assistant invocation while keeping three evidence sources
distinct:

1. deterministic shell checks,
2. the command-line-to-AppKit bridge,
3. independent accessibility/visual inspection.

This test calls the installed Gym Assistant Service, interacts with its autocomplete UI
by keyboard, and verifies that the chosen text returns across the Service boundary. It
does not test Apple Notes, Notes insertion, caret placement, focus restoration, or human
usability.

## Synthetic service case

Create a private synthetic pasteboard owned by a temporary CLI process, invoke the
installed `Gym Assistant` macOS Service, search for `seated row`, choose the first ranked
result, and inspect the text returned to the CLI pasteboard. The expected return value is
`seated band row`.

## Observed evidence

| Claim | Evidence source | Result |
| --- | --- | --- |
| The installed app is signed and declares the `autocompleteExercise` service. | `codesign --verify --strict` and installed `Info.plist` inspection | Pass. Bundle hash: `1565295f208f20d6a42bb72d4aeb6292896d3fa4e3f8e7568248195d1120c14c`. The declaration restricts normal service availability to Notes, while the direct AppKit probe invokes the service by name. |
| A command-line process can invoke the installed macOS Service. | Temporary AppKit probe using `NSPerformService("Gym Assistant", pasteboard)` | Pass: `serviceStarted=true`. |
| The service displayed ranked autocomplete candidates for the synthetic query. | Independent Computer Use accessibility state and visual inspection | Pass. The query `seated row` displayed `seated band row` and `Seated Cable Row` at `.999`, followed by lower fuzzy results. |
| The selected result crossed back over the command-line bridge. | Probe pasteboard output | Pass: `returnedText=seated band row`. |

## Exact command-line bridge

The probe used a private, synthetic pasteboard and the already-installed service:

```sh
swift -e 'import AppKit; let pasteboard = NSPasteboard(name: NSPasteboard.Name("com.dangoldburt.gym-assistant.exercise12.synthetic")); pasteboard.clearContents(); let started = NSPerformService("Gym Assistant", pasteboard); print("serviceStarted=\(started)"); print("returnedText=\(pasteboard.string(forType: .string) ?? "<none>")")'
```

Observed output after selecting the first candidate:

```text
serviceStarted=true
returnedText=seated band row
```

## Calibration failure kept separate

- The first sandboxed Swift probe could not write to the compiler module cache outside
  the repository. Re-running the same narrow probe with explicit authorization reached
  the service. This is a sandbox-boundary result, not a product failure.

## Reproduction procedure

1. Run the exact AppKit probe above from a CLI process with permission to use Swift's
   compiler cache and invoke the installed Service.
2. In the Gym Assistant panel, enter `seated row`.
3. Select the first ranked candidate and press Return.
4. Confirm that the CLI prints `serviceStarted=true` and
   `returnedText=seated band row`.
5. Do not report this result as evidence about Notes insertion, focus, caret placement,
   or usability.

## Execution mode

The observed run was automated, but it was not performed by the CLI process alone. The
CLI-owned AppKit probe invoked the Service and waited for its return value. An independently
authorized desktop Computer Use process entered the query, inspected the candidate list,
selected the first row, and pressed Return. A future CLI-only runner would need its own
authorized keyboard/UI automation mechanism and must preserve the same evidence boundaries.

## Current checkpoint boundary

This artifact is named for the complete boundary it exercises: installed Service
invocation, keyboard interaction with the autocomplete UI, and selected-value return.
It makes no claim about Notes or human usability.
